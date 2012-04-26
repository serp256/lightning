
value (|>) v f = f v;


value _atlas = ref None;
value atlas () = 
  match !_atlas with
  [ None -> 
    let r = TextureAtlas.load "ui/window.bin" in
    (
      _atlas.val := Some r;
      r
    )
  | Some r -> r
  ];

value bgcolor = 0xFCE2A9;
value hfcolor = 0xE4AA4E;

value hfheight = 50.;

class c ?(top=False) ?(bottom=False) width height = 
  let atlas = atlas () in
  let corner = TextureAtlas.atlasNode atlas "corner.png" ()
  and hborder = TextureAtlas.atlasNode atlas "hborder.png" ()
  and vborder = TextureAtlas.atlasNode atlas "vborder.png" ()
  in
  object(self)
    inherit Sprite.c;
    initializer begin
      let cw = AtlasNode.width corner
      and ch = AtlasNode.height corner
      and hbw = AtlasNode.width hborder
      and hbh = AtlasNode.height hborder
      and vbw = AtlasNode.width vborder
      and vbh = AtlasNode.height vborder
      in
      (
        let center = Quad.create ~color:bgcolor (width -. cw +. 1.) (height -. ch +. 1.) in
        (
          center#setPos (cw /. 2.)  (ch /. 2.);
          self#addChild center;
        );

        let border = Atlas.create (AtlasNode.texture corner) in
        (
          (* top left corner *)
          border#addChild corner; 

          (* top right corner *)
          border#addChild ((AtlasNode.setFlipX True corner) |> AtlasNode.setX (width -. cw));

          (* bottom left corner *)
          border#addChild  ((AtlasNode.setFlipY True corner) |> AtlasNode.setY (height -. ch));

          (* bottom right corner *)
          border#addChild  (AtlasNode.setFlipX True corner |> AtlasNode.setFlipY True |> AtlasNode.setPos (width -. cw) (height -. ch));


          let hborder = AtlasNode.setScaleX ((width -. 2. *. cw) /. hbw) hborder |> AtlasNode.setX cw in
          (
            (* top line *)
            border#addChild hborder;
            (* bottom line *)
            border#addChild (AtlasNode.setY (height -. hbh) hborder);
          );
          let vborder = AtlasNode.setScaleY ((height -. 2. *. ch) /. vbh) vborder |> AtlasNode.setY ch in
          (
            (* left line *)
            border#addChild vborder;
            (* right line *)
            border#addChild (AtlasNode.setX (width -. vbw) vborder);
          );

          if top || bottom
          then
            let hborder = AtlasNode.setScaleX ((width -. 2. *. vbw) /. hbw) hborder |> AtlasNode.setX vbw in
            (
              if top
              then 
              (
                border#addChild (AtlasNode.setY (hfheight -. hbh) hborder);
                let bg = Quad.create ~color:hfcolor (width -. cw +. 1.) (hfheight -. hbh) in
                (
                  bg#setPos (cw /. 2.)  (hbh /. 2.);
                  self#addChild bg;
                )
              )
              else ();
              if bottom
              then 
              (
                border#addChild (AtlasNode.setY (height -. hfheight) hborder);
                let bg = Quad.create ~color:hfcolor (width -. cw +. 1.) (hfheight -. hbh) in
                (
                  bg#setPos (cw /. 2.)  (height -. hfheight +. hbh /. 2.);
                  self#addChild bg;
                )
              )
              else ();
            )
          else ();
          self#addChild border;
        ); 
      )
    end;

  end;
