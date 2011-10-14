

module Make
  (D:DisplayObjectT.M with type evType = private [> DisplayObjectT.eventType | `ENTER_FRAME ] and type evData = private [> `PassedTime of float | DisplayObjectT.eventData ])
  (Image: Image.S with module D = D)

  : sig

  exception Frame_not_found;

  type frameID = [= `num of int | `label of string ];

  type direction =
    [= `forward
    | `backward
    ];


  type descriptor;

  value load: string -> descriptor;

  class c: [ ?fps:int ] -> [ descriptor ] ->
    object
      inherit Image.c;
      method loop: bool;
      method setLoop: bool -> unit;
      method fps: int;
      method currentFrame: int;
      method currentFrameLabel: option string;
      method totalFrames: int;
      method playDirection: direction;
      method setPlayDirection: direction -> unit;
      method play: ?onComplete:(unit -> unit) -> ?direction:direction -> unit -> unit;
      method isPlaying: bool;
      method stop: unit -> unit;
      method gotoAndPlay: ?onComplete:(unit -> unit) -> frameID -> unit;
      method gotoAndStop: frameID -> unit;
      method playRange: ?onChangeFrame:(unit->unit) -> ?onComplete:(unit -> unit) ->  ?direction:direction -> frameID -> frameID -> unit;
    end;


  value create: ?fps:int -> descriptor -> c;

end;
