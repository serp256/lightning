
value max_size = ref 2048;
type rect = {
  x : int;
  y : int;
  w : int;
  h : int
};



(* 
  пробуем упаковать прямоугольники в заданные пустые прямоугольники.
  возвращаем оставшиеся прямоугольники и страницы
*)
value rec tryLayout rects placed empty unfit = 
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
            let e1 = { x = c.x; y = c.y + rh; w = rw; h = c.h - rh }
            and e2 = { x = c.x + rw; y = c.y; w = c.w - rw; h = c.h }
            in 
            (
              [(info,(c.x,c.y,img)) :: placed], 
              List.append containers' (List.append used_containers [e1; e2])
            )
        ]
      in 
    
      (* пытаемся впихнуть наибольший прямоугольник в наименьшую пустую область *)
      try 
        let (placed', empty') = putToMinimalContainer r placed empty []  
        in tryLayout rects' placed' (List.sort begin fun c1 c2 -> 
          let s1 = c1.w*c1.h 
          and s2 = c2.w*c2.h
          in 
          if s1 = s2 
          then 0
          else if s1 > s2 
          then 1
          else -1  
        end empty') unfit
      with [Not_found -> tryLayout rects' placed empty [r :: unfit]]
    ]
  ];


(* размещаем на одной странице, постепенно увеличивая ее размер *)
value rec layout_page rects w h = 
  let mainrect = { x = 0; y = 0; w; h } in
  let (placed, rest) = tryLayout rects [] [mainrect] [] in 
  match rest with 
  [ [] -> (w, h, placed, rest) (* разместили все *)
  | _  -> 
      let (w', h') = 
        if w > h 
        then (w, (h*2))
        else ((w*2), h)
      in 
      if w' > !max_size 
      then (* не в местили в максимальный размер. возвращаем страницу *)
        (!max_size, !max_size, placed, rest)
      else
        layout_page rects w' h'
  ];


(* размещаем на нескольких страницах *)
value rec layout_multipage rects pages = 
  let (w, h, placed, rest) = 
    layout_page 
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
  | _  -> layout_multipage rest [(w,h,placed) :: pages]
  ];


(* 
 возвращает список страниц. каждая страница не больше 2048x2048
*)
value layout rects = layout_multipage rects [];
