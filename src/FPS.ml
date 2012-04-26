
module Make
  (Sprite:Sprite.S type D.evType = private [> `ENTER_FRAME | DisplayObjectT.eventType ] and type D.evData = private [> `PassedTime of float | DisplayObjectT.eventData] )
  (TextField:TextField.S with module D = D) = struct


  class c ?fontSize ?color () = 
    object(self)
      inherit Sprite.c;
      value mutable frames = 0;
      value mutable time = 0.;

      value mutable listenerID: int = 0;

      initializer ignore(self#addEventListener `ENTER_FRAME self#onEnterFrame);


      method private onEnterFrame event _ _ = 
        match event.Ev.data with
        [ `PassedTime dt -> 
          let osecs = int_of_float time in
          (
            time := time +. dt;
            let seconds = (int_of_float time) - osecs in
            match seconds with
            [ 0 ->  frames := frames + 1
            | _ -> 
              (
                self#clearChildren();
                TLF.create ~dest:self (TLP.p ?fontSize ?fontColor:color [`text (string_of_int (frames / seconds))]);
                frames := 1;
              )
            ]
          )
        | _ -> assert False
        ];

    end;

  value create = new c;

end;
