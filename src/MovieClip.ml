open LightCommon;

value floats = float_of_string;

module Make
  (D:DisplayObjectT.M with type evType = private [> DisplayObjectT.eventType | `ENTER_FRAME ] and type evData = private [> `PassedTime of float | DisplayObjectT.eventData ]) 
  (Image: Image.S with module Q.D = D)
  
  = struct


  exception Frame_not_found;

  type frameID = [= `num of int | `label of string ];

  type keyFrame = 
    {
      region: Rectangle.t;
      hotpos: Point.t;
      textureID: int;
      label: option string;
      texture: mutable option Texture.c;
    };

  type frame = 
    [ KeyFrame of keyFrame
    | Frame of int
    ];

  type descriptor = (string * array Texture.c * array frame * Hashtbl.t string int);

  DEFINE FRAME_TO_STRING(f) = match f with [ `label l -> Printf.sprintf "label:%s" l | `num n -> Printf.sprintf "num: %d" n ];

  value load xmlpath : descriptor = (*{{{*)
    let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
    let () = XmlParser.accept (`Dtd None) in
    let labels = Hashtbl.create 0 in
    let rec parse_textures result = 
      match XmlParser.parse_element "Texture" [ "path" ] with
      [ Some [ path ] _ -> parse_textures [ Texture.load (Filename.concat (Filename.dirname xmlpath) path) :: result ]
      | None -> result
      | _ -> assert False
      ]
    in
    let rec parse_frames i result = 
      match XmlParser.parse_element "Frame" [ "textureID"; "x"; "y"; "width"; "height"; "posX"; "posY" ] with
      [ Some [ textureID; x; y; width; height; posX; posY ] attributes -> 
        let label =  XmlParser.get_attribute "label" attributes in
        let frame = 
          {
            region = Rectangle.create (floats x) (floats y) (floats width) (floats height);
            hotpos = ((floats posX),(floats posY));
            textureID = int_of_string textureID;
            label; texture = None;
          }
        in
        (
          match frame.label with
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
    let textures = Array.of_list (List.rev textures) in
    let frames = Array.of_list (List.rev frames) in
    (
      let first_frame = match frames.(0) with [ KeyFrame frame -> frame | Frame _ -> assert False ] in
      let first_texture = Texture.createSubTexture first_frame.region (textures.(first_frame.textureID)) in
      first_frame.texture := Some first_texture;
      debug "[%s] cntFrames: %d, labels: %s" xmlpath (Array.length frames) (String.concat ";" (Hashtbl.fold (fun label frame res -> [ (Printf.sprintf "%s: %d" label frame) :: res ]) labels []));
      (xmlpath,textures,frames,labels)
    );(*}}}*)

  class c ?(fps=10) (clipname,textures,frames,labels) = 
    let first_frame = match frames.(0) with [ KeyFrame frame -> frame | Frame _ -> assert False ] in
    let first_texture = Option.get first_frame.texture in
    let framesLength = Array.length frames in
  object(self)
    inherit Image.c first_texture as super;
    value mutable frameTime = 1. /. (float fps); 
    value mutable currentFrameID = 0;
    method currentFrame = currentFrameID;
    method currentFrameLabel = 
      match frames.(currentFrameID) with
      [ KeyFrame frame -> frame.label
      | _ -> None
      ];
    value mutable loop = False;
    method loop = loop;
    method setLoop l = loop := l;
    value mutable startFrame = 0;
    value mutable endFrame = framesLength - 1;
    value mutable fps = fps;
    value mutable elapsedTime = 0.;
    value mutable eventID = None;
    method fps = fps;
(*     method virtual setFps: int -> unit; *)
    method totalFrames = framesLength;
    method play () = 
      match eventID with 
      [ None -> 
        (
          startFrame := 0;
          endFrame := framesLength - 1;
          elapsedTime := ~-.1.;
          eventID := Some (self#addEventListener `ENTER_FRAME self#onEnterFrame)
        )
      | _ -> ()
      ];

    method isPlaying = match eventID with [ None -> False | Some _ -> True ];
    initializer self#setTransformPoint first_frame.hotpos;

    method stop () = 
    (
      match eventID with
      [ None -> ()
      | Some evID ->
        (
          elapsedTime := 0.;
          self#removeEventListener `ENTER_FRAME evID;
          eventID := None;
        )
      ]
    );

    method private resolveFrame = fun
      [ `label label -> try Hashtbl.find labels label with [ Not_found -> raise Frame_not_found ]
      | `num n when n >= 0 && n < Array.length frames -> n
      | _ -> raise Frame_not_found
      ];

    method private changeFrame f = 
      let cf = self#resolveFrame f in
      self#setCurrentFrame cf;

    method gotoAndStop (f:frameID) =
    (
      debug "[%s] gotoAndStop: %s" clipname (FRAME_TO_STRING(f));
      self#changeFrame f;
      self#stop();
    );

    method gotoAndPlay (f:frameID) = 
    (
      debug "[%s] gotoAndPlay: %s" clipname (FRAME_TO_STRING(f));
      self#changeFrame f;
      self#play(); (* FIXME: we need skip current rendering *)
    );

    method playRange f1 f2 = 
    (
      debug "[%s] playRange '%s' to '%s'" clipname (FRAME_TO_STRING(f1)) (FRAME_TO_STRING(f2));
      let sf = self#resolveFrame f1 in
      (
        startFrame := sf;
        self#setCurrentFrame sf;
      );
      endFrame := self#resolveFrame f2;
      if (endFrame < startFrame) then failwith("Incorrect range") else ();
      elapsedTime := ~-.1.;
      match eventID with 
      [ None -> eventID := Some (self#addEventListener `ENTER_FRAME self#onEnterFrame)
      | _ -> ()
      ];
    );

    method private setCurrentFrame cf = 
      let () = debug "Clip: [%s] - setCurrentFrame: %d" clipname cf in
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
            self#setTransformPoint frame.hotpos;
          );
        with [ Exit -> () ];
        currentFrameID := cf;
      );

    method private onEnterFrame event _ = 
      let () = debug "onEnterFrame: [%s], currentFrame: %d" clipname currentFrameID in
      if elapsedTime = ~-.1. then elapsedTime := 0.
      else
        match event.Event.data with
        [  `PassedTime dt ->
          (
            elapsedTime := elapsedTime +. dt;
            match int_of_float (elapsedTime /. frameTime) with
            [  0 -> ()
            | n -> 
              (
                elapsedTime := elapsedTime -. ((float n) *. frameTime);
                let cFrame = currentFrameID + n in
                let currentFrame = 
                  if cFrame > endFrame
                  then 
                  (
                    match loop with
                    [ True -> 
                      let len = endFrame - startFrame in
                      let num = cFrame / len in
                      startFrame + (cFrame - (num * len))
                    | False -> 
                      (
                        self#stop();
                        endFrame
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
