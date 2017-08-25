open Stream;

type t = UTF8.t;

(* *)
value  charStorage = 
[
	(65165, [65165; 65166; 65165; 65166]);	
	(65167, [65167; 65168; 65169; 65170]);	
	(64342, [64342; 64343; 64344; 64345]);	
	(65173, [65173; 65174; 65175; 65176]);	
	(65177, [65177; 65178; 65179; 65180]);	
	(65181, [65181; 65182; 65183; 65184]);	
	(64378, [64378; 64379; 64380; 64381]);	
	(65185, [65185; 65186; 65187; 65188]);	
	(65189, [65189; 65190; 65191; 65192]);	
	(65193, [65193; 65194; 65193; 65194]);	
	(65195, [65195; 65196; 65195; 65196]);	
	(65197, [65197; 65198; 65197; 65198]);	
	(65199, [65199; 65200; 65199; 65200]);	
	(64394, [64394; 64395; 64394; 64395]);	
	(65201, [65201; 65202; 65203; 65204]);	
	(65205, [65205; 65206; 65207; 65208]);	
	(65209, [65209; 65210; 65211; 65212]);	
	(65213, [65213; 65214; 65215; 65216]);	
	(65217, [65217; 65218; 65219; 65220]);	
	(65221, [65221; 65222; 65223; 65224]);	
	(65225, [65225; 65226; 65227; 65228]);	
	(65229, [65229; 65230; 65231; 65232]);	
	(65233, [65233; 65234; 65235; 65236]);	
	(65237, [65237; 65238; 65239; 65240]);	
	(64398, [64398; 64399; 64400; 64401]);	
	(64402, [64402; 64403; 64404; 64405]);	
	(65245, [65245; 65246; 65247; 65248]);	
	(65249, [65249; 65250; 65251; 65252]);	
	(65253, [65253; 65254; 65255; 65256]);	
	(65261, [65261; 65262; 65261; 65262]);	
	(65257, [65257; 65258; 65259; 65260]);
  	(64508, [64508; 64509; 64510; 64511]);
  	(65153, [65153; 65154; 65153; 65154]);

	(1575, [1575; 65166; 65165; 65166]);
	(1576, [1576; 65168; 65169; 65170]);
	(1662, [1662; 64343; 64344; 64345]);
	(1578, [1578; 65174; 65175; 65176]);
	(1579, [1579; 65178; 65179; 65180]);
	(1580, [1580; 65182; 65183; 65184]);
	(1670, [1670; 64379; 64380; 64381]);
	(1581, [1581; 65186; 65187; 65188]);
	(1582, [1582; 65190; 65191; 65192]);
	(1583, [1583; 65194; 65193; 65194]);
	(1584, [1584; 65196; 65195; 65196]);
	(1585, [1585; 65198; 65197; 65198]);
	(1586, [1586; 65200; 65199; 65200]);
	(1688, [1688; 64395; 64394; 64395]);
	(1587, [1587; 65202; 65203; 65204]);
	(1588, [1588; 65206; 65207; 65208]);
	(1589, [1589; 65210; 65211; 65212]);
	(1590, [1590; 65214; 65215; 65216]);
	(1591, [1591; 65218; 65219; 65220]);
	(1592, [1592; 65222; 65223; 65224]);
	(1593, [1593; 65226; 65227; 65228]);
	(1594, [1594; 65230; 65231; 65232]);
	(1601, [1601; 65234; 65235; 65236]);
	(1602, [1602; 65238; 65239; 65240]);
	(1705, [1705; 64399; 64400; 64401]);
	(1711, [1711; 64403; 64404; 64405]);
	(1604, [1604; 65246; 65247; 65248]);
	(1605, [1605; 65250; 65251; 65252]);
	(1606, [1606; 65254; 65255; 65256]);
	(1608, [1608; 65262; 65261; 65262]);
	(1607, [1607; 65258; 65259; 65260]);
	(1740, [1740; 64509; 64510; 64511]);
	(1570, [1570; 65154; 65153; 65154]);


 	(65265, [65265; 65266; 65267; 65268]);
    (65171, [65171; 65172; 65171; 65172]);
    (65263, [65263; 65264; 65263; 65264]);
	(65157, [65157; 65158; 65157; 65158]);
	(65155, [65155; 65156; 65155; 65156]);
	(65159, [65159; 65160; 65159; 65160]);
	(65241, [65241; 65242; 65243; 65244]);
	(65161, [65161; 65162; 65163; 65164]);

    (1610, [65265; 65266; 65267; 65268]);
    (1577, [65171; 65172; 65171; 65172]);
    (1609, [65263; 65264; 65263; 65264]);
	(1572, [65157; 65158; 65157; 65158]);
	(1571, [65155; 65156; 65155; 65156]);
	(1573, [65159; 65160; 65159; 65160]);
	(1603, [65241; 65242; 65243; 65244]);
	(1574, [65161; 65162; 65163; 65164]);

];



