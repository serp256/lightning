
value out_dir = ref "";
value gen_pvr = ref False;

exception Empty_image;
value crop_edges img32 = 
  let rec find get (x,width) (y,height) = 
    let () = Printf.printf "find [%d:%d] [%d:%d]\n" x width y height in
    let delta = if y > height then ~-1 else 1 in
    let rec loop y = 
      if y = height
      then raise Empty_image
      else
        let rec check_line x = 
          if x < width
          then 
            let () = Printf.printf "check %d:%d\n" x y in
            match (get x y).Color.alpha = 0 with
            [ True -> check_line (x + 1)
            | False -> let () = print_endline "non empty" in False
            ]
          else True
        in
        match check_line x with
        [ True -> loop (y + delta)
        | False -> y
        ]
    in
    loop y
  in
  let height = img32#height and width = img32#width in
  let () = Printf.printf "%dx%d\n" width height in
  let y = find img32#get (0,width) (0,height-1)
  and y' = find img32#get (0,width) (height-1,~-1)
  in
  let get y x = img32#get x y in
  let x = find get (y,y'+1) (0,width-1)
  and x' = find get (y,y'+1) (width-1,~-1)
  in
  let () = Printf.printf "%d:%d:%d:%d\n" x y x' y' in
  (x,y,(x' -x),(y' - y));


(*
value check_layout layout max_cols = (*{{{*)
  loop layout max_cols (0,0) 0 0 where
    rec loop layout cols (x,y) width line_height = 
      match layout with
      [ [ h :: tl ] ->
        if (cols > 0)
        then
          if (x + h.width) > max_size 
          then None
          else
            let line_height = max line_height h.height in
            if (y + line_height) > max_size
            then None
            else
              let x = x + h.width in
              loop tl (cols - 1) (x,y) (max x width) line_height
        else
          let y = y + line_height in
          if (y + h.height > max_size || h.width > max_size)
          then None
          else loop tl (max_cols-1) (h.width,y) (max h.width width) h.height
      | [] -> Some (max width (y+line_height))
      ];(*}}}*)

value layout_variances layout = (*{{{*)
  let cols = ExtLib.List.mapi (fun i _ -> i+1) layout in
  ExtLib.List.filter_map begin fun cols ->
    match check_layout layout cols with
    [ None -> None
    | Some size -> Some (cols,size)
    ]
  end cols;(*}}}*)
      
value select_layout_variance layout =
  match (layout_variances layout) with
  [ [] -> None
  | [ h :: tl ] -> Some (List.fold_left (fun ((min_cols,min_size) as a) ((cols,size) as s) -> if size < min_size then s else a) h tl)
  ];

*)

(*
value test_crop fname = 
  let image = OImages.load fname [] in
  let rgba32 = OImages.rgba32 image in
  let (x,y,width,height) = crop_edges rgba32 in
  let simage = rgba32#sub x y width height in
  simage#save "output.png" None [];
  (*
    let (x,y,width,height) = test_crop dirname in
    Printf.printf "%d:%d:%d:%d\n%!" x y width height;
    *)
*)

(* Тулза которая делает либо просто атласы *)



value readdir d =
  let files = Sys.readdir d in
  let files = ExtLib.Array.filter (fun f -> f.[0] <> '.') files in
  (
    files
  );



value () = 
  let dirname = ref None in
  (
    Arg.parse
      [
        ("-o",Arg.Set_string out_dir,"output directory");
        ("-p",Arg.Set gen_pvr,"generate pvr file")
      ]
      (fun dn -> match !dirname with [ None -> dirname.val := Some dn | Some _ -> failwith "You must specify only one directory" ])
      "---"
    ;
    let dirname =
      match !dirname with
      [ None -> failwith "You must specify directory for process"
      | Some d -> d
      ]
    in
    let files = readdir dirname in
    create_atlas dirname files
  );
