open LightCommon;

value floats = float_of_string;

module Make(D:DisplayObjectT.M with type evType = private [> DisplayObjectT.eventType | `ENTER_FRAME ] and type evData = private [> `PassedTime of float | DisplayObjectT.eventData ]) = struct

  module Image = Image.Make D;


  type keyFrame = 
    {
      region: Rectangle.t;
      hotpos: Point.t;
      textureID: int;
      texture: mutable option Texture.c;
    };

  type frame = 
    [ KeyFrame of keyFrame
    | Frame of int
    ];


  value parse_xml xmlpath = (*{{{*)
    let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
    let () = XmlParser.accept (`Dtd None) in
    let labels = Hashtbl.create 0 in
    let rec parse_textures result = 
      match XmlParser.parse_element "Texture" [ "path" ] with
      [ Some [ path ] _ -> parse_textures [ Texture.createFromFile path :: result ]
      | None -> result
      | _ -> assert False
      ]
    in
    let rec parse_frames i result = 
      match XmlParser.parse_element "Frame" [ "textureID"; "x"; "y"; "width"; "height"; "posX"; "posY" ] with
      [ Some [ textureID; x; y; width; height; posX; posY ] attributes -> 
        let frame = 
          {
            region = Rectangle.create (floats x) (floats y) (floats width) (floats height);
            hotpos = ((floats posX),(floats posY));
            textureID = int_of_string textureID;
            texture = None;
          }
        in
        (
          match XmlParser.get_attribute "label" attributes with
          [ Some label -> Hashtbl.add labels label i
          | None -> ()
          ];
          let result = [ KeyFrame frame :: result ] in
          let ni = ref (i + 1) in
          let result = 
            match XmlParser.get_attribute "duration" attributes with
            [ None -> result
            | Some duration -> 
                match int_of_string duration with
                [ 0 -> result
                | d -> (ni.val := !ni + d; (ExtList.List.make d (Frame i)) @ result)
                ]
            ]
          in
          parse_frames !ni result
        )
      | None -> result
      | _ -> assert False
      ]
    in
    let (textures,frames) = 
      match XmlParser.next () with
      [ `El_start ((_,"MovieClip"),attribues) ->
        (
          match XmlParser.next () with
          [ `El_start ((_,"Textures"),_) ->
            let textures = parse_textures [] in
            match XmlParser.next () with
            [ `El_start ((_,"Frames"),_) ->
              let frames = parse_frames 0 [] in
              (
                XmlParser.close ();
                (textures,frames)
              )
            | _ -> XmlParser.error "Frames not found"
            ]
          | _ -> XmlParser.error "Textures not found"
          ]
        )
      | _ -> XmlParser.error "MovieClip not found"
      ]
    in
    (List.rev textures,List.rev frames,labels);(*}}}*)

  class c ?(fps=10) xmlpath = 
    (* parse xml *)
    let (textures,frames,labels) = parse_xml xmlpath in
    let textures = Array.of_list textures and frames = Array.of_list frames in
    let first_frame = match frames.(0) with [ KeyFrame frame -> frame | Frame _ -> assert False ] in
    let first_texture = Texture.createSubTexture first_frame.region (textures.(first_frame.textureID)) in
    let () = first_frame.texture := Some first_texture in
  object(self)
    inherit Image.c first_texture as super;
    value mutable frameTime = 1. /. (float fps); 
    value textures = textures;
    value frames = frames;
    value labels = labels;
    value mutable currentFrameID = 0;
    value mutable hotpos: Point.t = first_frame.hotpos;
    method! x = x -. (fst hotpos);
    method! setX nx = super#setX (nx +. (fst hotpos));
    method! y = y -. (snd hotpos);
    method! setY ny = super#setX (ny +. (snd hotpos));
    method !pos = Point.subtractPoint (x,y) hotpos;
    method! setPos p = super#setPos (Point.addPoint p hotpos);
    value mutable loop = False;
    method loop = loop;
    method setLoop l = loop := l;
    value mutable fps = fps;
    value mutable elapsedTime = 0.;
    value mutable eventID = None;
    method fps = fps;
(*     method virtual setFps: int -> unit; *)
    method totalFrames = Array.length frames;
    method play () = eventID := Some (self#addEventListener `ENTER_FRAME self#onEnterFrame);
    method isPlaying = match eventID with [ None -> False | Some _ -> True ];
    initializer 
      (
        Printf.eprintf "frameTime: %F\n%!" frameTime;
        self#setPos (0.,0.);
        self#play ();
      );

    method stop () = 
    (
      Printf.eprintf "stop\n";
      match eventID with
      [ None -> ()
      | Some evID ->
        (
          prerr_endline "hey i'am stoped";
          elapsedTime := 0.;
          self#removeEventListener `ENTER_FRAME evID;
          eventID := None;
        )
      ]
    );

    method gotoAndStop () = ();
    method gotoAndPlay () = ();

    method private setCurrentFrame cf = 
      let () = Printf.eprintf "setCurrentFrame: %d\n%!" cf in
      (
        try
          let frame = 
            match frames.(cf) with
            [ KeyFrame frame ->  frame (* тады все просто *)
            | Frame i -> 
                if i = currentFrameID 
                then raise Exit
                else
                  match frames.(i) with 
                  [ KeyFrame frame -> frame 
                  | _ -> assert False 
                  ]
            ]
          in
          (
            match frame.texture with
            [ Some t -> self#setTexture t
            | None -> 
                let t = Texture.createSubTexture frame.region (textures.(frame.textureID)) in
                (
                  frame.texture := Some t;
                  self#setTexture t;
                )
            ];
            let pos = self#pos in
            (
              hotpos := frame.hotpos;
              self#setPos pos;
            )
          );
        with [ Exit -> () ];
        currentFrameID := cf;
      );

    method private onEnterFrame event _ = 
      match event.Event.data with
      [  `PassedTime dt ->
        (
          elapsedTime := elapsedTime +. dt;
          Printf.eprintf "elapsedTime: %F\n%!" elapsedTime;
          match int_of_float (elapsedTime /. frameTime) with
          [  0 -> ()
          | n -> 
            (
              Printf.eprintf "play %d frames\n%!" n;
              elapsedTime := elapsedTime -. ((float n) *. frameTime);
              let cFrame = currentFrameID + n in
              let currentFrame = 
                if cFrame >= (Array.length frames)
                then 
                (
                  match loop with
                  [ True -> cFrame - (Array.length frames)
                  | False -> 
                    (
                      self#stop();
                      (Array.length frames - 1);
                    )
                  ]
                )
                else cFrame
              in
              self#setCurrentFrame currentFrame
            )
          ]
        )
      | _ -> assert False
      ];

  end;

  value create = new c;

end;
