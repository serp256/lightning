module ED = EventDispatcher;

module Light = Lightning.Make (struct
  type evType = [= Stage.eventType | `TRIGGERED ];
  type evData = Stage.eventData;
end);

open Light;
module Button = Button.Make DisplayObject;

class atlasScene =
  object(self)
    inherit Sprite.c as super;

    method private onTouch: !'etarget. Event.t _ _ _ (#DisplayObject.c as 'etarget) -> int -> unit = fun event _ ->
      match event.Event.target with
      [ None -> print_endline "onTouch with none target"
      | Some target -> Printf.printf "touch on %s\n%!" target#name
      ];

    initializer 
      let atlas = TextureAtlas.createFromFile "atlas.xml" in
      (
       let q = new Quad.c ~color:0xFF0000 100. 200. in
        (
          q#setPos (100.,100.);
          q#setName "green quad";
          self#addChild q;
        );
       let image1 = new Image.c (TextureAtlas.textureByName atlas "walk_00") in
        (
          image1#setPos (30.,30.);
          image1#setName "atlas image 1";
          ignore(image1#addEventListener `TOUCH self#onTouch);
          self#addChild image1;
        );
        let image2 = new Image.c (TextureAtlas.textureByName atlas "walk_01") in
        (
          image2#setPos (90.,110.);
          image2#setName "atlas image 2";
          ignore(image2#addEventListener `TOUCH self#onTouch);
          self#addChild image2;
        );
        let image3 = new Image.c (TextureAtlas.textureByName atlas "walk_03") in
        (
          image3#setPos (150.,100.);
          image3#setName "atlas image 3";
          image3#setScaleX 2.;
          self#addChild image3;
        );
        let image4 = new Image.c (TextureAtlas.textureByName atlas "walk_05") in
        (
          image4#setPos (210.,270.);
          image4#setName "atlas image 4";
          self#addChild image4;
        );
        let egg = new Image.c (TextureAtlas.textureByName atlas "benchmark_object") in
        (
          egg#setPos (500.,300.);
          egg#setName "egg";
          ignore begin 
            egg#addEventListener `TOUCH  begin fun event _ ->
              let () = prerr_endline "egg touch" in
              match event.Event.data with
              [ `Touches _ -> 
                let () = egg#setRotation (egg#rotation +. 0.1) in
                Printf.eprintf "egg.rotation = %f\n%!" egg#rotation
              | _ -> ()
              ]
            end;
          end;
          self#addChild egg;
        );
        ignore(self#addEventListener `TOUCH self#onTouch);

      );
      
  end;

(*
class quadScene ['a,'b] = 
  object(self)
    inherit CompiledSprite.c ['a,'b];

    initializer
       let q = new Quad.c ~color:0xFFFFFF 100. 200. in
        (
          q#setPos (100.,100.);
          q#setName "green quad";
          self#addChild q;
        );

  end;
*)

let stage width height =
  let () = Printf.printf "stage with %f:%f\n%!" width height in
  object(self)
    inherit Stage.c width height;
    value color = 0xCCCCCC;

    initializer 
      (
        BitmapFont.register "Helvetica.fnt";
        (*
        self#setName "stage";
        let q = new Quad.c ~color:0x0000FF 100. 100. in
        (
          q#setName "red quad";
          self#addChild q;
        );
        *)
        (*
        let q = new Quad.c ~color:0x00FF00 200. 100. in
        (
          q#setPos (200.,200.);
          q#setName "green quad";
          self#addChild q;
        );
        let q = new Quad.c ~color:0x0000FF 100. 200. in
        (
          q#setPos (300.,300.);
          q#setName "green quad";
          self#addChild q;
        );
        *)
        (*
        let ball = Image.createFromFile "ball.png" in
        let () = Printf.eprintf "ball size: [%F:%F]\n%!" ball#width ball#height in
        (
          ball#setPos (150.,300.);
          ball#setName "cactus";
          self#addChild ball;
(*           i#addEventListener `my_fucking_event self#onImageFuckingEvent; *)
          let ball2 = Image.createFromFile "ball.png" in
          (
            ball2#setX (ball#x +. ball#width);
            ball2#setY ball#y;
            self#addChild ball2;
          )
        );
        *)
        (*
        let atlasScene = new atlasScene in
        (
          atlasScene#setPos (100.,150.);
          atlasScene#setName "atlas scene";
(*           atlasScene#setMask (Rectangle.create 10. 10. 100. 100.); *)
          self#addChild atlasScene;
        );
        *)
(*
        let quadScene = new quadScene in 
        self#addChild quadScene;
*)
(*
        BitmapFont.register "test_font.fnt";
        print_endline "font regisred";
        let tf = TextField.create ~fontName:"Helvetica" ~color:LightCommon.color_white ~width:200. ~height:400. "Now your can use cast, but ... " in
        (
          tf#setBorder True;
          tf#setHAlign `HAlignCenter;
          tf#setVAlign `VAlignCenter;
          tf#setPos (300.,400.);
          self#addChild tf;
        );
*)


        (*
        let butTexture = Texture.createFromFile "button.png" in
        let button = Button.create ~text:"Кликай нах!" butTexture in
        (
          button#setPos (200.,400.);
          button#addEventListener `TRIGGERED (fun _ -> print_endline "button clicked");
          button#setName "first button";
          self#addChild button;
        );
        *)

        let clip = MovieClip.create ~fps:20 "Boom.xml" in
        (
          clip#setPos (200.,200.);
          clip#setLoop True;
          clip#addEventListener `TOUCH begin fun tEv _ ->
            match tEv.Event.data with
            [ `Touches [ touch :: _ ] ->
              match touch.Touch.phase with
              [ Touch.TouchPhaseEnded -> 
                match clip#isPlaying with
                [ True -> clip#stop ()
                | False -> clip#play ()
                ]
              | _ -> ()
              ]
            | _ -> assert False
            ]
          end;
          self#addChild clip;
        );

        let fps = FPS.create ~color:0xFF0000 () in
        (
          fps#setPos ((width -. fps#width),(height -. fps#height));
          self#addChild fps;
        );

      );

(*     method onImageFuckingEvent event = prerr_endline "image fucking event"; *)


  end
in
Lightning.init stage;
