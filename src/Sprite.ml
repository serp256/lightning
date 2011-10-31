
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

  type imageCahce = {ic: Image.c; tex: mutable Texture.rendered; valid: mutable bool};

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
            imageCache := Some {ic = Image.create (tex :> Texture.c); tex ; valid = False}
          | _ -> ()
          ]
        | False ->
            match imageCache with
            [ Some {ic; tex; _ } -> 
              match ic#filters = [] with
              [ True -> 
                  (
                    tex#release ();
                    imageCache := None;
                )
              | False -> ()
              ]
            | _ -> ()
            ]
        ];

      method filters =
        match imageCache with
        [ None -> []
        | Some {ic; _ } -> ic#filters
        ];

      method setFilters filters = 
        match imageCache with
        [ None -> 
          let bounds = self#bounds in
          let tex = Texture.rendered ~color:0x000000 ~alpha:1. bounds.Rectangle.width bounds.Rectangle.height in
          let img = Image.create (tex :> Texture.c) in
          (
            img#setPosPoint (Point.subtractPoint {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} pos);
            img#setFilters filters;
            imageCache := Some {ic = img; tex; valid = False}
          )
        | Some {ic; _ } -> ic#setFilters filters
        ];

      method! private render' ?alpha ~transform rect = 
        match imageCache with
        [ None -> super#render' ?alpha ~transform rect
        | Some ({ic; tex; valid} as c) -> 
          (
            if not valid then 
            (
              tex#draw (fun () ->
                (
                  Render.push_matrix (Matrix.create ~translate:ic#pos ());
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

