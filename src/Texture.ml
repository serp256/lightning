open LightCommon;

type ubyte_array = Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;

type filter = [ FilterNearest | FilterLinear ];
value defaultFilter = FilterNearest;

external glClear: int -> float -> unit = "ml_clear";
external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";
external zero_textureID: unit -> textureID = "ml_texture_id_zero";
external int32_of_textureID: textureID -> int32 = "ml_texture_id_to_int32";
external delete_textureID: textureID -> unit = "ml_texture_id_delete";
value string_of_textureID textureID = 
  let i = int32_of_textureID textureID in
  Int32.to_string i;

type textureFormat = 
  [ TextureFormatRGBA
  | TextureFormatRGB
  | TextureFormatAlpha
  | TextureFormatPvrtcRGB2
  | TextureFormatPvrtcRGBA2
  | TextureFormatPvrtcRGB4
  | TextureFormatPvrtcRGBA4
  | TextureFormat565
  | TextureFormat5551
  | TextureFormat4444
  | TextureFormatPallete of int
  ];



(*
value mem = ref 0;
value add_mem m =
  (
    mem.val := !mem + m;
    Printf.printf "MEMORY: %d\n%!" !mem;
  );
*)

type textureInfo = 
  {
    texFormat: textureFormat;
    realWidth: int;
    width: int;
    realHeight: int;
    height: int;
    pma:bool; 
    memSize: int;
    textureID: textureID;
  };

type kind = [ Simple of bool | Alpha | Pallete of textureInfo ];
type renderInfo = 
  {
    rtextureID: textureID;
    rwidth: float;
    rheight: float;
    clipping: option Rectangle.t;
    kind: kind;
  };

type event = [= `RESIZE | `CHANGE ]; 



class type renderer = 
  object
    method onTextureEvent: event -> c -> unit;
  end
and c =
  object
    method kind : kind;
    method renderInfo: renderInfo;
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method setFilter: filter -> unit;
(*     method scale: float; *)
    method textureID: textureID;
    method base : option c; 
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
    method released: bool;
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
    method addRenderer: renderer -> unit;
    method removeRenderer: renderer -> unit;
  end;

value zero : c = 
  let renderInfo = { rtextureID = zero_textureID (); rwidth = 0.; rheight = 0.; clipping = None; kind = Simple False } in
  object(self)
    method kind = renderInfo.kind;
    method renderInfo = renderInfo;
    method width = 0.;
    method height = 0.;
    method hasPremultipliedAlpha = False;
    method setFilter filter = ();
(*     method scale = 1.; *)
    method textureID = renderInfo.rtextureID;
    method base = None;
    method clipping = None;
    method rootClipping = None;
    method released = False;
    method release () = ();
    method subTexture _ = self;
    method addRenderer _ = ();
    method removeRenderer _ = ();
  end;

type imageInfo;
external loadImageInfo: string -> imageInfo = "ml_load_image_info";
external freeImageInfo: imageInfo -> unit = "ml_free_image_info";
external loadTexture: ?textureID:textureID -> imageInfo -> textureInfo = "ml_load_texture";
(* external loadTexture: textureInfo -> option ubyte_array -> textureInfo = "ml_loadTexture"; *)
external loadImage: ?textureID:textureID -> ~path:string -> ~suffix:option string -> textureInfo = "ml_loadImage";

module TextureCache = WeakHashtbl.Make (struct
  type t = string;
  value equal = (=);
  value hash = Hashtbl.hash;
end);

(*
class type r = 
  object
    inherit c;
    method setTextureID: textureID -> unit;
    method releaseSubTexture: unit -> unit;
  end;
*)

class subtexture region (baseTexture:c) = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let clipping = Rectangle.create (region.Rectangle.x /. tw) (region.Rectangle.y /. th) (region.Rectangle.width /. tw) (region.Rectangle.height /. th) in
  let rootClipping = Rectangle.tm_of_t clipping in
  let () = 
    let open Rectangle in
    adjustClipping (baseTexture :> c) where
      rec adjustClipping texture =
        match texture#clipping with
        [ None -> ()
        | Some baseClipping ->
            (
              rootClipping.m_x := baseClipping.x +. rootClipping.m_x *. baseClipping.width;
              rootClipping.m_y := baseClipping.y +. rootClipping.m_y *. baseClipping.height;
              rootClipping.m_width := rootClipping.m_width *. baseClipping.width;
              rootClipping.m_height := rootClipping.m_height *. baseClipping.height;
              match texture#base with
              [ Some baseTexture -> adjustClipping baseTexture
              | None -> ()
              ]
            )
        ]
  in
  let renderInfo = 
    {
      rtextureID = baseTexture#textureID;
      rwidth = region.Rectangle.width;
      rheight = region.Rectangle.height;
      clipping = Some (Obj.magic rootClipping);
      kind = baseTexture#kind;
    }
  in
  object(self)
    method renderInfo = renderInfo;
    method kind = renderInfo.kind;
    method width = renderInfo.rwidth;
    method height = renderInfo.rheight;
    method textureID = renderInfo.rtextureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
