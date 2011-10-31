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


type textureID = Render.textureID;
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
    textureID: Render.textureID;
  };

class type c = 
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: Render.textureID;
    method base : option (c * Rectangle.t);
    method clipping: option Rectangle.t;
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
(*     method update: string -> unit; *)
  end;


external loadTexture: textureInfo -> option ubyte_array -> textureInfo = "ml_loadTexture";

IFDEF SDL THEN

value loadImage ?(textureID=0) ~path ~contentScaleFactor = 
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
        scale = 1.0;
        textureID = textureID;
      }
    in
(*     let () = debug "loaded texture" (* : [%d:%d] -> [%d:%d] width height legalWidth legalHeight*) in *)
    let res = loadTexture textureInfo (Some (Sdl.Video.surface_pixels rgbSurface)) in
    (
      Sdl.Video.free_surface rgbSurface;
      res
    );
  );

ELSE IFDEF IOS THEN
external loadImage: ?textureID:Render.textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
(* external freeImageData: GLTexture.textureInfo -> unit = "ml_freeImageData"; *)
ELSE IFDEF ANDROID THEN
external loadImage: ?textureID:Render.textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
ENDIF;
ENDIF;
ENDIF;

module Cache = WeakHashtbl.Make (struct
  type t = string;
  value equal = (=);
  value hash = Hashtbl.hash;
end);


class type r = 
  object
    inherit c;
    method setTextureID: Render.textureID -> unit;
    method retain: unit -> unit;
    method releaseSubTexture: unit -> unit;
  end;

class subtexture region baseTexture = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let clipping = Rectangle.create (region.Rectangle.x /. tw) (region.Rectangle.y /. th) (region.Rectangle.width /. tw)  (region.Rectangle.height /. th) in
  let rootClipping = Rectangle.tm_of_t clipping in
  let () = 
    let open Rectangle in
    adjustClipping (baseTexture :> c) where
      rec adjustClipping texture =
        match texture#base with
        [ None -> ()
        | Some (baseTexture,baseClipping) ->
            (
              rootClipping.m_x := baseClipping.x +. rootClipping.m_x *. baseClipping.width;
              rootClipping.m_y := baseClipping.y +. rootClipping.m_y *. baseClipping.height;
              rootClipping.m_width := rootClipping.m_width *. baseClipping.width;
              rootClipping.m_height := rootClipping.m_height *. baseClipping.height;
              adjustClipping baseTexture
            )
        ]
  in
  let rootClipping : Rectangle.t = Obj.magic rootClipping in
  object(self)
    method width = baseTexture#width *. clipping.Rectangle.width;
    method height = baseTexture#height *. clipping.Rectangle.height;
    method textureID = baseTexture#textureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
    method scale = baseTexture#scale;
    method base = Some ((baseTexture :> c),clipping);
    method clipping = Some rootClipping;
(*     method update path = baseTexture#update path; *)
    method subTexture region = ((new subtexture region (self :> r)) :> c);
    method retain () = baseTexture#retain ();
    method releaseSubTexture () = baseTexture#releaseSubTexture ();
    method release () = baseTexture#releaseSubTexture ();
    method setTextureID tid = baseTexture#setTextureID tid;
    initializer Gc.finalise (fun t -> t#release ()) self;
  end;

value cache = Cache.create 11;

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

external delete_texture: Render.textureID -> unit = "ml_delete_texture";

value make textureInfo = 
  let textureID = textureInfo.textureID
  and width = float textureInfo.width
  and height = float textureInfo.height
  and hasPremultipliedAlpha = textureInfo.premultipliedAlpha
  and scale = textureInfo.scale 
  in
  let res = 
    object(self)
      value mutable textureID = textureID;
      value mutable counter = 0;

      method retain () = counter := counter + 1;

      method releaseSubTexture () = 
      (
        counter := counter - 1;
        if counter = 0
        then self#release ()
        else ();
      );

      method release () = 
        if (textureID <> 0) 
        then
        (
          delete_texture textureID; 
          textureID := 0
        )
        else ();
      method width = width /. scale;
      method height = height /. scale;
      method hasPremultipliedAlpha = hasPremultipliedAlpha;
      method scale = scale;
      method setTextureID tid = textureID := tid;
      method textureID = textureID;
      method base = None;
      method clipping = None;
(*       method update path = ignore(loadImage ~textureID ~path ~contentScaleFactor:1.);  (* Fixme cache it *) *)
      method subTexture region = ((new subtexture region self) :> c);
      initializer Gc.finalise (fun t -> t#release ()) self;
    end
  in
  if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
  then new subtexture (Rectangle.create 0. 0. (float textureInfo.realWidth) (float textureInfo.realHeight)) res
  else res;

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


value load path : c = 
  try
    ((Cache.find cache path) :> c)
  with 
  [ Not_found ->
    let textureInfo = 
      proftimer:t "Loading texture [%F]" loadImage path 1. 
    in
    let () = debug:gc Gc.compact () in
    let () = 
      debug
        "load texture: %s [%d->%d; %d->%d] [pma=%s]\n%!" 
        path textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.premultipliedAlpha) 
    in
    let res = make textureInfo in
    (
      Cache.add cache path res;
      (res :> c)
    )
  ];


class type renderObject =
  object
    method render: ?alpha:float -> ?transform:bool -> option Rectangle.t -> unit;
  end;

type framebufferID;
external create_render_texture: int -> float -> float -> float -> (framebufferID*Render.textureID) = "ml_rendertexture_create";
type framebufferState;
external activate_framebuffer: framebufferID -> float -> float -> framebufferState = "ml_activate_framebuffer";
external deactivate_framebuffer: framebufferState -> unit = "ml_deactivate_framebuffer";
external delete_framebuffer: framebufferID -> unit = "ml_delete_framebuffer";

class type rendered = 
  object
    inherit c;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
  end;

value rendered ?(color=0) ?(alpha=0.) width height : rendered =
  let (frameBufferID,textureID) = create_render_texture color alpha width height in
  object(self)
    value mutable isActive = False;
    value mutable textureID = textureID;
    method width = width;
    method height = height;
    method hasPremultipliedAlpha = False;
    method scale = 1.;
    method textureID = textureID;
    method base : option (c*Rectangle.t) = None;
    method clipping : option Rectangle.t = None;
    method subTexture (region:Rectangle.t) : c = assert False;
    method release () = 
      if textureID <> 0
      then
      (
        delete_framebuffer frameBufferID;
        delete_texture textureID;
        textureID := 0;
      )
      else ();

    method draw f = 
      match isActive with
      [ False ->
        let oldState = activate_framebuffer frameBufferID width height in
        (
          debug "buffer activated";
          isActive := True;
          f();
          deactivate_framebuffer oldState;
          isActive := False;
        )
      | True -> f()
      ];

    method clear color alpha = 
      self#draw 
      (fun () -> Render.clear color alpha);
    initializer Gc.finalise (fun r -> r#release ()) self;

  end;

