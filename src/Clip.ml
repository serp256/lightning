open LightCommon;

open ExtList;


module D = DisplayObject;

exception Frame_not_found;

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


class type virtual c =
  object
    inherit D.c;
    method ccast: [= `Clip of c ];
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


(* value memo : WeakMemo.c movie = new WeakMemo.c 1; *)

(* value cast: #D.c -> option movie = fun x -> try Some (memo#find x) with [ Not_found -> None ]; *)


class virtual base ['frame] ~fps ~frames:(frames:array (cFrame 'frame)) ~labels =  (*{{{*)
(*     let first_frame = match frames.(0) with [ KeyFrame frame -> frame | Frame _ -> assert False ] in *)
  let framesLength = Array.length frames in
object(self)
  inherit D.c as super;
  value mutable frameTime = 1. /. (float fps);
  value mutable currentFrameID = 0;
  method ccast: [= `Clip of c ] = `Clip (self :> c);
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
        eventID := Some (self#addEventListener D.ev_ENTER_FRAME self#onEnterFrame)
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
        self#removeEventListener D.ev_ENTER_FRAME evID;
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
          debug:quest "Not found frame %d" n;
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
    [ None -> eventID := Some (self#addEventListener D.ev_ENTER_FRAME self#onEnterFrame)
    | _ -> ()
    ];
    changeHandler := onChangeFrame;
    completeHandler := onComplete;
    playDirection := direction;
  );

  method private virtual applyFrame: int -> 'frame -> unit;

  method private setCurrentFrame cf =
  (
    debug:setframe "setCurrentFrame: [%d], frames num %d" cf (Array.length frames);
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
    with 
      [ Same_frame -> () 
      | Invalid_argument err -> failwith (Printf.sprintf "Invalid_argument %s for %s; cf : %d; count_frames : %d "  err self#name cf (Array.length frames) )
      ];
    currentFrameID := cf;
  );

  method private onEnterFrame event _ _ =
		(*let () = debug:setframe "onEnterFrame %f %B" elapsedTime (elapsedTime = ~-.1.) in*)
		let () = debug:setframe "onEnterFrame %f" elapsedTime in
    if elapsedTime = ~-.1. then elapsedTime := 0.
    else
      match Ev.float_of_data event.Ev.data with
      [ Some dt ->
        (
					debug:setframe "dt %f" dt;
          elapsedTime := elapsedTime +. dt;
					debug:setframe "elapsedTime %f, frameTime %f" elapsedTime frameTime;
          match int_of_float (elapsedTime /. frameTime) with
          [  0 -> ()
          | n ->
            (
							debug:setframe "n %d" n;
              elapsedTime := elapsedTime -. ((float n) *. frameTime);
              let (currentFrame,complete) =
                match playDirection with
                [ `forward ->
                    let cFrame = currentFrameID + n in
										let () = debug:setframe "forward cFrame %d" cFrame in
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
      | None -> assert False
      ];
  initializer self#play();
end; (*}}}*)




(*
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

value image_from_texture texture=
  ((new image texture) :> c);

value image_async path callback =
  Texture.load_async path begin fun texture ->
    let res = new image texture in
    callback (res :> c)
  end;
*)