(*     method scale = baseTexture#scale; *)
    method base = Some (baseTexture :> c);
    method clipping = Some clipping;
    method setFilter filter = set_texture_filter baseTexture#textureID filter;
    method rootClipping = renderInfo.clipping;
(*     method update path = baseTexture#update path; *)
    method subTexture region = ((new subtexture region (self :> c)) :> c);
(*     method releaseSubTexture () = baseTexture#releaseSubTexture (); *)
    method released = baseTexture#released;
    method release () = ();(* let () = debug:gc "release subtexture" in baseTexture#releaseSubTexture (); *)
(*     method setTextureID tid = baseTexture#setTextureID tid; *)
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
(*     initializer Gc.finalise (fun t -> t#release ()) self; *)
  end;

value cache = TextureCache.create 11;
(*
value texture_memory = ref 0;
value texture_mem_add v = 
  (
    texture_memory.val := !texture_memory + v;
    debug:mem "TextureMemory = %d" !texture_memory;
  );
value texture_mem_sub v = 
  (
    texture_memory.val := !texture_memory - v;
    debug:mem "TextureMemory = %d" !texture_memory;
  );
*)

(*
IFDEF ANDROID THEN
value reloadTextures () = 
  let () = debug:android "reload textures" in
  Cache.iter begin fun path t ->
    let textureInfo = loadImage path 1. in
    let textureID = GLTexture.create textureInfo in
    t#setTextureID textureID
  end;

Callback.register "realodTextures" reloadTextures;
ENDIF;
*)

(* external delete_texture: textureID -> unit = "ml_delete_texture"; *)

module PalleteCache = WeakHashtbl.Make(struct
  type t = int;
  value equal = (=);
  value hash = Hashtbl.hash;
end);

value palleteCache = PalleteCache.create 0;
value loadPallete palleteID = 
  try
    PalleteCache.find palleteCache palleteID
  with 
  [ Not_found -> 
    let pallete = loadImage (Printf.sprintf "palletes/%d.plt" palleteID) None in
    (
      PalleteCache.add palleteCache palleteID pallete;
      (* здесь бы финализер повесить на нее, но да хуй с ней нахуй *)
      pallete;
    )
  ];


class s textureInfo = 
  let () = debug "make texture: <%ld>, width=[%d->%d],height=[%d -> %d]" (int32_of_textureID textureInfo.textureID) textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height in
  let width = float textureInfo.realWidth
  and height = float textureInfo.realHeight
  in
(*   let () = add_mem textureInfo.memSize in *)
  let clipping = 
    if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
    then Some (Rectangle.create 0. 0. (width /. (float textureInfo.width)) (height /. (float textureInfo.height)))
    else None 
  and kind = 
    match textureInfo.texFormat with
    [ TextureFormatPallete palleteID -> 
      let pallete = loadPallete palleteID in
      Pallete pallete
    | TextureFormatAlpha -> Alpha
    | _ -> Simple textureInfo.pma
    ]
  in
  let renderInfo = 
    {
      rtextureID = textureInfo.textureID;
      rwidth = width;
      rheight = height;
      clipping = clipping;
      kind = kind;
    }
  in
  object(self)
(*     value mutable textureID = renderInfo.rtextureID; *)
    value renderInfo = renderInfo;
    method renderInfo = renderInfo;
    method kind = renderInfo.kind;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;
    value mutable released = False;
    method released = released;
    method release () = 
      if not released
      then
      (

        debug:gc "release 's' texture: <%ld>" (int32_of_textureID renderInfo.rtextureID);
        delete_textureID renderInfo.rtextureID;
        released := True;
      ) else ();

      (*
      if (textureID <> 0) 
      then
      (
        debug "release texture <%d>" textureID;
        delete_texture textureID; 
        textureID := 0;
        texture_mem_sub mem;
      )
      else ();
      *)
    method width = renderInfo.rwidth;
    method height = renderInfo.rheight;
    method hasPremultipliedAlpha = True; (* CHECK THIS *)
    method textureID = renderInfo.rtextureID;
    method base : option c = None;
    method clipping = renderInfo.clipping;
    method rootClipping = renderInfo.clipping;
(*       method update path = ignore(loadImage ~textureID ~path ~contentScaleFactor:1.);  (* Fixme cache it *) *)
    method subTexture region = ((new subtexture region (self :> c)) :> c);
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
    (*
    initializer 
    (
      Gc.finalise (fun t -> (debug:gc "release texture <%d>" textureID; t#release ())) self;
      texture_mem_add mem;
    );
    *)
  end;


value make textureInfo = new s textureInfo;

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

value make_and_cache path textureInfo = 
(*   let mem = textureInfo.memSize in *)
  let res = 
    object(self) 
      inherit s textureInfo as super;
      method !release () = 
        if not released
        then
        (
          debug:gc "release cached texture: <%ld>" (int32_of_textureID renderInfo.rtextureID);
          delete_textureID renderInfo.rtextureID;
          TextureCache.remove cache path;
          released := True;
        )
        else ();

      initializer Gc.finalise (fun t -> if not t#released then TextureCache.remove cache path else ()) self;
        (*
        if (textureID <> 0) 
        then
        (
          debug "release texture <%d>" textureID;
          delete_texture textureID; 
          textureID := 0;
          texture_mem_sub mem;
          TextureCache.remove cache path;
        )
        else ();
        *)
    end
  in
  (
    debug:cache "texture <%d> cached" (int32_of_textureID res#textureID);
    TextureCache.add cache path res;
    (res :> c)
  );

value load ?(with_suffix=True) path : c = 
  try
    debug:cache (
      Debug.d "print cache";
      TextureCache.iter (fun k _ -> Debug.d "image cache: %s" k) cache;
    );
    ((TextureCache.find cache path) :> c)
  with 
  [ Not_found ->
    let suffix =
      match with_suffix with
      [ True -> LightCommon.resources_suffix ()
      | False ->  None
      ]
    in
    let textureInfo = proftimer:t "Loading texture [%F]" loadImage path suffix in
    let () = 
      debug
        "loaded texture: %s <%ld> [%d->%d; %d->%d] [pma=%s]\n%!" 
        path (int32_of_textureID textureInfo.textureID) textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.pma) 
    in
    make_and_cache path textureInfo
  ];



module type AsyncLoader = sig

  value load: bool -> string -> (c -> unit) -> unit;
  value check_result: unit -> unit;

end;

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

type aloader_runtime;
external aloader_create_runtime: unit -> aloader_runtime = "ml_texture_async_loader_create_runtime";
external aloader_push: aloader_runtime -> string -> option string -> unit = "ml_texture_async_loader_push";
external aloader_pop: aloader_runtime -> option (string * textureInfo) = "ml_texture_async_loader_pop";

module AsyncLoader(P:sig end) : AsyncLoader = struct

  value waiters = Hashtbl.create 1;
  value cruntime = aloader_create_runtime ();

  value load with_suffix path callback = 
  (
    if not (Hashtbl.mem waiters path)
    then 
      let suffix = 
        match with_suffix with
        [ True -> LightCommon.resources_suffix ()
        | False -> None
        ]
      in
      aloader_push cruntime path suffix
    else ();
    Hashtbl.add waiters path callback;
  );



  value rec check_result () = 
    if Hashtbl.length waiters > 0
    then
      match aloader_pop cruntime with
      [ Some (path,textureInfo) -> 
        (
          let texture = make_and_cache path textureInfo in
          (
            debug "texture: %s loaded" path;
            let waiters = MHashtbl.pop_all waiters path in
            List.iter (fun f -> f texture) (List.rev waiters);
          );
          check_result ();
        )
      | None -> ()
      ]
    else ();

end;


value async_loader = ref None; (* ссылка на модуль *) 

value check_async () =
  match !async_loader with
  [ Some m ->
    let module Loader = (value m:AsyncLoader) in
    Loader.check_result ()
  | None -> ()
  ];

value load_async ?(with_suffix=True) path callback = 
  let texture = 
    try
      debug:cache (
        Debug.d "print cache";
        TextureCache.iter (fun k _ -> Debug.d "image cache: %s" k) cache;
      );
      Some (((TextureCache.find cache path) :> c))
    with 
    [ Not_found -> None ]
  in
  match texture with
  [ Some t -> callback t
  | None ->
    let m =
      match !async_loader with
      [ Some m -> m
      | None -> 
          let module Loader = AsyncLoader (struct end) in
          let m = (module Loader:AsyncLoader) in
          (
            async_loader.val := Some m;
            m
          )
          
      ]
    in
    let module Loader = (value m:AsyncLoader) in
    Loader.load with_suffix path callback
  ];


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


class rbt rb = 
  object(self)
    method renderInfo = rb.renderInfo;
    method renderbuffer = rb;
    method kind = rb.renderInfo.kind;
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
      Gc.finalise (fun obj -> if not obj#released then renderbuffer_delete obj#renderbuffer.renderbuffer else ()) self;
    );

  end; (*}}}*)

value rendered ?(format=glRGBA) ?(filter=FilterLinear) width height : rendered = (*{{{*)
  let () = debug:rendered "try create rtexture of size %f:%f" width height in
  let rb = renderbuffer_create format filter width height in
  new rbt rb;


IFDEF IOS THEN
external loadExternalImage: string -> (textureInfo -> unit) -> option (int -> string -> unit) -> unit = "ml_loadExternalImage";
value loadExternal url ~callback ~errorCallback = 
  loadExternalImage url begin fun textureInfo ->
    let texture = make textureInfo in
    callback (texture :> c)
  end errorCallback;



ELSE

value loadExternal url ~callback ~errorCallback = (); (* TODO: Get it by URLLoader *)

ENDIF;
