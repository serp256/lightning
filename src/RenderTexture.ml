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

value lazy_renderbuffer_tex_size = Lazy.from_fun _renderbuffer_tex_size;

value renderbufferTexSize () = Lazy.force lazy_renderbuffer_tex_size;

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
      value clone (x, y) = create x y;
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
      value clone (lb, rt) = (Point.clone lb, Point.clone rt); 
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

      value clone bin =
        let cloneRectLst lst = List.map (fun rect -> Rectangle.clone rect) lst in
        let retval = { id = !cnt; width = bin.width; height = bin.height; holes = cloneRectLst bin.holes; rects = cloneRectLst bin.rects; reuseRects = cloneRectLst bin.reuseRects; reuseCoeff = bin.reuseCoeff } in (
          incr cnt;
          retval;
        );

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

      value clean bin = (
        bin.holes := [ Rectangle.fromCoordsAndDims 0 0 bin.width bin.height ];
        bin.rects := [];
        bin.reuseRects := [];
        bin.reuseCoeff := 0;
      );

      value add bin ?pos width height =
        let pos =
          match pos with
          [ Some pos -> pos
          | _ ->
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
              Rectangle.leftBottom holeToPlace
          ]
        in
          if Point.x pos = max_int
          then None
          else
            let placedRect = Rectangle.fromPntAndDims pos width height in

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
              let rec splitHoles holes (maxHoles, notAffected) =
                if holes = []
                then maxHoles @ notAffected
                else
                  let hole = List.hd holes in
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
              Some pos;
            );

      value repairByAdd bin =
        let rects = bin.rects in (
          clean bin;
          List.iter (fun rect -> ignore(add bin ~pos:(Rectangle.leftBottom rect) (Rectangle.width rect) (Rectangle.height rect))) rects;
        );

      value repairByMerge bin =
        let rec mergePass holes retval =
          match holes with
          [ [ holeA :: holes ] -> merge holeA holes [] retval False
          | _ -> assert False
          ]

        and merge holeA holes checkedHoles retval changed =
          match holes with
          [ [] ->
              if changed
              then mergePass ((List.rev retval) @ (List.rev checkedHoles) @ [ holeA ]) []
              else
                match checkedHoles with
                [ [] -> [ holeA :: retval ]
                | _ -> mergePass checkedHoles [ holeA :: retval ] 
                ]
          | _ ->
            let holeB = List.hd holes in
              if Rectangle.rectInside holeA holeB
              then merge holeA (List.tl holes) checkedHoles retval changed
              else

              if Rectangle.rectInside holeB holeA
              then merge holeB (List.tl holes) checkedHoles retval True
              else

              if Rectangle.intersects holeA holeB
              then              
                match Hole.plus holeA holeB with
                [ [ newHoleA; newHoleB ] when Rectangle.(equal newHoleA holeA && equal newHoleB holeB || equal newHoleA holeB && equal newHoleB holeA) ->
                    merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
                | [ newHoleA; newHoleB ] ->
                  let allHoles = [ holeA :: holes @ checkedHoles @ retval ] in
                  let (changed, checkedHoles) =
                    if List.exists (fun hole -> Rectangle.rectInside hole newHoleB) allHoles
                    then (changed, checkedHoles)
                    else (True, [ newHoleB :: checkedHoles ])
                  in
                  let (changed, checkedHoles) =
                    if List.exists (fun hole -> Rectangle.rectInside hole newHoleA) allHoles
                    then (changed, checkedHoles)
                    else (True, [ newHoleA :: checkedHoles ])
                  in
                    merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
                | [ newHole ] when Rectangle.rectInside newHole holeA && Rectangle.rectInside newHole holeB -> merge newHole (List.tl holes) checkedHoles retval True
                | [ newHole ] when Rectangle.rectInside newHole holeA -> merge newHole (List.tl holes) [ holeB :: checkedHoles ] retval True
                | [ newHole ] when Rectangle.rectInside newHole holeB -> merge holeA (List.tl holes) [ newHole :: checkedHoles ] retval True
                | [ newHole ] ->
                  let allHoles = [ holeA :: holes @ checkedHoles @ retval ] in
                  let (changed, checkedHoles) =
                    if List.exists (fun hole -> Rectangle.rectInside hole newHole) allHoles
                    then (changed, checkedHoles)
                    else (True, [ newHole :: checkedHoles ])
                  in
                   merge holeA (List.tl holes) [ holeB :: checkedHoles] retval changed
                | [] -> merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed (* this case is when rects contacts by single vertex *)
                | _ -> assert False
                ]
              else merge holeA (List.tl holes) [ holeB :: checkedHoles ] retval changed
          ]
        in (
          debug:consistent "before repair: %d r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes);

          let reuseRects = bin.reuseRects in (
            bin.reuseRects := [];
            bin.reuseCoeff := 0;
            (* reseting reuseRects called before merging cause when merging gc may finalize some rects on bin and when we reset reusedRects after merge -- we can lose whose rects *)
            bin.holes := mergePass (bin.holes @ reuseRects) [];
          );

          debug:consistent "repair complete: %d r:%d; ru:%d; h:%d" (bin.id) (List.length bin.rects) (List.length bin.reuseRects) (List.length bin.holes);
          (* assert (isConsistent bin); *)
        );

      value repair bin =
        if needRepair bin
        then
          let () = debug:consistent "repair call" in
          if bin.rects = []
          then clean bin
          else repairByAdd bin
        else ();

      value reuse bin width height =
        let w = width in
        let h = height in
          try
            let hole =
              List.find (fun rect ->
                let wdiff = Rectangle.width rect - w in
                let hdiff = Rectangle.height rect - h in
                   wdiff >= 0 && wdiff < 10 && hdiff >= 0 && hdiff < 10
              ) bin.reuseRects
            in (
              bin.reuseRects := List.remove bin.reuseRects hole;
              bin.reuseCoeff := bin.reuseCoeff - 1;
              bin.rects := [ hole :: bin.rects ];
              Some (Rectangle.leftBottom hole);
            )
          with [ Not_found -> None ];

      value remove bin x y =
        try
          let rect = List.find (fun rect -> Rectangle.x rect = x && Rectangle.y rect = y) bin.rects in (
            bin.rects := List.remove bin.rects rect;
            bin.reuseRects := [ rect :: bin.reuseRects ];
            bin.reuseCoeff := bin.reuseCoeff + 1;
          )
        with [ Not_found -> () ];
    end;

  value bins = ref [];

  value findPos w h =
    let newRenderbuffTex () =
      let tid = create_renderbuffer_tex () in
      let bin = Bin.create (renderbufferTexSize ()) (renderbufferTexSize ()) in (
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
      | binsLst when repairsCnt > 3 -> newRenderbuffTex ()
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
      [ [] ->
        let rec shuffle bins cnt times = if cnt = times then bins else shuffle (List.sort ~cmp:(fun _ _ -> (Random.int 3) - 1) bins) (cnt + 1) times in
        let needRepair = shuffle (List.filter (fun (tid, bin) -> Bin.needRepair bin) !bins) 0 5 in
          tryWithNeedRepair 0 needRepair
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

  value getRect w h =    
    let (tid, pos) = findPos w h in
      (tid, pos);

  value freeRect tid x y =
    let bin = List.assoc tid !bins in
      Bin.remove bin x y;

  value binsNum () = List.length !bins;

  value dumpTextures () =
    List.iter (fun (tid, bin) -> (
      dumptex tid;

      let out = open_out (Printf.sprintf "/tmp/%ld.holes" (int32_of_textureID tid)) in (
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.rects bin))));
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.holes bin))));
        output_string out (Printf.sprintf "%s\n" (String.concat ";" (List.map (fun rect -> Rectangle.(Printf.sprintf "%d,%d,%d,%d" (x rect) (y rect) (width rect) (height rect))) (Bin.reuseRects bin))));
        close_out out;
      )
    )) !bins;

