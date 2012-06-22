
type frameID = [= `num of int | `label of string ];
type direction = 
  [= `forward
  | `backward
  ];

type cFrame 'keyframe = 
  [ KeyFrame of (option string * 'keyframe)
  | Frame of int
  ];

exception Frame_not_found;

class type virtual c = 
  object
    inherit DisplayObject.c;
    method ccast: [= `Clip of c ];
    method loop: bool;
    method setLoop: bool -> unit;
    method fps: int;
    method currentFrame: int;
    method currentFrameLabel: option string;
    method totalFrames: int;
    method playDirection: direction;
    method setPlayDirection: direction -> unit;
    method play: ?onChangeFrame:(unit->unit) -> ?onComplete:(unit -> unit) -> ?direction:direction -> unit -> unit;
    method isPlaying: bool;
    method stop: unit -> unit;
    method gotoAndPlay: ?onComplete:(unit -> unit) -> frameID -> unit;
    method gotoAndStop: frameID -> unit;
    method playRange: ?onChangeFrame:(unit->unit) -> ?onComplete:(unit -> unit) ->  ?direction:direction -> frameID -> frameID -> unit;
    method resolveFrame: frameID -> int;
  end;

type labels = Hashtbl.t string int;

class virtual base ['frame] : [ ~fps:int ] -> [ ~frames:array (cFrame 'frame)] -> [~labels:labels] ->
  object
    inherit c;
    value currentFrameID: int;
    method private virtual applyFrame: int -> 'frame -> unit;
  end;
