type form = array Point.t;

type cpt = (float * float);

type t;

(* создает сруктуру t и заплняет массивы цвета и текстуры *)
external makeTexGrid	: int -> (float * float * float * float) -> float -> t = "ml_make_grid_tex";
(* заполняет массивы вертексов *)
external makeVertGrid	: t -> array cpt -> float -> int -> (float * float) -> unit = "ml_make_grid_vert";
external renderGrid		: Matrix.t -> t -> LightCommon.textureID -> Render.prg -> unit = "ml_render_grid" "noalloc";

(*
	порядок точек в массиве:

	0 1 2
	7   3
	6 5 4
	
	нормальные значения(x,y):
	(-1,  1) (0,  1) (1,  1)
	(-1,  0)         (1,  0)
	(-1, -1) (0, -1) (1, -1)
*)

type pointIndex =	[LeftTop
					|Top
					|RightTop
					|Right
					|RightBottom
					|Bottom
					|LeftBottom
					|Left];

value indexToInt a = match a with
						[LeftTop	-> 0
						|Top		-> 1
						|RightTop	-> 2
						|Right		-> 3
						|RightBottom-> 4
						|Bottom		-> 5
						|LeftBottom	-> 6
						|Left		-> 7];

value linesCrossing (a,b) (c,d) =
	let open Point in
	let signf a = if a = 0.
					then 0.
				  else if a < 0.
					then -1.
				  else 1. in
	let fixf a = if a < 0.001 && a > (-. 0.001) then 0. else a in
	let vectorMul v1 v2 = signf (fixf (v1.x *. v2.y -. v2.x *. v1.y)) in
	let mkv b a = {x = a.x -. b.x; y = a.y -. b.y} in
	let abc = vectorMul (mkv a b) (mkv a c)
	and abd = vectorMul (mkv a b) (mkv a d)
	and cda = vectorMul (mkv c d) (mkv c a)
	and cdb = vectorMul (mkv c d) (mkv c b) in
	if (abc <> abd && cda <> cdb) || (abc = 0. && abd = 0. && cda = 0. && cdb = 0.)
		then 1
		else 0;


