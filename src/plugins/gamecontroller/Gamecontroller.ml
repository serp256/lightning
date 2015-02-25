external init: unit -> unit = "gamecontroller_init";

module Handler = struct
  module type GroupParam = sig
    type callbackArg;
    value cnameBase: string;
  end;

  module type ConcreteParam = sig
    value cname: string;
  end;

  module type S = sig
    type callback;

    value pushCallback: callback -> unit;
    value popCallback: unit -> unit;
  end;

  module Make(GroupP:GroupParam)(ConcreteP:ConcreteParam) = struct
    type callback = GroupP.callbackArg -> bool;

    value queue = Lazy.from_fun (fun _ -> Queue.create ());
    value queue () = Lazy.force queue;

    value runCallback arg =
      let () = debug "run callback %s" (GroupP.cnameBase ^ ConcreteP.cname) in
      try
        let callback = Queue.top (queue ()) in
          callback arg
      with [ Queue.Empty -> False ];

    value pushCallback (callback:callback) = Queue.push callback (queue ());

    value popCallback () =
      try
        let _ = Queue.pop (queue ()) in ()
      with [ Queue.Empty -> () ];

    Callback.register (GroupP.cnameBase ^ ConcreteP.cname) runCallback;
  end;
end;

module Keys = struct
  module Params = struct type callbackArg = unit; value cnameBase = "Gamecontroller.Keys."; end;
  module Handler = Handler.Make(Params);

  module Back = Handler(struct value cname = "Back"; end);
  module Menu = Handler(struct value cname = "Menu"; end);
  module A = Handler(struct value cname = "A"; end);
  module B = Handler(struct value cname = "B"; end);
  module X = Handler(struct value cname = "X"; end);
  module Y = Handler(struct value cname = "Y"; end);
  module LeftStick = Handler(struct value cname = "LeftStick"; end);
  module RightStick = Handler(struct value cname = "RightStick"; end);
  module PlayPause = Handler(struct value cname = "PlayPause"; end);
  module Rewind = Handler(struct value cname = "Rewind"; end);
  module FastForward = Handler(struct value cname = "FastForward"; end);
  module LeftShoulder = Handler(struct value cname = "LeftShoulder"; end);
  module RightShoulder = Handler(struct value cname = "RightShoulder"; end);
end;

module Joysticks = struct
  module Params = struct type callbackArg = (float * float); value cnameBase = "Gamecontroller.Joysticks."; end;
  module Handler = Handler.Make(Params);

  module Left = Handler(struct value cname = "Left"; end);
  module Right = Handler(struct value cname = "Right"; end);
  module Navigation = Handler(struct value cname = "Navigation"; end);
end;

module Triggers = struct
  module Params = struct type callbackArg = float; value cnameBase = "Gamecontroller.Triggers."; end;
  module Handler = Handler.Make(Params);

  module Left = Handler(struct value cname = "Left"; end);
  module Right = Handler(struct value cname = "Right"; end);
end;
