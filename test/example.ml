open LightCommon;

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value bgColor = 0xCCCCCC;
    initializer begin
      let req1 = URLLoader.request "http://192.168.21.75/main.161131.ru.redspell.smallfarm.obb" in
      let req2 = URLLoader.request "http://ya.ru" in
      let req3 = URLLoader.request "http://pizdaya.ru" in

      let ldr1 = new URLLoader.loader () in
      let ldr2 = new URLLoader.loader () in
      let ldr3 = new URLLoader.loader () in (
        
        ldr1#load req1;
        ldr2#load req2;
        ldr3#load req3;
        (* ldr#cancel (); *)

        (* ignore(Timers.start 2. (fun _ -> ldr1#cancel ())); *)
        ldr3#cancel ();

        ignore(ldr1#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ -> ( debug "complete 1 %d %Ld %s" ldr1#httpCode ldr1#bytesTotal ldr1#contentType; () )));
        ignore(ldr2#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ -> ( debug "complete 2 %d %Ld %s" ldr2#httpCode ldr2#bytesTotal ldr2#contentType; () )));
        ignore(ldr3#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ -> ( debug "complete 3 %d %Ld %s" ldr3#httpCode ldr3#bytesTotal ldr3#contentType; () )));

        ignore(ldr1#addEventListener URLLoader.ev_IO_ERROR (fun ev _ _ -> ( match URLLoader.ioerror_of_data ev.Ev.data with [ Some (code, mes) -> debug "ioerr 1 %d %s" code mes | _ -> () ]; )));
        ignore(ldr2#addEventListener URLLoader.ev_IO_ERROR (fun ev _ _ -> ( match URLLoader.ioerror_of_data ev.Ev.data with [ Some (code, mes) -> debug "ioerr 2 %d %s" code mes | _ -> () ]; )));
        ignore(ldr3#addEventListener URLLoader.ev_IO_ERROR (fun ev _ _ -> ( match URLLoader.ioerror_of_data ev.Ev.data with [ Some (code, mes) -> debug "ioerr 3 %d %s" code mes | _ -> () ]; )));

        ignore(ldr1#addEventListener URLLoader.ev_PROGRESS (fun _ _ _ -> ( debug "progress 1"; (); )));
        ignore(ldr2#addEventListener URLLoader.ev_PROGRESS (fun _ _ _ -> ( debug "progress 2"; (); )));
        ignore(ldr3#addEventListener URLLoader.ev_PROGRESS (fun _ _ _ -> ( debug "progress 3"; (); )));

        (* ldr#addEventListener URLLoader.ev_PROGRESS (fun _ _ _ -> ( debug "progress"; (); )); *)
(*         ldr#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ -> ( debug "complete %s %d %Ld %s" ldr#data ldr#httpCode ldr#bytesTotal ldr#contentType; ldr#load (URLLoader.request "http://google.com"); ));
        (* ldr#addEventListener URLLoader.ev_IO_ERROR (fun ev _ _ -> ( match URLLoader.ioerror_of_data ev.Ev.data with [ Some (code, mes) -> debug "ioerr %d %s" code mes | _ -> () ]; )); *)
        ldr#load request; *)
      )
    end;
  end
in
  Lightning.init stage;