(*   value addRepairTime bin = ~-.0.001706 +. 8.567 *. 1e-05 *. (float (List.length bin.rects)) +. 1.551 *. 1e-05 *. (float (List.length bin.holes)) +. 1.761 *. 1e-05 *. (float (List.length bin.reuseRects));
  value mergeRepairTime bin = ~-.0.731 +. 0.003802 *. (float (List.length bin.rects)) +. 0.021 *. (float (List.length bin.holes)) +. 0.018 *. (float (List.length bin.reuseRects)); *)

  value repairBenchmark rectsNum rmPct minimizeLevel =
    let () = Random.self_init () in
    let bin1 = Bin.create 512 512 in
    let (rectPoss, bin2) =
      if minimizeLevel > 0
      then (
        ignore(Bin.add bin1 300 300);

        if minimizeLevel > 1
        then (ignore(Bin.add bin1 150 150);ignore(Bin.add bin1 250 150);)
        else ();

        if minimizeLevel > 2
        then (ignore(Bin.add bin1 50 50);ignore(Bin.add bin1 350 50);ignore(Bin.add bin1 260 50);)
        else ();

        let rec split changed rects retval =
          match rects with
          [ [] when (List.length retval < rectsNum) && changed -> split False retval []
          | [ rect :: rest ] when (List.length retval) + (List.length rects) < rectsNum ->
            if Rectangle.(width rect <= 10 || height rect <= 10)
            then split changed rest [ rect :: retval ]
            else
              let lbx = Rectangle.x rect in
              let lby = Rectangle.y rect in
              let rtx = lbx + Rectangle.width rect in
              let rty = lby + Rectangle.height rect in
                if Random.int 1000 mod 2 = 0
                then let x = Random.int (rtx - lbx - 10) + 5 in split True rest [ (Rectangle.fromCoords lbx lby (lbx + x) rty) :: [(Rectangle.fromCoords (lbx + x) lby rtx rty) :: retval] ]
                else let y = Random.int (rty - lby - 10) + 5 in split True rest [ (Rectangle.fromCoords lbx lby rtx (lby + y)) :: [(Rectangle.fromCoords lbx (lby + y) rtx rty) :: retval] ]
          | _ -> rects @ retval
          ]
        in (
          bin1.Bin.rects := split False bin1.Bin.rects [];

          for i = 0 to Random.int 10 + 5 do {
            bin1.Bin.rects := List.sort ~cmp:(fun _ _ -> Random.int 1000 mod 3 - 1) bin1.Bin.rects;
          };

          assert (Bin.isConsistent bin1);
          (List.map (fun rect -> Rectangle.leftBottom rect) bin1.Bin.rects, Bin.clone bin1);
        );
      )
      else
        let bin2 = Bin.create 512 512 in
          (List.init rectsNum (fun _ ->
                      let (w, h) =
                        if Random.int 1000 mod 11 = 0
                        then ((Random.int 30 + 10), (Random.int 30 + 10))
                        else
                          if Random.int 100 mod 2 = 0
                          then ((Random.int 10 + 20), (Random.int 10 + 5))
                          else ((Random.int 10 + 5), (Random.int 10 + 20))
                      in
                        (ignore(Bin.add bin1 w h); match Bin.add bin2 w h with [ Some pos -> pos | _ -> assert False ];)
                    ), bin2)
    in

    let rectToRm = ref rectPoss in (
      for i = 0 to Random.int 5 + 10 do {
        rectToRm.val := List.sort ~cmp:(fun _ _ -> Random.int 10000 mod 3 - 1) !rectToRm;
      };

      List.iter (fun (x, y) -> (Bin.remove bin1 x y;Bin.remove bin2 x y)) (List.take (rectsNum * rmPct / 100) !rectToRm);

      let rectsNum = List.length bin1.Bin.rects in
      let holesNum = List.length bin1.Bin.holes in
      let reuseNum = List.length bin1.Bin.reuseRects in (
        (* let prognosis1 = Bin.addRepairTime bin1 in *)
        let ptmr1 = ProfTimer.start () in (
          debug:rprbnchmk "processing %d,%d,%d..." rectsNum holesNum reuseNum;

          Bin.repairByAdd bin1;
          ProfTimer.stop ptmr1;
          assert (Bin.isConsistent bin1);

          (* let prognosis2 = Bin.mergeRepairTime bin2 in *)
          let ptmr2 = ProfTimer.start () in (
            Bin.repairByMerge bin2;
            ProfTimer.stop ptmr2;
            assert (Bin.isConsistent bin2);
            debug:rprbnchmk "done";
            (rectsNum, holesNum, reuseNum, ProfTimer.length ptmr1, (* prognosis1,  *)ProfTimer.length ptmr2(* , prognosis2 *));
          );
        );
      );        
    );
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

    method subTexture region =
      let scale = !scale in
      let clipping = 
        let tw = renderInfo.rwidth /. scale
        and th = renderInfo.rheight /. scale in
        Rectangle.create 
          (region.Rectangle.x /. tw) 
          (region.Rectangle.y /. th) 
          (region.Rectangle.width /. tw) 
          (region.Rectangle.height /. th) 
      in
        Texture.createSubtex region clipping scale (self :> c);

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

