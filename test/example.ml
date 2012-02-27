open Light;

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
  obj#addEventListener `TOUCH begin fun ev (_,target) _ ->
    match ev.Ev.data with
    [ `Touches [ {Touch.phase=Touch.TouchPhaseEnded; _ } :: _ ] -> handler target
    | _ -> ()
    ]
  end |> ignore;



value tlf (stage:Stage.c) = 
(
  BitmapFont.register "MyriadPro-Regular.fnt";
  TLF.default_font_family.val := "Myriad Pro";
  let (_,text) = TLF.create begin
    TLF.p  ~halign:`center 
      [ 
        TLF.img ~height:50. ~valign:`default (Image.load "quad.png") ; 
        TLF.span ~fontSize:20 ~fontFamily:"Myriad Pro" [ `text " nah nah" ]; `br ; 
        `text "bla bla bla BLA yyyy"
      ]
  end in
  (
    text#setPos 100. 100.;
(*     text#setFilters [ Filters.glow ~size:2 0xFF0000 ]; *)
(*     text#setAlpha 0.3; *)
    stage#addChild text;
  );
  (*
  let (_,text) = TLF.create (TLF.p ~halign:`center ~fontFamily:"Myriad Pro" [`text "laldddih" ]) in
  (
    text#setPos 300. 100.;
    stage#addChild text;
  )
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
  let tx = ref (Texture.load "e_cactus.png") in
  (
    onClick img (fun img ->
      let t = img#texture in
      (
        img#setTexture !tx;
        img#setTexFlipX (not img#texFlipX);
        tx.val := t;
      )
    );
    img#setPos 100. 100.;
    stage#addChild img;
  );


value async_load (stage:Stage.c) = 
(
  let lib = Clip.load "Clips" in
  let sprite = Sprite.create () in
  (
    let loading = Clip.get_symbol lib "ESkins.LoadClip" in
    (
      loading#setPos 100. 100.;
      sprite#addChild loading;
    );
    Texture.load_async "tree.png" (fun t -> (sprite#clearChildren(); sprite#addChild (Image.create t)));
    stage#addChild sprite;
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

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value color = 0xCCCCCC;
    initializer begin
(*       alert self; *)
(*       flip self; *)
(*       async_load self; *)
(*       filters self; *)
(*         size self; *)
      tlf self;
(*       atlas self; *)
(*       masks self; *)
    end;
  end
in
Lightning.init stage;

