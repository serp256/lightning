
open Printf;
open Unix;


value min_columns = 174;
IFNDEF IOS THEN
value columns : int = 
  let tput = Unix.open_process_in "tput cols 2>/dev/null" in
  try
    let cols = input_line tput in
    (
      ignore (Unix.close_process_in tput);
      prerr_endline cols;
      max (int_of_string cols) min_columns;
    )
  with [ End_of_file -> min_columns ];
ELSE
value columns = 80;
END;

value fail_writer = (fun s -> failwith s);
value e_writer = ref (fun s -> prerr_endline s);
value w_writer = ref (fun s -> prerr_endline s);
value d_writer = ref (fun s -> prerr_endline s);
value _flush = ref (fun () -> ());
value null_writer = (fun _ -> ());
value flush () = !_flush();


(* Временно дату вырезал нах
 * %04d%02d%02d (tm.tm_year + 1900) (tm.tm_mon + 1) (tm.tm_mday)  
*)

value string_of_timestamp t = 
  let tm = Unix.localtime t in
  sprintf "%04d%02d%02d_%02d:%02d:%02d.%03d" (tm.tm_year + 1900) (tm.tm_mon + 1) (tm.tm_mday) tm.tm_hour tm.tm_min tm.tm_sec (int_of_float ((t -. floor t) *. 1000.)) ;

value timestamp () = 
  let t = Unix.gettimeofday() in
  string_of_timestamp t;

value out writer level mname mline s = 
  let t = Unix.gettimeofday() in
  let tm = Unix.localtime t in
  let line = 
    let message = sprintf "[%02d:%02d:%02d.%03d] [%s] %s" tm.tm_hour tm.tm_min tm.tm_sec (int_of_float ((t -. floor t) *. 1000.)) level s in
    let place = sprintf "[%s:%d]" mname mline in
    let module UTF = UTF8 in
    let message_length = try (UTF.length message) mod columns with [UTF.Malformed_code -> String.length message] in
    let spaces_cnt = columns - message_length - (String.length place) in
    if spaces_cnt > 0 
    then message ^ (String.make spaces_cnt ' ') ^ place
    else message ^ "\n" ^ (String.make (columns - (String.length place)) ' ') ^ place (* Здесь бы ещё вставить кол-во пробелов чтобы справо было *)
  in
  writer line;

value simple_out writer s = 
  writer (sprintf "[%s] %s" (timestamp()) s);
                    
value fail mname mline fmt = 
  kprintf (out fail_writer "FAIL" mname mline) fmt; 

value e mname mline fmt =
  kprintf (out !e_writer "ERROR" mname mline) fmt; 

value w mname mline fmt =
  kprintf (out !w_writer "WARN" mname mline) fmt; 

value d mname mline ?l fmt =
  let l = 
    match l with
    [ Some l -> "D:"^l
    | None -> "D"
    ]
  in
  ksprintf (out !d_writer l mname mline) fmt;

value m m = !e_writer m;
value msg fmt = ksprintf (simple_out !w_writer) fmt;
value smsg = simple_out !w_writer;
