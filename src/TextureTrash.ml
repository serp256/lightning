
(*
module AsyncLoader (P:sig end) : AsyncLoader = struct

  debug "Async loader created";

  value waiters = Hashtbl.create 1;

  value load_queue = ThreadSafeQueue.create ();
  value condition = Condition.create ();
  value load path callback = 
  (
    if not (Hashtbl.mem waiters path)
    then
    (
      ThreadSafeQueue.enqueue load_queue path;
      Condition.signal condition;
    )
    else ();
    Hashtbl.add waiters path callback;
  );

  value result_queue = ThreadSafeQueue.create ();

  value rec check_result () = 
    match ThreadSafeQueue.dequeue result_queue with
    [ Some (path,image_info) -> 
      (
        let textureInfo =  loadTexture image_info in
        let () = freeImageInfo image_info in
        let texture = make_and_cache path textureInfo in
        (
          debug "texture: %s loaded" path;
          let waiters = MHashtbl.pop_all waiters path in
          List.iter (fun f -> f texture) waiters;
        );
        check_result ();
      )
    | None -> ()
    ];

  value mutex = Mutex.create ();
  value run () =
    let () = debug "Async loader run" in
    let () = Mutex.lock mutex in
    loop () where
      rec loop () = 
        let () = debug "try check requests" in
        match ThreadSafeQueue.dequeue load_queue with
        [ Some path ->
          (
            let l = loadImageInfo path  in
            let () = debug "image loaded" in
            ThreadSafeQueue.enqueue result_queue (path,l);
            loop ();
          )
        | None -> 
          (
            debug "wait signal";
            Condition.wait condition mutex;
            loop ()
          )
        ];

  value thread = Thread.create run ();

end;
*)
(*
IFDEF IOS THEN
value render_texture_size ((w,h) as ok) =
    if w <= 8 
    then
      if w > h
      then  (w,w) (* incorrect case *)
      else
        if h > w * 2 
        then  (min (h / 2) 16, h) (* incorrect case *)
        else ok
    else
      if h <= 8 
      then (w,min 16 w)
      else ok
    ;

ELSE

value render_texture_size p = p;

ENDIF;




(* RENDERED TEXTURE *)

type renderbuffer_t;
type renderbuffer = 
  {
    renderbuffer: renderbuffer_t;
    renderInfo: renderInfo;
  };
external renderbuffer_create: int -> filter -> float -> float -> renderbuffer = "ml_renderbuffer_create";
type framebufferState;
external renderbuffer_activate: renderbuffer_t -> framebufferState = "ml_renderbuffer_activate";
external renderbuffer_deactivate: framebufferState -> unit = "ml_renderbuffer_deactivate";
external renderbuffer_clone: renderbuffer_t -> renderbuffer = "ml_renderbuffer_clone";
external renderbuffer_resize: renderbuffer -> float -> float -> bool = "ml_renderbuffer_resize";
external renderbuffer_delete: renderbuffer_t -> unit = "ml_renderbuffer_delete";

class type rendered = 
  object
    inherit c;
    method renderbuffer: renderbuffer;
    method activate: unit -> unit;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
    method deactivate: unit -> unit;
    method clone: unit -> rendered;
  end;


value glRGBA = 0x1908;
value glRGB = 0x1907;

module Renderers = Weak.Make(struct type t = renderer; value equal r1 r2 = r1 = r2; value hash = Hashtbl.hash; end);




class rbt rb = 
  let () = debug "create rendered texture <%ld>" (int32_of_textureID rb.renderInfo.rtextureID) in
  object(self)
    method renderInfo = rb.renderInfo;
    method renderbuffer = rb;
    method kind = rb.renderInfo.kind;
    method scale = 1.;
    value mutable isActive = None;
(*
    value mutable legalWidth = legalWidth;
    method realWidth = legalWidth;
*)
    method width = rb.renderInfo.rwidth;
(*
    value mutable legalHeight = legalHeight;
    method realHeight = legalHeight;
*)
    method height = rb.renderInfo.rheight;
    method hasPremultipliedAlpha = match rb.renderInfo.kind with [ Simple v -> v | _ -> assert False ];
(*     method scale = 1.; *)
    method textureID = rb.renderInfo.rtextureID;
    method base : option c = None;
    method clipping = rb.renderInfo.clipping;
    method rootClipping = rb.renderInfo.clipping;
    method subTexture (region:Rectangle.t) : c = assert False;
(*     method framebufferID = framebufferID; *)
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method private changed () = Renderers.iter (fun r -> r#onTextureEvent `CHANGE (self :> c)) renderers;
    method setFilter filter = set_texture_filter rb.renderInfo.rtextureID filter;

    method resize w h = 
      match renderbuffer_resize rb w h with
      [ True -> 
        (
          Gc.compact ();
          Renderers.iter (fun r -> r#onTextureEvent `RESIZE (self :> c)) renderers
        )
      | False -> ()
      ];
    (*
      let () = debug:rendered "resize <%ld> from %f->%f, %f->%f" (int32_of_textureID renderInfo.rtextureID) width w height h in
      if w <> width || h <> height
      then
(*         let () = texture_mem_sub (legalWidth * legalHeight * 4) in *)
        let iw = truncate (ceil w) in
        let ih = truncate (ceil h) in
        let legalWidth' = nextPowerOfTwo iw
        and legalHeight' = nextPowerOfTwo ih in
        let (legalWidth',legalHeight') = render_texture_size (legalWidth',legalHeight') in
        let textureID = 
          if (legalWidth' <> legalWidth || legalHeight <> legalHeight')
          then resize_texture renderInfo.rtextureID legalWidth' legalHeight'
          else renderInfo.rtextureID
        in
        (
          legalWidth := legalWidth'; legalHeight := legalHeight';
(*           texture_mem_add (legalWidth * legalHeight * 4); *)
          let flw = float legalWidth' and flh = float legalHeight' in
          let clipping =
            if flw <> w || flh <> h 
            then Some (Rectangle.create ((flw -. w) /. (2. *. flw)) ((flh -. h) /. (2. *. flh))  (w /. flw) (h /. flh))
            else None 
          in
          renderInfo := {(renderInfo) with rtextureID = textureID; rwidth = w; rheight = h; clipping};
          Renderers.iter (fun r -> r#onTextureEvent `RESIZE (self :> c)) renderers;
        )
      else ();
    *)

    value mutable released = False;
    method released = released;
    method release () = 
      match released with
      [ False ->
        (
(*           debug:gc "release rendered texture: [%d] <%ld>" framebufferID (int32_of_textureID renderInfo.rtextureID); *)
          renderbuffer_delete rb.renderbuffer;
          delete_textureID rb.renderInfo.rtextureID;
          released := True;
  (*         texture_mem_sub (legalWidth * legalHeight * 4); *)
        )
      | True -> ()
      ];


    method activate () = 
      match isActive with
      [ None ->
        let oldState = renderbuffer_activate rb.renderbuffer in
        isActive := Some oldState
      | Some _ -> ()
      ];

    method deactivate () =
      match isActive with
      [ Some state -> 
        (
          renderbuffer_deactivate state;
          isActive := None;
          self#changed ();
        )
      | None -> () (* FIXME: assert here ? *)
      ];

    method draw f = 
      match isActive with
      [ None ->
        let oldState = renderbuffer_activate rb.renderbuffer in
        (
          isActive := Some oldState;
          f();
          renderbuffer_deactivate oldState;
          isActive := None;
          self#changed();
        )
      | Some _ -> f()
      ];

    method clear color alpha = self#draw (fun () -> glClear color alpha);
    method clone () = 
      let rb = renderbuffer_clone rb.renderbuffer in
      new rbt rb;

    initializer 
    (
(*       texture_mem_add (legalWidth * legalHeight * 4); *)
      Gc.finalise (fun obj -> (debug:gc "release renderbuffer"; if not obj#released then renderbuffer_delete obj#renderbuffer.renderbuffer else ())) self;
    );

  end; (*}}}*)

value rendered ?(format=glRGBA) ?(filter=FilterLinear) width height : rendered =
  let () = debug:rendered "try create rtexture of size %f:%f" width height in
  let rb = renderbuffer_create format filter width height in
  new rbt rb;




  ============


(*
value create texFormat width height data =
  let legalWidth = nextPowerOfTwo width
  and legalHeight = nextPowerOfTwo height in
  let textureInfo = 
    {
      texFormat;
      realWidth = width;
      width = legalWidth;
      realHeight = height;
      height = legalHeight;
      numMipmaps = 0;
      generateMipmaps = False;
      premultipliedAlpha = False;
      scale = 1.0;
      textureID = Obj.magic 0;
    }
  in
  let textureInfo = loadTexture textureInfo data in
  let res = make textureInfo in
  (res :> c);
*)


(*
Callback.register "create_ml_texture" begin fun textureID width height clipping ->
  let () = debug "create_ml_texture <%ld>" (int32_of_textureID textureID) in
  let renderInfo =
    {
      rtextureID = textureID;
      rwidth = width;
      rheight = height;
      clipping = clipping;
      kind = Simple True;
    }
  in
(*   let mem = ((nextPowerOfTwo (truncate width)) * (nextPowerOfTwo (truncate height)) * 4) in *)
  object(self:c)
    method renderInfo = renderInfo;
    method kind = renderInfo.kind;
    method scale = 1.;
    method textureID = renderInfo.rtextureID;
    method width = renderInfo.rwidth;
    method height = renderInfo.rheight;
    method hasPremultipliedAlpha = True;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;
(*     method scale = 1.; *)
    method base = None;
    method clipping = renderInfo.clipping;
    method rootClipping = renderInfo.clipping;
    value mutable released = False;
    method released = released;
    method release () = 
      if not released 
      then
      (
        debug:gc "release 'c' texture: <%ld>" (int32_of_textureID renderInfo.rtextureID);
        delete_textureID renderInfo.rtextureID;
        released := True;
      )
      else ();
    (*
      if (textureID <> 0) 
      then
      (
        debug:gc "release create from c texture <%d>" textureID;
        delete_texture textureID; 
        textureID := 0;
        texture_mem_sub mem;
      )
      else ();
    *)
    method subTexture _ = assert False;
    method addRenderer _ = ();
    method removeRenderer _ = ();
    (*
    initializer 
    (
      Gc.finalise (fun t -> let () = debug:gc "release c texture <%d>" textureID in t#release ()) self;
      texture_mem_add mem;
    );
    *)
  end
end;
*)

(*
value texture_finaliser path = 
(
  ();
  fun t -> if not t#released then TextureCache.remove cache path else ();
);
*)
    
