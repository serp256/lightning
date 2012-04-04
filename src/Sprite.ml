
module D = DisplayObject;

(* наверно лучше было бы сделать RenderedImage *)

type cache_valid = [ CInvalid | CPrerender | CEmpty | CValid ];
type imageCache = 
  {
    ic: mutable option Image.c; 
    tex: mutable option Texture.rendered; 
    valid: mutable cache_valid;
    force: mutable bool
  };

class c =
  object(self)
    inherit D.container as super; 
    method ccast: [= `Sprite of c] = `Sprite (self :> c);

    value mutable imageCache = None;
    method !name = if name = ""  then Printf.sprintf "sprite%d" (Oo.id self) else name;
    method cacheAsImage = imageCache <> None;
    value mutable filters = [];
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

    method filters = filters;

    method! boundsChanged () = 
    (
(*         debug "%s bounds changed" self#name; *)
      match imageCache with
      [ Some ({valid=CValid;_} as c) -> (self#addPrerender self#updateImageCache; c.valid := CInvalid)
      | Some ({valid=CPrerender;_} as c) -> c.valid := CInvalid
      | _ -> ()
      ];
      super#boundsChanged();
    );

    method private updateImageCache () = 
      match imageCache with
      [ Some ({ic; tex; valid = CInvalid;  _} as c) -> 
        (
          debug:prerender "validate image cache: %s" self#name;
          let () = debug:prerender "cacheImage %s not valid" ic#name in
          let bounds = self#boundsInSpace (Some self) in
          if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
          then c.valid := CEmpty
          else 
            let (ic,tex) = 
              match (ic,tex) with 
              [ (Some ic, Some tex) -> 
                (
                  tex#resize bounds.Rectangle.width bounds.Rectangle.height;
                  (ic,tex) 
                )
              | (None,None) -> 
                  let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
                  let img = Image.create (tex :> Texture.c) in
                  (
                    img#setFilters filters;
                    c.tex := Some tex;
                    c.ic := Some img;
                    (img,tex)
                  )
              | _ -> assert False
              ]
            in
            (
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
            );
            c.valid := CValid; 
          )
    | Some ({ic = Some ic; valid = CPrerender ; _} as c) -> 
      (
        debug:prerender "prerender image cache: %s" self#name;
        ic#prerender True;
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
          | Some {tex=Some tex;force=False;_} -> (tex#release();imageCache := None)
          | Some ({ic = Some ic;valid;_} as c) -> 
            (
                ic#setFilters []; 
                match valid with
                [ CValid  -> (c.valid := CPrerender; self#addPrerender self#updateImageCache)
                | _ -> ()
                ]
            )
          | Some ({valid=CValid; _} as c) -> (c.valid := CInvalid; self#addPrerender self#updateImageCache)
          | _ -> () (* значит уже висит пререндер нахуй *)
          ]
        | _ -> 
          match imageCache with
          [ None -> 
            (*
            let bounds = self#boundsInSpace (Some self) in
            let () = debug "bounds of sprite: [%f:%f:%f:%f]" bounds.Rectangle.x bounds.Rectangle.y bounds.Rectangle.width bounds.Rectangle.height in
            let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
            let img = Image.create (tex :> Texture.c) in
            *)
            (
              debug:filters "create %s as image cache for %s" img#name self#name;
              (*
              img#setPosPoint {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y};
              img#setFilters filters;
              imageCache := Some {ic = img; tex; empty = False; valid = `invalid; force = False};
              *)
              let bounds = self#bounds in
              if bounds.Rectangle.width = 0. || bounds.Rectangle.height = 0.
              then imageCache := Some {ic = None; tex = None; valid = CEmpty; force = False}
              else
              (
                imageCache := Some {ic = None; tex = None; valid = CInvalid; force = False};
                self#addPrerender self#updateImageCache;
              )
            )
          | Some ({ic = Some ic; valid; _ } as c) -> 
            (
              ic#setFilters filters;
              match valid with
              [ CValid -> (c.valid := CPrerender; self#addPrerender self#updateImageCache) 
              | _ -> ()
              ]
            )
          | _ -> ()
          ]
        ];
      );

    method! private render' ?alpha:(alpha') ~transform rect = 
      match imageCache with
      [ None -> super#render' ?alpha:alpha' ~transform rect
      | Some {ic=Some ic; valid=CValid;_} ->
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
      | _ -> assert False
      ];

  end;


value create () = new c;

