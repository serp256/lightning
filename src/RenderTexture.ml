open LightCommon;
open Texture;
open ExtList;

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";
external delete_textureID: textureID -> unit = "ml_render_texture_id_delete" "noalloc";
(* external rendertexture_resize: renderInfo -> float -> float -> bool = "ml_rendertexture_resize"; *)


type framebuffer;
external renderbuffer_draw: ~dedicated:bool -> ~filter:filter -> ?clear:(int*float) -> textureID -> int -> int -> float -> float -> (framebuffer -> unit) -> renderInfo = "ml_renderbuffer_draw_byte" "ml_renderbuffer_draw";
external renderbuffer_draw_to_texture: ?clear:(int*float) -> ?new_params:(int * int * float * float) -> ?new_tid:textureID -> renderInfo -> (framebuffer -> unit) -> unit = "ml_renderbuffer_draw_to_texture";
external renderbuffer_draw_to_dedicated_texture: ?clear:(int*float) -> ?width:float -> ?height:float -> renderInfo -> (framebuffer -> unit) -> bool = "ml_renderbuffer_draw_to_dedicated_texture";
external create_renderbuffer_tex: ?size:(int * int) -> unit -> textureID = "ml_create_renderbuffer_tex";
external _renderbuffer_tex_size: unit -> int = "ml_renderbuffer_tex_size";


value renderbufferTexSize = _renderbuffer_tex_size ();

external renderbuffer_save: renderInfo -> string -> bool = "ml_renderbuffer_save";
external dumptex: textureID -> unit = "ml_dumptex";

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
      type t = {
        id: int;
        width: int;
        height: int;
        holes: mutable list Rectangle.t;
        rects: mutable list Rectangle.t;
        reuseRects: mutable list Rectangle.t;
        reuseCoeff: mutable int;
      };

      value cnt = ref 0;
      value create width height =
        let retval = { id = !cnt; width; height; holes = [ Rectangle.fromCoordsAndDims 0 0 width height ]; rects = []; reuseRects = []; reuseCoeff = 0 } in (
          incr cnt;
          retval;
        );

      (* value create width height = { width; height; holes = [ Rectangle.fromCoordsAndDims 0 0 width height ]; rects = []; reuseRects = []; reuseCoeff = 0 }; *)
