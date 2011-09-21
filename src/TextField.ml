open LightCommon;

module type S = sig
  module D: DisplayObjectT.M;
  class c :  [ ?fontName:string ] -> [ ?fontSize:int ] -> [ ?color:int ] -> [ ~width:float ] -> [ ~height:float ] -> [ string ] ->
  object
    inherit D.container;
    method setText: string -> unit;
    method setFontName: string -> unit;
    method setFontSize: option int -> unit;
    method setBorder: bool -> unit;
    method setColor: int -> unit;
    method setHAlign: LightCommon.halign -> unit;
    method setVAlign: LightCommon.valign -> unit;
    method textBounds: Rectangle.t;
  end;


  value create: ?fontName:string -> ?fontSize:int -> ?color:int -> ~width:float -> ~height:float -> string -> c;
end;

module Make(Quad:Quad.S)(FontCreator:BitmapFont.Creator with module CompiledSprite.Sprite.D = Quad.D) = struct

  module D = Quad.D;
  module BF = FontCreator;

  (* FIXME: make it more light -:) *)
  class c ?fontName ?fontSize ?color ~width ~height text = 
    let _fontName = Option.default "Helvetica" fontName in
    object(self)
      inherit Quad.D.container as super;

      value mutable fontSize = fontSize;
      value mutable color = Option.default color_black color;
      value mutable hAlign : halign = `HAlignCenter;
      value mutable vAlign : valign = `VAlignCenter;
      value mutable border = False;
      value mutable fontName = _fontName;
      value mutable text = text;
      value hitArea = Quad.create width height;
      value textArea = Quad.create width height;
      value mutable requiresRedraw = True;
      value mutable isRenderedText = not (BitmapFont.exists _fontName);
      value mutable contents = None;

      initializer 
      (
        hitArea#setAlpha 0.;
        self#addChild hitArea;
        textArea#setVisible False;
        self#addChild textArea;
      );

      method setText ntext = 
      (
        text := ntext;
        requiresRedraw := True;
      );

      method! setWidth nw = 
      (
        hitArea#setWidth nw;
        requiresRedraw := True;
      );

      method! setHeight nh = 
      (
        hitArea#setHeight nh;
        requiresRedraw := True
      );

      method setFontName fname = 
      (
        fontName := fname;
        requiresRedraw := True;
        isRenderedText := not (BitmapFont.exists fname);
      );

      method setFontSize size = 
      (
        fontSize := size;
        requiresRedraw := True;
      );


      method setBorder nb = 
        if nb <> border 
        then
        (
          border := nb;
          requiresRedraw := True;
        )
        else ();

      method setColor ncolor = 
        if ncolor <> color
        then
        (
          color := ncolor;
          (*
          if (mIsRenderedText)
              [(SPImage * )mContents setColor:color];
          else *)
              requiresRedraw := True;
        )
        else ();
        
      method setHAlign nha = 
        if nha <> hAlign
        then
          (
            hAlign := nha;
            requiresRedraw := True;
          )
        else ();
        
      method setVAlign nva = 
        if nva <> vAlign
        then
          (
            vAlign := nva;
            requiresRedraw := True;
          )
        else ();
          
      method private createRenderedContents () = failwith "Native fonts not supported yet";
      method private createComposedContents () =
        let bitmapFont = BitmapFont.get ?size:fontSize fontName in
        let contents = BF.createText bitmapFont ~width:hitArea#width ~height:hitArea#height ~color ~border ~hAlign ~vAlign text in
        let bounds = (contents#getChildAt 0)#bounds in
        (
          textArea#setX bounds.Rectangle.x; textArea#setY bounds.Rectangle.y;
          textArea#setWidth bounds.Rectangle.width; textArea#setHeight bounds.Rectangle.height;
          contents;
        );

      method private redrawContents () = 
        (
          match contents with
          [ Some c -> c#removeFromParent ()
          | None -> ()
          ];
          let contents' = 
              match isRenderedText with
              [ True -> self#createRenderedContents ()
              | False -> self#createComposedContents ()
              ]
          in
          (
            contents'#setTouchable False;
            self#addChild contents';
            contents := Some contents';
          );
          requiresRedraw := False;
        );

      method! private render' rect = 
      (
        if requiresRedraw then self#redrawContents () else ();
        super#render' rect;
      );

      method! renderPrepare () = if requiresRedraw then self#redrawContents () else ();

      method textBounds = 
      (
        if requiresRedraw then self#redrawContents () else ();
        textArea#boundsInSpace parent;
      );

      method! boundsInSpace targetCoordinateSpace = hitArea#boundsInSpace targetCoordinateSpace;

    end;


  value create = new c;

end;
