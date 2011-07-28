
type eventType = [= Stage.eventType | `TRIGGERED ];
type eventData = Stage.eventData;


(*
module type Display = sig
  module DisplayObject: DisplayObjectT.M;
  module Quad : Quad.S;
  module Image : Image.S;
  module Sprite: Sprite.S;
  module CompiledSprite: CompiledSprite.S;
end;
*)

module Make(Param:sig type evType = private [> eventType ]; type evData = private [> eventData ]; end) = struct
  module DisplayObject = DisplayObject.Make Param;
  module Quad = Quad.Make DisplayObject;
  module Image = Image.Make Quad;
  module Sprite = Sprite.Make DisplayObject;
  module CompiledSprite = CompiledSprite.Make Image Sprite;
  module MovieClip = MovieClip.Make DisplayObject Image;
  module BitmapFontCreator = BitmapFont.MakeCreator Image CompiledSprite;
  module TextField = TextField.Make Quad BitmapFontCreator; 
  module FPS = FPS.Make DisplayObject TextField;
  module Button = Button.Make DisplayObject Sprite Image TextField;
  module Stage = Stage.Make DisplayObject;
end;


module DefaultParam = struct
  type evType = eventType;
  type evData = eventData;
end;

(* добавлю с таймерами отдельно чтоли ? *)


IFDEF IOS THEN
external showNativeWaiter: Point.t -> unit = "ml_showActivityIndicator";
external hideNativeWaiter: unit -> unit = "ml_hideActivityIndicator";
ELSE
value showNativeWaiter _pos = ();
value hideNativeWaiter () = ();
ENDIF;

type stage_constructor =
  float -> float -> 
    <
      render: option Rectangle.t -> unit;
      processTouches: list Touch.n -> unit;
      advanceTime: float -> unit;
      name: string;
    >;

(* value _stage: ref (option (float -> float -> stage eventTypeDisplayObject eventEmptyData)) = ref None; *)

IFDEF SDL THEN
value init s = 
  let s = (s :> stage_constructor) in
  Sdl_run.run s;
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

IFDEF ANDROID THEN (* for link mlwrapper_android *)
external jni_onload: unit -> unit = "JNI_OnLoad";
ENDIF;

value () = 
(
  Printexc.record_backtrace True;
  Callback.register "stage_create" stage_create;
);
ENDIF;





