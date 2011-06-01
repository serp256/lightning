
DEFINE MAX_DRAG_DIST = 40.;

module Make
  (D:DisplayObjectT.M with 
    type evType = private [> `TRIGGERED | `TOUCH | DisplayObjectT.eventType ] and
    type evData = private [> `Touches of list Touch.t | DisplayObjectT.eventData ]
  )
  (Sprite: Sprite.S with module D = D)
  (Image: Image.S with module Q.D = D)
  (TextField: TextField.S with module D = D)
  = struct

  class c  ?downstate ?text upstate = 
    let width = upstate#width and height = upstate#height in
    let () = Printf.eprintf "create button with [%f:%f]\n%!" width height in
    object(self)
      inherit D.container;
      value upState:Texture.c = upstate;
      value downState:Texture.c = match downstate with [ None -> upstate | Some ds -> ds ];
      value contents = Sprite.create ();
      value background = Image.create upstate;
      value mutable textBounds: Rectangle.t = Rectangle.create 0. 0. width height;
      value scaleWhenDown: float = match downstate with [ None -> 0.9 | _ -> 1.0 ];
      value alphaWhenDisabled: float = 0.5;
      value mutable enabled = True;
      value mutable isDown = False;
      value mutable textField = 
        match text with 
        [ None -> None 
        | Some text -> 
            let r = TextField.create ~width ~height text in
            (
              r#setBorder True;
              r#setHAlign `HAlignCenter; r#setVAlign `VAlignCenter;
              Some r
            )
        ];

      initializer
      (
        background#setName "button background";
        contents#addChild background;
        match textField with [ Some tf -> contents#addChild tf | None -> () ];
        self#addChild contents;
        ignore(self#addEventListener `TOUCH self#onTouch);
      );

      method private onTouch touchEvent _ = (*{{{*)
        match enabled with
        [ False -> ()
        | True -> 
            let open Touch in
            match touchEvent.Event.data with
            [ `Touches touches -> 
              match touches with
              [ [ touch :: _ ] ->
                match touch.phase with
                [ TouchPhaseBegan ->
                  (
                    background#setTexture downState;
                    contents#setScale scaleWhenDown;
                    contents#setX ((1. -. scaleWhenDown) /. 2. *. downState#width);
                    contents#setY ((1. -. scaleWhenDown) /. 2. *. downState#height);
                    isDown := True;
                  )
                | TouchPhaseMoved when isDown ->
                    let open Rectangle in
                    let () = Printf.eprintf "self: %s, parent: %s\n%!" name (match parent with [ None -> "NONE" | Some p -> p#name ]) in
                    let buttonRect = self#boundsInSpace self#stage in
                    if (touch.globalX < buttonRect.x -. MAX_DRAG_DIST) ||
                      (touch.globalY < buttonRect.y -. MAX_DRAG_DIST) ||
                      (touch.globalX > buttonRect.x +. buttonRect.width +. MAX_DRAG_DIST) ||
                      (touch.globalY > buttonRect.y +. buttonRect.height +. MAX_DRAG_DIST)
                    then
                      self#resetContents ()
                    else ()
                | TouchPhaseEnded when isDown ->
                    (
                      self#resetContents ();
                      self#dispatchEvent (Event.create `TRIGGERED ());
                    )
                | TouchPhaseCancelled when isDown -> self#resetContents ()
                | _ -> ()
                ]
              | _ -> assert False
              ]
            | _ -> assert False
            ]
        ];(*}}}*)

      method private resetContents () = (*{{{*)
        (
          isDown := False;
          background#setTexture upState;
          contents#setPos (0.,0.);
          contents#setScale 1.;
        );(*}}}*)


      method private textField = 
        match textField with
        [ None -> 
          let r = TextField.create ~width:textBounds.Rectangle.width ~height:textBounds.Rectangle.height "" in
          (
            r#setX textBounds.Rectangle.x;
            r#setY textBounds.Rectangle.y;
            r#setHAlign `HAlignCenter; r#setVAlign `VAlignCenter;
            contents#addChild r;
            textField := Some r;
            r
          )
        | Some tf -> tf
        ];

      method setText text = 
        let tf = self#textField in
        tf#setText text;

      method setFontName fname =
        let tf = self#textField in
        tf#setFontName fname;

      method setFontColor color = 
        let tf = self#textField in
        tf#setColor color;

      method setFontSize size = 
        let tf = self#textField in
        tf#setFontSize size;

      method setTextBounds bounds = textBounds := bounds;

    end;



  value create = new c;

end;
