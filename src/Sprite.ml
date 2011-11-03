
module type S = sig
  module D : DisplayObjectT.M;

  class c:
    object
      inherit D.container;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method cacheAsImage: bool;
      method setCacheAsImage: bool -> unit;
    end;

  value create: unit -> c;

end;

module Make(D:DisplayObjectT.M)(Image:Image.S with module D = D) = struct

  module D = D;

  type imageCahce = {ic: Image.c; tex: mutable Texture.rendered; valid: mutable bool; force: mutable bool};

  class c =
    object(self)
      inherit D.container as super; 

      value mutable imageCache = None;
      method cacheAsImage = imageCache <> None;
      method setCacheAsImage = fun
        [ True -> 
          match imageCache with
          [ None -> 
            let bounds = self#bounds in
            let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
            imageCache := Some {ic = Image.create (tex :> Texture.c); tex ; valid = False; force = True}
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
        match imageCache with
        [ Some c -> c.valid := False
        | None -> ()
        ];
        super#boundsChanged();
      );

      method setFilters = fun
        [ [] ->
          match imageCache with
          [ None -> ()
          | Some {tex;force=False;_} -> (tex#release();imageCache := None)
          | Some ({ic;_} as c) -> (ic#setFilters []; c.valid := False)
          ]
        | filters -> (* нужно обновлять сцука размеры нахуй поняла блядь *)
          match imageCache with
          [ None -> 
            let bounds = self#boundsInSpace (Some self) in
            let () = debug "bounds of sprite: [%f:%f:%f:%f]" bounds.Rectangle.x bounds.Rectangle.y bounds.Rectangle.width bounds.Rectangle.height in
            let tex = Texture.rendered ~color:0x000000 ~alpha:0. bounds.Rectangle.width bounds.Rectangle.height in
            let img = Image.create (tex :> Texture.c) in
            (
              img#setPosPoint {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y};
              img#setFilters filters;
              imageCache := Some {ic = img; tex; valid = False; force = False}
            )
          | Some {ic; _ } -> ic#setFilters filters
          ]
        ];

      method! private render' ?alpha ~transform rect = 
        match imageCache with
        [ None -> super#render' ?alpha ~transform rect
        | Some ({ic; tex; valid;_} as c) -> 
          (
            if not valid then 
            (
              tex#draw (fun () ->
                (
                  Render.push_matrix (Matrix.create ~translate:(Point.mul ic#pos ~-.1.) ());
                  Render.clear 0x000000 0.;
                  super#render' ?alpha ~transform:False rect;
                  Render.restore_matrix ();
                );
              );
              c.valid := True; 
            ) else ();
            if transform then Render.push_matrix self#transformationMatrix else ();
            ic#render rect;
            if transform then Render.restore_matrix () else ();
          )
        ];

    end;


  value create () = new c;

end;

