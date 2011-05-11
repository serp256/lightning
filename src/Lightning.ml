
module Make(Param:sig type evType = private [> Stage.eventType ]; type evData = private [> Stage.eventData ]; end) = struct
  module DisplayObject = DisplayObject.Make Param;
  module Quad = Quad.Make DisplayObject;
  module Image = Image.Make DisplayObject;
  module Sprite = Sprite.Make DisplayObject;
  module MovieClip = MovieClip.Make DisplayObject;
  module TextField = TextField.Make DisplayObject;
  module FPS = FPS.Make DisplayObject;
  module Stage = Stage.Make DisplayObject;
end;


module Default = Make (struct type evType = Stage.eventType; type evData = Stage.eventData; end);

(* добавлю с таймерами отдельно чтоли ? *)



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
value init s = 
  let s = (s :> stage_constructor) in
  _stage.val := Some s;
value stage_create width height = 
  match _stage.val with
  [ None -> failwith "Stage not initialized"
  | Some stage -> stage width height
  ];
value () = 
(
  Callback.register "stage_create" stage_create;
);
ENDIF;
