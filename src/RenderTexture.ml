open LightCommon;
open Texture;
open ExtList;

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";
external delete_textureID: textureID -> unit = "ml_render_texture_id_delete" "noalloc";
(* external rendertexture_resize: renderInfo -> float -> float -> bool = "ml_rendertexture_resize"; *)


type framebuffer;
external renderbuffer_draw: ~filter:filter -> ?clear:(int*float) -> textureID -> int -> int -> float -> float -> (framebuffer -> unit) -> renderInfo = "ml_renderbuffer_draw_byte" "ml_renderbuffer_draw";
external renderbuffer_draw_to_texture: ?clear:(int*float) -> ?new_params:(int * int * float * float) -> ?new_tid:textureID -> renderInfo -> (framebuffer -> unit) -> unit = "ml_renderbuffer_draw_to_texture";
external create_renderbuffer_tex: unit -> textureID = "ml_create_renderbuffer_tex";
external _renderbuffer_tex_size: unit -> int = "ml_renderbuffer_tex_size";


value renderbufferTexSize = _renderbuffer_tex_size ();

external renderbuffer_save: renderInfo -> string -> bool = "ml_renderbuffer_save";

type data = Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;
external renderbuffer_data: renderInfo -> data = "ml_renderbuffer_data";

module Renderers = Weak.Make(struct type t = renderer; value equal r1 r2 = r1 = r2; value hash = Hashtbl.hash; end);

