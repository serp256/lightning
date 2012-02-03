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
  BitmapFont.register "Arial.fnt";
  let text = TLF.create (TLF.p ~fontSize:20 ~halign:`center ~fontFamily:"Arial" [`text "This is first line\nThis is "; TLF.img ~width:50. ~height:40. (Image.load "e_cactus.png"); `text " second line"]) in
  (
    stage#addChild text;
  )
);


value atlas (stage:Stage.c) = 
(

  let texture = Texture.load "tree.png" in
  let atlas = Atlas.create texture in
  (
    atlas#addChild (AtlasNode.create texture (Rectangle.create 10. 30. 100. 100.) ());
    atlas#addChild (AtlasNode.create texture (Rectangle.create 10. 30. 100. 20.) ~pos:{Point.x=150.;y=50.} ());
    atlas#setPos 100. 100.;
    stage#addChild atlas;
  );
);

value filters (stage:Stage.c) =
(
  let img = Image.load "tree.png" in
  (
(*     img#setFilters [ `ColorMatrix gray_filter ]; *)
    img#setFilters [ Filters.glow ~size:2 ~strength:10 0x0000FF ];
    img#setAlpha 0.2;
    img#setPos 100. 100.;
    stage#addChild img;
  );
  let img = Image.load "tree.png" in
  (
    img#setPos 300. 100.;
    img#setAlpha 0.2;
    stage#addChild img;
  );
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

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value color = 0xFFFFFF;
    initializer begin
      filters self;
(*         size self; *)
    end;
  end
in
Lightning.init stage;