(*     value create width height =
      let aholes = [(67,254,317,16);(0,267,512,3);(67,259,445,11);(67,242,95,100);(0,267,168,75);(67,244,101,98);(67,244,197,26);(155,166,44,12);(155,166,7,176);(143,166,56,1);(120,192,42,150);(315,106,5,25);(301,156,109,15);(320,155,90,16);(192,99,7,79);(143,115,8,23);(504,132,8,296);(427,132,42,22);(427,132,85,21);(499,132,13,67);(509,51,3,461);(508,132,4,380);(169,99,136,7);(169,99,91,12);(485,45,9,6);(485,77,27,3);(503,51,9,29);(295,71,115,9);(295,69,40,11);(408,45,2,35);(408,45,86,1);(363,45,27,1);(390,70,20,10);(466,0,28,23);(363,17,1,6);(230,17,134,4);(366,147,44,24);(366,147,146,6);(366,147,103,7);(254,506,107,6);(0,298,233,44);(428,372,44,56);(499,259,13,169);(185,244,79,94);(0,372,308,82);(120,359,67,105);(384,194,26,5);(470,176,42,23);(0,398,361,56);(0,398,472,30);(185,254,86,84);(281,480,80,32);(287,372,21,140);(82,508,430,4);(0,298,271,40);(185,244,48,98);(82,492,137,20);(185,254,199,57);(0,398,512,2);(428,372,84,28);(478,474,34,5);(0,372,86,115);(219,368,14,112);(287,398,74,114);(120,368,113,96);(502,474,10,38);(0,298,394,13);(219,372,16,108);(0,372,235,92);(0,426,512,2);(0,451,443,3);(254,507,258,5);(185,259,209,52);(185,259,327,27);(495,259,17,141);(489,259,23,79);(0,509,512,3);(287,451,156,28);(82,372,4,140);(431,259,81,52);(102,24,31,2);(120,0,13,26);(180,26,50,20);(351,71,15,58);(315,106,51,23);(295,46,10,60);(221,98,39,13);(239,73,15,38);(221,98,84,8);(169,99,30,13);(169,87,11,25);(264,182,33,12);(260,157,4,21);(283,157,127,14);(283,157,14,37);(73,192,89,20);(0,199,162,13);(73,174,29,38);(162,178,102,66);(410,46,75,34);(199,111,61,67);(297,171,113,23);(410,154,59,22);(410,176,60,23);(469,153,30,23);(264,194,120,30);(384,199,120,30);(0,212,120,30);(264,224,120,30);(384,229,120,30);(233,338,75,34);(308,338,120,30);(0,342,120,30);(308,368,120,30);(428,338,67,17);(120,342,67,17);(428,355,67,17);(297,0,67,17);(361,428,147,23);(235,454,52,26);(230,0,67,17);(86,464,71,28);(157,464,62,28);(361,479,88,28);(449,479,53,28);(0,487,82,22);(394,286,18,25);(478,451,30,23);(254,480,27,26);(102,0,18,24);(364,0,102,23);(180,46,74,27);(363,23,131,22);(305,46,30,23);(335,46,55,25);(494,0,18,26);(494,26,18,25);(390,45,18,25);(254,46,41,26);(254,72,41,26);(180,73,41,26);(427,80,41,26);(102,87,49,28);(468,80,41,26);(260,106,55,25);(485,51,18,26);(221,73,18,25);(151,87,18,25);(412,286,19,25);(427,106,41,26);(468,106,41,26);(151,112,41,26);(102,115,41,26);(260,131,41,26);(143,138,49,28);(102,141,41,26);(301,131,19,25);(264,157,19,25);(102,167,53,25);(0,174,73,25);(219,480,35,28);(168,270,17,28);(305,80,46,26);(320,129,46,26);(187,342,46,26);(443,451,35,28);(366,80,61,67);(102,26,78,61)] in
      let aholes = List.map (fun (x, y, w, h) -> Rectangle.fromCoordsAndDims x y w h) aholes in
      let arects = [(133,0,97,26);(271,311,218,27);(230,21,133,25);(472,400,27,26);(0,0,102,174);(0,242,67,25)] in
      let arects = List.map (fun (x, y, w, h) -> Rectangle.fromCoordsAndDims x y w h) arects in
        { width; height; holes = aholes; rects = arects; reuseRects = []; reuseCoeff = 300 }; *)

      value rects bin = bin.rects;
      value holes bin = bin.holes;
      value reuseRects bin = bin.reuseRects;
      value getRect bin indx = List.nth bin.rects (indx mod (List.length bin.rects));
      value getHole bin indx = List.nth bin.holes (indx mod (List.length bin.holes));
      value width bin = bin.width;
      value height bin = bin.height;

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

      value isConsistent bin = (holesSquare bin.holes) + (rectsSquare bin.rects) + (rectsSquare bin.reuseRects) = bin.width * bin.height;

      value needRepair bin = bin.reuseCoeff > 15;

      value repair bin =
        if needRepair bin
        then
          let () = debug:reuse "repair call for: reuseCoeff: %d, res: %B" bin.reuseCoeff (needRepair bin) in

          let () = debug "+++rects %s" (String.concat ";" (List.map (fun hole -> Rectangle.toString hole) bin.rects)) in
          let () = debug "+++holes %s" (String.concat ";" (List.map (fun hole -> Rectangle.toString hole) bin.holes)) in

          let () = debug:consistent "%d writing repair... r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes)  in
          let out = open_out "/sdcard/repair" in
          let () = output_string out (Printf.sprintf "let brects = [%s] in\n" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.rects)))) in
          let () = output_string out (Printf.sprintf "let bholes = [%s] in\n" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) (bin.holes @ bin.reuseRects))))) in
          let () = debug:consistent "%d writing repair... r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes)  in

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
            let () = debug:consistent "%d r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes)  in

            let reuseRects = bin.reuseRects in (
              bin.reuseRects := [];
              bin.reuseCoeff := 0;
              (* reseting reuseRects called before merging cause when merging gc may finalize some rects on bin and when we reset reusedRects after merge -- we can lose whose rects *)
              bin.holes := mergePass (bin.holes @ reuseRects) [];
            );

            let () = debug:consistent "%d r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes)  in

            if not (isConsistent bin)
            then (
              output_string out (Printf.sprintf "let arects = [%s] in\n" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.rects))));
              output_string out (Printf.sprintf "let aholes = [%s] in\n" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.holes))));
              close_out out;
              let () = debug:consistent "r:%d; ru:%d; h:%d" (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes)  in
              assert False;
            ) else ();

            close_out out;
          )
        else ();

      value reuse bin width height =
        let w = width in
        let h = height in
          try
            let hole = List.find (fun rect -> Rectangle.(width rect = w && height rect = h)) bin.reuseRects in (
              bin.reuseRects := List.remove bin.reuseRects hole;
              bin.reuseCoeff := bin.reuseCoeff - 1;
              bin.rects := [ hole :: bin.rects ];
              Some (Rectangle.leftBottom hole);
            )
          with [ Not_found -> None ];

      value add bin width height =
