
Gc.set {(Gc.get ()) with Gc.verbose  = (0x001 lor 0x002 lor 0x004 lor 0x010 lor 0x040 lor 0x080)};

value max_anim_len = 40;
value (|>) a b = b a;
(*
value run_thread () = 
  while True do
    Thread.delay 1.;
    debug "I'am thread";
  done;
*)
(* Printexc.record_backtrace True; *)


(* external print_float_array: int -> Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit = "ml_print_float_array"; *)

value fin d = debug "finalize: %s" d#name;

(* Test TLF {{{
let stage width height =
  let () = Printf.printf "stage with %f:%f\n%!" width height in
  let () = BitmapFont.register "Helvetica.fnt" in 
(*   let () = GameCenter.init ~callback:(fun res -> debug "Game center initialized: %s" (string_of_bool res)) () in *)
(*
  let () = 
    (
      let s = LocalStorage.load "test" in
      ( s#set "testkey" "testvalue"; s#save ();)
    )
  in
*)
  object(self)
    inherit Stage.c width height as super;
    value color = 0;

    initializer 
    (
      (*
      let sprite = Sprite.create () in
      let img = Image.load "e_cactus.png" in
      (
        img#setPos (100.,100.);
        sprite#addChild img;
        self#addChild sprite;
        debug "img size: [%f:%f], sprite size: [%f:%f]" img#width img#height sprite#width sprite#height;
      );
      *)
      let line = Quad.create ~color:0xFF0000 500. 1. in
      (
        line#setPos(49.,49.);
        self#addChild line;
      );
      let line = Quad.create ~color:0xFF0000 1. 500. in
      (
        line#setPos(49.,49.);
        self#addChild line;
      );
      let line = Quad.create ~color:0xFF0000 1. 500. in
      (
        line#setPos(121.,49.);
        self#addChild line;
      );
      let tlf = 
        TLF.create ~width:70.
          (TLF.p ~color:0xFFFFFF ~fontSize:30 ~fontFamily:"Helvetica" ~halign:`center 
            [
              `text "pizda"; 
              TLF.img ~valign:`center ~height:10. (Image.load  "chess.png");
              TLF.span ~alpha:0.9 ~fontSize:20 ~color:0xFF0000 [`text "lala" ];
  (*             TLF.img ~valign:`baseLine (Image.load "chess.png"); *)
              TLF.span ~fontSize:12 [`text "бля"; TLF.img ~height:5. ~valign:`lineCenter (Image.load "chess.png")];
              `text "  пизда";
              TLF.img ~valign:`center (Image.load "chess.png");
              `br;
              TLF.span ~color:0x00FF00 [`text "gavno "]; 
              TLF.span ~color:0x0000FF ~fontSize:40 [ `text "ebuche" ]; 
              `text " naxyn"
            ]
          )
      in
      (
        tlf#setPos (50.,50.);
        self#addChild tlf;
      );
      (*
      let xml = 
        "<p color='0xFFFFFF' font-size='30'>pizda<img src='e_cactus.png' valign='baseline'/><span font-size='20' color='0xFF0000'>lala</span><img src='e_cactus.png' valign='center'/><span font-size='40'>бля</span><br/><span color='0x00FF00'>гавно </span><span color='0x0000FF' font-size='40'>ебучее</span> нахуй</p>" in
      let tlf = TLF.parse xml in
      let t = TLF.create tlf in
      (
        t#setY 200.;
        self#addChild t;
      );
      *)

      (*
      let tf = TextField.create ~color:0xFFFFFF ~fontSize:20 ~width:200. ~height:200. "pizda" in
      (
        tf#setY 100.;
        tf#setHAlign `HAlignLeft;
        tf#setVAlign `VAlignTop;
(*         tf#setBorder True; *)
        self#addChild tf;
      )
      *)

    );

  end
in
Lightning.init stage;
}}}*)


value gray_filter = 
  Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout
    [| 0.3086000084877014; 0.6093999743461609; 0.0820000022649765; 0.; 0.;
        0.3086000084877014; 0.6093999743461609; 0.0820000022649765; 0.; 0.;
        0.3086000084877014; 0.6093999743461609; 0.0820000022649765; 0.; 0.;
        0.; 0.; 0.; 1.; 0.
    |];

value onClick obj handler  =
  obj#addEventListener Stage.ev_TOUCH begin fun ev (_,target) _ ->
    match Stage.touches_of_data ev.Ev.data with
    [ Some [ {Touch.phase=Touch.TouchPhaseEnded; _ } :: _ ] -> handler target
    | _ -> ()
    ]
  end |> ignore;



value tlf (stage:Stage.c) = 
(
  BitmapFont.register "MyriadPro-Regular.fnt";
  TLF.default_font_family.val := "Myriad Pro";
  let quad = Quad.create  ~color:0xCC0000 100. 20. in
  (
    quad#setPos 100. 100.;
    stage#addChild quad;
  );
  let ((w,h),text) = 
    TLF.create begin
        TLF.p ~halign:`center ~color:0xfff4c7 ~fontSize:15 
          [ 
            `text "животные";
          ]
    end 
  in
  (
    debug "w:%f,h:%f" w h;
    text#setPos 100. 100.;
    text#setFilters [ Filters.glow ~size:2 0x00FF00 ];
(*     text#setAlpha 0.3; *)
    stage#addChild text;
  );
  (*
  let quad = Quad.create  ~color:0xCC0000 100. 20. in
  (
    quad#setPos 220. 100.;
    stage#addChild quad;
  );
  let (_,text) = 
    TLF.create ~width:100. begin
        TLF.p ~halign:`center ~color:0xfff4c7 ~fontSize:15 
          [ 
            `text "животные";
          ]
    end 
  in
  (
    text#setPos 220. 100.;
    text#setFilters [ Filters.glow 0x00FF00 ];
(*     text#setAlpha 0.3; *)
    stage#addChild text;
  );
  let quad = Quad.create  ~color:0xFF0000 100. 20. in
  (
    quad#setPos 190. 134.;
    stage#addChild quad;
  );
  let tex = (Texture.load "MyriadPro-Regular0.png")#subTexture (Rectangle.create 341. 421. 6. 8.) in
  (
    let g = Image.create tex in
    (
      g#setPos 200. 140.;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 220. 140.5;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 240.5 140.0;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 260.4 140.5;
      stage#addChild g;
    );
  );

  let tree = Image.load "tree.png" in
  (
    tree#setPos 20.5 200.;
    tree#setFilters [ Filters.glow ~size:2 ~strength:2 0xFF0000 ];
    stage#addChild tree;
  );
  let tree = Image.load "tree.png" in
  (
(*     tree#texture#setFilter Texture.FilterLinear; *)
    tree#setPos 150. 200.;
    tree#setFilters [ Filters.glow ~size:2 ~strength:2 0xFF0000 ];
    stage#addChild tree;
  );
  *)
);


value masks (stage:Stage.c) =
(
  let tree = Image.load "tree.png" in
  (
    tree#setMask ~onSelf:True (Rectangle.create 20. 50. 50. 30.);
    tree#setPos 100. 100.;
    stage#addChild tree;
  )
);


value atlas (stage:Stage.c) = 
(

  let texture = Texture.load "tree.png" in
  let atlas = Atlas.create texture in
  (
    atlas#addChild (AtlasNode.create texture (Rectangle.create 10. 30. 100. 100.) ~flipY:True ());
    atlas#addChild (AtlasNode.create texture (Rectangle.create 10. 30. 100. 20.) ~pos:{Point.x=150.;y=50.} ());
    atlas#setPos 100. 100.;
(*     atlas#setFilters [ Filters.glow ~size:2 0xFF0000 ]; *)
    stage#addChild atlas;
  );
);


value disable_filter = 
  Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout
   [| 
     0.4284989; 0.283371; 0.03813; 0.; 0.0622549019607843146;
     0.143499; 0.568371; 0.03813; 0.; 0.0622549019607843146;
     0.143499; 0.28337; 0.32313; 0.; 0.0622549019607843146;
     0.; 0.; 0.; 1.; 0.
   |];


value filters (stage:Stage.c) =
(
  let sprite = Sprite.create () in
  (
    let img = Image.load "tree.png" in
    sprite#addChild img;
    let img = Image.load "e_cactus.png" in
    (
      img#setPos 100. 100.;
      sprite#addChild img;
    );
    sprite#setFilters [ `ColorMatrix disable_filter ];
(*     sprite#setFilters [ Filters.glow 0xFF0000 ]; *)
    sprite#setPos 100. 100.;
    stage#addChild sprite;
  );

    let tree = Image.load "tree.png" in
    (
      tree#setPos 100. 350.;
      tree#setFilters [ `ColorMatrix disable_filter ];
(*       tree#setFilters [ Filters.glow 0xFF0000 ]; *)
      stage#addChild tree;
    );
  (*
  let img = Image.load "tree.png" in
  (
    img#setPos 300. 100.;
    img#setAlpha 0.2;
    stage#addChild img;
  );
  *)
  (*
  BitmapFont.register "Arial.fnt";
  let text = TLF.create (TLF.p ~fontSize:22 [`text "pizda lala"]) in
  (
    text#setName "text";
    text#setFilters [ Filters.glow ~size:2 0x00FF00 ];
    text#setPos 300. 100.;
(*     text#setAlpha 0.2; *)
    stage#addChild text;
  )
  *)
);


value size (stage:Stage.c) = 
  let img = Image.load "tree.png" in
  (
    stage#addChild img;
    onClick img begin fun img ->
      (
        img#setWidth 50.;
        img#setHeight 100.;
      )
    end;
  );


value flip (stage:Stage.c) =
  let img = Image.load "tree.png" in
  let () = debug "max_int: %d, min_int: %d, calc: %d" max_int min_int (if 1 lsl 32 = 0 then 1 else 2) in
(*   let tx = ref (Texture.load "e_cactus.png") in *)
  (
    img#setTexFlipX True;
    onClick img (fun img ->
      match img#filters with
      [ [] -> img#setFilters [ Filters.glow 0xFF0000 ]
      | _ -> img#setFilters []
      ]
    );
    img#setPos 100. 100.;
    stage#addChild img;
  );


value async_load (stage:Stage.c) = 
(
  let lib = LightLib.load "Clips" in
  let sprite = Sprite.create () in
  (
    let loading = LightLib.get_symbol lib "ESkins.LoadClip" in
    (
      loading#setPos 100. 100.;
      sprite#addChild loading;
    );
    Texture.load_async "tree.png" (fun t -> (sprite#clearChildren(); sprite#addChild (Image.create t)));
    stage#addChild sprite;
  );
);

value sound (stage:Stage.c) =
(
  Sound.init ();
  let sound = Sound.load "ra_fertilizer.caf" in
  let sound2 = Sound.load "stoneBoom.caf" in
  let tree = Image.load "tree.png" in
  (
    stage#addChild tree;
    onClick tree begin fun _ ->
      (
        Gc.full_major ();
        let channel = 
          match Random.int 2 with
          [ 0 -> Sound.createChannel sound2
          | 1 -> Sound.createChannel sound
          ]
        in
        channel#play ();
      )
    end
  )
);


value half_pixels (stage:Stage.c) =
(
  (*
  let tree = Image.load "60.png" in
  (
(*     tree#setAlpha 0.5; *)
    (* tree#setColors [| 0xFF0000; 0xFF0000; 0x00FF00; 0x00FF00 |]; *)
(*     tree#setFilters [ Filters.glow 0xFF0000 ]; *)
    tree#setAlpha 0.3;
    tree#setFilters [ `ColorMatrix disable_filter ];
    tree#setPos 100. 10.;
    (*
    let tex = Texture.rendered 100. 100. in
    (
      tex#draw (fun () -> (Render.clear 0 1.; tree#render ~transform:False None));
      let img = Image.create (tex :> Texture.c) in
      stage#addChild img;
    );
    *)
    stage#addChild tree;
  );
  let tree = Image.load "61.png" in
  (
(*     tree#setAlpha 0.5; *)
    (* tree#setColors [| 0xFF0000; 0xFF0000; 0x00FF00; 0x00FF00 |]; *)
(*     tree#setFilters [ Filters.glow 0xFF0000 ]; *)
    tree#setFilters [ `ColorMatrix disable_filter ];
    tree#setAlpha 0.3;
    tree#setPos 100. 300.;
    (*
    let tex = Texture.rendered 100. 100. in
    (
      tex#draw (fun () -> (Render.clear 0 1.; tree#render ~transform:False None));
      let img = Image.create (tex :> Texture.c) in
      stage#addChild img;
    );
    *)
    stage#addChild tree;
  );
  *)
  (*
  let img = Image.load "frame.png" in
  (
    img#setPos 100.5 100.;
    stage#addChild img;
  );
  *)
  let font = Image.load "MyriadPro-Regular0.alpha" in
  (
    font#setColor 0xFFFFFF;
    font#setPos 100. 100.;
    stage#addChild font;
  );
  (*
  let tex = (Texture.load "MyriadPro-Regular0.png")#subTexture (Rectangle.create 341. 421. 6. 8.) in
  (
    let g = Image.create tex in
    (
      g#setPos 200. 140.;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 220. 140.5;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 240.5 140.0;
      stage#addChild g;
    );
    let g = Image.create tex in
    (
      g#setPos 260.4 140.5;
      stage#addChild g;
    );
  );
  *)
);

value external_image (stage:Stage.c) =
(
  Texture.loadExternal 
    "http://votrube.ru/uploads/posts/2012-03/thumbs/1330888418_-(www.votrube.ru)5.jpg"
    ~callback:(fun texture ->
      let image = Image.create texture in
      stage#addChild image
    )
    ~errorCallback:
    (Some 
      (fun code msg -> 
        let (_,text) = TLF.create (TLF.p [`text (Printf.sprintf "loading error: %d, %s" code msg) ]) in
        stage#addChild text
      )
    );
);

(*
value alert (stage:Stage.c) =
(
  let lib = Clip.load "Clips" in
  let loading = Clip.get_symbol lib "ESkins.LoadClip" in
  (
    loading#setPos 100. 100.;
    stage#addChild loading;
  );
  Timers.start 20. (fun () -> Lightning.show_alert "this is test alert" "this message for test alert");
  ();
);*)


value game_center (stage:Stage.c) =
  GameCenter.init ~callback:begin fun res ->
    let text = 
      match res with 
      [ True -> "Game center success"
      | False -> "Game center failed"
      ]
    in
    let (_,text) = TLF.create (TLF.p ~color:0xFFFF00 [ `text text ]) in
    (
      text#setFilters [ Filters.glow ~size:2 0 ];
      stage#addChild text;
    )
  end ();


value test_alpha (stage:Stage.c) = 
  let sprite = Sprite.create () in
  let tree = Image.load "tree.png" in
  (
    tree#setAlpha 0.5;
    tree#setPos 100. 100.;
    sprite#addChild tree;
    sprite#setAlpha 0.2;
    stage#addChild sprite;
  );



(* value sounds = ref []; *)

value sound (stage:Stage.c) =
  let sndfiles = 
    [
      "achievement1"; "an_pig"; "buy"; "deathtree1"; "friend_help"; "new_message"; "sw_segway_steps"; "wn_nanoemitter"; "achievement2"; "an_sheep"; "combo_1"; "combo_6"; "deathtree2"; "ra_fertilizer"; 
      "ra_root"; "take_energy"; "wn_nebulizergas"; "achievement3"; "bl_blastfurnace"; "deathtree3"; "take_food"; "wn_slingshot"; "add_energy"; "bl_hutches"; "combo_2"; "destruct1"; "mn_alien_off"; 
      "ra_venom"; "take_mats"; "add_friend"; "bl_laboratory"; "combo_7"; "destruct2"; "get_item"; "mn_alien_on"; "ra_metal"; "take_money1";
      "add_money"; "bl_magnetto"; "combo_3"; "destruct3"; "jewell_add"; "mn_bigfoot_off";  "take_money2";
      "ambience_forest"; "bl_mill"; "en_inc2"; "level_up"; "mn_bigfoot_on";  "sell"; "take_money3";
      "ambience_sea"; "bl_stratochamber"; "combo_4"; "combo_8"; "en_inc3"; "lightning"; "mn_tree_off"; "ra_other1"; "send_gift"; "take_star";
      "an_chicken"; "bonus_drop"; "en_inc4"; "mason1"; "mn_tree_on"; "ra_other2"; "signal"; "task_complete";
      "an_cow"; "build_house"; "combo_5"; "en_inc8"; "mason2"; "mn_wolf_off"; "ra_other3"; "ra_radium"; "steps"; "tell";
      "an_goat"; "button_click"; "create"; "en_inc_max1"; "mason3"; "mn_wolf_on"; "ra_other4"; "stone_crack"; "wn_beegun"
    ]
  in
  (
    (*
    Sound.init ();
    sounds.val := List.map (fun kind -> Sound.load (Filename.concat "caf" (kind ^ ".caf"))) sndfiles;
    *)
    let (_,text) = TLF.create (TLF.p [ `text "SOUNDS LOADED" ]) in
    stage#addChild text;
  );


value quad (stage:Stage.c) = 
  let q = Quad.create ~color:0xFF0000 200. 200. in
  (
    q#setPos 100. 100.;
    stage#addChild q;
  );

value window (stage:Stage.c) = 
  let window = new Panelbg.c ~top:True ~bottom:True 500. 350. in
  (
    window#setPos 100. 100.;
    stage#addChild window;
    (*
    let tree = Image.load "tree.png" in
    (
      tree#setPos 200. 400.;
      stage#addChild tree;
    );
    *)
  );

value zsort (stage:Stage.c) = 
(
  Testz.init ();
  proftimer "zSort: %F" Testz.zSort ();
);

value pallete (stage:Stage.c) =
(
  let img = Image.load "pallete.plx" in
  (
    img#setPos 100. 100.;
    stage#addChild img;
  )
);

(*
value image (stage:Stage.c) =
  let image = Image.load "default.png" in
  stage#addChild image;
*)

value map (stage:Stage.c) =
  let map1 = Image.load "test_map/map_12.jpg"
  and map2 = Image.load "test_map/map_13.jpg"
  in
  (
    map1#setX ~-.500.;
    debug "map1#width: %f" map1#width;
    stage#addChild map1;
    map2#setX (map1#x +. map1#width -. 8.);
    stage#addChild map2;
  );

value test_gc (stage:Stage.c) = 
  let items = 
    [|
      "bl_blastfurnace.png";
      "bl_bridge1_break.png";
      "bl_bridge2_break.png";
      "bl_chickencoop.png";
      "bl_chickencoop_gold.png";
      "bl_chickencoop_gold_lock.png";
      "bl_chickencoop_lock.png";
      "bl_collider.png";
      "bl_collider_lock.png";
      "bl_cote.png";
      "bl_cote_gold.png";
      "bl_cote_gold_lock.png";
      "bl_cote_lock.png";
      "bl_cowshed.png";
      "bl_cowshed_gold.png";
      "bl_cowshed_gold_lock.png";
      "bl_cowshed_lock.png";
      "bl_dam.png";
      "bl_doghouse.png";
      "bl_gold_mine.png";
      "bl_gold_mine_lock.png";
      "bl_greenhouse.png";
      "bl_house.png";
      "bl_hutches.png";
      "bl_hutches_gold.png";
      "bl_hutches_gold_lock.png";
      "bl_hutches_lock.png";
      "bl_incubator.png";
      "bl_incubator_lock.png";
      "bl_ionizer.png";
      "bl_ionizer_lock.png";
      "bl_laboratory.png";
      "bl_laboratory1.png";
      "bl_laboratory1_lock.png";
      "bl_laboratory2.png";
      "bl_laboratory2_lock.png";
      "bl_laboratory_lock.png";
      "bl_magnetto.png";
      "bl_magnetto_lock.png";
      "bl_mill.png";
      "bl_neutrino.png";
      "bl_neutrino_lock.png";
      "bl_paddock.png";
      "bl_paddock_gold.png";
      "bl_paddock_gold_lock.png";
      "bl_paddock_lock.png";
      "bl_stable.png";
      "bl_stable_gold.png";
      "bl_stable_gold_lock.png";
      "bl_stable_lock.png";
      "bl_stratochamber.png";
      "bl_stratochamber_lock.png";
      "bl_synchrophasotron.png";
      "bl_synchrophasotron_lock.png";
      "bl_teleport.png";
      "bl_tesla.png";
      "bl_tesla_lock.png";
      "bl_turkeycoop.png";
      "bl_turkeycoop_gold.png";
      "bl_turkeycoop_gold_lock.png";
      "bl_turkeycoop_lock.png";
      "bl_ultrasonic.png";
      "bl_ultrasonic_lock.png";
      "bl_warehouse.png";
      "bl_warehouse_lock.png";
      "bl_workshop.png";
      "bl_workshop_lock.png";
      "bl_xray.png";
      "bl_xray_lock.png"
    |]
  in
  let sprite = Sprite.create () in
  let i = ref 1 in
  (
    let img = Image.load (Filename.concat "items" items.(0)) in
    sprite#addChild img;
    onClick sprite begin fun sprite ->
      (
        sprite#clearChildren ();
        if !i >= Array.length items
        then i.val := 0
        else ();
        let img = Image.load (Filename.concat "items" items.(!i)) in
        (
          incr i;
          sprite#addChild img;
          Gc.full_major ();
        )
      )
    end;
    sprite#setPos 100. 100.;
    stage#addChild sprite;
  );

value library = RefList.empty ();
value library (stage:Stage.c) = 
  for i = 0 to 87 do
    Texture.load_async (Printf.sprintf "library/%d.png" i) (fun texture ->
      RefList.push library texture
    )  
  done;




value data = Hashtbl.create 99;

value lang (stage:Stage.c) = 
(
  let json = LightCommon.read_json (Printf.sprintf "locale/Lang%s.json" "RU") in
  match json with
  [ `Assoc obj -> List.iter (fun (k,v) -> Hashtbl.replace data k v) obj
  | _ ->  failwith "Incorrect lang json"
  ];
);

value print_mem msg = 
  let meminfo = Gc.stat () in
  let sysmem = Lightning.memUsage () in
  Printf.eprintf "!MEMORY [%s]: live: %d, total: %d, sys: %d\n%!" msg ((Sys.word_size/8) * meminfo.Gc.live_words) ((Sys.word_size/8) * meminfo.Gc.heap_words) sysmem;

value memtest (stage:Stage.c) =
(
  let texture = ref (Texture.load "library/0.png") in
  let img = Image.create !texture in
  (
    let timer = Timer.create 0.5 in
    (
      timer#addEventListener Timer.ev_TIMER (fun _ _ _ -> (!texture#release(); texture.val := Texture.load "library/0.png"; img#setTexture !texture; print_mem "timer"));
      timer#start ();
    );
    stage#addChild img;
  );
);

value memtest_async (stage:Stage.c) =
  let img = Image.create Texture.zero in
  (
    let rec f () = 
      (
        img#texture#release();
        Texture.load_async "library/0.png" (fun texture -> (img#setTexture texture; ignore(Timers.start 1. f)));
      )
    in
    Timers.start 0.5 f;
    stage#addChild img;
  );

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value color = 0xCCCCCC;
    initializer begin
        BitmapFont.register "MyriadPro-Regular.fnt";
        TLF.default_font_family.val := "Myriad Pro";

        let ((w, h), tlf) = TLF.create (TLF.p [ TLF.span [`text "test"]; TLF.img ~paddingLeft:30. (Image.load ("e_cactus.png"))]) in
          self#addChild tlf;
        (* map self; *)
(*         image self; *)
(*         test_alpha self; *)
(*       alert self; *)
(*       flip self; *)
(*       async_load self; *)
(*       filters self; *)
(*         size self; *)
(*       tlf self; *)
(*       external_image self; *)
(*       sound self; *)
(*       atlas self; *)
(*       masks self; *)
(*       half_pixels self; *)
(*         gradient self; *)
(*         pallete self; *)
(*         map self; *)
(*         test_gc self; *)
(*         library self; *)
(*         lang self; *)
        memtest_async self;
        (* map self; *)
(*         test_gc self;
        game_center self;
 *)(*         sound self; *)
(*         window self; *)
(*         zsort self; *)
    end;
  end
in
Lightning.init stage;
