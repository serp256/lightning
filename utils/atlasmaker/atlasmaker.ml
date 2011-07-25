type rect = {
  x : int;
  y : int;
  w : int;
  h : int
};

value out_file = ref "tx_texture";
value gen_pvr = ref False;

value imageRects : (Hashtbl.t string rect) = Hashtbl.create 55;

exception Break_loop;

(* получаем кропленый прямоугольник *)
value croppedImageRect img = 

  let vlineEmpty img num f t = 
    let y = ref f in
    try 
    (
      while !y <= t do 
      (
        let elt = Rgba32.get img num !y in  
        match elt.Color.Rgba.alpha with
        [0 -> incr y
        |_ -> raise Break_loop
        ]
      )  
      done;
      True
    )  
    with [ Break_loop -> False]
  
  and hlineEmpty img num f t = 
    let x = ref f in
    try 
    (
      while !x <= t do 
      (
        let elt = Rgba32.get img !x num in  
        match elt.Color.Rgba.alpha with
        [0 -> incr x
        |_ -> raise Break_loop
        ]
      )  
      done;
      True
    )
    with [Break_loop -> False]
  in
  match img with
  [ Images.Rgba32 i -> 
    let x = ref 0
    and y = ref 0 
    and w = ref i.Rgba32.width
    and h = ref i.Rgba32.height in 
    (
      
      (* сканируем сверху *)
      try 
        while !y < i.Rgba32.height do 
          match hlineEmpty i !y !x (!x + !w - 1) with
          [ True    -> incr y
          | False   -> raise Break_loop
          ]
        done
      with [Break_loop -> ()];
      
      (* сканируем снизу *)
      try 
        while !h > 0 do 
          match hlineEmpty i (!h - 1) !x (!x + !w - 1) with
          [ True    -> decr h
          | False   -> raise Break_loop
          ]
        done        
      with [Break_loop -> ()];
      
      (* слева *)
      try 
        while !x < i.Rgba32.width do 
          match vlineEmpty i !x !y (!y + !h - 1) with
          [ True    -> incr x
          | False   -> raise Break_loop
          ]
        done        
      with [Break_loop -> ()];      
      
      (* справа *)
      try 
        while !w > 0 do 
          match vlineEmpty i (!w - 1) !y (!y + !h - 1) with
          [ True    -> decr w
          | False   -> raise Break_loop
          ]
        done        
      with [Break_loop -> ()];      
      
      { x = !x; y = !y; w = (!w - !x); h = (!h - !y) }
    )
    
  | Images.Rgb24 i -> 
    { x = 0; y = 0; w = i.Rgb24.width; h = i.Rgb24.height }

  | _ -> assert False
  ];



(* зачитываем картинку, получаем кроп-прямоугольник и сохраняем его*)
value readImageRect fname = 
  let () = Printf.eprintf "Loading %s\n%!" fname in
  try 
    let rect = croppedImageRect (Images.load fname []) in
    Hashtbl.add imageRects fname rect
  with [Images.Wrong_file_type -> ()];



(* загружаем все файлы, влючая поддиректории *)
value loadFiles d =
  let rec _readdir dir = 
    Array.iter begin fun f -> 
      try 
        let path = dir ^ "/" ^ f in
        match Sys.is_directory path with
        [ True  ->  _readdir path
        | False -> readImageRect path
        ]
      with [Sys_error _ -> ()]
    end (Sys.readdir dir)   
  in _readdir d;


(* 
 возвращает список страниц. каждая страница не больше 2048x2048
*)