module FramebufferTexture = struct
  module Point =
    struct
      type t = (int * int);

      value create x y = (x, y);
      value x (x, _) = x;
      value y (_, y) = y;
      value toString pnt = Printf.sprintf "(%d, %d)" (x pnt) (y pnt);

      value xBetween (x, _) (xA, _) (xB, _) = ((min xA xB) <= x) && (x <= (max xA xB));
      value yBetween (_, y) (_, yA) (_, yB) = ((min yA yB) <= y) && (y <= (max yA yB));
      value equal (xA, yA) (xB, yB) = xA = xB && yA = yB;
    end;

  module Rectangle = 
    struct
      type t = (Point.t * Point.t);

      value fromPnts lb rt = (lb, rt);
      value fromCoords lbX lbY rtX rtY = fromPnts (Point.create lbX lbY) (Point.create rtX rtY);
      value fromCoordsAndDims x y w h = fromPnts (Point.create x y) (Point.create (x + w) (y + h));
      value fromPntAndDims pnt w h = fromPnts pnt Point.(create (x pnt + w) (y pnt + h));

      value leftBottom (lb, _) = lb;
      value rightTop (_, rt) = rt;
      value width (lb, rt) = Point.(x rt - x lb);
      value height (lb, rt) = Point.(y rt - y lb);
      value x (lb, _) = Point.x lb;
      value y (lb, _) = Point.y lb;

      value toString rect = Printf.sprintf "(%d, %d, %d, %d)" (x rect) (y rect) (width rect) (height rect);

      value isDegenerate (lb, rt) = Point.(x lb = x rt || y lb = y rt);

      value pntInside (lb, rt) pnt = Point.(xBetween pnt lb rt && yBetween pnt lb rt);

      value rectInside outer (lb, rt) = pntInside outer lb && pntInside outer rt;

      value intersects (lbA, rtA) (lbB, rtB) = not Point.(x rtA < x lbB || x rtB < x lbA || y rtA < y lbB || y rtB < y lbA);

      value intersection (lbA, rtA) (lbB, rtB) =
        let left = Point.(max (x lbA) (x lbB)) in
        let right = Point.(min (x rtA) (x rtB)) in
          if left > right
          then None
          else
            let bottom = Point.(max (y lbA) (y lbB)) in
            let top = Point.(min (y rtA) (y rtB)) in
            if top < bottom
            then None
            else
              (* let () = debug "left %d bottom %d right %d top %d" left bottom right top in *)
              let intersection = fromCoords left bottom right top in
                if isDegenerate intersection then None else Some intersection;

      value minus (lbFrom, rtFrom) (lbRect, rtRect) =
        let addRect lbx lby rtx rty retval =
          let rect = fromCoords lbx lby rtx rty in
            if isDegenerate rect then retval else [ rect :: retval ]
        in
          Point.(
            let retval = addRect (x lbFrom) (y lbFrom) (x lbRect) (y rtFrom) [] in
            let retval = addRect (x lbRect) (y lbFrom) (x rtRect) (y lbRect) retval in
            let retval = addRect (x lbRect) (y rtRect) (x rtRect) (y rtFrom) retval in
              addRect (x rtRect) (y lbFrom) (x rtFrom) (y rtFrom) retval;
          );

      value areContiguous (lbA, rtA) (lbB, rtB) =
        Point.((x lbA = x lbB || x lbA = x rtB) && (yBetween lbA lbB rtB || yBetween rtA lbB rtB)
          || (y lbA = y lbB || y lbA = y rtB) && (xBetween lbA lbB rtB || xBetween rtA lbB rtB));

      value equal (lbA, rtA) (lbB, rtB) = Point.(equal lbA lbB && equal rtA rtB);
    end;

  module Hole =
    struct
      value plus holeA holeB =
        let lbHA = Rectangle.leftBottom holeA in
        let rtHA = Rectangle.rightTop holeA in

        let lbHB = Rectangle.leftBottom holeB in
        let rtHB = Rectangle.rightTop holeB in

          Point.(
            let newHoleA = Rectangle.fromCoords (max (x lbHA) (x lbHB)) (min (y lbHA) (y lbHB)) (min (x rtHA) (x rtHB)) (max (y rtHA) (y rtHB)) in
            let newHoleB = Rectangle.fromCoords (min (x lbHA) (x lbHB)) (max (y lbHA) (y lbHB)) (max (x rtHA) (x rtHB)) (min (y rtHA) (y rtHB)) in

            let holes = if Rectangle.isDegenerate newHoleA then [] else [ newHoleA ] in
              if Rectangle.isDegenerate newHoleB then holes else [ newHoleB :: holes ];
          );

      value minus hole rect =
        let lbH = Rectangle.leftBottom hole in
        let rtH = Rectangle.rightTop hole in

        let lbR = Rectangle.leftBottom rect in
        let rtR = Rectangle.rightTop rect in

          Point.(
            let holes = if x rtR < x rtH then [ Rectangle.fromCoords (x rtR) (y lbH) (x rtH) (y rtH) ] else [] in
            let holes = if y rtR < y rtH then [ Rectangle.fromCoords (x lbH) (y rtR) (x rtH) (y rtH) :: holes ] else holes in
            let holes = if x lbH < x lbR then [ Rectangle.fromCoords (x lbH) (y lbH) (x lbR) (y rtH) :: holes ] else holes in
              let holes = if y lbH < y lbR then [ Rectangle.fromCoords (x lbH) (y lbH) (x rtH) (y lbR) :: holes ] else holes in
              let () = debug "cut %s from hole %s: %s" (Rectangle.toString rect) (Rectangle.toString hole) (String.concat "," (List.map (fun rect -> Rectangle.toString rect) holes)) in
                holes; 
          );
    end;

  module Bin =
    struct
      exception CantPlace;

      type t = {
        width: int;
        height: int;
        holes: mutable list Rectangle.t;
        rects: mutable list Rectangle.t;
        needRepair: mutable bool;
      };

      value create width height = { width; height; holes = [ Rectangle.fromCoordsAndDims 0 0 width height ]; rects = []; needRepair = False };
      value rects bin = bin.rects;
      value holes bin = bin.holes;
      value getRect bin indx = List.nth bin.rects (indx mod (List.length bin.rects));
      value getHole bin indx = List.nth bin.holes (indx mod (List.length bin.holes));
      value width bin = bin.width;
      value height bin = bin.height;
      value needRepair bin = bin.needRepair;

      value holesSquare holes =
        let rec prepare holeA holes nextPassHoles retval =
          match holes with 
          [ [ holeB :: holes ] ->
            match Rectangle.intersection holeA holeB with
            [ Some intersection ->
              let cuttingsA = Rectangle.minus holeA intersection in
              let cuttingsB = Rectangle.minus holeB intersection in
                prepare intersection holes (cuttingsA @ cuttingsB @ nextPassHoles) retval
            | _ -> prepare holeA holes [ holeB :: nextPassHoles ] retval
            ]
          | _ ->
            match nextPassHoles with
            [ [] -> [ holeA :: retval ]
            | nextPassHoles -> prepare (List.hd nextPassHoles) (List.tl nextPassHoles) [] [ holeA :: retval ]
            ]
          ]
        in

        let rects = prepare (List.hd holes) (List.tl holes) [] [] in
          List.fold_left (fun square rect -> square + Rectangle.(width rect * height rect)) 0 rects;

      value rectsSquare rects = List.fold_left (fun square rect -> square + Rectangle.(width rect * height rect)) 0 rects;

      value isConsistent bin = (holesSquare bin.holes) + (rectsSquare bin.rects) = bin.width * bin.height;

      value repair bin =
        if bin.needRepair
        then
          let () = debug "+++rects %s" (String.concat ";" (List.map (fun hole -> Rectangle.toString hole) bin.rects)) in
          let () = debug "+++holes %s" (String.concat ";" (List.map (fun hole -> Rectangle.toString hole) bin.holes)) in

          let rec mergePass holes retval =
            let () = debug "mergePass call %s" (String.concat "," (List.map (fun hole -> Rectangle.toString hole) holes)) in
            let () = debug:holes "mergePass call %d %d" (List.length holes) (List.length retval) in
            match holes with
            [ [ holeA :: holes ] -> merge holeA holes [] retval False
            | _ -> assert False
            ]

          and merge holeA holes checkedHoles retval changed =
            let () = debug "\t-------------------------------" in
            let () = debug "\tholes %s" (String.concat "," (List.map (fun hole -> Rectangle.toString hole) holes)) in
            let () = debug "\tcheckedHoles %s" (String.concat "," (List.map (fun hole -> Rectangle.toString hole) checkedHoles)) in
            let () = debug "\tretval %s" (String.concat "," (List.map (fun hole -> Rectangle.toString hole) retval)) in
            (* let () = debug "\trects square + holes square %d" (holesSquare [ holeA :: (holes @ checkedHoles) ] + rectsSquare bin.rects) in *)
            match holes with
            [ [] ->
                let () = debug "\tchanged %B" changed in
                if changed
                then mergePass ((List.rev retval) @ (List.rev checkedHoles) @ [ holeA ]) []
                else
                  match checkedHoles with
                  [ [] -> [ holeA :: retval ]
                  | _ -> mergePass checkedHoles [ holeA :: retval ] 
                  ]
            | _ ->
              let holeB = List.hd holes in
                let () = debug "\tholeA = %s holeB = %s" (Rectangle.toString holeA) (Rectangle.toString holeB) in
                let () = debug "\t%s inside %s: %B" (Rectangle.toString holeB) (Rectangle.toString holeA) (Rectangle.rectInside holeA holeB) in

                if Rectangle.rectInside holeA holeB
                then merge holeA (List.tl holes) checkedHoles retval changed
                else

                let () = debug "\t%s inside %s: %B" (Rectangle.toString holeA) (Rectangle.toString holeB) (Rectangle.rectInside holeB holeA) in
                if Rectangle.rectInside holeB holeA
                then merge holeB (List.tl holes) checkedHoles retval True
                else

                let () = debug "\t%s and %s intersects: %B" (Rectangle.toString holeA) (Rectangle.toString holeB) (Rectangle.intersects holeA holeB) in
                if Rectangle.intersects holeA holeB
                then              
                  let () = debug "\t%s plus %s: %s" (Rectangle.toString holeA) (Rectangle.toString holeB) (String.concat ";" (List.map (fun hole -> Rectangle.toString hole) (Hole.plus holeA holeB))) in
                  match Hole.plus holeA holeB with
                  [ [ newHoleA; newHoleB ] when Rectangle.(equal newHoleA holeA && equal newHoleB holeB || equal newHoleA holeB && equal newHoleB holeA) ->
                    let () = debug "\tcase 0" in
                      merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
                  | [ newHoleA; newHoleB ] ->
                    let () = debug "\tcase 1" in
                    let allHoles = [ holeA :: holes @ checkedHoles @ retval ] in
                    let (changed, checkedHoles) =
                      if List.exists (fun hole -> Rectangle.rectInside hole newHoleB) allHoles
                      then let () = debug "\t%s or it's shell rect already in max rects" (Rectangle.toString newHoleB) in (changed, checkedHoles)
                      else let () = debug "\tadding %s to max rects" (Rectangle.toString newHoleB) in (True, [ newHoleB :: checkedHoles ])
                    in
                    let (changed, checkedHoles) =
                      if List.exists (fun hole -> Rectangle.rectInside hole newHoleA) allHoles
                      then let () = debug "\t%s or it's shell rect already in max rects" (Rectangle.toString newHoleA) in (changed, checkedHoles)
                      else let () = debug "\tadding %s to max rects" (Rectangle.toString newHoleA) in (True, [ newHoleA :: checkedHoles ])
                    in
                      merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
                  | [ newHole ] when Rectangle.rectInside newHole holeA && Rectangle.rectInside newHole holeB -> let () = debug "\tcase 2" in merge newHole (List.tl holes) checkedHoles retval True
                  | [ newHole ] when Rectangle.rectInside newHole holeA -> let () = debug "\tcase 3" in merge newHole (List.tl holes) [ holeB :: checkedHoles ] retval True
                  | [ newHole ] when Rectangle.rectInside newHole holeB -> let () = debug "\tcase 4" in merge holeA (List.tl holes) [ newHole :: checkedHoles ] retval True
                  | [ newHole ] ->
                    let () = debug "\tcase 5" in
                    let allHoles = [ holeA :: holes @ checkedHoles @ retval ] in
                    let (changed, checkedHoles) =
                      if List.exists (fun hole -> Rectangle.rectInside hole newHole) allHoles
                      then let () = debug "\t%s or it's shell rect already in max rects" (Rectangle.toString newHole) in (changed, checkedHoles)
                      else let () = debug "\tadding %s to max rects" (Rectangle.toString newHole) in (True, [ newHole :: checkedHoles ])
                    in
                     merge holeA (List.tl holes) [ holeB :: checkedHoles] retval changed
                  | [] -> let () = debug "\t case 6" in merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed (* this case is when rects contacts by single vertex *)
                  | _ -> assert False
                  ]
                else merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
            ]
          in (
            bin.holes := mergePass bin.holes [];
            bin.needRepair := False;
          )
        else ();

      value add bin width height =
        let w = width in
        let h = height in
          try
            let hole = List.find (fun rect -> Rectangle.(width rect = w && height rect = h)) bin.holes in (
              bin.holes := List.remove bin.holes hole;
              bin.rects := [ hole :: bin.rects ];
              Point.create (Rectangle.x hole) (Rectangle.y hole);
            )
          with
          [ Not_found ->
            (* let () = if bin.needRepair then repair bin else () in *)
            let holeToPlace = 
              List.fold_left (fun holeToPlace hole ->
                if Rectangle.width hole >= width && Rectangle.height hole >= height
                then
                  let bestPos = Rectangle.leftBottom holeToPlace in
                  let holeLb = Rectangle.leftBottom hole in
                    if Point.(y holeLb < y bestPos || y holeLb = y bestPos && x holeLb < x bestPos)
                    then hole
                    else holeToPlace
                else holeToPlace
              ) (Rectangle.fromCoordsAndDims max_int max_int max_int max_int) bin.holes
            in
              if Point.x (Rectangle.leftBottom holeToPlace) = max_int
              then raise CantPlace
              else
                let rectPos = Rectangle.leftBottom holeToPlace in
                let placedRect = Rectangle.fromPntAndDims rectPos width height in

                let filterHoles hole maxHoles = 
                  let rec filterHoles hole maxHoles retval =
                    if maxHoles = []
                    then [ hole :: retval]
                    else
                      let maxHole = List.hd maxHoles in
                        if Rectangle.rectInside hole maxHole
                        then filterHoles hole (List.tl maxHoles) retval
                        else
                          if Rectangle.rectInside maxHole hole
                          then retval @ maxHoles
                          else filterHoles hole (List.tl maxHoles) [ maxHole :: retval ]
                  in
                    filterHoles hole maxHoles [] 
                in

                let splitHoles holes =
                  let () = debug "split holes call" in
                  let rec splitHoles holes (maxHoles, notAffected) =
                    if holes = []
                    then maxHoles @ notAffected
                    else
                      let hole = List.hd holes in
                      let () = debug "scan hole %s, %B" (Rectangle.toString hole) (Rectangle.intersects placedRect hole) in
                        if Rectangle.intersects placedRect hole
                        then
                          let cuttings = Hole.minus hole placedRect in
                          let maxHoles = List.fold_left (fun maxHoles cutting -> filterHoles cutting maxHoles) maxHoles cuttings in
                            splitHoles (List.tl holes) (maxHoles, notAffected)
                        else splitHoles (List.tl holes) (maxHoles, [ hole :: notAffected ])
                  in
                    splitHoles holes ([], [])
                in (
                  bin.holes := splitHoles bin.holes;
                  bin.rects := [ placedRect :: bin.rects ];

                  debug "holes: %s" (String.concat "," (List.map (fun rect -> Rectangle.toString rect) bin.holes));
                  rectPos;
                )            
          ];

      value remove bin x y =
        try
          let rect = List.find (fun rect -> Rectangle.x rect = x && Rectangle.y rect = y) bin.rects in (
            bin.rects := List.remove bin.rects rect;
            bin.holes := [ rect :: bin.holes ];
            bin.needRepair := True;
          )
        with [ Not_found -> () ];

      value clean bin = (
        bin.holes := [ Rectangle.fromCoordsAndDims 0 0 bin.width bin.height ];
        bin.rects := [];
        bin.needRepair = False;
      );
    end;

  value bins = ref [];

  value findPos w h =
    let rec findPos binsLst =
      match binsLst with
      [ [] ->
        let tid = create_renderbuffer_tex () in
        let bin = Bin.create renderbufferTexSize renderbufferTexSize in (
          bins.val := [ (tid, bin) :: !bins ];
          (tid, Bin.add bin w h)
        )
      | [ (tid, bin) :: binsLst ] ->
        try (tid, Bin.add bin w h)
        with
        [ Bin.CantPlace ->
          let () = debug:createtex "trying to rapair bin %B" (Bin.needRepair bin) in
          if Bin.needRepair bin
          then (
            Bin.repair bin;
            try (tid, Bin.add bin w h) with [ Bin.CantPlace -> let () = debug:createtex "fail" in findPos binsLst ]
          )
          else findPos binsLst
        ]
      ]
    in
      findPos !bins;

  value getRect w h =
    let (tid, pos) = findPos w h in
    let () = debug:createtex "pos %s, texs num %d" (* (Int32.to_string (int32_of_textureID tid))  *)(Point.toString pos) (List.length !bins) in
      (tid, pos);

  value freeRect tid x y =
    let () = debug:createtex "freerect at %d %d" x y in
    let bin = List.assoc tid !bins in
      Bin.remove bin x y;
