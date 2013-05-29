open LightCommon;

module D = DisplayObject;


type cache_valid = [ CInvalid | CEmpty | CValid ];
type imageCache = 
  {
    c_tex: mutable option RenderTexture.c;
    c_img: mutable option Render.Image.t;
    c_prg: mutable Render.prg;
    c_mat: mutable Matrix.t;
    glow: mutable option Filters.glow;
    valid: mutable cache_valid;
    force: mutable bool (* ??? *)
  };

class c =
  object(self)
    inherit D.container as super; 
    method ccast: [= `Sprite of c] = `Sprite (self :> c);

    value mutable imageCache = None;
    method !name = if name = ""  then Printf.sprintf "sprite%d" (Oo.id self) else name;
    method cacheAsImage = imageCache <> None;
    value mutable filters = [];

    method color = `NoColor;
    method setColor (c:color) = ();
    method setCacheAsImage (v:bool) = ();

    (*
    method setCacheAsImage = fun
      [ True -> 
        match imageCache with
        [ None -> 
          (
            let bounds = self#bounds in
(*             let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in *)
            if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
            then imageCache := Some {ic = None;  valid = CInvalid; tex = None; force = True}
            else
            (
              imageCache := Some {ic = None; valid = CInvalid; tex = None; force = True};
              self#addPrerender self#updateImageCache;
            )
          )
        | Some c -> c.force := True
        ]
      | False ->
          match imageCache with
          [ Some ({tex = Some tex; force; _ } as c) -> 
            match filters = [] with
            [ True -> 
              (
                tex#release ();
                imageCache := None;
              )
            | False when force = True -> c.force := False
            | _ -> ()
            ]
          | _ -> ()
          ]
      ];
    *)

    method filters = filters;

    method! boundsChanged () = 
    (
(*         debug "%s bounds changed" self#name; *)
      match imageCache with
      [ Some ({valid=CValid | CEmpty;_} as c) -> (self#addPrerender self#updateImageCache; c.valid := CInvalid)
      | _ -> ()
      ];
      super#boundsChanged();
    );

    method private updateImageCache () = 
      match imageCache with
      [ Some ({c_img; c_tex; glow; valid = CInvalid;  _} as c) -> 
         let () = debug:prerender "update cacheImage %s" self#name in
         let bounds = self#boundsInSpace (Some self) in
         if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
         then c.valid := CEmpty
         else 
         (
           let draw_texture width height f = (*{{{*)
             match (c_img,c_tex) with 
             [ (Some img, Some tex) -> 
               let () = debug "get_tex [%f:%f] [%f:%f]" w h tex#width tex#height in
               (
                 match tex#draw ~clear:(0,0.) ~width ~height f with
                 [ True -> Render.Image.update img tex#renderInfo ~flipX:False ~flipY:False
                 | False -> ()
                 ]
               )
             | (None,None) -> 
                 let tex = RenderTexture.draw ~filter:Texture.FilterLinear width height f in
                 let img = Render.Image.create tex#renderInfo ~color:`NoColor ~alpha:1. in
                 (
                   c.c_tex := Some tex;
                   c.c_img := Some img;
                 )
             | _ -> assert False
             ]
           in (*}}}*)
           match glow with
           [ None ->
               let alpha' = alpha in
               (
                 self#setAlpha 1.;
                 draw_texture bounds.Rectangle.width bounds.Rectangle.height begin fun _ ->
                   (
                      debug:drawf "sprite drawf";
                     Render.push_matrix (Matrix.create ~translate:{Point.x = ~-.(bounds.Rectangle.x);y= ~-.(bounds.Rectangle.y)} ());
                     Render.clear 0 0.;
                     super#render' ~transform:False None;
                     Render.restore_matrix ();
                   )
                 end;
                 self#setAlpha alpha';
                 c.c_mat := Matrix.create ~translate:{Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} ();
               )
           | Some glow ->
               (* рассчитать размер глоу *)
               let hgs =  (powOfTwo glow.Filters.glowSize) - 1 in
               (
                 let gs = hgs * 2 in
                 let rw = bounds.Rectangle.width +. (float gs)
                 and rh = bounds.Rectangle.height +. (float gs) in
                 let m = Matrix.create ~translate:{Point.x = (float hgs) -. bounds.Rectangle.x; y = (float hgs) -. bounds.Rectangle.y} () in
                 let ctex = 
                   let alpha' = alpha in
                   (
                     self#setAlpha 1.;
                     let ctex = RenderTexture.draw ~filter:Texture.FilterNearest rw rh begin fun _ ->
                       (
                         Render.push_matrix m;
                         Render.clear 0 0.;
                         super#render' ~transform:False None;
                         Render.restore_matrix ();
                       )
                     end in
                     (
                       self#setAlpha alpha';
                       ctex
                     )
                   )
                 in
                 (
                   let cimg = Render.Image.create ctex#renderInfo ~color:`NoColor ~alpha:1. in
                   draw_texture rw rh begin fun fb ->
                     (
                       Render.clear 0 0.;
                       Render.Image.render Matrix.identity (GLPrograms.Image.Normal.create ()) cimg;
                       match glow.Filters.glowKind with
                       [ `linear -> proftimer:glow "linear time: %f" RenderFilters.glow_make fb glow
                       | `soft -> proftimer:glow "soft time: %f" RenderFilters.glow2_make fb glow
                       ];
                       Render.Image.render Matrix.identity (GLPrograms.Image.Normal.create ()) cimg;
                     )
                   end;
                   ctex#release ();
                 );
                 c.c_mat := Matrix.create ~translate:{Point.x =  (bounds.Rectangle.x -. (float hgs)); y = (bounds.Rectangle.y -. (float hgs))} ();
               )
           ];
           c.valid := CValid; 
         )
    | Some _ -> assert False (* FIXME: иногда срабатывает этот ассерт *)
    | _ -> ()
    ];

    method setFilters fltrs = 
      let () = debug:filters "set filters [%s] on %s" (String.concat "," (List.map Filters.string_of_t fltrs)) self#name in
      (
        filters := fltrs;
        match fltrs with
        [ [] ->
          match imageCache with
          [ None -> ()
          | Some {c_tex;force=False;_} -> 
            (
              match c_tex with
              [ Some tex -> tex#release()
              | None -> ()
              ];
              imageCache := None
            )
          | Some c -> 
            (
              c.c_prg := GLPrograms.Image.Normal.create ();
              if c.glow <> None
              then
              (
                c.glow := None;
                if c.valid = CValid 
                then 
                  (
                    c.valid := CInvalid;
                    self#addPrerender self#updateImageCache
                  )
                else ();
              )
              else ()
            )
          ]
        | _ -> 
            let glow = ref None in
            let prg =
              List.fold_left begin fun c -> fun
                [ `Glow g ->
                  (
                    glow.val := Some g;
                    c
                  )
                | `ColorMatrix m -> `cmatrix m
                ]
              end `simple fltrs
            in
            let c_prg = 
              let module Prg=  GLPrograms.Image in
              match prg with [ `simple -> Prg.Normal.create () | `cmatrix m -> Prg.ColorMatrix.create m ] 
            in
            match imageCache with
            [ None -> 
              (
                let bounds = self#bounds in
                imageCache := Some begin
                  if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
                  then {c_img = None; c_tex = None; c_mat = Matrix.identity; valid = CEmpty; c_prg; glow = !glow; force = False}
                  else
                  (
                    self#addPrerender self#updateImageCache;
                    {c_img = None; c_tex = None; c_mat = Matrix.identity; valid = CInvalid; c_prg; glow = !glow; force = False};
                  )
                end
              )
            | Some c -> 
              (
                c.c_prg := c_prg;
                if c.glow <> !glow
                then
                (
                  c.glow := !glow;
                  if c.valid = CValid then (c.valid := CInvalid; self#addPrerender self#updateImageCache) else ();
                )
                else ();
              )
            ]
        ];
      );

    method! private render' ?alpha:(alpha') ~transform rect = 
      match imageCache with
      [ Some {c_img=Some img; c_mat; c_prg; valid=CValid;_} ->
        (
          (*
          if transform then Render.push_matrix self#transformationMatrix else ();
          let alpha = 
            if alpha < 1.
            then Some (match alpha' with [ Some a -> a *. alpha | None -> alpha ])
            else alpha'
          in
          ic#render ?alpha rect;
          if transform then Render.restore_matrix () else ();
          *)
          let alpha = 
            if alpha < 1.
            then Some (match alpha' with [ Some a -> a *. alpha | None -> alpha ])
            else alpha'
          in
          Render.Image.render (if transform then Matrix.concat c_mat self#transformationMatrix else c_mat) c_prg ?alpha img
        )
      | Some {valid = CEmpty;_} -> ()
      | _ -> super#render' ?alpha:alpha' ~transform rect
      ];

  end;


value create () = new c;

