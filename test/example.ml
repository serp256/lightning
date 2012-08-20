open LightCommon;

(* Gc.set {(Gc.get ()) with Gc.verbose  = (0x001 lor 0x002 lor 0x004 lor 0x010 lor 0x040 lor 0x080)}; *)

Printexc.record_backtrace True;
value max_anim_len = 40;
value (|>) a b = b a;
(*
value run_thread () = 
  while True do
option     Thread.delay 1.;
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
  debug "REGISTR FONT";
  BitmapFont.register "MyriadPro-Regular.fnt";
  BitmapFont.register "MyriadPro-Bold.fnt";
  BitmapFont.register "CCFairyTale.fnt";
  debug "FONT REGISTRED";
  TLF.default_font_family.val := "Myriad Pro";
  TLF.default_font_size.val := 18;
  (*
  let xml = "<p valign=\"center\" halign=\"center\" color=\"0x591100\" font-size=\"16\"><span color=\"0xA01063\">семена дыни</span> будет открыт за <span><img src=\"fb.png\" padding-right=\"1.\"
  padding-left=\"0.\" height=\"20.\" width=\"20.\"/><span color=\"0xA01063\" font-size=\"18\" font-family=\"CCFairyTale\">9</span></span>. Продолжить?</p>" in
  *)
  (*
  let xml = 
    "<p valign=\"center\" halign=\"left\" color=\"0x591100\" font-size=\"16\"><span color=\"0xA01063\" font-size=\"18\" font-family=\"CCFairyTale\">6</span> шт <span color=\"0x317AC9\">баклажан</span> будет продано за б<span><img src=\"fb.png\" padding-right=\"1.\" padding-left=\"0.\" height=\"16.\"></img><span color=\"0xA01063\" font-size=\"16\" font-family=\"CCFairyTale\">1800</span></span> Продолжить?</p>"
  in
  *)

  let tlf_text = TLF.p ~fontWeight:"bold" ~halign:`center ~color:0xFFE000 ~fontSize:18 [`text "Add бля нах"] in
  let (_,text) = TLF.create tlf_text in
  (
    text#setFilters [ Filters.glow ~size:2 ~strength:2. 0x14484D ];
    text#setPos 100. 100.;
    stage#addChild text;
  );
);