(*         let () = debug:consistent "add width %d height %d" width height in
        let () = debug:consistent "let brects = [%s] in" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.rects))) in
        let () = debug:consistent "let bholes = [%s] in" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.holes))) in
 *)
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
          then None
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

(*               if not (isConsistent bin)
              then (
                debug:consistent "let arects = [%s] in" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.rects)));
                debug:consistent "let aholes = [%s] in" ((String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "(%d,%d,%d,%d)" (x rect) (y rect) (width rect) (height rect))) bin.holes)));
                assert False;                
              )
              else (); *)

              Some rectPos;
            );

      value remove bin x y =
        let () = debug:consistent "remove call for (%d,%d)" x y in
        try
          let rect = List.find (fun rect -> Rectangle.x rect = x && Rectangle.y rect = y) bin.rects in (
            bin.rects := List.remove bin.rects rect;
            bin.reuseRects := [ rect :: bin.reuseRects ];
            bin.reuseCoeff := bin.reuseCoeff + 1;
          )
        with [ Not_found -> () ];

      value clean bin = (
        bin.holes := [ Rectangle.fromCoordsAndDims 0 0 bin.width bin.height ];
        bin.rects := [];
        bin.reuseRects := [];
        bin.reuseCoeff := 0;
      );
    end;

  value bins = ref [];

  value findPos w h =
    let newRenderbuffTex () =
      let tid = create_renderbuffer_tex () in
      let bin = Bin.create renderbufferTexSize renderbufferTexSize in (
        bins.val := [ (tid, bin) :: !bins ];

        match Bin.add bin w h with
        [ Some pos -> (tid, pos)
        | _ -> assert False
        ];
      )    
    in

    let rec tryWithNeedRepair repairsCnt binsLst =
      match binsLst with
      [ [] -> newRenderbuffTex ()
      | binsLst when repairsCnt > 1 -> newRenderbuffTex ()
      | [ (tid, bin) :: binsLst ] ->
        if Bin.needRepair bin
        then (
          Bin.repair bin;
          match Bin.add bin w h with
          [ Some pos -> (tid, pos)
          | _ -> tryWithNeedRepair (repairsCnt + 1) binsLst
          ]          
        )
        else tryWithNeedRepair repairsCnt binsLst
      ]      
    in

    let rec tryWithRepaired binsLst =
      match binsLst with
      [ [] -> tryWithNeedRepair 0 !bins
      | [ (tid, bin) :: binsLst ] ->
        if not (Bin.needRepair bin)
        then
          match Bin.add bin w h with
          [ Some pos -> (tid, pos)
          | _ -> tryWithRepaired binsLst
          ]
        else tryWithRepaired binsLst
      ]
    in

    let rec tryReuse binsLst =
      match binsLst with
      [ [] -> tryWithRepaired !bins
      | [ (tid, bin) :: binsLst ] ->
        match Bin.reuse bin w h with
        [ Some pos -> (tid, pos)
        | _ -> tryReuse binsLst
        ]
      ]
    in
      tryReuse !bins;




(*     let rec findPosWithRepair repairCnt binsLst =
      match binsLst with
      [ [ (tid, bin) :: binsLst ] when repairCnt < 3 ->
        let repaired = Bin.repair bin in
          try (tid, Bin.add bin w h)
          with [ Bin.CantPlace -> findPosWithRepair (if repaired then repairCnt + 1 else repairCnt) binsLst ]
      | _ ->
        let tid = create_renderbuffer_tex () in
        let bin = Bin.create renderbufferTexSize renderbufferTexSize in (
          bins.val := !bins @ [ (tid, bin) ];
          (tid, Bin.add bin w h)
        )          
      ]
    in

    let rec findPos binsLst =
      match binsLst with
      [ [] -> findPosWithRepair 0 !bins
      | [ (tid, bin) :: binsLst ] ->
        try (tid, Bin.add bin w h)
        with [ Bin.CantPlace -> findPos binsLst ]
      ]
    in
      findPos !bins; *)

  value getRect w h =    
    let (tid, pos) = findPos w h in
      (tid, pos);

  value freeRect tid x y =
    let bin = List.assoc tid !bins in
      Bin.remove bin x y;

  value binsNum () = List.length !bins;

  value dumpTextures () =
    let bin = Bin.create 512 512 in (
      assert (Bin.isConsistent bin);
      Bin.repair bin;
      assert (Bin.isConsistent bin);
    );
