

module Make
  (D:DisplayObjectT.M with type evType = private [> DisplayObjectT.eventType | `ENTER_FRAME ] and type evData = private [> `PassedTime of float | DisplayObjectT.eventData ])
  (Image: Image.S with module Q.D = D)

  : sig

  exception Frame_not_found;

  type frameLink = [= `num of int | `label of string ];

  class c: [ ?fps:int ] -> [ string ] ->
    object
      inherit Image.c;
      method loop: bool;
      method setLoop: bool -> unit;
      method fps: int;
      method currentFrame: int;
      method currentFrameLabel: option string;
      method totalFrames: int;
      method play: unit -> unit;
      method isPlaying: bool;
      method stop: unit -> unit;
      method gotoAndPlay: frameLink -> unit;
      method gotoAndStop: frameLink -> unit;
    end;


  value create: ?fps:int -> string -> c;

end;