(* *)
value boolStorage = 
[
	(65165, [0; 1]);
 	(65167, [1; 1]);
 	(64342, [1; 1]);
 	(65173, [1; 1]);
 	(65177, [1; 1]);
 	(65181, [1; 1]);
 	(64378, [1; 1]);
 	(65185, [1; 1]);
 	(65189, [1; 1]);
 	(65193, [0; 1]);
 	(65195, [0; 1]);
 	(65197, [0; 1]);
 	(65199, [0; 1]);
 	(64394, [0; 1]);
 	(65201, [1; 1]);
 	(65205, [1; 1]);
 	(65209, [1; 1]);
 	(65213, [1; 1]);
 	(65217, [1; 1]);
 	(65221, [1; 1]);
 	(65225, [1; 1]);
 	(65229, [1; 1]);
 	(65233, [1; 1]);
 	(65237, [1; 1]);
 	(64398, [1; 1]);
 	(64402, [1; 1]);
 	(65245, [1; 1]);
 	(65249, [1; 1]);
 	(65253, [1; 1]);
 	(65261, [0; 1]);
 	(65257, [1; 1]);
 	(64508, [1; 1]);
 	(65153, [0; 1]);
 
	(1575, [0; 1]);
 	(1576, [1; 1]);
 	(1662, [1; 1]);
 	(1578, [1; 1]);
 	(1579, [1; 1]);
 	(1580, [1; 1]);
 	(1670, [1; 1]);
 	(1581, [1; 1]);
 	(1582, [1; 1]);
 	(1583, [0; 1]);
 	(1584, [0; 1]);
 	(1585, [0; 1]);
 	(1586, [0; 1]);
 	(1688, [0; 1]);
 	(1587, [1; 1]);
 	(1588, [1; 1]);
 	(1589, [1; 1]);
 	(1590, [1; 1]);
 	(1591, [1; 1]);
 	(1592, [1; 1]);
 	(1593, [1; 1]);
 	(1594, [1; 1]);
 	(1601, [1; 1]);
 	(1602, [1; 1]);
 	(1705, [1; 1]);
 	(1711, [1; 1]);
 	(1604, [1; 1]);
 	(1605, [1; 1]);
 	(1606, [1; 1]);
 	(1608, [0; 1]);
 	(1607, [1; 1]);
 	(1740, [1; 1]);
 	(1570, [0; 1]);
 

	(65265, [1; 1]);
 	(65171, [0; 1]);
 	(65263, [0; 1]);
 	(65157, [0; 1]);
 	(65155, [0; 1]);
 	(65159, [0; 1]);
 	(65241, [1; 1]);
 	(65161, [1; 1]);
 
	(1610, [1; 1]);
 	(1577, [0; 1]);
 	(1609, [0; 1]);
 	(1572, [0; 1]);
 	(1571, [0; 1]);
 	(1573, [0; 1]);
 	(1603, [1; 1]);
 	(1574, [1; 1]);
];






  