(*
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

*)

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
(*     sprite#setFilters [ `ColorMatrix disable_filter ]; *)
(*     sprite#setFilters [ Filters.glow 0xFF0000 ]; *)
    sprite#setPos 100. 100.;
    stage#addChild sprite;
  );

    let tree = Image.load "tree.png" in
    (
      tree#setPos 100. 350.;
(*       tree#setFilters [ `ColorMatrix disable_filter ]; *)
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


(*
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
*)


value flip (stage:Stage.c) =
  let () = LightCommon.set_resources_suffix "@2x" in
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


(*
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
    font#setColor (`Color 0xFFFFFF);
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
    let text = "Ежедневный бонус PipIy" in
  (
    (*
  GameCenter.init ~callback:begin fun res ->
    let text = 
      match res with 
      [ True -> "Game center success"
      | False -> "Game center failed"
      ]
    in
    *)
    let (_,text) = TLF.create (TLF.p ~fontWeight:"bold" ~fontSize:26 ~color:0xFFFF00 [ `text text ]) in
    (
      text#setPos 100. 100.;
(*       text#setFilters [ Filters.glow ~size:1 ~strength:10 0 ]; *)
      stage#addChild text;
    );
    let (_,text) = TLF.create (TLF.p ~fontWeight:"bold" ~fontSize:26 ~color:0xFFFF00 [ `text text ]) in
    (
      text#setPos 100. 150.;
      text#setFilters [ Filters.glow ~size:1 ~strength:3. 0 ];
      stage#addChild text;
    );

    let img = Image.load "tree.png" in
    (
      img#setPos 50. 300.;
      img#setFilters [ Filters.glow ~size:1 ~strength:3. 0 ];
      stage#addChild img;
    );
  );
(*   end (); *)


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



(* 
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
 *)

(* value zsort (stage:Stage.c) = 
(
  Testz.init ();
  proftimer "zSort: %F" Testz.zSort ();
); *)

value pallete (stage:Stage.c) =
(
  let img = Image.load "pallete.plx" in
  (
    img#setPos 100. 100.;
    stage#addChild img;
  )
);
*)


value items = 
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
  |];


value async_images (stage:Stage.c) = 
  let load_async fname f = Texture.load_async fname f in (* let t = Texture.load fname in f t in  *)
  let x = ref 0. and y = ref 0. in
  Array.iter begin fun it ->
(*     let () = prerr_endline it in *)
    load_async (Filename.concat "items" it) begin fun t -> 
      let image = Image.create t in 
      (
        image#setPos !x !y; 
(*         Printf.printf "x=%f,y=%f\n%!" !x !y; *)
        x.val := !x +. 100.;
        if (!x > fst (Stage.screenSize ())) then (y.val := !y +. 100.; x.val := 0.) else ();
(*         Printf.eprintf "next x=%f,y=%f\n%!" !x !y; *)
        stage#addChild image;
      )
    end
  end items;

  (*
    (
      (
        stage#addChild image;
        loop 1 where
          rec loop i =
            let i = if i = Array.length items then 0 else i in
            Timers.start 0.05 begin fun () ->
              Texture.load_async (Filename.concat "items" items.(i)) (fun t -> (image#setTexture t; loop (i+1)))
            end |> ignore
      )
    )
  end;
  *)

value image (stage:Stage.c) =
  let image = Image.load "tree.png" in
  (
    image#setX 101.; image#setY 102.;
    stage#addChild image;
  );
  (*
  Texture.load_async "tree.png" begin fun t ->
    let image = Image.create t in
    (
(*       image#setColor (`QColors (qColor 0xFF0000 0x00FF00 0x0000FF 0xFFFFFF)); *)
      stage#addChild image;
    )
  end;
  *)

(*
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

*)

value url_loader (stage:Stage.c) = 
  let loader = new URLLoader.loader () in
  (
    ignore <| loader#addEventListener URLLoader.ev_PROGRESS (fun ev _ _ -> debug "recieved %d bytes" (Option.get (Ev.int_of_data ev.Ev.data)));
    let rec loop () = 
      (
        let request = URLLoader.request ~httpMethod:`GET "http://st-farm.redspell.ru/images/map_bottom_2.png" in
        loader#load request;
      )
    in
    (
      ignore <| loader#addEventListener URLLoader.ev_COMPLETE (fun ev (loader,_) _ -> (debug "request complete: %d, %s, %Ld" loader#httpCode loader#contentType loader#bytesTotal; ignore <| Timers.start 0.1 loop));
      ignore <| Timers.start 0.1 loop;
    )
  );

value pvr (stage:Stage.c) = 
  let image = Image.load "map/1.jpg" in
  stage#addChild image;

value glow (stage:Stage.c) = 
(
  (*
  let img = Image.load "1px_line.png" in
  (
    img#setFilters [ Filters.glow ~size:1 0 ];
    img#setPos 100. 100.;
    stage#addChild img;
  );
  *)
  let change_filter el = 
    match el#filters with
    [ [ `Glow {Filters.glowKind=`linear;_} ] -> el#setFilters [ Filters.glow ~kind:`soft ~strength:2. ~size:2 0xFF0000 ]
(*     | [ `Glow {Filters.glowKind=`soft;_} ] -> el#setFilters [ `ColorMatrix gray_filter ] *)
(*     | [ `ColorMatrix m ] -> el#setFilters [ Filters.glow ~kind:`linear ~strength:1. ~size:2 0xFF0000 ] *)
    | [ ] -> el#setFilters [ Filters.glow ~kind:`linear ~size:2 0xFF0000 ]
    | _ -> assert False 
    ]
  in
  let img = Image.load "tree.png" in
  (
    img#setPos 20. 50.;
    stage#addChild img;
    onClick img change_filter;
  );
  (*
  let img = Image.load "2px_line.png" in
  (
    img#setPos 100. 180.;
    stage#addChild img;
  );
  *)
    (*
    let tex = Texture.rendered 100. 100. in
    (
      tex#draw begin fun () ->
        (
          Render.clear 0xFFFFFF 1.;
          img#render ~transform:False None;
        );
      end;
      let img = Image.create (tex :> Texture.c) in
      (
        img#setPos 100. 300.;
        stage#addChild img;
      );
    );
    *)
  (*
  let img = Image.load "2px_line.png" in
  (
    img#setPos 100. 150.;
    stage#addChild img;
  );
  let text = "Ежедневный бонус PipIy" in
  (
    let (_,text) = TLF.create (TLF.p ~fontWeight:"bold" ~fontSize:26 ~color:0xFFFF00 [ `text text ]) in
    (
      text#setPos 120. 200.;
      stage#addChild text;
      onClick text change_filter;
    );
    let sprite = Sprite.create () in
    (
      let img = Image.load "tree.png" in
      sprite#addChild img;
      let (_,text) = TLF.create (TLF.p ~fontWeight:"bold" ~fontSize:26 ~color:0xFFFF00 [ `text text ]) in
      (
        text#setPos 20. 50.;
        sprite#addChild text;
      );
      stage#addChild sprite;
      sprite#setPos 10. 300.;
      onClick sprite change_filter;
    );
  )
    (*
    let (_,text) = TLF.create (TLF.p ~fontWeight:"bold" ~fontSize:26 ~color:0xFF0000 [ `text text ]) in
    (
      text#setPos 120. 200.;
      stage#addChild text;
    );
    *)
  );
  *)
);

value quad (stage:Stage.c) = 
  let q = Quad.create (*~color:(`Color 0xFF0000)*) 200. 200. in
  (
    stage#addChild q;
    q#setPos 100. 100.;
    q#setAlpha 0.2;
(*     q#setColor (`Color 0x00FF00); *)
  );

value hardware (stage:Stage.c) =
(
  let open Hardware in
  debug "platform: %s, model: %s, cpu: %d, total mem: %d, user mem: %d" (platform()) (hwmodel()) (cpu_frequency()) (total_memory()) (user_memory());
  match LightCommon.deviceType () with
  [ LightCommon.Pad -> debug "this is PAD"
  | LightCommon.Phone -> debug "this is phone"
  ]
);

value raise_some_exn () = 
  if True then raise (Failure "BLYYYY exn") else ();

value test_exn (stage:Stage.c) =
  Timers.start 5. begin fun () ->
(*     try *)
    (
      prerr_endline "now call exn";
      raise_some_exn ();
    )
(*     with [ exn -> (Printexc.print_backtrace stderr; flush stderr) ] *)
  end;


(*
value social (stage:Stage.c) = 
(
  let b = Image.load "tree.png" in
  (
    b#setPos 50. 100.;
    stage#addChild b;
    onClick b begin fun _ ->
      let module OK = 
        OK.Make(struct
          value appid = "59630080";
          value permissions = let open OK in [ Valuable_access; Set_status; Photo_content ];
          value application_key = "CBADOOIEABABABABA";
          value private_key = "70F1FED9D831D37A338485A4";
        end)
      in
      let delegate = 
        {
          SNTypes.on_error = begin fun 
            [ SNTypes.IOError -> debug "OK IOERROR"
            | SNTypes.SocialNetworkError (code, msg) -> debug "social network error (%s,%s)" code msg
            | SNTypes.OAuthError e -> debug "OAuth error"
            ]
          end;
          on_success = begin fun id ->
            debug "on_success"
          end
        }
      in
      OK.call_method ~delegate "users.getCurrentUser" [];
    end;
  );
  let b = Image.load "tree.png" in
  (
    b#setPos 200. 100.;
    stage#addChild b;
    onClick b begin fun _ ->
      let module VK = 
        VK.Make(struct
          value appid = "2831779";
          value permissions = let open VK in [Notify; Friends; Photos; Docs; Notes; Pages; Wall; Groups; Messages; Notifications ; Stats ; Ads; Offline ];
        end)
      in
      let delegate = 
        {
          SNTypes.on_error = begin fun 
            [ SNTypes.IOError -> debug "OK IOERROR"
            | SNTypes.SocialNetworkError (code, msg) -> debug "social network error (%s,%s)" code msg
            | SNTypes.OAuthError e -> debug "OAuth error"
            ]
          end;
          on_success = begin fun id ->
            debug "on_success VK"
          end
        }
      in
      VK.call_method ~delegate "friends.getAppUsers" [];
    end
  );
);
*)


value tweens (stage:Stage.c) =
  let bt = Image.load "tree.png" in 
  let () = stage#addChild bt in
  let tweenY = Tween.create ~transition:`easeOutBounce 10.
  (* and tweenX = Tween.create 0.7 *)
  (* and tweenAlpha = Tween.create 0.8 *)
  in
  (         
    bt#setX 100.;
    (* Stage.addTween tweenX; *)
    Stage.addTween tweenY;
    (* Stage.addTween tweenAlpha; *)
    (* tweenX#animate bt#prop'x 300.; *)
    tweenY#animate bt#prop'y 600.;
    (* tweenAlpha#animate bt#prop'alpha 0.5; *)
    (* tweenX#setOnComplete (fun () -> Stage.removeg tweenX); *)
    (* tweenY#setOnComplete (fun () -> Stage.removeTween tweenY); *)
    (* tweenAlpha#setOnComplete begin fun () ->  
      (
        Stage.removeTween tweenAlpha;
        let tween =  Tween.create 0.15 in
          (
            Stage.addTween tween;
            tween#animate bt#prop'alpha 0.;
            (* tween#setOnComplete (fun () -> Stage.removeTween tween); *)
            (* ignore(tween#process 0.04); *)
          )
      ) end; *)
    );

value storage (stage:Stage.c) = 
(
  KVStorage.put_string "pizda" "lala";
  debug "get_string: %s" (KVStorage.get_string "pizda");
);

value localNotif () =
  let time = Unix.time () in
  (
    ignore(LocalNotifications.schedule "xyu" (time +. 5.) "xyu");
    ignore(LocalNotifications.schedule ~badgeNum:10 "pizda" (time +. 15.) "pizda");
    LocalNotifications.cancel "xyu";
  );

value accelerometer () =
  Motion.acmtrStart (fun data -> debug "%f %f %f" data.Motion.accX data.Motion.accY data.Motion.accZ) 1.;

value music (self:Stage.c) =
(
  Sound.init ();
  let sound = Sound.load "sound.mp3" in
  let channel = Sound.createChannel sound in
  (
    channel#play ();
    channel#addEventListener Sound.ev_SOUND_COMPLETE (fun _ _ _ -> debug "sound complete") |> ignore;
  );
  let timer = Timer.create ~repeatCount:3 5. "GC" in
  (
    timer#addEventListener Timer.ev_TIMER (fun _ _ _ -> (debug "call major"; Gc.full_major ())) |> ignore;
    timer#start ();
  );
);


value glow_and_gc (stage:Stage.c) = 
(
  let make_sprite (parent:Stage.c) =
    let (_,text) = TLF.create (TLF.p ~fontSize:20 [`text "Пизда Ля Ля"]) in
    let tree = Image.load "tree.png" in
    let sprite = Sprite.create () in
    (
      sprite#addChild tree;
      sprite#addChild text;
      sprite#setFilters [ Filters.glow ~size:2 0xFF0000 ];
      parent#addChild sprite;
      sprite;
    )
  in
  let sprite = ref (make_sprite stage) in
  stage#addEventListener DisplayObject.ev_ENTER_FRAME begin fun _ (_,stage) _ ->
    (
      !sprite#removeFromParent();
      sprite.val := make_sprite stage;
    );
  end |> ignore;
);

value touchesTest(stage:Stage.c) =
(
  let img = Image.load "tree.png" in
  (
    img#setX 50.;
    img#setY 50.;

    Stage.(
      img#addEventListener ev_TOUCH (fun ev _ _ ->
        match touches_of_data ev.Ev.data with
        [ Some [ touch :: _ ] ->
          Touch.(
            let () = debug "touch id: %ld" touch.tid in
              match touch.phase with
              [ TouchPhaseBegan -> debug "TouchPhaseBegan"
              | TouchPhaseMoved ->
                (
                  debug "TouchPhaseMoved";
                  img#setX (img#x -. touch.previousGlobalX +. touch.globalX);
                  img#setY (img#y -. touch.previousGlobalY +. touch.globalY);
                )
              | TouchPhaseEnded -> debug "TouchPhaseEnded"
              | _ -> debug "some other phase"
              ]
          )
        | _ -> ()
        ]
      )
    );

    stage#addChild img;
  );  
);

value assets (s:Stage.c) =
(
  let img = Image.load "prof.jpg" in
  (
    ignore(Stage.(
      img#addEventListener ev_TOUCH (fun ev _ _ ->
        match touches_of_data ev.Ev.data with
        [ Some [ touch :: _ ] ->
          Touch.(
              match touch.phase with
              [ TouchPhaseEnded -> Lightning.extractAssets (fun success -> debug "assets extracted, %B" success)
              | _ -> ()
              ]
          )
        | _ -> ()
        ]
      )
    ));
    s#addChild img;
  );

  let img = Image.load "prof.jpg" in
  (
    ignore(Stage.(
      img#addEventListener ev_TOUCH (fun ev _ _ ->
        match touches_of_data ev.Ev.data with
        [ Some [ touch :: _ ] ->
          Touch.(
              match touch.phase with
              [ TouchPhaseEnded ->
                let snd = Sound.createChannel (Sound.load "melody0.mp3") in
                  snd#play ()
              | _ -> ()
              ]
          )
        | _ -> ()
        ]
      )
    ));

    img#setX 300.;
    s#addChild img;
  );

  let img = Image.load "prof.jpg" in
  (
    ignore(Stage.(
      img#addEventListener ev_TOUCH (fun ev _ _ ->
        match touches_of_data ev.Ev.data with
        [ Some [ touch :: _ ] ->
          Touch.(
              match touch.phase with
              [ TouchPhaseEnded -> tweens s
              | _ -> ()
              ]
          )
        | _ -> ()
        ]
      )
    ));

    img#setY 300.;
    s#addChild img;
  );
);

    
value udid (self:Stage.c) = 
  let text = Lightning.getMACID () in
  let (_,text) = TLF.create (TLF.p [`text ("<<<< " ^ text ^ " >>>>")]) in
  (
    text#setY 300.;
    self#addChild text;
  );


value bl_greenhouse (stage:Stage.c) =
(*   let texture = Texture.load "28x05.png"  *)
  let texture = Texture.load "25.png" 
(*   and pos = {Point.x = ~-.80.; y = 11.}  *)
  and pos = {Point.x = 59.; y = 23.}
  and flipX = False 
  in
  (
    (*
    let house = AtlasNode.create texture (Rectangle.create 124. 74. 127. 133.) ~pos:{Point.x = ~-.153.; y = ~-.52.} ~flipX ()
    and img1 = ref (AtlasNode.create texture (Rectangle.create 376. 0. 50. 69.) ~pos ~flipX ())
    and img2 = ref (AtlasNode.create texture (Rectangle.create 224. 0. 50. 69.) ~pos ~flipX ())
    *)
(*
    let house = AtlasNode.create texture (Rectangle.create 246. 672. 254. 266.) ~pos:{Point.x = 51.; y = ~-.103.} ~flipX ()
    and img1 = ref (AtlasNode.create texture (Rectangle.create 871. 594. 100. 137.) ~pos ~flipX ())
    and img2 = ref (AtlasNode.create texture (Rectangle.create 871. 455. 100. 137.) ~pos ~flipX ())
*)
    let house = AtlasNode.create texture (Rectangle.create 246. 672. 254. 266.) ~pos:{Point.x = 51.; y = ~-.103.} ~flipX ()
    and img1 = ref (AtlasNode.create texture (Rectangle.create 871. 594. 100. 137.) ~pos ~flipX ())
    and img2 = ref (AtlasNode.create texture (Rectangle.create 871. 455. 100. 137.) ~pos ~flipX ())
    in
    let atlas = Atlas.create texture in
    (
      atlas#setScale 0.5;
      atlas#setPos 200.0 100.0;
      atlas#addChild house;
      atlas#addChild !img2;
      stage#addChild atlas;
      let timer = Timer.create ~repeatCount:~-1 0.5 "pizda" in
      (
        timer#addEventListener Timer.ev_TIMER begin fun _ _ _ ->
          (
            (*
            if atlas#numChildren = 1 
            then
            (
              atlas#clearChildren();
              atlas#addChild house;
              atlas#addChild !img2;
            )
            else 
            (
              atlas#clearChildren();
              atlas#addChild house;
            )
            *)
            atlas#clearChildren();
            atlas#addChild house;
            atlas#addChild !img2;
            let img = img1.val in
            (
              img1.val := !img2;
              img2.val := img;
            )
          )
        end |> ignore;
        timer#start();
      );
    )
  );

(* value music (self:Stage.c) =
(
  Sound.init ();
  let sound = Sound.load "sound.mp3" in
  let channel = Sound.createChannel sound in
  (
    channel#play ();
    channel#addEventListener Sound.ev_SOUND_COMPLETE (fun _ _ _ -> debug "sound complete") |> ignore;
  );
  let timer = Timer.create ~repeatCount:3 5. "GC" in
  (
    timer#addEventListener Timer.ev_TIMER (fun _ _ _ -> (debug "call major"; Gc.full_major ())) |> ignore;
    timer#start ();
  );
); *)

value avsound (stage:Stage.c) path =
(
  Sound.init ();

    let channel1 = Sound.createChannel (Sound.load "melody0.mp3") in
    let channel2 = Sound.createChannel (Sound.load "melody0.mp3") in
      let createImg click =
        let img = Image.load "Russia.png" in
        (
          img#setScaleX 0.5;
          img#setScaleY 0.5;
          stage#addChild img;

          ignore(Stage.(
            img#addEventListener ev_TOUCH (fun ev _ _ ->
              match touches_of_data ev.Ev.data with
              [ Some [ touch :: _ ] ->
                Touch.(
                    match touch.phase with
                    [ TouchPhaseEnded -> let () = debug "click!" in click ()
                    | _ -> ()
                    ]
                )
              | _ -> ()
              ]
            )
          ));

          img;
        )
      in
        let play = createImg channel1#play
        and stop = createImg channel1#stop
        and pause = createImg channel1#pause in
        (
          ignore(channel1#addEventListener Sound.ev_SOUND_COMPLETE (fun _ _ _ -> debug "pizda"));

          stage#addChild play;
          stage#addChild stop;
          stage#addChild pause;

          stop#setX 150.;
          pause#setX 300.;
        );
);
  (* ignore(Sound.createChannel path); *)

value fbtest () = 
  (
  (*  FBConnect.init "412548172119201"; *)
 (*   debug "FBTEST";  *)
    FBConnect.init "412548172119201"; 

    let delegate = 
      {
        FBConnect.GraphAPI.fb_request_did_fail = Some (fun error -> debug "ERROR : %s" error );
        FBConnect.GraphAPI.fb_request_did_load = Some (fun _ -> debug "SUCCESS ANSWER"  );
      }
    in
    FBConnect.GraphAPI.request "me" [] ~delegate ();
(*
    let timer = Timer.create ~repeatCount:1 5. "PIZDA" in 
    (
      ignore(timer#addEventListener Timer.ev_TIMER_COMPLETE (fun _ _ _ -> FB.graphAPI "me" [ ("pizda_key","pizda_value");  ("key","value"); ("xuj_key","xyj_value"); ] ~callback:(fun resp -> debug "OCAML CALLBACK : %S" resp) ~ecallback:(fun error -> debug "OCAML ERROR CALLBACK : %S" error)));
      timer#start ();
    )
  *)
  );


value texture_atlas (stage:Stage.c) =
  let () = Texture.scale.val := 2. in
  let atlas = TextureAtlas.load "libandroid.bin" in
  let image = Image.create (TextureAtlas.subTexture atlas "/background_levels/1.png") in
  stage#addChild image;

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value bgColor = 0xCCCCCC;
    initializer begin
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "++++++++++++++++++++++++++++++++++++++++";
      debug "device id : %s" (match Lightning.deviceIdentifier () with [ Some id -> id | _ -> "NONE"]);
(*       assets self; *)
(*       avsound self "melody0.mp3"; *)
      (*
      debug "qweqweqweqwe";
      ignore(self#addEventListener Stage.ev_BACK_PRESSED (fun ev _ _ -> ( debug "pizda"; Ev.stopPropagation ev; )));
*)
      (* fbtest ();  *)
(*      avsound self "melody0.mp3"; *)
      (* assets self; *)
(*       debug "START OCAML, locale: %s" (Lightning.getLocale()); *)
(*       assets self; *)
(*       quad self; *)
(*       tweens self; *)
      (* touchesTest self; *)

(*       accelerometer (); *)
        (* BitmapFont.register "MyriadPro-Regular.fnt"; *)
(*         BitmapFont.register "MyriadPro-Bold.fnt"; *)
        (* TLF.default_font_family.val := "Myriad Pro"; *)
(*
        let ((w, h), tlf) = TLF.create (TLF.p [ TLF.span [`text "test"]; TLF.img ~paddingLeft:30. (Image.load ("e_cactus.png"))]) in
          self#addChild tlf;