value layoutRects rects = 
  (* 
    пробуем упаковать прямоугольники в заданные пустые прямоугольники.
    возвращаем оставшиеся прямоугольники и страницы
  *)
  let rec tryLayout rects placed empty unfit = 
    match rects with
    [ [] -> (placed, unfit)    (* все разместили *)
    | [r :: rects']  -> 
      match empty with 
      [ []  -> (placed, (List.append rects unfit))
      | _   -> 
      
        let rec putToMinimalContainer rect placed containers used_containers = 
          match containers with 
          [ [] -> raise Not_found
          | [ c :: containers'] -> 
            
            match rect with
            [ (id, r) -> 
              if r.w > c.w || r.h > c.h then
                putToMinimalContainer rect  placed containers' [c :: used_containers]
              else
                let r' =  { x = c.x; y = c.y; w = r.w; h = r.h }             
                and e1 = { x = c.x; y = c.y + r.h; w = r.w; h = c.h - r.h }
                and e2 = { x = c.x + r.w; y = c.y; w = c.w - r.w; h = c.h }
                in ([(id,r') :: placed], (List.append containers' (List.append used_containers [e1; e2])))
            ]
          ]
        in 
      
        (* пытаемся впихнуть наибольший прямоугольник в наименьшую пустую область *)
        try 
          let (placed', empty') = putToMinimalContainer r placed empty []  
          in tryLayout rects' placed' (List.sort begin fun c1 c2 -> 
            let s1 = c1.w*c1.h 
            and s2 = c2.w*c2.h
            in 
            if s1 = s2 then
              0
            else if s1 > s2 then
              1
            else 
              -1  
          end empty') unfit
        with [Not_found -> tryLayout rects' placed empty [r :: unfit]]
      ]
    ]
  in 
  
  
  (* размещаем на одной странице, постепенно увеличивая ее размер *)
  let rec layout rects w h = 
    let mainrect = { x = 0; y = 0; w; h } in
    let (placed, rest) = tryLayout rects [] [mainrect] [] in 
    match rest with 
    [ [] -> (w, h, placed, rest) (* разместили все *)
    | _  -> 
        let (w', h') = 
          if w > h then
            (w, (h*2))
          else 
            ((w*2), h)
        in 
        if w' > 2048 then (* не в местили в максимальный размер. возвращаем страницу *)
          (2048, 2048, placed, rest)
        else
          layout rects w' h'
    ]

  in 
  
  (* размещаем на нескольких страницах *)
  let rec layout_multipage rects pages = 
    let (w, h, placed, rest) = 
      layout 
        (List.sort 
          begin fun (_,r1)  (_,r2) -> 
            let s1 = r1.w*r1.h and s2 = r2.w*r2.h in
            if s1 = s2 then 0
            else if s1 > s2 then -1
            else 1
        end rects
      ) 2 2
    in match rest with 
    [ [] -> [ (w,h,placed) :: pages]
    | _  -> layout_multipage rest [(w,h,placed) :: pages]
    ]
  in layout_multipage rects [];
  
  
  
(* *)
value createAtlas () = 
    let i = ref 0 
    and pages = layoutRects (Hashtbl.fold (fun k v acc -> [(k,v) :: acc]) imageRects []) in
    let xml  = ref "<TextureAtlases >\n" in
    (
      List.iter begin fun (w,h,rects) -> 
      (
      
        let fname = match List.length pages with 
          [ 1 -> (!out_file ^ ".png")
          | _ -> 
            (
              incr i;
              Printf.sprintf "%s_%d.png" !out_file !i;
            )
          ] in
        let () = xml.val := !xml ^ (Printf.sprintf "<TextureAtlas imagePath='%s'>\n" fname) in
        let rgba = Rgba32.make w h {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
        let () = Printf.eprintf "Canvas: %dx%d\n%!" w h in
        let canvas  = Images.Rgba32 rgba in 
        (
          List.iter begin fun (id, rect) -> 
            let cropFrame = Hashtbl.find imageRects id 
            and img = Images.load id [] in
            let img = match img with 
            [ Images.Rgba32 i -> img
            | Images.Rgb24 i -> Images.Rgba32 (Rgb24.to_rgba32 i)
            | _ -> assert False
            ] in
            let subTextureElt = Printf.sprintf "\t<SubTexture name='%s' x='%d' y='%d' height='%f' width='%f'/>\n" id rect.x rect.y (float_of_int rect.h) (float_of_int rect.w) in
            let () = xml.val := !xml ^ subTextureElt in
            let cropped = Images.sub img cropFrame.x cropFrame.y cropFrame.w cropFrame.h in
            Images.blit cropped 0 0 canvas rect.x rect.y rect.w rect.h  
          end rects;
          Images.save fname (Some Images.Png) [] canvas;
        );
        
        xml.val := !xml ^ "</TextureAtlas>\n";
      )
      end pages;
      
      let oc = open_out (!out_file ^ ".xml") in (
        output_string oc !xml;
        output_string oc "</TextureAtlases>";
        close_out oc;
      )
      
    );      

      
      



(* *)
value () = 
  let dirname = ref None in
  (
    Arg.parse
      [
        ("-o",Arg.Set_string out_file,"output file");
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
    in (
      loadFiles dirname;
      createAtlas ();
    )
  );

(* 
TODO: Попробовать поворачивать картинки на 90 градусов.
*)
