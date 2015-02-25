value init: unit -> unit;

module Handler: sig
  module type S = sig
    type callback;

    value pushCallback: callback -> unit;
    value popCallback: unit -> unit;
  end;
end;

module Keys: sig
  type phase = [= `up | `down ];
  module Params: sig type callbackArg = phase; end;

  module Back: Handler.S with type callback = Params.callbackArg -> bool;
  module Menu: Handler.S with type callback = Params.callbackArg -> bool;
  module A: Handler.S with type callback = Params.callbackArg -> bool;
  module B: Handler.S with type callback = Params.callbackArg -> bool;
  module X: Handler.S with type callback = Params.callbackArg -> bool;
  module Y: Handler.S with type callback = Params.callbackArg -> bool;
  module LeftStick: Handler.S with type callback = Params.callbackArg -> bool;
  module RightStick: Handler.S with type callback = Params.callbackArg -> bool;
  module PlayPause: Handler.S with type callback = Params.callbackArg -> bool;
  module Rewind: Handler.S with type callback = Params.callbackArg -> bool;
  module FastForward: Handler.S with type callback = Params.callbackArg -> bool;
  module LeftShoulder: Handler.S with type callback = Params.callbackArg -> bool;
  module RightShoulder: Handler.S with type callback = Params.callbackArg -> bool;
end;

module Joysticks: sig
  type joystick = [= `none | `left | `right ];

  module Params: sig type callbackArg = (float * float); end;

  module Left: Handler.S with type callback = Params.callbackArg -> bool;
  module Right: Handler.S with type callback = Params.callbackArg -> bool;
  module Navigation: Handler.S with type callback = Params.callbackArg -> bool;

  value bindToTouches: ?incFactor:float -> ?position:(float * float) -> ~joystick:joystick -> unit -> unit;
end;

module Triggers: sig
  module Params: sig type callbackArg = float; end;

  module Left: Handler.S with type callback = Params.callbackArg -> bool;
  module Right: Handler.S with type callback = Params.callbackArg -> bool;
end;