*)
        (* map self; *)
(*         glow self; *)
(*         image self; *)
(*         rec_fun self; *)
(*         test_alpha self; *)
(*       alert self; *)
      (* test_exn self; *)
   (*   tweens self; *)
      (* flip self; *)
(*       social self; *)
(*       async_load self; *)
(*       filters self; *)
(*         size self; *)
(*        tlf self;  *)
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
(*         memtest_async self; *)
(*           url_loader self; *)
        (* map self; *)
(*         test_gc self; *)
(*         filters self; *)
(*         game_center self; *)
          (* pvr self; *)
          (* sound self; *)
(*           url_loader self; *)
(*           glow self; *)
(*           storage self; *)
 (*         sound self; *)
(*         window self; *)
(*         zsort self; *)
      (* localNotif (); *)
(*           music self; *)
          (* tlf self; *)
(*           quad self; *)
          (* hardware self; *)
(*           glow_and_gc self; *)
(*        udid self; *)
       (* bl_greenhouse self; *)
(*        async_images self; *)
(*         image self; *)
(*        texture_atlas self; *)
(*        tlf self *)
    end;
  end
in
Lightning.init stage;


(* debug "VALUE IN STORAGE: %s" (try KVStorage.get_string "pizda" with [ KVStorage.Kv_not_found -> "NOT FOUND"]); *)
