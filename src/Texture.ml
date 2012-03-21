open LightCommon;

type ubyte_array = Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;

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
  ];



type textureInfo = 
  {
    texFormat: textureFormat;
    realWidth: int;
    width: int;
    realHeight: int;
    height: int;
    numMipmaps: int;
    generateMipmaps: bool;
    premultipliedAlpha:bool;
    scale: float;
    memSize: int;
    textureID: textureID;
  };




type event = [= `RESIZE | `CHANGE ]; 

type filter = [ FilterNearest | FilterLinear ];

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";

class type renderer = 
  object
    method onTextureEvent: event -> c -> unit;
  end
and c =
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method setFilter: filter -> unit;
    method scale: float;
    method textureID: textureID;
    method base : option c; 
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
    method addRenderer: renderer -> unit;
    method removeRenderer: renderer -> unit;
  end;

value zero : c = 
  object(self)
    method width = 0.;
    method height = 0.;
    method hasPremultipliedAlpha = False;
    method setFilter filter = ();
    method scale = 1.;
    method textureID = 0;
    method base = None;
    method clipping = None;
    method rootClipping = None;
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
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";

(*
value loadImage ?(textureID=0) ~path ~contentScaleFactor = 
(*     let () = debug "loaded texture" (* : [%d:%d] -> [%d:%d] width height legalWidth legalHeight*) in *)
  let surface = Sdl_image.load (LightCommon.resource_path path) in
  let bpp = Sdl.Video.surface_bpp surface in
  let () = assert (bpp = 32) in
  let width = Sdl.Video.surface_width surface in
  let legalWidth = nextPowerOfTwo width in
  let height = Sdl.Video.surface_height surface in
  let legalHeight = nextPowerOfTwo height in
  let rgbSurface = Sdl.Video.create_rgb_surface [] legalWidth legalHeight bpp in
  (
    Sdl.Video.set_blend_mode surface Sdl.Video.BLENDMODE_NONE;
    Sdl.Video.blit_surface surface None rgbSurface None;
    Sdl.Video.free_surface surface;
    let textureInfo = 
      {
        texFormat = TextureFormatRGBA;
        realWidth = width;
        width = legalWidth;
        realHeight = height;
        height = legalHeight;
        numMipmaps = 0;
        generateMipmaps = False;
        premultipliedAlpha = False;
        scale = 2.0;
        textureID = textureID;
      }
    in
    let res = loadTexture textureInfo (Some (Sdl.Video.surface_pixels rgbSurface)) in
    (
      Sdl.Video.free_surface rgbSurface;
      res
    );
  );

ELSE IFDEF IOS THEN
ELSE IFDEF ANDROID THEN
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
ENDIF;
ENDIF;
ENDIF;
*)

