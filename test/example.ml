open LightCommon;

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value bgColor = 0xCCCCCC;
    initializer begin
      let request = URLLoader.request "http://pizdaya.ru" in
      let ldr = new URLLoader.loader () in (
        ldr#addEventListener URLLoader.ev_PROGRESS (fun _ _ _ -> ( debug "progress"; (); ));
        ldr#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ -> ( debug "complete %s %d %Ld %s" ldr#data ldr#httpCode ldr#bytesTotal ldr#contentType; (); ));
        ldr#addEventListener URLLoader.ev_IO_ERROR (fun ev _ _ -> ( match URLLoader.ioerror_of_data ev.Ev.data with [ Some (code, mes) -> debug "ioerr %d %s" code mes | _ -> () ]; ));
        ldr#load request;
      )
    end;
  end
in
  Lightning.init stage;
