
module D = DisplayObject;


type cache_valid = [ CInvalid | CEmpty | CValid ];
type imageCache = 
  {
    c_tex: mutable option Texture.c;
    c_img: mutable option Render.Image.t;
    c_prg: mutable Render.prg;
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
         let () = debug:prerender "cacheImage %s not valid" ic#name in
         let bounds = self#boundsInSpace (Some self) in
         if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
         then c.valid := CEmpty
         else 
         (
           let get_tex w h = (*{{{*)
             match (c_img,c_tex) with 
             [ (Some img, Some tex) -> 
               if tex#width <> w || tex#height <> h
               then
               (
                 tex#resize w h;
                 Render.Image.update img tex#renderInfo ~texFlipX ~texFlipY;
                 tex 
               )
             | (None,None) -> 
                 let tex = Texture.rendered w h in
                 let img = Render.Image.create tex#renderInfo ~color:0xFFFFFF ~alpha:1. in
                 (
                   c.c_tex := Some tex;
                   c.c_img := Some img;
                   tex
                 )
             | _ -> assert False
             ]
           in (*}}}*)
           match glow with
           [ None ->
               let tex = get_tex bounds.Rectangle.width bounds.Rectangle.height in
               let ip = {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} in
               let alpha' = alpha in
               (
                 self#setAlpha 1.;
                 tex#draw begin fun () ->
                   (
                     Render.push_matrix (Matrix.create ~translate:(Point.mul ic#pos ~-.1.) ());
                     Render.clear 0 0.;
                     super#render' ~transform:False None;
                     Render.restore_matrix ();
                   );
                 end;
                 self#setAlpha alpha';
               )
           | Some glow ->
               (* рассчитать размер глоу *)
               let hgs =  (powOfTwo glow.Filters.glowSize) - 1 in
               let gs = hgs * 2 in
               let rw = w +. (float gs)
               and rh = h +. (float gs) in
               let tex = get_tex rw rh in
               (
                 tex#activate ();
                 tex#deactivate ();
               )
           ];
           c.valid := CValid; 
         )
    | Some _ -> assert False
    | _ -> ()
    ];

    method setFilters fltrs = 
      let () = debug:filters "set filters [%s] on %s" (String.concat "," (List.map Filters.string_of_t filters)) self#name in
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
              c.c_prg = GLPrograms.ImageSimple.create ();
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
              List.fold_left begin fun f -> fun
                [ `Glow g ->
                  (
                    glow.val := Some g;
                    c
                  )
                | `ColorMatrix m -> `cmatrix m
                ]
              end `simple fltrs
            in
            let c_prg = match prg with [ `simple -> GLPrograms.Image.create () | `cmatrix m -> GLProgram.ImageColorMatrix m ] in
            match imageCache with
            [ None -> 
              (
                debug:filters "create %s as image cache for %s" img#name self#name;
                let bounds = self#bounds in
                imageCache := Some begin
                  if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
                  then {c_img = None; c_tex = None; valid = CEmpty; c_prg; !glow; force = False}
                  else
                  (
                    self#addPrerender self#updateImageCache;
                    {c_img = None; c_tex = None; valid = CInvalid; c_prg; !glow; force = False};
                  )
                end
              )
            | Some c -> 
              (
                c.c_prg = c_prg;
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
      [ Some {ic=Some ic; valid=CValid;_} ->
        (
          if transform then Render.push_matrix self#transformationMatrix else ();
          let alpha = 
            if alpha < 1.
            then Some (match alpha' with [ Some a -> a *. alpha | None -> alpha ])
            else alpha'
          in
          ic#render ?alpha rect;
          if transform then Render.restore_matrix () else ();
        )
      | Some {valid = CEmpty;_} -> ()
      | _ -> super#render' ?alpha:alpha' ~transform rect
      ];

  end;


value create () = new c;

