
module D = DisplayObject;

type imageCache = {ic: Image.c; tex: Texture.rendered; empty: mutable bool; valid: mutable [= `invalid | `prerender | `valid ]; force: mutable bool};

class c =
  object(self)
    inherit D.container as super; 
    method ccast: [= `Sprite of c] = `Sprite (self :> c);

    value mutable imageCache = None;
    method !name = if name = ""  then Printf.sprintf "sprite%d" (Oo.id self) else name;
    method cacheAsImage = imageCache <> None;
    method setCacheAsImage = fun
      [ True -> 
        match imageCache with
        [ None -> 
          (
            let bounds = self#bounds in
            let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
            imageCache := Some {ic = Image.create (tex :> Texture.c); empty = False; valid = `invalid; tex ; force = True};
            self#addPrerender self#updateImageCache;
          )
        | Some c -> c.force := True
        ]
      | False ->
          match imageCache with
          [ Some ({ic; tex; force; _ } as c) -> 
            match ic#filters = [] with
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

    method filters =
      match imageCache with
      [ None -> []
      | Some {ic; _ } -> ic#filters
      ];

    method! boundsChanged () = 
    (
(*         debug "%s bounds changed" self#name; *)
      match imageCache with
      [ Some ({valid=`valid;_} as c) -> (self#addPrerender self#updateImageCache; c.valid := `invalid)
      | Some ({valid=`prerender;_} as c) -> c.valid := `invalid
      | _ -> ()
      ];
      super#boundsChanged();
    );

    method private updateImageCache () = 
      match imageCache with
      [ Some ({ic; tex; valid = (( `invalid | `prerender) as valid); _} as c) -> 
        (
          debug:prerender "updateImageCache: %s" self#name;
          match valid with
          [ `invalid ->
            let () = debug:prerender "cacheImage %s not valid" ic#name in
            let bounds = self#boundsInSpace (Some self) in
            if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
            then c.empty := True
            else 
            (
              tex#resize bounds.Rectangle.width bounds.Rectangle.height;
              let ip = {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} in
              if ip <> ic#pos
              then ic#setPosPoint ip
              else ();
              let alpha' = alpha in
              (
                self#setAlpha 1.;
                tex#draw (fun () ->
                  (
                    Render.push_matrix (Matrix.create ~translate:(Point.mul ic#pos ~-.1.) ());
                    Render.clear 0 0.;
                    super#render' ~transform:False None;
                    Render.restore_matrix ();
                  );
                );
                self#setAlpha alpha';
              );
              ic#prerender True;
              c.empty := False;
            )
          | `prerender -> 
              let () = debug:prerender "prerender %s" ic#name in
              ic#prerender True
          ];
          c.valid := `valid; 
        )
    | _ -> ()
    ];

    method setFilters filters = 
      let () = debug:filters "set filters [%s] on %s" (String.concat "," (List.map Filters.string_of_t filters)) self#name in
      match filters with
      [ [] ->
        match imageCache with
        [ None -> ()
        | Some {tex;force=False;_} -> (tex#release();imageCache := None)
        | Some ({ic;valid;_} as c) -> 
          (
              ic#setFilters []; 
              match valid with
              [ `valid -> (c.valid := `prerender; self#addPrerender self#updateImageCache)
              | _ -> ()
              ]
          )
        ]
      | filters -> 
        match imageCache with
        [ None -> 
          let bounds = self#boundsInSpace (Some self) in
          let () = debug "bounds of sprite: [%f:%f:%f:%f]" bounds.Rectangle.x bounds.Rectangle.y bounds.Rectangle.width bounds.Rectangle.height in
          let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
          let img = Image.create (tex :> Texture.c) in
          (
            debug:filters "create %s as image cache for %s" img#name self#name;
            img#setPosPoint {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y};
            img#setFilters filters;
            imageCache := Some {ic = img; tex; empty = False; valid = `invalid; force = False};
            self#addPrerender self#updateImageCache;
          )
        | Some ({ic; valid; _ } as c) -> 
          (
            ic#setFilters filters;
            match valid with
            [ `valid -> (c.valid := `prerender; self#addPrerender self#updateImageCache) 
            | _ -> ()
            ]
          )
        ]
      ];

    method! private render' ?alpha:(alpha') ~transform rect = 
      match imageCache with
      [ None -> super#render' ?alpha:alpha' ~transform rect
      | Some {ic; tex;empty=False;_} ->
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
      | _ -> ()
      ];

  end;


value create () = new c;

