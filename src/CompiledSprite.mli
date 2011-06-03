
module type S = sig

  module Sprite: Sprite.S;

  class c:
    object
      inherit Sprite.c;
      method compile: unit -> unit;
      method invalidate: unit -> unit;
    end;


  value create: unit -> c;

end;


module Make(Image:Image.S)(Sprite:Sprite.S with module D = Image.Q.D) : S with module Sprite = Sprite;
