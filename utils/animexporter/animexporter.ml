module PNG = Png;
module BITMAP = Bitmap;
module GENIMAGE = Genimage;

value (///) = Filename.concat;

(* FIXME: make it configurable *)
value dataDir = ref "/Volumes/newdata/data";
value img_dir = ref "/Volumes/newdata/img";
value outputDir = ref "output";

value file_frames () = !dataDir /// "frames1L.swf";
value (!!) l = Lazy.force l; 

value _libsettings = 
  lazy (
    match Json_io.load_json (!dataDir /// "libsettings.json") with
    [ Json_type.Object lst -> 
      fun key ->
        match List.assoc key lst with
        [ Json_type.String s -> s
        | _ -> failwith (Printf.sprintf "bad setting: %s" key)
        ]
    | _ -> assert False
    ]
  );

value libsettings param = (Lazy.force _libsettings) param;


value info_obj = lazy (JSObjAnim.init_obj_info (!dataDir /// (libsettings  "info")));
value animations = lazy (JSObjAnim.init_animations (!dataDir /// (libsettings  "animations")));
value frames_dir = lazy (JSObjAnim.init_frames_dir (!dataDir /// "frames_dir.json"));

(*
type new_frame_desc_item = {
  texId:int;
  recId:int;
  nxi:int;
  nyi:int;
  nflip:bool;
  nalpha:int;
};

type new_frame_desc = {
 nw:int;
 nh:int;
 nx:int;
 ny:int;
 nitems: list new_frame_desc_item;
};
*)

type frame_desc_item = {
 libId:int;
 pngId:int;
 xi:int;
 yi:int;
 flip:bool;
 alpha:int;
 urlId:int;
};

type frame_desc = {
 w:int;
 h:int;
 x:int;
 y:int;
 icon_x: int;
 icon_y: int;
 items: list frame_desc_item;
};


value read_boolean input =
  let i = BatIO.read_byte input in
  if i <> 0
  then True
  else False;

value read_frames () =
  let input = BatFile.open_in (file_frames()) in
  let rec loop index res =
     try
      let w = BatIO.read_i16 input in
      let h = BatIO.read_i16 input in
      let x = BatIO.read_i16 input in
      let y = BatIO.read_i16 input in
      let icon_x = BatIO.read_i16 input in
      let icon_y = BatIO.read_i16 input in
(*       let _ = print_endline (Printf.sprintf "fields: %d, %d, %d, %d" field1 field2 field3 field4) in *)
      let frame = {w;h;x;y;icon_x;icon_y;items=[]} in
      let count = BatIO.read_byte input in
(*       let _ = print_endline ("count: " ^ (string_of_int count)) in *)
      let rec loop1 i frame =
          if i <= count
          then
(*             let _ = print_endline ("i: " ^ (string_of_int i)) in *)
            let libId = BatIO.read_byte input in
            let pngId = BatIO.read_i32 input in
            let xi = BatIO.read_i16 input in
            let yi = BatIO.read_i16 input in
            let flags = BatIO.read_byte input in
            let flip = if flags <> 0 then True else False in
            let alpha = if (flags land 2) = 2 then BatIO.read_byte input else 0 in
            let urlId = BatIO.read_i32 input in
(*             let _ = print_endline (Printf.sprintf "ifields: %d, %d, %d, %d, %d, %d" ifield1 ifield2 ifield3 ifield4 ifield6 ifield7) in  *)
            let item = {libId;pngId;xi;yi;flip;alpha;urlId} in
            loop1 (i+1) {(frame) with items = [item::frame.items]}
          else frame
      in
      let frame = loop1 1 frame in
      (
        loop (index+1) (Array.append res [| frame |]);
      )
     with [BatInnerIO.No_more_input -> res]
  in
  let res = loop 0 [||] in
  let _ = print_endline (Printf.sprintf "length res: %d" (Array.length res)) in
  res;

value (=|=) k v = (("",k),v);
value (=.=) k v = k =|= string_of_float v;
value (=*=) k v = k =|= string_of_int v;

(*
value write_animations animations dir = 
  let out = open_out (dir /// "animations.xml") in
  let xml = Xmlm.make_output (`Channel out) in
  (
    Xmlm.output xml (`Dtd None);
    Xmlm.output xml (`El_start (("","Animations"),[]));
    List.iter begin fun (objname,animation) ->
    (
      Xmlm.output xml (`El_start (("","Object"),[ "name" =|= objname ]));
      List.iter begin fun (anim_name,frames) ->
      (
        Xmlm.output xml (`El_start (("","Animation"),[ "name" =|= anim_name ]));
        Array.iter begin fun frame ->
        (
          Xmlm.output xml (`El_start (("","Frame"),[ "id" =*= frame ]));
          Xmlm.output xml `El_end
        )
        end frames;
        Xmlm.output xml `El_end;
      )
      end animation;
      Xmlm.output xml `El_end;
    )
    end animations;
    Xmlm.output xml `El_end;
    close_out out;
  );
*)

(*
value write_animations animations dir = 
  let out = BatFile.open_out (dir /// "animations.dat") in
  (
    List.iter begin fun (objname,animation) ->
    (
      BatIO.write_string out objname;
      BatIO.write_ui16 out (List.length animation);
      List.iter begin fun (anim_name,frames) ->
      (
        BatIO.write_string out anim_name;
        BatIO.write_ui16 out (Array.length frames);
        Array.iter (fun frame -> BatIO.write_i32 out frame) frames;
      )
      end animation;
    )
    end animations;
    BatIO.close_out out;
  );

value write_frames_and_animations new_obj dir =
  let file_out = BatFile.open_out (dir /// "frames.dat") in
  let (_,animations) = 
    Hashtbl.fold begin fun key anims (index,animations) ->
      let _ = print_endline (Printf.sprintf "write_frames_and_anim_json obj: %s" key) in
      let (i,animation) =
        List.fold_left begin fun (i,animation) (animn,frames) ->
          let _ = print_endline (Printf.sprintf "write_frames_and_anim_json animn: %s" animn) in
          let (cnt,f) =
            List.fold_left begin fun (cnt,f) (index,frame) ->
            (
              BatIO.write_i16 file_out frame.nw;
              BatIO.write_i16 file_out frame.nh;
              BatIO.write_i16 file_out frame.nx;
              BatIO.write_i16 file_out frame.ny;
              BatIO.write_byte file_out (List.length frame.nitems);
              List.iter begin fun item ->
              (
                BatIO.write_byte file_out item.texId;
                BatIO.write_i32 file_out item.recId;
                BatIO.write_i16 file_out item.nxi;
                BatIO.write_i16 file_out item.nyi;
                BatIO.write_byte file_out (if item.nflip then 1 else 0);
                BatIO.write_i32 file_out item.nalpha;
              )
              end frame.nitems;
              (cnt+1,[cnt::f])
            )
            end (i,[]) frames
          in
          (cnt,[(animn,(Array.of_list f))::animation])
        end (index,[]) anims
      in
      (i,[(key,animation)::animations])
  end new_obj (0,[])
  in
  write_animations animations dir;


value object_items : Hashtbl.t string (list (string*string*int*frame_desc_item*Images.t))= Hashtbl.create 0;

value object_items_create obj frames_desc =
  let anims = List.assoc obj (!!animations) in
  let () = Hashtbl.add object_items obj [] in
  (
    List.iter begin fun (animn,frames) ->
      let _ = print_endline (Printf.sprintf "anim_name: %s" animn) in
      Array.iter begin fun index_frame ->
        let frame_desc = frames_desc.(index_frame) in
        BatList.iteri begin fun index_item item ->
          let _ = print_endline (Printf.sprintf "item libId: %d, pngId %d, urlId: %d" item.libId item.pngId item.urlId) in
          let png_path = !!frames_dir.JSObjAnim.paths.(item.urlId) in
          let _ = print_endline (Printf.sprintf "png_path: %s" png_path) in
          let img = Images.load (!img_dir /// png_path) [] in
          try
            let items = Hashtbl.find object_items obj in
            Hashtbl.replace object_items obj [(obj,animn,index_frame,item,img)::items]
          with [Not_found -> Hashtbl.add object_items obj [(obj,animn,index_frame,item,img)] ]
        end frame_desc.items
      end frames
    end anims;
    Hashtbl.find object_items obj;
  );
*)

(* Возвращает картинки которые влезли в этот w h  *)
(*
value hold_in_size size imgs = 
  let sx = ref 0
  and sy = ref 0
  and mh = ref 0
  MList.span begin fun (_,_,_,_,img) ->
    let (iw,ih) = Images.size img in
    if iw > w || ih > h
    then False
    else 
      let (nsx,nsy,nmh) = if !sx + iw >= w then (0,!sy+!mh,0) else (sx,sy,max ih !mh) in
      if nsy + ih >= h
      then False
      else 
      (
        sx.val := nsx;
        sy.val := nsy;
        mh.val := nmh;
        True
      );
  end imgs;
*)


value hold_in_size (w,h) imgs = 
(*   let () = Printf.eprintf "hold to [%d:%d]\n" w h in *)
  let rec loop sx sy mh input =
    match input with
    [ [] -> ([],[])
    | [ (p1,img) :: tl ] -> 
        let (iw,ih) = Images.size img in
(*         let () = Printf.eprintf "hold to [%d:%d - %d [%d:%d]]\n" sx sy mh iw ih in *)
        if iw > w || ih > h
        then ([],input)
        else 
          let (sx,sy,mh) = if sx + iw >= w then (0,sy + mh,ih) else (sx,sy,max ih mh) in
          if sy + ih >= h
          then ([],input )
          else 
            let (holded,notholded) = loop (sx + iw) sy mh tl in
            ( [ (p1,(sx,sy,img)) :: holded ] , notholded )
    ]
  in
  loop 0 0 0 imgs;

value rec blit_by_textures imgs = 
(*   let () = Printf.eprintf "blit %d images\n" (List.length imgs) in *)
  try
    let res = 
      BatList.find_map begin fun size ->
        let (holded,notholded) = hold_in_size size imgs in
        match notholded with
        [ [] -> Some (size,holded)
        | _ -> None
        ]
      end [(64,64);(128,128);(256,256);(512,512)]
    in
    [ res ]
  with [ Not_found ->
    let maxsize = (1024,1024) in
    let (holded,notholded) = hold_in_size maxsize imgs in
    let hd = 
      match holded with
      [ [] -> failwith "Can't hold it in max texture"
      | _ -> (maxsize,holded)
      ]
    in
    let tl = 
      match notholded with
      [ [] -> []
      | _ -> blit_by_textures notholded
      ]
    in
    [ hd :: tl ]
  ];

 

(*
value get_size imgs =
  let (w,h) =
    try
      List.find begin fun (w,h) ->
        let _ = print_endline (Printf.sprintf "w: %d h: %d" w h) in
        try
          let (_,_,_,cnt) =
            List.fold_left begin fun (sx,sy,mh,cnt) (_,_,_,_,img) ->
              let (iw,ih) = Images.size img in
        (*       let _ = print_endline (Printf.sprintf "obj: %s, sx: %d, sy:%d, iw:%d, ih:%d, mh:%d" obj sx sy iw ih mh) in *)
              let (nsx,nsy) = if sx + iw >= w then (0,sy+mh) else (sx,sy) in
              if nsy + ih >= h
              then
                if iw > w || ih > h
                then raise Images.Out_of_image
                else
                  (iw,0,ih,cnt+1)
              else
                if iw > w || ih > h
                then raise Images.Out_of_image
                else
                  let mh = if ih > mh then ih else mh in
                  (nsx+iw,nsy,mh,cnt)
            end (0,0,0,1) imgs
          in
          cnt = 1
        with [ Images.Out_of_image -> False ]
      end [(64,64);(128,128);(256,256);(512,512);(1024,1024)]
    with [Not_found -> failwith ("many textures not implemented") ]
  in
  (w,h);
*)

(*
value create_texture obj imgs oframes =
  let new_obj : Hashtbl.t string (list (string*(list (int*new_frame_desc)))) = Hashtbl.create 0 in
  let add_in_new_obj (objn,animn,indexf,old_item,texId,recId) =
    let item = {texId;recId;nxi=old_item.xi;nyi=old_item.yi;nflip=old_item.flip;nalpha=old_item.alpha} in
    try
      let anims = Hashtbl.find new_obj objn in
      try
        let frames = List.assoc animn anims in
        try
          let fd = List.assoc indexf frames in
          let nfd = {(fd) with nitems = [item::fd.nitems]} in
          let nframes = [(indexf,nfd)::List.remove_assoc indexf frames]in
          Hashtbl.replace new_obj objn [(animn,nframes)::(List.remove_assoc animn anims)]
        with
        [ Not_found ->
          let oldf = oframes.(indexf) in
          let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
          let nf = [(indexf,nfd)::frames] in
          Hashtbl.replace new_obj objn [(animn,nf)::(List.remove_assoc animn anims)]
        ]
      with
      [ Not_found ->
        let oldf = oframes.(indexf) in
        let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
        Hashtbl.replace new_obj objn [(animn,[(indexf,nfd)])::anims]
      ]
    with
    [ Not_found ->
      let oldf = oframes.(indexf) in
      let nfd = {nw=oldf.w;nh=oldf.h;nx=oldf.x;ny=oldf.y;nitems=[item]} in
      Hashtbl.add new_obj objn [(animn,[(indexf,nfd)])]
    ]
  in
  let dir = !outputDir /// obj in
  let () =
    if not (Sys.file_exists dir)
    then
      Unix.mkdir dir 0o755
    else ()
  in
  let imgs =
    List.sort (fun (_,_,_,_,img1) (_,_,_,_,img2) ->
      let (_,ih1) = Images.size img1 in
      let (_,ih2) = Images.size img2 in
      compare ih1 ih2
    ) imgs
  in
  let fname cnt ext = (string_of_int cnt) ^ "." ^ ext in
  let texInfo = BatFile.open_out (dir /// "texInfo.dat") in
  (
    let textures = blit_by_textures imgs in
    let () = BatIO.write_ui16 texInfo (List.length textures) in
    BatList.iteri begin fun cnt ((w,h),imgs) ->
      let () = Printf.eprintf "write [%d:%d]\n" w h in
      let () = BatIO.write_string texInfo ((string_of_int cnt) ^ ".png") in
      let () = BatIO.write_ui16 texInfo (List.length imgs) in
      let rgb = Rgba32.make w h  {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
      let new_img = Images.Rgba32 rgb in
      (
        BatList.iteri begin fun i (objn,animn,frame_index,old_item,(sx,sy,img)) ->
        (
          let (iw,ih) = Images.size img in
          (
            let () = Printf.eprintf "blit img to [%d:%d:%d:%d]..." sx sy iw ih in
            Images.blit img 0 0 new_img sx sy iw ih;
            BatIO.write_ui16 texInfo sx;
            BatIO.write_ui16 texInfo sy;
            BatIO.write_ui16 texInfo iw;
            BatIO.write_ui16 texInfo ih;
          );
          add_in_new_obj (objn,animn,frame_index,old_item,cnt,i);
        )
        end imgs;
        Images.save (dir /// (fname cnt "png")) (Some Images.Png) [] new_img;
      )
    end textures;
    BatIO.close_out texInfo;
    write_frames_and_animations new_obj dir;
  );
  *)

  (*
  let out = open_out (dir /// "1.xml") in
  let xml = Xmlm.make_output (`Channel out) in
  let () = Xmlm.output xml (`Dtd None) in
  let () = Xmlm.output xml (`El_start (("","Texture"),[ "imagPath" =|= "1.png" ])) in
  let (_,_,_,new_img,cnt,_,xml,out) =
    List.fold_left begin fun (sx,sy,mh,new_img,cnt,i_rec,xml,out) (objn,animn,frame_index,old_item,img) ->
      let (iw,ih) = Images.size img in
(*       let _ = print_endline (Printf.sprintf "obj: %s, sx: %d, sy:%d, iw:%d, ih:%d, mh:%d" obj sx sy iw ih mh) in *)
      let (nsx,nsy) = if sx + iw >= w then (0,sy+mh) else (sx,sy) in
      if nsy + ih >= h
      then
        let _ = Images.save (dir /// (fname cnt "png")) (Some Images.Png) [] new_img in
        let () = Xmlm.output xml `El_end in
        let () = close_out out in
        let out = open_out (dir /// (fname cnt "xml")) in
        let xml = Xmlm.make_output (`Channel out) in
        let () = Xmlm.output xml (`Dtd None) in
        let () = Xmlm.output xml (`El_start (("","Texture"),[ "imagPath" =|= ((string_of_int cnt) ^".png") ])) in
        let rgb = Rgba32.make w h  {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
        let new_img = (Images.Rgba32 rgb) in
        let _ = Images.blit img 0 0 new_img 0 0 iw ih in
        let () = Xmlm.output xml (`El_start (("","SubTexture"),["x" =|= "0."; "y" =|= "0."; "height" =*= ih; "width" =*= iw])) in
        let () = Xmlm.output xml `El_end in
        let () = add_in_new_obj (objn,animn,frame_index,old_item,cnt,i_rec) in
        (iw,0,ih,new_img,(cnt+1),i_rec+1,xml,out)
      else
(*         let _ = print_endline (Printf.sprintf "obj: %s,nsx: %d, nsy:%d" obj nsx nsy) in *)
        let _ = Images.blit img 0 0 new_img nsx nsy iw ih in
        let () = Xmlm.output xml (`El_start (("","SubTexture"),[ "x" =*= nsx; "y" =*= nsy; "height" =*= ih; "width" =*= iw ])) in
        let () = Xmlm.output xml `El_end in
        let () = add_in_new_obj (objn,animn,frame_index,old_item,cnt,i_rec) in
        let mh = if ih > mh then ih else mh in
        (nsx+iw,nsy,mh,new_img,cnt,i_rec+1,xml,out)
    end (0,0,0,new_img,1,0,xml,out) imgs
  in
  (
    let () = Xmlm.output xml `El_end in
    let () = close_out out in
    Images.save (dir /// (fname cnt "png")) (Some Images.Png) [] new_img;
    write_frames_and_animations new_obj dir;
  );
*)

value get_objects_for_lib lib =
   List.filter begin fun (oname,info) ->
     match info.JSObjAnim.lib with
     [ Some l when lib = l-> True
     | _ -> False
     ]
   end !!info_obj;

value make_frames framesMap frames libobjects = 
  let framesIds = HSet.create 0 in
  (
    List.iter begin fun (objname,animname) ->
      let frms = List.assoc animname (List.assoc objname !!animations) in
      Array.iter (fun i -> HSet.add framesIds i) frms
    end libobjects;
    (* Сформировали массив фреймов нах *)
    let framesIds = HSet.to_list framesIds in
    BatList.mapi begin fun i fid ->
      let frame = frames.(fid) in
      (
        Hashtbl.add framesMap fid i;
        frame
      )
    end framesIds 
  );

value write_textures imagesMap frames outdir = 
  let images = 
    let imageUrls = HSet.create 0 in
    (
      List.iter (fun frame -> List.iter (fun item -> HSet.add imageUrls item.urlId) frame.items) frames;
      let imgs = 
        HSet.fold begin fun urlId res ->
          let png_path = !!frames_dir.JSObjAnim.paths.(urlId) in
          let img = Images.load (!img_dir /// png_path) [] in
          [ (urlId,img) :: res ]
        end imageUrls []
      in
      List.sort (fun (_,img1) (_,img2) ->
        let (_,ih1) = Images.size img1 in
        let (_,ih2) = Images.size img2 in
        compare ih1 ih2
      ) imgs
    )
  in
  let texInfo = BatFile.open_out (outdir /// "texInfo.dat") in
  (
    let textures = blit_by_textures images in
    let () = BatIO.write_ui16 texInfo (List.length textures) in
    BatList.iteri begin fun cnt ((w,h),imgs) ->
(*       let () = Printf.eprintf "texture [%d:%d]\n%!" w h in *)
      let () = BatIO.write_string texInfo ((string_of_int cnt) ^ ".png") in
      let () = BatIO.write_ui16 texInfo (List.length imgs) in
      let rgb = Rgba32.make w h {Color.color={Color.r=0;g=0;b=0}; alpha=0;} in
      let new_img = Images.Rgba32 rgb in
      (
        BatList.iteri begin fun i (urlId,(sx,sy,img)) ->
        (
          let (iw,ih) = Images.size img in
          (
            try
              Images.blit img 0 0 new_img sx sy iw ih;
            with [ Invalid_argument _ -> 
              (
                match img with
                [ Images.Index8 _ -> prerr_endline "index8"
                | Images.Rgb24 _ -> prerr_endline "rgb24"
                | Images.Rgba32 _ -> prerr_endline "rgba32"
                | _ -> prerr_endline "other"
                ];
                raise Exit;
              )
            ];
            BatIO.write_ui16 texInfo sx;
            BatIO.write_ui16 texInfo sy;
            BatIO.write_ui16 texInfo iw;
            BatIO.write_ui16 texInfo ih;
          );
          Hashtbl.add imagesMap urlId (cnt,i);
        )
        end imgs;
        Images.save (outdir /// ((string_of_int cnt) ^ ".png")) (Some Images.Png) [] new_img;
      )
    end textures;
    BatIO.close_out texInfo;
  );


value write_frames imagesMap frames outdir = 
  let out = BatFile.open_out (outdir /// "frames.dat") in
  (
    let () = BatIO.write_i32 out (List.length frames) in
    List.iter begin fun frame ->
      (
        BatIO.write_i16 out frame.w;
        BatIO.write_i16 out frame.h;
        BatIO.write_i16 out frame.x;
        BatIO.write_i16 out frame.y;
        BatIO.write_byte out (List.length frame.items);
        List.iter begin fun item ->
          (
            let (texId,recId) = Hashtbl.find imagesMap item.urlId in
            (
              BatIO.write_byte out texId;
              BatIO.write_i32 out recId;
            );
            BatIO.write_i16 out item.xi;
            BatIO.write_i16 out item.yi;
            BatIO.write_byte out (if item.flip then 1 else 0);
            BatIO.write_i32 out item.alpha;
          )
        end frame.items
      )
    end frames;
    BatIO.close_out out;
  );

value write_lib libname libobjects frames = 
  let () = Printf.eprintf "make lib: %s\n%!" libname in
  let framesMap = Hashtbl.create 0 in
  let frames = make_frames framesMap frames libobjects in
  (* анимации составить с учетом новых фреймов *)
  let animations = 
    List.fold_left begin fun res (objname,animname) ->
      let frms = List.assoc animname (List.assoc objname !!animations) in
      let frms = Array.map (fun i -> Hashtbl.find framesMap i) frms in
      let anims = 
        try
          List.assoc objname res
        with [ Not_found -> [ ] ]
      in
      let res = List.remove_assoc objname res in
      [ (objname,[(animname,frms) :: anims]) :: res]
    end [] libobjects
  in
  let outdir = !outputDir /// libname in
  (* теперь зачитать картинки *)
  let () = Unix.mkdir outdir 0o755  in
  let imagesMap = Hashtbl.create 0 in
  let () = write_textures imagesMap frames outdir in
  let () = write_frames imagesMap frames outdir in
  let anim_out = BatFile.open_out (outdir /// "animations.dat") in
  (
    List.iter begin fun (objname,animation) ->
    (
      BatIO.write_string anim_out objname;
      BatIO.write_ui16 anim_out (List.length animation);
      List.iter begin fun (anim_name,frames) ->
      (
        BatIO.write_string anim_out anim_name;
        BatIO.write_ui16 anim_out (Array.length frames);
        Array.iter (fun frame -> BatIO.write_i32 anim_out frame) frames;
      )
      end animation;
    )
    end animations;
    BatIO.close_out anim_out;
  );

value group_by_objects (oname,info) res =
  (* Взять все анимации для объекта и это будет отдельная либа *)
  try
    let anims = List.assoc oname !!animations in
    let items = List.map (fun (animname,_) -> (oname,animname)) anims in
    Hashtbl.add res oname items;
    Some oname
  with [ Not_found -> None ];

value () =
(
  let force = ref False in
  (
    Arg.parse 
      [ 
        ("-f", Arg.Set force, "force delete exists output"); 
        ("-data",Arg.Set_string dataDir,"data dir"); 
        ("-img",Arg.Set_string img_dir, "img dir"); 
        ("-o",Arg.Set_string outputDir,"output dir");
     ] (fun _ -> ()) "";
    match Sys.file_exists !outputDir with
    [ True -> 
      match !force with
      [ True -> 
          match Sys.command (Printf.sprintf "rm -rf %s" !outputDir) with
          [ 0 -> Unix.mkdir !outputDir 0o755
          | n -> exit n
          ]
      | False -> (Printf.eprintf "Directory '%s' alredy exists\n" !outputDir; exit 1)
      ]
    | False -> Unix.mkdir !outputDir 0o755
    ];
  );
  (* convert info objects to xml *)
  let out = open_out (!outputDir /// "info_objects.xml") in
  let xml = Xmlm.make_output (`Channel out) in
  (
    let () = Xmlm.output xml (`Dtd None) in
    let () = Xmlm.output xml (`El_start (("","Objects"),[])) in
    let group_libs = group_by_objects in
    let libs = Hashtbl.create 1 in
    (
      List.iter begin fun ((oname,info) as infobj) ->
        let () = print_endline (Printf.sprintf "oname: %s" oname) in
        match group_libs infobj libs with
        [ None -> ()
        | Some lib ->
          let attribs = [ "sizex" =*= info.JSObjAnim.sizex; "sizey" =*= info.JSObjAnim.sizey ; "lib" =|= lib ] in
          let () = Xmlm.output xml (`El_start (("","Object"),attribs)) in
          Xmlm.output xml `El_end
        ]
     end !!info_obj;
     (* Начинаем хуячить нахуй *)
     let frames = read_frames () in
     Hashtbl.iter begin fun libname elements -> 
       try
         write_lib libname elements frames
       with [ Exit -> Printf.eprintf "failed to make lib: %s\n%!" libname ]
      end libs
    );
    Xmlm.output xml `El_end;
    close_out out;
  );
);