end;

class c renderInfo = 
  let () = debug "create rendered texture <%ld>" (int32_of_textureID renderInfo.rtextureID) in
  object(self)
    method renderInfo = renderInfo;
    method kind = renderInfo.kind;
    method asTexture = (self :> Texture.c);
    method scale = 1.;
    method texture = (self :> Texture.c);
    method width = renderInfo.rwidth;
    method height = renderInfo.rheight;
    method hasPremultipliedAlpha = match renderInfo.kind with [ Simple v -> v | _ -> assert False ];
    method textureID = renderInfo.rtextureID;
    method base : option Texture.c = None;
    method clipping = renderInfo.clipping;
    method rootClipping = renderInfo.clipping;
    method subTexture (region:Rectangle.t) : Texture.c = assert False;
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;


    value mutable released = False;
    method released = released;
    method release () = 
      match released with
      [ False ->
        (
          FramebufferTexture.freeRect renderInfo.rtextureID renderInfo.rx renderInfo.ry;
          released := True;
        )
      | True -> ()
      ];

    method draw ?clear ?width ?height (f:(framebuffer -> unit)) =      
      let (changed, w) = match width with [ Some width when ceil width <> renderInfo.rwidth -> (True, ceil width) | _ -> (False, renderInfo.rwidth) ] in
      let (changed, h) = match height with [ Some height when ceil height <> renderInfo.rheight -> (True, ceil height) | _ -> (False, renderInfo.rheight) ] in
      let () = debug:createtex "%B %f %f %f %f" changed w h renderInfo.rwidth renderInfo.rheight in
      let resized = 
        if changed
        then (
          FramebufferTexture.freeRect renderInfo.rtextureID renderInfo.rx renderInfo.ry;

          let (tid, pos) = FramebufferTexture.getRect (int_of_float w) (int_of_float h) in
          let new_tid = if tid = renderInfo.rtextureID then None else Some tid in
          let new_params = (FramebufferTexture.Point.x pos, FramebufferTexture.Point.y pos, w, h) in (
            renderbuffer_draw_to_texture ?clear ~new_params ?new_tid renderInfo f;
            (* debug:createtex "tid: %s" (Int32.to_string (int32_of_textureID renderInfo.rtextureID)); *)
            True;
          );
        )
        else (
          renderbuffer_draw_to_texture ?clear renderInfo f;
          False;
        )
      in (
        debug:createtex "before renderers notify";
        (* Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers; *)
        debug:createtex "after renderers notify";
        resized;
      );

    method data () = renderbuffer_data renderInfo;
    method save filename = renderbuffer_save renderInfo filename;


  end; (*}}}*)


value draw ~filter ?color ?alpha width height f =
  let (tid, pos) = FramebufferTexture.getRect (int_of_float (ceil width)) (int_of_float (ceil height)) in
  let clear =
    match (color, alpha) with
    [ (Some color, Some alpha) -> (color, alpha)
    | (Some color, _) -> (color, 0.)
    | (_, Some alpha) -> (0x000000, alpha)
    | _ -> (0x000000, 0.)
    ]
  in
  let tex = new c (renderbuffer_draw ~filter ~clear tid (FramebufferTexture.Point.x pos) (FramebufferTexture.Point.y pos) width height f) in (
    Gc.finalise (fun tex -> tex#release ()) tex;
    tex;
  );