(*     List.iter (fun (tid, bin) -> (
      dumptex tid;

      let out = open_out (Printf.sprintf "/sdcard/%ld.holes" (int32_of_textureID tid)) in (
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.rects bin))));
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.holes bin))));
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.reuseRects bin))));
        close_out out;
      )
    )) !bins; *)
end;

class virtual base renderInfo = 
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
    method virtual release: unit -> unit;
    method virtual draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method data () = renderbuffer_data renderInfo;
    method save filename = renderbuffer_save renderInfo filename;
  end; (*}}}*)

class shared renderInfo =
  object(self)
    inherit base renderInfo;

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
      let (changed, h) = match height with [ Some height when ceil height <> renderInfo.rheight -> (True, ceil height) | _ -> (changed, renderInfo.rheight) ] in
      let resized = 
        if changed
        then (
          FramebufferTexture.freeRect renderInfo.rtextureID renderInfo.rx renderInfo.ry;

          let (tid, pos) = FramebufferTexture.getRect (int_of_float w) (int_of_float h) in
          let new_tid = if tid = renderInfo.rtextureID then None else Some tid in
          let new_params = (FramebufferTexture.Point.x pos, FramebufferTexture.Point.y pos, w, h) in (
            renderbuffer_draw_to_texture ?clear ~new_params ?new_tid renderInfo f;
            True;
          );
        )
        else (
          renderbuffer_draw_to_texture ?clear renderInfo f;
          False;
        )
      in (
        Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers;
        resized;
      );    
  end;

class dedicated renderInfo =
  object(self)
    inherit base renderInfo;

    method release () = 
      match released with
      [ False ->
        (
          delete_textureID renderInfo.rtextureID;
          released := True;
        )
      | True -> ()
      ];

    method draw ?clear ?width ?height (f:(framebuffer -> unit)) = 
      let resized = renderbuffer_draw_to_dedicated_texture ?clear ?width ?height renderInfo f in
      (
        Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers;
        resized;
      );
  end;

class type c =
  object
    inherit Texture.c;
    method asTexture: Texture.c;
    method draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method texture: Texture.c;
    method save: string -> bool;
    method data: unit -> data; 
  end;  

value dedicatedCnt = ref 0;

value draw ~filter ?color ?alpha ?(dedicated = False) width height f =
  let () = debug:dedicated "draw call %f %f (%f %f), dedicated %B" width height ((float renderbufferTexSize) /. 2.) ((float renderbufferTexSize) /. 2.) dedicated in
  let () = debug:dedicated "dedicated || (width > (float renderbufferTexSize) /. 2.) || (height > (float renderbufferTexSize) /. 2.) %B" (dedicated || (width > (float renderbufferTexSize) /. 2.) || (height > (float renderbufferTexSize) /. 2.)) in
  let dedicated = dedicated || (width > (float renderbufferTexSize) /. 2.) || (height > (float renderbufferTexSize) /. 2.) in
  let () = if dedicated then incr dedicatedCnt else () in
  let () = debug:dedicated "dedicated cnt %d" !dedicatedCnt in

  let (tid, pos) =
    if dedicated
    then (create_renderbuffer_tex ~size:(int_of_float (ceil width), int_of_float (ceil height)) (), FramebufferTexture.Point.create 0 0)
    else FramebufferTexture.getRect (int_of_float (ceil width)) (int_of_float (ceil height))
  in
  let clear =
    match (color, alpha) with
    [ (Some color, Some alpha) -> (color, alpha)
    | (Some color, _) -> (color, 0.)
    | (_, Some alpha) -> (0x000000, alpha)
    | _ -> (0x000000, 0.)
    ]
  in
  let renderInfo = renderbuffer_draw ~dedicated ~filter ~clear tid (FramebufferTexture.Point.x pos) (FramebufferTexture.Point.y pos) width height f in
    if dedicated
    then new dedicated renderInfo
    else
      let tex = new shared renderInfo in (
        Gc.finalise (fun tex -> tex#release () ) tex;
        tex;        
      );

value sharedTexsNum = FramebufferTexture.binsNum;
value dumpTextures = FramebufferTexture.dumpTextures;
