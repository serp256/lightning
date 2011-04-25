

type init = [ JPG | PNG | TIF ];


external img_init: int -> unit = "ml_IMG_Init";

value init flags = 
  let flag = 
    List.fold_left begin fun v f ->
      let v' = 
        match f with
        [ JPG -> 0x01 
        | PNG -> 0x02
        | TIF -> 0x04
        ]
      in
      v land v'
    end 0 flags
  in
  img_init flag;


external load: string -> Sdl.Video.surface = "ml_IMG_Load";