value texRectDimCorrection dim = 8 - dim mod 8;

class shared renderInfo =
  object(self)
    inherit base renderInfo;

    method release () = 
      match released with
      [ False ->
        let rx = renderInfo.rx - (texRectDimCorrection (int_of_float (ceil renderInfo.rwidth))) / 2 in
        let ry = renderInfo.ry - (texRectDimCorrection (int_of_float (ceil renderInfo.rheight))) / 2 in
        (
          FramebufferTexture.freeRect renderInfo.rtextureID rx ry;
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

value draw ~filter ?color ?alpha ?(dedicated = False) width height f =
  let width = int_of_float (ceil width) in
  let height = int_of_float (ceil height) in

  let dedicated = dedicated || (width > (renderbufferTexSize ()) / 2) || (height > (renderbufferTexSize ()) / 2) in

  let (rectw,recth,offsetx,offsety) =
    if dedicated
    then
      let rectw = nextPowerOfTwo width in
      let recth = nextPowerOfTwo height in
        (rectw, recth, (rectw - width) / 2, (recth - height) / 2)
    else
      let widthCrrcnt = texRectDimCorrection width in
      let heightCrrcnt = texRectDimCorrection height in
        (width + widthCrrcnt, height + heightCrrcnt, widthCrrcnt / 2, heightCrrcnt / 2)
  in

  let (tid, pos) =
    if dedicated
    then (create_renderbuffer_tex ~size:(rectw, recth) (), FramebufferTexture.Point.create offsetx offsety)
    else
      let (tid, pos) = FramebufferTexture.getRect rectw recth in
        (tid, FramebufferTexture.Point.create (FramebufferTexture.Point.x pos + offsetx) (FramebufferTexture.Point.y pos + offsety))
  in
  let clear =
    match (color, alpha) with
    [ (Some color, Some alpha) -> (color, alpha)
    | (Some color, _) -> (color, 0.)
    | (_, Some alpha) -> (0x000000, alpha)
    | _ -> (0x000000, 0.)
    ]
  in
  let renderInfo = renderbuffer_draw ~dedicated ~filter ~clear tid (FramebufferTexture.Point.x pos) (FramebufferTexture.Point.y pos) (float width) (float height) f in
    if dedicated
    then new dedicated renderInfo
    else
      let tex = new shared renderInfo in (
        Gc.finalise (fun tex -> tex#release () ) tex;
        tex;        
      );

value sharedTexsNum = FramebufferTexture.binsNum;
(* value dumpTextures = FramebufferTexture.dumpTextures; *)
(* value repairBenchmark = FramebufferTexture.repairBenchmark; *)