module Cache = WeakHashtbl.Make (struct
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
  let rootClipping : Rectangle.t = Obj.magic rootClipping in
  let width = region.Rectangle.width
  and height = region.Rectangle.height in
  object(self)
    method width = width;
    method height = height;
    method textureID = baseTexture#textureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
    method scale = baseTexture#scale;
    method base = Some (baseTexture :> c);
    method clipping = Some clipping;
    method setFilter filter = set_texture_filter baseTexture#textureID filter;
    value rootClipping : option Rectangle.t = Some (Obj.magic rootClipping);
    method rootClipping = rootClipping;
(*     method update path = baseTexture#update path; *)
    method subTexture region = ((new subtexture region (self :> c)) :> c);
(*     method releaseSubTexture () = baseTexture#releaseSubTexture (); *)
    method release () = ();(* let () = debug:gc "release subtexture" in baseTexture#releaseSubTexture (); *)
(*     method setTextureID tid = baseTexture#setTextureID tid; *)
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
(*     initializer Gc.finalise (fun t -> t#release ()) self; *)
  end;

value cache = Cache.create 11;
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

external delete_texture: textureID -> unit = "ml_delete_texture";


class s textureInfo = 
  let textureID = textureInfo.textureID
  and width = float textureInfo.width
  and height = float textureInfo.height
  and hasPremultipliedAlpha = textureInfo.premultipliedAlpha
  and scale = textureInfo.scale 
  in
  let () = debug "make texture: <%d>, width=[%d->%f],height=[%d -> %f],scale=%f" textureID textureInfo.realWidth width textureInfo.realHeight height scale in
  let mem = textureInfo.memSize in
  let clipping = 
    if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
    then Some (Rectangle.create 0. 0. ((float textureInfo.realWidth) /. width) ((float textureInfo.realHeight) /. height))
    else None 
  in
  let w = float textureInfo.realWidth
  and h = float textureInfo.realHeight in
  object(self)
    value mutable textureID = textureID;
(*     value mutable counter = 0; *)
    (*
    method releaseSubTexture () = 
    (
      debug:gc "release subtexture: %d" textureID;
      counter := counter - 1;
      if counter = 0
      then self#release ()
      else ();
    );
    *)

    method setFilter filter = set_texture_filter textureID filter;
    method release () = 
      if (textureID <> 0) 
      then
      (
        debug "release texture <%d>" textureID;
        delete_texture textureID; 
        textureID := 0;
        texture_mem_sub mem;
      )
      else ();
    method width = w;
    method height = h;
    method hasPremultipliedAlpha = hasPremultipliedAlpha;
    method scale = scale;
(*    method setTextureID tid = textureID := tid; *)
    method textureID = textureID;
    method base : option c = None;
    method clipping = clipping;
    method rootClipping = clipping;
(*       method update path = ignore(loadImage ~textureID ~path ~contentScaleFactor:1.);  (* Fixme cache it *) *)
    method subTexture region = ((new subtexture region (self :> c)) :> c);
    method addRenderer (_:renderer) = ();
    method removeRenderer (_:renderer) = ();
    initializer 
    (
      Gc.finalise (fun t -> (debug:gc "release texture <%d>" textureID; t#release ())) self;
      texture_mem_add mem;
    );
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
  let () = debug "create_ml_texture <%d>" textureID in
  let mem = ((nextPowerOfTwo (truncate width)) * (nextPowerOfTwo (truncate height)) * 4) in
  object(self:c)
    value mutable textureID = textureID;
    method textureID = textureID;
    method width = width;
    method height = height;
    method hasPremultipliedAlpha = True;
    method setFilter filter = set_texture_filter textureID filter;
    method scale = 1.;
    method base = None;
    method clipping = clipping;
    method rootClipping = clipping;
    method release () = 
      if (textureID <> 0) 
      then
      (
        debug:gc "release create from c texture <%d>" textureID;
        delete_texture textureID; 
        textureID := 0;
        texture_mem_sub mem;
      )
      else ();
    method subTexture _ = assert False;
    method addRenderer _ = ();
    method removeRenderer _ = ();
    initializer 
    (
      Gc.finalise (fun t -> let () = debug:gc "release c texture <%d>" textureID in t#release ()) self;
      texture_mem_add mem;
    );
  end
end;

value make_and_cache path textureInfo = 
  let mem = textureInfo.memSize in
  let res = 
    object 
      inherit s textureInfo;
      method !release () = 
        if (textureID <> 0) 
        then
        (
          debug "release texture <%d>" textureID;
          delete_texture textureID; 
          textureID := 0;
          texture_mem_sub mem;
          Cache.remove cache path;
        )
        else ();
    end
  in
  (
    debug:cache "texture <%d> loaded" res#textureID;
    Cache.add cache path res;
    (res :> c)
  );

value load path : c = 
  try
    debug:cache (
      Debug.d "print cache";
      Cache.iter (fun k _ -> Debug.d "image cache: %s" k) cache;
    );
    ((Cache.find cache path) :> c)
  with 
  [ Not_found ->
    let textureInfo = 
      proftimer:t "Loading texture [%F]" loadImage path 1. 
    in
    let () = 
      debug
        "load texture: %s %d [%d->%d; %d->%d] [pma=%s]\n%!" 
        path textureInfo.textureID textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.premultipliedAlpha) 
    in
    make_and_cache path textureInfo
  ];



module type AsyncLoader = sig

  value load: string -> (c -> unit) -> unit;
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
external aloader_push: aloader_runtime -> string -> unit = "ml_texture_async_loader_push";
external aloader_pop: aloader_runtime -> option (string * textureInfo) = "ml_texture_async_loader_pop";

module AsyncLoader(P:sig end) : AsyncLoader = struct

  value waiters = Hashtbl.create 1;
  value cruntime = aloader_create_runtime ();

  value load path callback = 
  (
    if not (Hashtbl.mem waiters path)
    then aloader_push cruntime path
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
            List.iter (fun f -> f texture) waiters;
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

value load_async path callback = 
  (* хитрая логика с кэшем, но пока хуй с ней *)
  let texture = 
    try
      debug:cache (
        Debug.d "print cache";
        Cache.iter (fun k _ -> Debug.d "image cache: %s" k) cache;
      );
      Some (((Cache.find cache path) :> c))
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
    Loader.load path callback
  ];




(*
class type renderObject =
  object
    method render: ?alpha:float -> ?transform:bool -> option Rectangle.t -> unit;
  end;
*)

external create_render_texture: int -> int -> float -> int -> int -> (framebufferID*textureID) = "ml_rendertexture_create";
type framebufferState;
external activate_framebuffer: framebufferID -> int -> int -> framebufferState = "ml_activate_framebuffer";
external deactivate_framebuffer: framebufferState -> unit = "ml_deactivate_framebuffer";
external delete_framebuffer: framebufferID -> unit = "ml_delete_framebuffer";
external resize_texture: textureID -> int -> int -> unit = "ml_resize_texture";

class type rendered = 
  object
    inherit c;
    method realWidth:int;
    method realHeight:int;
    method setPremultipliedAlpha: bool -> unit;
    method framebufferID: framebufferID;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
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

value rendered ?(format=glRGBA) ?(color=0) ?(alpha=0.) width height : rendered = (* make it fucking int {{{*)
  let iw = truncate (ceil width) in
  let ih = truncate (ceil height) in
  let legalWidth = nextPowerOfTwo iw
  and legalHeight = nextPowerOfTwo ih in
  let (legalWidth,legalHeight) = render_texture_size (legalWidth,legalHeight) in
  let (framebufferID,textureID) = create_render_texture format color alpha legalWidth legalHeight in
  let () = debug:rendered "rendered texture <%d>" textureID in
  let clipping = 
    let flw = float legalWidth and flh = float legalHeight in
    if flw <> width || flh <> height 
    then 
      let () = debug "clipping: [%f:%f] -> [%d:%d]" width height legalWidth legalHeight in
      Some (Rectangle.create 0. 0. (width /. flw) (height /. flh))
    else None
  in
  object(self)
    value mutable isActive = False;
    value mutable textureID = textureID;
    value mutable clipping = clipping;
    value mutable width = width;
    value mutable legalWidth = legalWidth;
    method realWidth = legalWidth;
    method width = width;
    value mutable height = height;
    value mutable legalHeight = legalHeight;
    method realHeight = legalHeight;
    method height = height;
    value mutable hasPremultipliedAlpha = True;
    method setPremultipliedAlpha v = hasPremultipliedAlpha := v;
    method hasPremultipliedAlpha = hasPremultipliedAlpha;
    method scale = 1.;
    method textureID = textureID;
    method base : option c = None;
    method clipping = clipping;
    method rootClipping = clipping;
    method subTexture (region:Rectangle.t) : c = assert False;
    method framebufferID = framebufferID;
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method private changed () = Renderers.iter (fun r -> r#onTextureEvent `CHANGE (self :> c)) renderers;
    method setFilter filter = set_texture_filter textureID filter;

    method resize w h =
      let () = debug:rendered "resize <%d> from %f->%f, %f->%f" textureID width w height h in
      if w <> width || h <> height
      then
        let () = texture_mem_sub (legalWidth * legalHeight * 4) in
        let iw = truncate (ceil w) in
        let ih = truncate (ceil h) in
        let legalWidth' = nextPowerOfTwo iw
        and legalHeight' = nextPowerOfTwo ih in
        let (legalWidth',legalHeight') = render_texture_size (legalWidth',legalHeight') in
        (
          width := w;
          height := h;
          if (legalWidth' <> legalWidth || legalHeight <> legalHeight')
          then resize_texture textureID legalWidth' legalHeight'
          else ();
          legalWidth := legalWidth'; legalHeight := legalHeight';
          texture_mem_add (legalWidth * legalHeight * 4);
          let flw = float legalWidth' and flh = float legalHeight' in
          clipping :=
            if flw <> w || flh <> h 
            then Some (Rectangle.create 0. 0. (w /. flw) (h /. flh))
            else None; 
          Renderers.iter (fun r -> r#onTextureEvent `RESIZE (self :> c)) renderers;
        )
      else ();

    method release () = 
      if textureID <> 0
      then
      (
        debug "release rendered texture: [%d] <%d>" framebufferID textureID;
        delete_framebuffer framebufferID;
        delete_texture textureID;
        textureID := 0;
        texture_mem_sub (legalWidth * legalHeight * 4);
      )
      else ();

    method draw f = 
      match isActive with
      [ False ->
(*         let oldState = activate_framebuffer framebufferID (truncate width) (truncate height) in *)
        let oldState = activate_framebuffer framebufferID legalWidth legalHeight in
        (
          debug:rendered "buffer [%d] activated" framebufferID;
          isActive := True;
          f();
          deactivate_framebuffer oldState;
          isActive := False;
          debug:rendered "buffer [%d] deactivated" framebufferID;
          self#changed();
        )
      | True -> f()
      ];

    method clear color alpha = self#draw (fun () -> Render.clear color alpha);
    initializer 
    (
      texture_mem_add (legalWidth * legalHeight * 4);
      Gc.finalise (fun r -> let () = debug:gc "release rendered texture <%d>" textureID in r#release ()) self;
    );


  end; (*}}}*)


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
