open LightCommon;

open ExtList;





module Make(Image:Image.S)(Atlas:Atlas.S with module D = Image.D)(Sprite:Sprite.S with module D = Image.D) = struct

exception Frame_not_found;

value default_fps = ref 20;
value set_default_fps f = default_fps.val := f;

module DisplayObject = Image.D;

type frameID = [= `num of int | `label of string ];

type cFrame 'keyframe = 
  [ KeyFrame of (option string * 'keyframe)
  | Frame of int
  ];

type direction = 
  [= `forward
  | `backward
  ];

DEFINE FRAME_TO_STRING(f) = match f with [ `label l -> Printf.sprintf "label:%s" l | `num n -> Printf.sprintf "num: %d" n ];
   
type labels = Hashtbl.t string int;
exception Same_frame;


class type virtual movie = 
  object
    inherit DisplayObject.c;
    method loop: bool;
    method setLoop: bool -> unit;
    method fps: int;
    method currentFrame: int;
    method currentFrameLabel: option string;
    method totalFrames: int;
    method playDirection: direction;
    method setPlayDirection: direction -> unit;
    method play: ?onChangeFrame:(unit->unit) -> ?onComplete:(unit -> unit) -> ?direction:direction -> unit -> unit;
    method isPlaying: bool;
    method stop: unit -> unit;
    method gotoAndPlay: ?onComplete:(unit -> unit) -> frameID -> unit;
    method gotoAndStop: frameID -> unit;
    method playRange: ?onChangeFrame:(unit->unit) -> ?onComplete:(unit -> unit) ->  ?direction:direction -> frameID -> frameID -> unit;
    method resolveFrame: frameID -> int;
  end;


value memo : WeakMemo.c movie = new WeakMemo.c 1;

value cast: #DisplayObject.c -> option movie = fun x -> try Some (memo#find x) with [ Not_found -> None ];

type clip_cast = [= `Image of Image.c | `Sprite of Sprite.c | `Atlas of Atlas.c | `Movie of movie ];

class virtual base ['frame] ?(fps=default_fps.val) ~frames:(frames:array (cFrame 'frame)) ~labels =  (*{{{*)
(*     let first_frame = match frames.(0) with [ KeyFrame frame -> frame | Frame _ -> assert False ] in *)
  let framesLength = Array.length frames in
object(self)
  inherit DisplayObject.c as super;
  value mutable frameTime = 1. /. (float fps); 
  value mutable currentFrameID = 0;
  method clip_cast : clip_cast = `Movie (self :> movie);
  method currentFrame = currentFrameID;
  method currentFrameLabel = 
    match frames.(currentFrameID) with
    [ KeyFrame label frame -> label
    | _ -> None
    ];
  value mutable loop = True;
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
  value mutable completeHandler = None;
  value mutable changeHandler = None;
  value mutable playDirection = `forward;

  method playDirection = playDirection;
  method setPlayDirection direction = playDirection := direction; 

  method play ?onChangeFrame ?onComplete ?(direction:direction=`forward) () = 
  (
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
    playDirection := direction;
    completeHandler := onComplete;
    changeHandler := onChangeFrame;
  );

  method isPlaying = match eventID with [ None -> False | Some _ -> True ];

  method stop () = 
  (
    match eventID with
    [ None -> ()
    | Some evID ->
      (
        elapsedTime := 0.;
        self#removeEventListener `ENTER_FRAME evID;
        eventID := None;
        changeHandler := None;
        completeHandler := None;
      )
    ];
  );

  method resolveFrame = fun
    [ `label label -> 
        try 
          (
            debug:quest "try resolve frame with label %s" label;
            Hashtbl.find labels label 
          )
        with 
          [ Not_found -> 
              (
                debug:quest "Not_found frame %s" label;
                raise Frame_not_found ;
              )
          ]
    | `num n when n >= 0 && n < Array.length frames -> 
        (
          debug:quest "Num %d" n;
          n
        )
    | `num n ->
        (
          debug:quest "Not found frame %d";
          raise Frame_not_found
        )
    ];

  method private changeFrame f = 
    let cf = self#resolveFrame f in
    self#setCurrentFrame cf;

  method gotoAndStop (f:frameID) =
  (
    debug:quest "gotoAndStop: %s" (match f with [ `label label -> label | `num n -> string_of_int n ]);
    self#changeFrame f;
    self#stop();
  );

  method gotoAndPlay ?onComplete (f:frameID) = 
  (
    self#changeFrame f;
    self#play ?onComplete (); 
  );

  method playRange ?onChangeFrame ?onComplete ?(direction=`forward) f1 f2 = 
  (
(*       debug "[%s] playRange '%s' to '%s'" clipname (FRAME_TO_STRING(f1)) (FRAME_TO_STRING(f2)); *)
    startFrame := self#resolveFrame f1;
    endFrame := self#resolveFrame f2;
    match direction with 
    [ `forward -> self#setCurrentFrame startFrame
    | `backward -> self#setCurrentFrame endFrame
    ];
    if (endFrame < startFrame) then failwith("Incorrect range") else ();
    elapsedTime := ~-.1.;
    match eventID with 
    [ None -> eventID := Some (self#addEventListener `ENTER_FRAME self#onEnterFrame)
    | _ -> ()
    ];
    changeHandler := onChangeFrame;
    completeHandler := onComplete;
    playDirection := direction;
  );

  method private virtual applyFrame: int -> 'frame -> unit;

  method private setCurrentFrame cf = 
  (
    debug:quest "setCurrentFrame: [%d]" cf;
    try
      let frame = 
        match frames.(cf) with
        [ KeyFrame _ frame ->  frame (* тады все просто *)
        | Frame i -> 
            if i = currentFrameID 
            then raise Same_frame
            else
              match frames.(i) with 
              [ KeyFrame _ frame -> frame 
              | _ -> assert False 
              ]
        ]
      in
      self#applyFrame cf frame
    with [ Same_frame -> () ];
    currentFrameID := cf;
  );

  method private onEnterFrame event _ _ = 
    if elapsedTime = ~-.1. then elapsedTime := 0.
    else
      match event.Ev.data with
      [  `PassedTime dt ->
        (
          elapsedTime := elapsedTime +. dt;
          match int_of_float (elapsedTime /. frameTime) with
          [  0 -> ()
          | n -> 
            (
              elapsedTime := elapsedTime -. ((float n) *. frameTime);
              let (currentFrame,complete) = 
                match playDirection with
                [ `forward -> 
                    let cFrame = currentFrameID + n in
                    if cFrame > endFrame
                    then 
                    (
                      match loop with
                      [ True -> 
                        let len = endFrame - startFrame + 1 in
                        (startFrame + ((cFrame - endFrame -1) mod len),False)
                      | False -> (endFrame,True)
                      ]
                    )
                    else (cFrame,False)
                | _ -> 
                    let cFrame = currentFrameID - n in
                    if cFrame < startFrame
                    then 
                    (
                      match loop with
                      [ True -> 
                        let len = endFrame - startFrame + 1 in
                        (endFrame - ((startFrame - cFrame -1) mod len),False)
                      | False -> (startFrame,True)
                      ]
                    )
                    else (cFrame,False)
                ]
              in
              (
                self#setCurrentFrame currentFrame;
                match changeHandler with
                [ Some ch -> ch ()
                | _ -> ()
                ];
                if complete then 
                  let cf = completeHandler in
                  (
                    self#stop(); 
                    match cf with
                    [ None -> ()
                    | Some ch -> ch()
                    ]
                  )
                else ();
              )
            )
          ]
        )
      | _ -> assert False
      ];
  initializer (memo#add (self :> movie); self#play());
end; (*}}}*)


