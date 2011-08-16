
value max_size = ref 2048;
type rect = {
  x : int;
  y : int;
  w : int;
  h : int
};

value countEmptyPixels = 2;


(* 
  пробуем упаковать прямоугольники в заданные пустые прямоугольники.
  возвращаем оставшиеся прямоугольники и страницы
*)
value rec tryLayout ~type_rects rects placed empty unfit = 
  match rects with
  [ [] -> (placed, unfit)    (* все разместили *)
  | [r :: rects']  -> 
    match empty with 
    [ []  -> (placed, (List.append rects unfit))
    | _   -> 
    
      let rec putToMinimalContainer ((info,img) as data) placed containers used_containers = 
        match containers with 
        [ [] -> raise Not_found
        | [ c :: containers'] -> 
          let (rw,rh) = Images.size img in
          if rw > c.w || rh > c.h 
          then
            putToMinimalContainer data  placed containers' [c :: used_containers]
          else
            let type_rects =
              match type_rects with
              [ 2 -> Random.int 2 
              | _ -> type_rects 
              ] 
            in
            let rects = 
              match type_rects with
              [ 0 ->
                  [
                    { x = c.x; y = c.y + rh + countEmptyPixels; w = rw; h = c.h - rh - countEmptyPixels };
                    { x = c.x + rw + countEmptyPixels; y = c.y; w = c.w - rw - countEmptyPixels; h = c.h }
                  ]
              | 1 -> 
                  [
                    { x = c.x; y = c.y + rh + countEmptyPixels; w = c.w; h = c.h - rh - countEmptyPixels };
                    { x = c.x + rw + countEmptyPixels; y = c.y; w = c.w - rw - countEmptyPixels; h = rh }
                  ]
              | _ -> failwith "unknown type_rects"
              ]
            in 
            (
              [(info,(c.x,c.y,img)) :: placed], 
              List.append containers' (List.append used_containers rects)
            )
        ]
      in 
    
      (* пытаемся впихнуть наибольший прямоугольник в наименьшую пустую область *)
      try 
        let (placed', empty') = putToMinimalContainer r placed empty []  
        in tryLayout ~type_rects rects' placed' (List.sort begin fun c1 c2 -> 
          let s1 = c1.w*c1.h 
          and s2 = c2.w*c2.h
          in 
          if s1 = s2 
          then 0
          else if s1 > s2 
          then 1
          else -1  
        end empty') unfit
      with [Not_found -> tryLayout ~type_rects rects' placed empty [r :: unfit]]
    ]
  ];


(* размещаем на одной странице, постепенно увеличивая ее размер *)
value rec layout_page ~type_rects ~sqr rects w h = 
  let mainrect = { x = 0; y = 0; w; h } in
  let (placed, rest) = tryLayout ~type_rects rects [] [mainrect] [] in 
  match rest with 
  [ [] -> (w, h, placed, rest) (* разместили все *)
  | _  -> 
      let (w', h') = 
        match sqr with
        [ True -> (w*2, h*2)
        | _ -> 
          if w > h 
          then (w, (h*2))
          else ((w*2), h)
        ]
      in 
      if w' > !max_size 
      then (* не в местили в максимальный размер. возвращаем страницу *)
        (!max_size, !max_size, placed, rest)
      else
        layout_page ~type_rects ~sqr rects w' h'
  ];


(* размещаем на нескольких страницах *)
value rec layout_multipage ~type_rects ~sqr rects pages = 
  let (w, h, placed, rest) = 
    layout_page ~type_rects ~sqr
      (List.sort 
        begin fun (_,i1)  (_,i2) -> 
          let (w1,h1) = Images.size i1
          and (w2,h2) = Images.size i2 in
          let s1 = w1*h1 and s2 = w2*h2 in
          if s1 = s2 then 0
          else if s1 > s2 then -1
          else 1
      end rects
    ) 16 16 
  in 
  match rest with 
  [ [] -> [ (w,h,placed) :: pages]
  | _  -> layout_multipage ~type_rects ~sqr rest [(w,h,placed) :: pages]
  ];


(* 
 возвращает список страниц. каждая страница не больше 2048x2048
*)
value layout ?(type_rects=0) ?(sqr=False) rects =
  (
    Random.self_init ();
    layout_multipage ~type_rects ~sqr rects [];
  );