class c pts s q t =
	let getClp t =
		let open Texture in
		let open Rectangle in
		match t#renderInfo.clipping with
							[Some r -> (r.x, r.y, r.width, r.height)
							|_		-> (0.,  0.,  1.,      1.)] in
	(* свапает верхние с нижними и убирает отрицательные значения *)
	let correctForm form =
		let open Point in
		let sx = form.(0).x and sy = form.(0).y in
		let (mx,my) = Array.fold_left (fun (mx,my) p -> (min mx p.x, min my p.y)) (sx,sy) form in
		let form' = Array.copy form in
		let sw a b =
			let mi a = {(a) with y = a.y *. (-1.)} in
			let t = form.(a) in (
				form'.(a) := mi form.(b);
				form'.(b) := mi t;
		) in (
			sw 0 6;
			sw 1 5;
			sw 2 4;
			form'
	) in

	let ptToCpt {Point.x=x;Point.y=y} = (x,y) in
	let makeArrays form step qty sz clp =	
		let t = makeTexGrid qty clp step in (
			makeVertGrid t (Array.map ptToCpt form) step qty sz;
			t
	) in
	object(self)
		inherit(DisplayObject.c) as super;
		value mutable points			: form = pts;
		value mutable step				: float = 0.1;
		value mutable qty				: int = 10;
		value mutable arrays 			: lazy_t t = lazy (makeArrays (correctForm pts) s q (t#renderInfo.Texture.rwidth,t#renderInfo.Texture.rheight) (getClp t));
		value mutable setVertexArray	: lazy_t unit = lazy ();
		method arrays = Lazy.force arrays;
		method points = Array.copy points;
		(* tex to draw *)
		value mutable tex				: Texture.c = t;
		method texture = tex;	
		method setPoints p = (
			points := p;
			setVertexArray := lazy (makeVertGrid (Lazy.force arrays) (Array.map ptToCpt (correctForm p)) step qty (t#renderInfo.Texture.rwidth,t#renderInfo.Texture.rheight));
		);
		method step = qty;
		method setStep a = (
			step := 1. /. (float_of_int a);
			qty := a;	
			arrays := lazy (makeArrays (correctForm points) step qty (tex#renderInfo.Texture.rwidth,tex#renderInfo.Texture.rheight) (getClp t));
			setVertexArray := lazy (self#setPoints points);
		);
		method setTexture t = (
			tex := t;
			self#setStep qty;
			(* self#setPoints pointsSrc; *)
		);
		value mutable color = `NoColor;
		method color = color; (* raise (StrEx "bezier has no color"); *)
		method setColor c =
			if c <> color
			then
				(
					self#forceStageRender ~reason:"bezier set color" ();
					color := c;
				)
			else ();
		value mutable filters = [];
		method filters = filters;
	    method setFilters f = filters := f;
		method! hitTestPoint' pt _ = 
			(* let _ = Printf.printf "%f %f\n%!" pt.Point.x pt.Point.y in *)
			let maxP = 8 in
			let w = tex#width in
			let h = tex#height in
			let pts = Array.map (fun p -> Point.({x = p.x *. w /. 2.; y = p.y *. h /. 2.})) (correctForm points) in
			let rec loop n acc testPair = if n >= 8
				then acc + linesCrossing (pts.(0), pts.(7)) testPair
				else loop (n+1) (acc + linesCrossing (pts.(n-1), pts.(n)) testPair) testPair in
			let crossCounts = loop 1 0 (pt, Point.create 100000. 0.) in
			if crossCounts mod 2 = 1
				then Some (self :> DisplayObject.c)
				else None;

		method! width =
			let open Point in
			let startVal = points.(0).x in
			let (mi,ma) = Array.fold_left (fun (mi,ma) p -> (min p.x mi, max p.x ma)) (startVal,startVal) (correctForm points) in
			(* let () = Printf.printf "wi - mi:%f ma:%f\n%!" mi ma in *)
				(ma -. mi) *. tex#width /. 2.;
		method! height = 
			let open Point in
			let startVal = points.(0).y in
			let (mi,ma) = Array.fold_left (fun (mi,ma) p -> (min p.y mi, max p.y ma)) (startVal,startVal) (correctForm points) in
			(* let () = Printf.printf "he - mi:%f ma:%f\n%!" mi ma in *)
				(ma -. mi) *. tex#height /. 2.;
		method texWidth = tex#width;
		method texHeight = tex#height;
		method relativeWidth  = self#width -. tex#width;
		method relativeHeight = self#height -. tex#height;
		method boundsInSpace targetCoordinateSpace = (
			let open Point in
			let tw = tex#width /. 2.
			and th = tex#height /. 2. in
			let pts = match targetCoordinateSpace with
							[Some o when o#asDisplayObject = self#asDisplayObject -> Array.map (fun p -> {x = p.x *. tw; y = p.y *. th}) (correctForm points)
							|_ ->
								let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
								Array.map (fun p -> (Matrix.transformPoint transformationMatrix) {x = p.x *. tw; y = p.y *. th}) (correctForm points)] in
			let () = debug:matrix "call transformPoints" in
			let open Point in
			let foldFunc (xm,ym,xM,yM) {x=x;y=y} = (min x xm, min y ym, max x xM, max y yM) in
			let fp = pts.(0) in
			let (lmx,lmy,lMx,lMy) = Array.fold_left foldFunc (fp.x,fp.y,fp.x,fp.y) pts in
			let w = lMx -. lmx and h = lMy -. lmy in
			Rectangle.create lmx lmy w h;
		);	

		method private render' ?alpha:(a) ~transform rect =
			let open Texture in
			let ri = tex#renderInfo in
			let id = ri.rtextureID in
			let () = Lazy.force setVertexArray in
			renderGrid	(if transform then self#transformationMatrix else Matrix.identity)
						self#arrays
						id
						(GLPrograms.Image.Normal.create ());
		(* points interface *)
		method getPoint ind = points.(indexToInt ind);
		method setPoint ind p = (
			points.(indexToInt ind) := p;
			self#setPoints points;
		);
	end;

value form ltx lty tx ty rtx rty rx ry rbx rby bx by lbx lby lx ly =
	let c = Point.create in
	Array.of_list [c ltx lty; c tx ty; c rtx rty; c rx ry; c rbx rby; c bx by; c lbx lby; c lx ly];

value normalForm () =
	let c = Point.create in
	Array.of_list [c (-1.) (1.); c 0. (1.); c 1. (1.); c 1. 0.; c 1. (-1.); c 0. (-1.); c (-1.) (-1.); c (-1.) 0.];

value create (form : form) (tex : Texture.c) = new c form 0.1 10 tex;