type imageKeyFrame = 
  {
    hotpos: Point.t;
    image: (int * Rectangle.t);
(*     texture: mutable option Texture.c; (* cache *) *)
  };


type imageFrame = cFrame imageKeyFrame;

type img = (int * Rectangle.t);
type child = (Rectangle.t * option string * Point.t); 
type children = list child;
type bchildren = [ CBox of (string * Point.t) | CImage of (img * option string * Point.t) | CAtlas of (int * list child) ];
type clipcmd = [ ClpPlace of (int * Rectangle.t * option string * Point.t) | ClpClear of (int * int) | ClpChange of (int * list [= `posX of float | `posY of float | `move of int]) ];
type frame = (children * option (list clipcmd)); (* наверное все-таки оставить список всех чтобы можно было на любой кадр ебошить и в любой последовательности играть - хотя это сцука память будет поджираться *)
type element = 
  [ Image of img
  | Sprite of list bchildren
  | Atlas of (int * list child)
  | Clip of (int * (array (cFrame frame)) * labels)
  | ImageClip of (array imageFrame * labels)
  ];

type lib = 
  {
    path: string;
    textures: [= `files of array string | `textures of array Texture.c ]; (* либо array текстур, либо строки нах *)
    symbols: Hashtbl.t string element
  };

value getTexture lib tid =
  match lib.textures with
  [ `files files -> Texture.load (Filename.concat lib.path files.(tid))
  | `textures textures -> textures.(tid)
  ];

value getTextureAsync lib tid callback =
  match lib.textures with
  [ `files files -> Texture.load_async (Filename.concat lib.path files.(tid)) callback
  | `textures textures -> callback textures.(tid)
  ];

value getSubTexture lib (tid,rect) =
  let t = 
    match lib.textures with
    [ `files files -> Texture.load (Filename.concat lib.path files.(tid))
    | `textures textures -> textures.(tid)
    ]
  in
  t#subTexture rect;

value getSubTextureAsync lib (tid,rect) callback =
  let f texture = callback (texture#subTexture rect) in
  match lib.textures with
  [ `files files -> Texture.load_async (Filename.concat lib.path files.(tid)) f
  | `textures textures -> f textures.(tid)
  ];

value image_clip ?fps ~lib ~frames ~labels () =
  let first_frame = match frames.(0) with [ KeyFrame _ frame -> frame | Frame _ -> assert False ] in
  let first_texture = getSubTexture lib first_frame.image in
  object(self)
    inherit base [ imageKeyFrame ] ?fps ~frames ~labels;
    inherit Image.c first_texture;

    method applyFrame _ frame = 
    (
      debug:quest "ic:applyFrame %d %s" (fst frame.image) (Rectangle.to_string (snd frame.image));
      (* TODO: cache subtextures for frames *)
      self#setTexture (getSubTexture lib frame.image);
      self#setTransformPoint frame.hotpos;
    );

  end;

value image_clip_async ?fps ~lib ~frames ~labels callback =
  let first_frame = match frames.(0) with [ KeyFrame _ frame -> frame | Frame _ -> assert False ] in
  getSubTextureAsync lib first_frame.image begin fun first_texture ->
    let obj = 
      object(self)
        inherit base [ imageKeyFrame ] ?fps ~frames ~labels;
        inherit Image.c first_texture;

        method applyFrame _ frame = 
        (
          debug:quest "ic:applyFrame %d %s" (fst frame.image) (Rectangle.to_string (snd frame.image));
          (* TODO: cache subtextures for frames *)
          self#setTexture (getSubTexture lib frame.image);
          self#setTransformPoint frame.hotpos;
        );
      end
    in
    callback obj
  end;



class clip texture frames labels = 
  object(self)
    inherit base [ frame ]  frames labels;
    inherit Atlas.c texture;
    method private applyChildren children =
    (
      debug "apply children";
      self#clearChildren();
   (*   let i = ref 0. in*)
      List.iter begin fun (rect,name,pos) ->
        let () = debug:quest "name:%s; img:( %d, %s) " (match name with [ Some name -> name | _ -> "None" ]) (fst img) (Rectangle.to_string (snd img)) in
        let el = AtlasNode.create texture rect ~pos () in
        (
(*           el#setPosPoint pos; *)
          (*
          el#setX (el#x +. !i *. 150.); 
          i.val := !i +. 1.; 
          *)
(*           match name with [ Some name -> el#setName name | None -> ()]; *)
          self#addChild el
        )
      end children;
    );

    method applyFrame frameid (children,cmds) =
    (
      debug:quest "clip:applyFrame %d" frameid;
      debug "apply frame";
      match cmds with
      [ Some cmds when frameid = currentFrameID + 1 -> (* FIXME: здесь бы усложнить проверку, не обязательно -1 главно чтобы KeyFrame был предыдущий - но пока не придумал как это проверить нормально *)
        let () = debug "apply cmds" in
        List.iter begin fun 
          [ ClpPlace idx rect name pos ->
            let () = debug "place img at %d" idx in
            let el = AtlasNode.create texture rect ~pos () in
            (
(*               el#setPosPoint pos; *)
(*               match name with [ Some name -> el#setName name | None -> ()]; *)
              self#addChild ~index:idx el
            )
          | ClpChange idx changes -> 
              let () = debug "change %d" idx in
              let child = self#getChildAt idx in
              ignore begin
                List.fold_left begin fun (idx,child) -> fun
                  [ `move z -> (debug "change z to %d" z; self#setChildIndex idx z; (z,child))
                  | `posX x -> 
                      let () = debug "set pos x to %f" x in
                      let child = AtlasNode.setX x child in
                      (
                        self#updateChild idx child; 
                        (idx,child)
                      )
                  | `posY y -> 
                      let () = debug "set pos y to %f" y in
                      let child = AtlasNode.setY y child in
                      (
                        self#updateChild idx child; 
                        (idx,child)
                      )
                  ]
                end (idx,child) changes
              end
            (*
              let el = self#getChildAt idx in
              (
                List.iter begin fun
                  [ `move z -> (* FIXME: setChildIndex *)
                    (
                      self#removeChild el;
                      self#addChild ~index:z el;
                    )
                  | `posX x -> el#setX x
                  | `posY y -> el#setY y
                  ]
                end changes
              )
            *)
          | ClpClear (from,count) -> 
              let () = debug "clear %d-%d" from count in
              for i = 0 to count - 1 do
                ignore(self#removeChild from)
              done
          ]
        end cmds
      | _ -> self#applyChildren children
      ]
    );
    initializer self#applyFrame 0 (match frames.(0) with [ KeyFrame _ f -> f | _ -> assert False ]);
  end;


class image texture = 
  object(self)
    inherit Image.c texture;
    method clip_cast : clip_cast = `Image (self :> Image.c);
  end;

class sprite = 
  object(self)
    inherit Sprite.c;
    method clip_cast : clip_cast = `Sprite (self :> Sprite.c);
  end;

class type virtual c = 
  object
    inherit Image.D.c;
    method clip_cast: clip_cast;
  end;

value image path = 
  let texture = Texture.load path in
  let res = new image texture in
  (res :> c);

value image_async path callback = 
  Texture.load_async path begin fun texture ->
    let res = new image texture in
    callback (res :> c)
  end;

value create_element lib = fun
  [ Image img -> 
    let res = new image (getSubTexture lib img) in
    (res :> c)
  | Sprite elements -> 
      let sprite = new sprite in
      (
        List.iter begin fun 
          [ CImage img name pos ->
            let el = Image.create (getSubTexture lib img) in
            (
              el#setPosPoint pos;
              match name with [ Some name -> el#setName name | None -> ()];
              sprite#addChild el
            )
          | CAtlas tid els ->
              let texture = getTexture lib tid in
              let atlas = Atlas.create texture in
              (
                List.iter begin fun (rect,name,pos) ->
                  let node = AtlasNode.create texture rect ~pos () in
                  atlas#addChild node
                end els;
                sprite#addChild atlas;
              )
          | CBox name pos ->
              let box = Sprite.create () in
              (
                box#setName name;
                box#setPosPoint pos;
                sprite#addChild box
              )
          ]
        end elements;
        (sprite :> c)
      )
  | Atlas tid children ->
      let texture = getTexture lib tid in
      let atlas = 
        object(self)
          inherit Atlas.c texture;
          method clip_cast: clip_cast = `Atlas (self :> Atlas.c);
        end
      in
      (
        List.iter begin fun (rect,name,pos) ->
          let node = AtlasNode.create texture rect ~pos () in
          atlas#addChild node
        end children;
        (atlas :> c)
      )
  | ImageClip frames labels -> ((image_clip ~lib ~frames ~labels ()) :> c)
  | Clip tid frames labels -> 
      let res = new clip (getTexture lib tid) frames labels in
      (res :> c)
  ]
;

value create_element_async lib symbol callback = 
  match symbol with
  [ Image img -> 
    getSubTextureAsync lib img begin fun texture ->
      let res = new image texture in
      callback (res :> c)
    end
  | Sprite elements -> 
      let sprite = new sprite in
      (
        let cnt = ref (List.length elements) in
        (
          List.iteri begin fun i -> fun
            [ CImage img name pos ->
              getSubTextureAsync lib img begin fun texture ->
                let el = Image.create texture in
                (
                  el#setPosPoint pos;
                  match name with [ Some name -> el#setName name | None -> ()];
                  if i < sprite#numChildren
                  then sprite#addChild ~index:i el
                  else sprite#addChild el;
                  decr cnt;
                  if cnt.val = 0 then callback (sprite :> c) else ()
                )
              end
            | CAtlas tid els ->
                getTextureAsync lib tid begin fun texture ->
                  let atlas = Atlas.create texture in
                  (
                    List.iter begin fun (rect,name,pos) ->
                      let node = AtlasNode.create texture rect ~pos () in
                      atlas#addChild node
                    end els;
                    if i < sprite#numChildren
                    then sprite#addChild ~index:i atlas
                    else sprite#addChild atlas;
                    decr cnt;
                    if cnt.val = 0 then callback (sprite :> c) else ()
                  )
                end
            | CBox name pos ->
                let box = Sprite.create () in
                (
                  box#setName name;
                  box#setPosPoint pos;
                  sprite#addChild box;
                  decr cnt;
                )
            ]
          end elements;
          if !cnt = 0 then callback (sprite :> c) else ();
        )
      )
  | Atlas tid children ->
      getTextureAsync lib tid begin fun texture ->
        let atlas = 
          object(self)
            inherit Atlas.c texture;
            method clip_cast: clip_cast = `Atlas (self :> Atlas.c);
          end
        in
        (
          List.iter begin fun (rect,name,pos) ->
            let node = AtlasNode.create texture rect ~pos () in
            atlas#addChild node
          end children;
          callback (atlas :> c)
        )
      end
  | ImageClip frames labels -> image_clip_async ~lib ~frames ~labels (fun ic -> callback (ic :> c))
  | Clip tid frames labels -> 
      getTextureAsync lib tid begin fun texture ->
        let res = new clip texture frames labels in
        callback (res :> c)
      end
  ]
;


exception Symbol_not_found of string;
value get_symbol lib cls =
  let symbol = try Hashtbl.find lib.symbols cls with [ Not_found -> raise (Symbol_not_found cls) ] in
  create_element lib symbol;

value get_symbol_async lib cls callback = 
  let symbol = try Hashtbl.find lib.symbols cls with [ Not_found -> raise (Symbol_not_found cls) ] in
  create_element_async lib symbol callback;

value symbols lib = ExtHashtbl.Hashtbl.keys lib.symbols;


(* бинарный формат нахуй *)
value _load libpath = 
  let () = debug "bin load %s" libpath in
  let path = Filename.concat libpath "lib.bin" in
  let inp = open_resource path 1. in
  let bininp = IO.input_channel inp in
  (
    let read_option_string () =
      let len = IO.read_byte bininp in
      match len with
      [ 0 -> None
      | _ -> Some (IO.nread bininp len)
      ]
    in
    let n_textures = IO.read_ui16 bininp in
    let textures = Array.init n_textures (fun _ -> IO.read_string bininp) in
    let n_items = IO.read_ui16 bininp in
    let items = Hashtbl.create n_items in
    (
      let read_children () = (*{{{*)
        let n_children = IO.read_byte bininp in
        let tid = ref 0 in
        let children = 
          List.init n_children begin fun _ ->
            let id = IO.read_ui16 bininp in
            let posx = IO.read_double bininp in
            let posy = IO.read_double bininp in
            let name = read_option_string () in
            match Hashtbl.find items id with
            [ Image (tid',rect) -> 
              (
                tid.val := tid';
                (rect,name,{Point.x = posx; y = posy})
              )
            | _ -> failwith "sprite children not an image"
            ]
          end 
        in
        (!tid,children) (*}}}*)
      and read_sprite_children () = (*{{{*)
        let n_children = IO.read_byte bininp in
        List.init n_children begin fun _ ->
          match IO.read_byte bininp with
          [ 0 ->
            let id = IO.read_ui16 bininp in
            let posx = IO.read_double bininp in
            let posy = IO.read_double bininp in
            let name = read_option_string () in
            match Hashtbl.find items id with
            [ Image img -> CImage (img,name,{Point.x = posx; y = posy})
            | _ -> failwith "sprite children not an image"
            ]
          | 1 -> (* atlas *)
            let cnt = IO.read_byte bininp in
            let tid = ref 0 in
            let children = 
              List.init cnt begin fun _ ->
                let id = IO.read_ui16 bininp in
                let posx = IO.read_double bininp in
                let posy = IO.read_double bininp in
                let name = read_option_string () in
                match Hashtbl.find items id with
                [ Image (tid',rect) -> 
                  (
                    tid.val := tid';
                    (rect,name,{Point.x = posx; y = posy})
                  )
                | _ -> failwith "sprite children not an image"
                ]
              end 
            in
            (CAtlas !tid children)
          | 2 -> (* box *)
            let posx = IO.read_double bininp in
            let posy = IO.read_double bininp in
            let name = IO.read_string bininp in
            CBox (name,{Point.x=posx;y=posy})
          | _ -> assert False
          ]
        end (*}}}*)
      in
      for i = 0 to n_items - 1 do (*{{{*)
        let id = IO.read_ui16 bininp in
        let kind = IO.read_byte bininp in
        let () = debug "bin read %d:%d" id kind in
        match kind with
        [ 0 -> (* image *)
            let page = IO.read_ui16 bininp in
            let x = IO.read_ui16 bininp in
            let y = IO.read_ui16 bininp in
            let width = IO.read_ui16 bininp in
            let height = IO.read_ui16 bininp in
            Hashtbl.add items id (Image (page,Rectangle.create (float x) (float y) (float width) (float height)))
        | 1 -> (* sprite *)
            let children = read_sprite_children () in
            let el = 
              match children with
              [ [ CAtlas tid children ] -> Atlas tid children
              | _ -> Sprite children
              ]
            in
            Hashtbl.add items id el
        | 2 -> (* image clip *)
            let n_frames = IO.read_ui16 bininp in
            let labels = Hashtbl.create 0 in
            let frames = DynArray.create () in
            (
              for i = 0 to n_frames - 1 do
                let duration = IO.read_byte bininp in
                let label = read_option_string () in
                let imgid = IO.read_ui16 bininp in
                let x = IO.read_double bininp in
                let y = IO.read_double bininp in
                match Hashtbl.find items imgid with
                [ Image image -> 
                  (
                    DynArray.add frames (KeyFrame (label,{image;hotpos={Point.x;y}}));
                    let i = DynArray.length frames - 1 in
                    (
                      match label with
                      [ Some l -> Hashtbl.add labels l i
                      | None -> ()
                      ];
                      for j = 1 to duration - 1 do
                        DynArray.add frames (Frame i);
                      done;
                    )
                  )
                | _ -> failwith "clip children not an image"
                ]
              done;
              Hashtbl.add items id (ImageClip ((DynArray.to_array frames),labels));
            )
        | 3 -> (* clip *)
            let n_frames = IO.read_ui16 bininp in
            let labels = Hashtbl.create 0 in
            let frames = DynArray.create () in
            let tid = ref 0 in
            (
              for i = 0 to n_frames - 1 do
                let duration = IO.read_byte bininp in
                let label = read_option_string () in
                let (tid',children) = read_children () in
                let () = tid.val := tid' in
                let commands = 
                  match IO.read_byte bininp with
                  [ 0 -> None
                  | _ -> 
                      let n_commands = IO.read_ui16 bininp in
                      let commands = 
                        List.init n_commands begin fun _ ->
                          match IO.read_byte bininp with
                          [ 0 -> (* place *)
                            let idx = IO.read_ui16 bininp in
                            let id = IO.read_ui16 bininp in
                            let name = read_option_string () in
                            let posx = IO.read_double bininp in
                            let posy = IO.read_double bininp in
                            match Hashtbl.find items id with
                            [ Image (_,rect) -> ClpPlace (idx,rect,name,{Point.x = posx; y = posy})
                            | _ -> failwith "frame element not an image"
                            ]
                          | 1 -> (* clear *)
                              let from = IO.read_ui16 bininp in
                              let count = IO.read_ui16 bininp in
                              ClpClear from count
                          | 2 ->  (* change *)
                              let idx = IO.read_ui16 bininp in
                              let n_changes = IO.read_byte bininp in
                              let changes = 
                                List.init n_changes begin fun _ ->
                                  match IO.read_byte bininp with
                                  [ 0 -> (* move *) `move (IO.read_ui16 bininp)
                                  | 1 -> (* posx *) `posX (IO.read_double bininp)
                                  | 2 -> (* posy *) `posY (IO.read_double bininp)
                                  | _ -> failwith "unknown clip change command"
                                  ]
                                end
                              in
                              ClpChange idx changes
                          | _ -> failwith "unknown clip command"
                          ]
                        end
                      in
                      Some commands
                  ]
                in
                (
                  DynArray.add frames (KeyFrame (label,(children,commands)));
                  let i = DynArray.length frames - 1 in
                  (
                    match label with
                    [ Some l -> Hashtbl.add labels l i
                    | None -> ()
                    ];
                    for j = 1 to duration - 1 do
                      DynArray.add frames (Frame i);
                    done;
                  )
                )
              done;
              Hashtbl.add items id (Clip !tid (DynArray.to_array frames) labels);
            )
        | n -> failwith (Printf.sprintf "unkonwn el type %d" n)
        ]
      done; (*}}}*)
      let n_symbols = IO.read_ui16 bininp in
      let symbols = Hashtbl.create n_symbols in
      (
        for i = 0 to n_symbols - 1 do
          let cls = IO.read_string bininp in
          let id = IO.read_ui16 bininp in
          let () = debug "%s" cls in
          Hashtbl.add symbols cls (Hashtbl.find items id);
        done;
        IO.close_in bininp;
        (textures,symbols);
      );
    );
  );



