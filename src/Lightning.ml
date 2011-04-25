
type stage_constructor =
  float -> float -> 
    <
      render: unit -> unit;
      processTouches: list Touch.t -> unit;
      advanceTime: float -> unit;
      name: string;
    >;

(* value _stage: ref (option (float -> float -> stage eventTypeDisplayObject eventEmptyData)) = ref None; *)

IFDEF SDL THEN
value init s = Sdl_run.run s;
ELSE
value _stage : ref (option stage_constructor) = ref None;
value init s = _stage.val := Some s;
value stage_create width height = 
  match _stage.val with
  [ None -> failwith "Stage not initialized"
  | Some stage -> stage width height
  ];
value () = 
(
(*   Callback.register "clear_texture" RenderSupport.clearTexture; *)
  Callback.register "stage_create" stage_create;
);
ENDIF;
