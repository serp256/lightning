
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

  class c  ?disabled ?downstate ?text upstate = 
    let width = upstate#width and height = upstate#height in
    object(self)
      inherit D.container;
      value upState:Texture.c = upstate;
      value disabledState:Texture.c = match disabled with [ None -> upstate | Some ds -> ds ];
      value downState:Texture.c = match downstate with [ None -> upstate | Some ds -> ds ];
      value contents = Sprite.create ();
      value background = Image.create upstate;
      value mutable textOffsetY = 0.0;
      value mutable textOffsetX = 0.0;
      value mutable fontColor = 0xffffff;
      value mutable disabledFontColor = 0x555555;
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
            match touchEvent.Ev.data with
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
                      self#dispatchEvent (Ev.create `TRIGGERED ());
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
        let tf = self#textField in (
          fontColor := color;
          if enabled then
            tf#setColor color
          else ();
        );

      method setDisabledFontColor color = 
        let tf = self#textField in (
          disabledFontColor := color;
          if not enabled then
            tf#setColor color
          else ();
        );


      method setFontSize size = 
        let tf = self#textField in
        tf#setFontSize size;


      method isEnabled = enabled;


      method setEnabled e = 
        match (enabled, e) with
        [ (True, True) | (False, False) -> ()
        | (True, False) -> 
          (
            enabled := False;
            background#setTexture disabledState;
            background#setColor (match disabled with [None -> 0xbbbbbb | _ -> 0xffffff]);
            let tf = self#textField in 
            tf#setColor disabledFontColor;
          )
          
        | (False, True) -> 
          (
            enabled := True;
            background#setTexture upState;
            background#setColor 0xffffff;
            let tf = self#textField in
            tf#setColor fontColor;
          )
        ];

      method setTextBounds bounds = textBounds := bounds;


      (* *)
      method setTextOffsetX offset = 
        let tf = self#textField in (
          tf#setX (tf#x -. textOffsetX +. offset);
          textOffsetX := offset;
        );
      

      (* *)
      method setTextOffsetY offset = 
        let tf = self#textField in (
          tf#setY (tf#y -. textOffsetY +. offset);
          textOffsetY := offset;
        );


    end;



  value create = new c;

end;