value load ?(loadTextures=False) libpath : lib = 
  let (textures,symbols) = _load libpath in
  let textures = 
    match loadTextures with
    [ True -> `textures (Array.map (fun file -> Texture.load (Filename.concat libpath file)) textures)
    | False -> `files textures
    ]
  in
  {path=libpath;textures;symbols}
;


value load_async libpath callback = 
  let (texture_files,symbols) = _load libpath in
  let cnt_tx = ref (Array.length texture_files) in
  let textures = Array.make !cnt_tx Texture.zero in
  (
    Array.iteri begin fun i file ->
      Texture.load_async (Filename.concat libpath file) begin fun texture ->
        (
          textures.(i) := texture;
          decr cnt_tx;
          if !cnt_tx = 0 then callback {path=libpath;textures=(`textures textures);symbols} else ();
        )
      end 
    end texture_files;
    if !cnt_tx = 0 then callback {path=libpath;textures=(`textures textures);symbols} else ();
  );

value loadxml ?(loadTextures=False) libpath : lib = 
  let module XmlParser = MakeXmlParser (struct value path = Filename.concat libpath "lib.xml"; end) in
  (
    XmlParser.accept (`Dtd None);
    let floats = XmlParser.floats
    and ints = int_of_string in
    match XmlParser.next () with
    [ `El_start (("","lib"),_) ->
      (* parse textures *)
      let parse_textures () = (*{{{*)
        match XmlParser.next () with
        [ `El_start (("","textures"),_) ->
          let rec loop res = 
            match XmlParser.parse_element "texture" ["file"] with
            [ Some [ file ] _ -> loop [ file :: res ]
            | None -> res
            | _ -> assert False
            ]
          in
          let textures = loop [] in
          Array.of_list (List.rev textures)
        | _ -> XmlParser.error "textures not found"
        ]
      in (*}}}*)
      let parse_items () = (*{{{*)
        match XmlParser.next () with
        [ `El_start (("","items"),_) ->
          let items = Hashtbl.create 11 in
          let add_frames attributes i frames = 
            let duration = XmlParser.get_attribute "duration" attributes in
            match duration with
            [ Some n ->
              let n = ints n in
              for j = 1 to n - 1 do
                DynArray.add frames (Frame i);
              done
            | None -> ()
            ]
          in
          let rec parse_children tid res = 
            match XmlParser.parse_element "child" [ "id"; "posX"; "posY"] with
            [ Some [ id;posX;posY ] attributes -> 
              match Hashtbl.find items (ints id) with
              [ Image (tid',rect) ->
                let name = XmlParser.get_attribute "name" attributes in
                parse_children tid' [ (rect , name , {Point.x = floats posX; y = floats posY}) :: res ]
              | _ -> XmlParser.error "sprite children must be image"
              ]
            | None -> (tid,List.rev res)
            | _ -> assert False
            ]
          in
          let rec parse_sprite_children_next res = 
            (
              XmlParser.accept `El_end;
              parse_sprite_children res;
            )
          and parse_sprite_children res = 
            match XmlParser.next () with
            [ `El_start (("",c),attributes) ->
              match c with
              [ "child" ->
                match XmlParser.get_attributes "child" [ "id"; "posX"; "posY"] attributes with
                [ [id;posx;posy] ->
                    match Hashtbl.find items (ints id) with
                    [ Image img ->
                      let name = XmlParser.get_attribute "name" attributes in
                      parse_sprite_children_next [ CImage (img , name , {Point.x = floats posx; y = floats posy}) :: res ]
                    | _ -> XmlParser.error "sprite children must be image"
                    ]
                | _ -> assert False
                ]
              | "box" ->
                  match XmlParser.get_attributes "box" [ "name"; "posX"; "posY"] attributes with
                  [ [ name;posx;posy] -> parse_sprite_children_next [ CBox (name,{Point.x=floats posx;y=floats posy}) :: res ]
                  | _ -> assert False
                  ]
              | "atlas" ->
                  let texture_id = ref None in
                  let rec parse_atlas res =
                    match XmlParser.parse_element "child" [ "id"; "posX"; "posY" ] with
                    [ Some ([ id;posx;posy],_) ->
                      match Hashtbl.find items (ints id) with
                      [ Image (tid,rect) -> 
                        (
                          match !texture_id with
                          [ None -> texture_id.val := Some tid
                          | _ -> ()
                          ];
                          let name = XmlParser.get_attribute "name" attributes in
                          parse_atlas [ (rect,name,{Point.x=floats posx; y = floats posy}) :: res ]
                        )
                      | _ -> assert False
                      ]
                    | None -> List.rev res
                    | _ -> assert False
                    ]
                  in
                  let els = parse_atlas [] in
                  let tid = match !texture_id with [ None -> XmlParser.error "need texture_id" | Some tid -> tid ] in
                  parse_sprite_children [ CAtlas (tid, els) :: res ]
              | _ -> XmlParser.error "unknown child"
              ]
            | `El_end -> List.rev res
            | _ -> assert False
            ]
          in
          let rec loop () = 
            match XmlParser.next () with
            [ `El_start (("","item"),attributes) ->
              match XmlParser.get_attributes "item" [ "id"; "type" ] attributes with
              [ [ id; "image" ] -> (*{{{*)
                match XmlParser.get_attributes "item" [ "texture"; "x";"y";"width";"height" ] attributes with
                [ [ texture; x; y; width; height] -> 
                  (
                    XmlParser.accept `El_end;
                    Hashtbl.add items (ints id) (Image (ints texture,Rectangle.create (floats x) (floats y) (floats width) (floats height)));
                    loop ()
                  )
                | _ -> assert False
                ] (*}}}*)
              | [ id; "sprite" ] -> (*{{{*)
                (
                  let children = parse_sprite_children [] in
                  match children with
                  [ [ CAtlas tid children ] -> Hashtbl.add items (ints id) (Atlas tid children)
                  | _ -> Hashtbl.add items (ints id) (Sprite children)
                  ];
                  loop ()
                )(*}}}*)
              | [ id; "iclip" ] -> (*{{{*)
                (
                  let frames = DynArray.create () in
                  let labels = Hashtbl.create 0 in
                  (
                    let rec parse_frames () = (*{{{*)
                      match XmlParser.parse_element "frame" [ "img"; "posX"; "posY" ] with
                      [ Some ([imgid; posX; posY ], attributes) ->
                        match Hashtbl.find items (ints id) with
                        [ Image image ->
                          (
                            let label = XmlParser.get_attribute "label" attributes in
                            let hotpos = {Point.x = floats posX; y = floats posY} in
                            (
                              DynArray.add frames (KeyFrame (label,{hotpos;image}));
                              let i = DynArray.length frames - 1 in
                              (
                                match label with
                                [ Some l -> Hashtbl.add labels l i
                                | None -> ()
                                ];
                                add_frames attributes i frames;
                              );
                            );
                            parse_frames ()
                        )
                        | _ -> assert False
                        ]
                    | None -> ()
                    | _ -> assert False
                    ](*}}}*)
                  in
                  parse_frames ();
                  Hashtbl.add items (ints id) (ImageClip (DynArray.to_array frames) labels);
                );
                loop ()
                ) (*}}}*)
              | [ id; "clip" ] -> (*{{{*)
                (
                  let frames = DynArray.create () in
                  let labels = Hashtbl.create 0 in
                  (
                    let rec parse_frames tid = (*{{{*)
                      match XmlParser.next () with
                      [ `El_start (("","frame"),attributes) ->
                        let tid = 
                          let label = XmlParser.get_attribute "label" attributes in
                          let (tid,children) = 
                            match XmlParser.next () with
                            [ `El_start (("","children"),_) -> parse_children 0 []
                            | _ -> XmlParser.error "frame must have children"
                            ]
                          in
                          let commands =
                            match XmlParser.next () with
                            [ `El_start (("","commands"),_) ->
                              let cmds = parse_cmds [] where
                                rec parse_cmds res = (*{{{*)
                                  match XmlParser.next () with
                                  [ `El_start (("",cmd),attributes) ->
                                    let idx = match XmlParser.get_attribute "idx" attributes with [ Some idx -> ints idx | None -> XmlParser.error "cmd must have idx attribute" ] in
                                    match cmd with
                                    [ "place" ->
                                      match XmlParser.get_attributes cmd [ "id"; "posX"; "posY" ] attributes with
                                      [ [ id; posX; posY ] -> 
                                        let () = XmlParser.accept `El_end in
                                        let () = debug "place: %d" (ints id) in
                                        let name = XmlParser.get_attribute "name" attributes in
                                        match Hashtbl.find items (ints id) with
                                        [ Image (_,rect) -> parse_cmds [ ClpPlace (idx,rect,name,{Point.x = floats posX; y = floats posY}) :: res]
                                        | _ -> XmlParser.error "clip can only place an images"
                                        ]
                                      | _ -> assert False
                                      ]
                                    | "clear-from" ->
                                        let () = XmlParser.accept `El_end in 
                                        let count = match XmlParser.get_attribute "count" attributes with [ Some count -> ints count | None -> 1 ] in
                                        parse_cmds [ ClpClear (idx,count) :: res ]
                                    | "change" ->
                                        let () = XmlParser.accept `El_end in
                                        let changes = 
                                          List.filter_map begin fun ((_,ln),v) ->
                                            match ln with
                                            [ "posX" -> Some (`posX (floats v))
                                            | "posY" -> Some (`posY (floats v))
                                            | "move" -> Some (`move (ints v))
                                            | _ -> None
                                            ]
                                          end attributes
                                        in
                                        parse_cmds [ ClpChange (idx,changes) :: res ]
                                    | cmd -> XmlParser.error "unknown cmd: %s" cmd
                                    ]
                                  | `El_end -> List.rev res
                                  | _ -> assert False
                                  ] (*}}}*)
                              in
                              (
                                XmlParser.accept `El_end;
                                Some cmds;
                              )
                            | `El_end -> None
                            | `El_start (("",tag),_) -> XmlParser.error "unexpected tag in frame [%s]" tag
                            | _ -> assert False
                            ]
                          in
                          (
                            DynArray.add frames (KeyFrame (label,(children,commands)));
                            let i = DynArray.length frames - 1 in
                            (
                              match label with
                              [ Some l -> Hashtbl.add labels l i
                              | None -> ()
                              ];
                              add_frames attributes i frames;
                            );
                            tid
                          )
                        in
                        parse_frames tid
                    | `El_end -> tid 
                    | _ -> XmlParser.error "incorrect frame"
                    ](*}}}*)
                  in
                  let tid = parse_frames 0 in
                  Hashtbl.add items (ints id) (Clip tid (DynArray.to_array frames) labels);
                );
                loop ()
                ) (*}}}*)
              | [ id; "imageclip" ] -> 
                (
                  let frames : DynArray.t imageFrame = DynArray.create () in
                  let labels = Hashtbl.create 0 in
                  (
                    let rec parse_frames () = 
                      match XmlParser.parse_element "frame" [ "id"; "posX"; "posY" ] with
                      [ Some [ id ; posX; posY ] attributes ->
                        match Hashtbl.find items (ints id) with
                        [ Image image ->
                          let label = XmlParser.get_attribute "label" attributes in
                          (
                            DynArray.add frames (KeyFrame label {hotpos = {Point.x = floats posX; y = floats posY}; image});
                            let i = DynArray.length frames - 1 in
                            (
                              match label with
                              [ Some l -> Hashtbl.add labels l i
                              | None -> ()
                              ];
                              add_frames attributes i frames;
                            );
                            parse_frames ()
                          )
                        | _ -> XmlParser.error "imageclip can containt only images"
                        ]
                      | None -> ()
                      | _ -> assert False
                      ]
                    in
                    parse_frames ();
                    Hashtbl.add items (ints id) (ImageClip (DynArray.to_array frames) labels);
                  );
                  loop ()
                )
              | [ id; kind ] -> XmlParser.error "unknown item type [%s:%s]" id kind
              | _ -> assert False
              ]
            | `El_end -> items
            | signal -> XmlParser.error "incorrect item '%s'" (match signal with [ `El_start ((_,name),_) -> Printf.sprintf "start [%s]" name | `El_end -> "end" | _ -> "else" ])
            ]
          in
          loop ()
        | _ -> XmlParser.error "items not found"
        ]
      in (*}}}*)
      let textures = parse_textures () in
      let items = parse_items () in
      let symbols = Hashtbl.create 1 in
      match XmlParser.next () with
      [ `El_start (("","symbols"),_) ->
        (
          let rec loop () = 
            match XmlParser.parse_element "symbol" ["class";"id"] with
            [ Some [ cls; id ] _ -> (Hashtbl.add symbols cls (Hashtbl.find items (ints id)); loop ())
            | None -> ()
            | _ -> assert False
            ]
          in
          loop ();
          (
            XmlParser.close ();
            let textures = 
              match loadTextures with
              [ True -> `textures (Array.map (fun file -> Texture.load (Filename.concat libpath file)) textures)
              | False -> `files textures
              ]
            in
            {path=libpath;textures;symbols}
          )
        )
      | _ -> XmlParser.error "exports not found"
      ]
    | _ -> XmlParser.error "lib not found"
    ];
  );

value release lib = 
  match lib.textures with
  [ `textures tx -> Array.iter (fun t -> t#release ()) tx
  | _ -> ()
  ];
end;
