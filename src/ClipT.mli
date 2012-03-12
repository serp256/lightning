
module type S = sig

  module D: DisplayObjectT.S;
  module Image: Image.S with module D := D;
  module Sprite: Sprite.S with module D := D;
  module Atlas: Atlas.S with module D := D;

  exception Frame_not_found;

  value default_fps: ref int;
  type frameID = [= `num of int | `label of string ];
  type direction = 
    [= `forward
    | `backward
    ];


  class type virtual movie = 
    object
      inherit D.c;
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

  class type virtual c = 
    object
      inherit D.c;
      method clip_cast: [= `Image of Image.c | `Sprite of Sprite.c | `Atlas of Atlas.c | `Movie of movie ];
    end;


  type lib;


  value load: ?loadTextures:bool -> string -> lib;
  value load_async: string -> (lib -> unit) -> unit;
  value loadxml: ?loadTextures:bool -> string -> lib;

  value image: string -> c;
  value image_from_texture : Texture.c -> c;
  value image_async: string -> (c -> unit) -> unit;

  value release: lib -> unit;

  value symbols: lib -> Enum.t string;
  value get_symbol: lib -> string -> c;
  value get_symbol_async: lib -> string -> (c -> unit) -> unit;

end;