(* В зависимости от того, где стоит буква (в начале, в конце или посередине) используется ее разное начертание. Возвращаем UTF8 представление  *)
value convert_char prev curr next = 
  let pr = 
    try 
      List.nth (List.assoc (UChar.int_of_uchar prev) boolStorage) 0
    with [ Not_found -> 0 ]

  and ne =
    try 
      List.nth (List.assoc (UChar.int_of_uchar next) boolStorage) 1
    with [ Not_found -> 0 ]  
  in 

  try     
    let idx = 2 * ne + pr in
    UChar.uchar_of_int (List.nth (List.assoc (UChar.int_of_uchar curr) charStorage) idx)
  with [ Not_found -> curr ];

(* 
  Не знаю точно, но кажется у некоторых букв есть различные формы написания в зависимости от того, где стоит эта буква  
  Здесь мы выбираем корректный символ.
*)
value remap_char_at_index text index = 
  let curr = UTF8.look text index 
  and prev = if (index = 0) then (UChar.uchar_of_int 0) else (UTF8.look text (UTF8.prev text index))
  and next = if (index = (UTF8.last text)) then (UChar.uchar_of_int 0) else (UTF8.look text (UTF8.next text index)) 
  in convert_char prev curr next;



(* *)
value isFarsi c = 
  let i = UChar.int_of_uchar c 
  in  ((i >= 1536 && i <= 1791) || (i >= 65136 && i <= 65279));


(* Convert a UTF8 Line to Farsi *)
value convert_line input = 
  let len   = (UTF8.length input) in
  let maxi  = len in
  let rec algoiter i listT listF = 
    if i = maxi then 
      (listT, listF) 
    else 
      let prev = if (i = 0) then (UChar.uchar_of_int 0) else (UTF8.get input (i - 1))
      and curr = (UTF8.get input i)
      and next = if (i = maxi - 1) then UChar.uchar_of_int 0 else (UTF8.get input (i + 1)) in
      match isFarsi curr with
      [ True    -> 
          let chT = convert_char prev curr next in 
          let listT = List.rev listT in
          let listF = List.append listF listT in
          let listF = List.append listF [chT]
          in  algoiter (i + 1) [] listF
      | False   -> algoiter (i + 1) (List.append listT [curr]) listF
      ]
  in 
  let (listT, listF) = algoiter 0 [] [] in
  let listT = List.rev listT in
  let listF = List.append listF listT in
  let listF = List.rev listF in 
  let buf = UTF8.Buf.create len in 
  let () = List.iter (fun char -> UTF8.Buf.add_char buf char) listF 
  in UTF8.Buf.contents buf;




(* Convert UTF8 Text to Farsi line by line *)
value convert text = 
  let linesBuf = UTF8.Buf.create (String.length text) in (* String, а не UTF8, так как нам нужно кол-во октетов (байт); а не уничаров *)
  let lineBuf  = UTF8.Buf.create 64 in 
  let newline  = UChar.uchar_of_int 10 in

  let rec line_by_line idx =

    match UTF8.out_of_range text idx with     
    [ True  -> 
        (
          UTF8.Buf.add_string linesBuf (convert_line (UTF8.Buf.contents lineBuf));
          UTF8.Buf.contents linesBuf
        )
    | False -> 
        let uchar = UTF8.look text idx in 
        if (uchar = newline) then 
        (
              UTF8.Buf.add_string linesBuf (convert_line (UTF8.Buf.contents lineBuf));
              UTF8.Buf.add_char linesBuf uchar;
              UTF8.Buf.clear lineBuf;
              line_by_line (UTF8.next text idx)
        )
        else 
        (
            UTF8.Buf.add_char lineBuf uchar;        
            line_by_line (UTF8.next text idx)
        )
    ]

  in line_by_line 0;
    

