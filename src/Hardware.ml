
IFDEF IOS THEN
external platform: unit -> string = "ml_platform";
external hwmodel: unit -> string = "ml_hwmodel";
external cpu_frequency: unit -> int = "ml_cpuFrequency";
external total_memory: unit -> int = "ml_totalMemory";
external user_memory: unit -> int = "ml_userMemory";
ELSE IFDEF ANDROID THEN
external platform: unit -> string = "ml_platform";
external hwmodel: unit -> string = "ml_hwmodel";
(*
external total_memory: unit -> int = "ml_totalMemory";
*)
value total_memory () = 
  let inp = IO.input_channel (open_in "/proc/meminfo") in
  let str = IO.read_all inp in
    (
      IO.close_in inp;
      let index = (ExtString.String.find str "MemTotal:" + 9) in
      let str = String.sub str index ((String.length str) - index) in
      let res = ref "" in
        (
          debug:hardware "mem : %S" str;
          try
            String.iter begin fun c -> 
              match c with
              [ '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' -> res.val := !res ^ (ExtString.String.of_char c) 
              | ' ' -> ()
              | _ -> raise Exit
              ]
            end str;
          with
            [ Exit -> () ];
          debug:hardware "PIZDA: %S" !res;
          ExtString.String.to_int !res; 
        )
    );
ELSE
value platform () = "PLATFORM";
value hwmodel () = "HWMODEL";
value cpu_frequency () = 0;
value total_memory () = 0;
ENDIF;
value cpu_frequency () = 0;
value internal_user_memory = ref 0;
value user_memory () = !internal_user_memory;
ENDIF;
