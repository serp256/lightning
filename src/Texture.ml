open LightCommon;
open Gl;

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


type textureID;

external glid_of_textureID: textureID -> int = "ml_glid_of_textureID" "noalloc";
external bind_texture: textureID -> unit = "ml_bind_texture" "noalloc";

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
    textureID: textureID;
  };

class type c = 
  object
    method bindGL: unit -> unit;
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: textureID;
    method base : option (c * Rectangle.t);
    method adjustTextureCoordinates: float_array -> unit;
    method update: string -> unit;
  end;


external loadTexture: textureInfo -> option ubyte_array -> textureInfo = "ml_loadTexture";

IFDEF SDL THEN

value loadImage ?textureID ~path ~contentScaleFactor = 
  let surface = Sdl_image.load (LightCommon.resource_path path 1.) in
  let bpp = Sdl.Video.surface_bpp surface in
  let () = assert (bpp = 32) in
  let width = Sdl.Video.surface_width surface in
  let legalWidth = nextPowerOfTwo width in
  let height = Sdl.Video.surface_height surface in
  let legalHeight = nextPowerOfTwo height in
  let rgbSurface = Sdl.Video.create_rgb_surface [Sdl.Video.HWSURFACE] legalWidth legalHeight bpp in
  (
    Sdl.Video.set_alpha surface [] 0;
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
        generateMipmaps = True;
        premultipliedAlpha = False;
        scale = 1.0;
        textureID = Obj.magic textureID;
      }
    in
    let res = loadTexture textureInfo (Some (Sdl.Video.surface_pixels rgbSurface)) in
    (
      Sdl.Video.free_surface rgbSurface;
      res
    );
  );

ELSE IFDEF IOS THEN
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
(* external freeImageData: GLTexture.textureInfo -> unit = "ml_freeImageData"; *)
ELSE IFDEF ANDROID THEN
external loadImage: ?textureID:textureID -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
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
    method setTextureID: textureID -> unit;
  end;

class subtexture region (baseTexture:c) = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let clipping = Rectangle.create (region.Rectangle.x /. tw) (region.Rectangle.y /. th) (region.Rectangle.width /. tw)  (region.Rectangle.height /. th) in
  let rootClipping = Rectangle.tm_of_t clipping in
  let () = 
    let open Rectangle in
    adjustClipping baseTexture where
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
  object
    method bindGL () = bind_texture baseTexture#textureID;
    method width = baseTexture#width *. clipping.Rectangle.width;
    method height = baseTexture#height *. clipping.Rectangle.height;
    method textureID = baseTexture#textureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
    method scale = baseTexture#scale;
    method base = Some (baseTexture,clipping);
    method adjustTextureCoordinates (texCoords:float_array) = 
      for i = 0 to (Bigarray.Array1.dim texCoords) / 2 - 1 do
        texCoords.{2*i} := rootClipping.Rectangle.m_x +. texCoords.{2*i} *. rootClipping.Rectangle.m_width;
        texCoords.{2*i+1} := rootClipping.Rectangle.m_y +. texCoords.{2*i+1} *. rootClipping.Rectangle.m_height;
      done;
    method update path = baseTexture#update path;
  end;

value createSubTexture = new subtexture;

value _createSubTexture region (baseTexture:r) =
  object 
    inherit subtexture region (baseTexture :> c);
    method setTextureID tid = baseTexture#setTextureID tid;
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

value make textureInfo = 
  let textureID = textureInfo.textureID
  and width = float textureInfo.width
  and height = float textureInfo.height
  and hasPremultipliedAlpha = textureInfo.premultipliedAlpha
  and scale = textureInfo.scale 
  in
  let res : r = 
    object
      method width = width;
      method height = height;
      method bindGL () = bind_texture textureID;
      method hasPremultipliedAlpha = hasPremultipliedAlpha;
      method scale = scale;
      value mutable textureID = textureID;
      method setTextureID tid = textureID := tid;
      method textureID = textureID;
      method base = None;
      method adjustTextureCoordinates texCoords = ();
      method update path = ignore(loadImage ~textureID ~path ~contentScaleFactor:1.);  (* Fixme cache it *)
    end
  in
  if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
  then _createSubTexture (Rectangle.create 0. 0. (float textureInfo.realWidth) (float textureInfo.realHeight)) res
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
      proftimer "Loading texture [%F]" loadImage path 1. 
    in
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


