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
    textureID: int;
  };

class type c = 
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: int;
    method base : option (c * Rectangle.t);
    method adjustTextureCoordinates: float_array -> unit;
    method update: string -> unit;
  end;



IFDEF SDL THEN

external loadTexture: textureInfo -> ubyte_array -> textureInfo = "ml_loadTexture";

value loadImage textureID ~path ~contentScaleFactor = 
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
        textureID = textureID;
      }
    in
    let res = loadTexture textureInfo (Sdl.Video.surface_pixels rgbSurface) in
    (
      Sdl.Video.free_surface rgbSurface;
      res
    );
  );

ELSE IFDEF IOS THEN
external loadImage: ~textureID:int -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
(* external freeImageData: GLTexture.textureInfo -> unit = "ml_freeImageData"; *)
ELSE IFDEF ANDROID THEN
external loadImage: ~textureID:int -> ~path:string -> ~contentScaleFactor:float -> textureInfo = "ml_loadImage";
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
    method setTextureID: int -> unit;
  end;

class subtexture region (baseTexture:c) = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let clipping = Rectangle.create (region.Rectangle.x /. tw) (region.Rectangle.y /. th) (region.Rectangle.width /. tw)  (region.Rectangle.height /. th) in
  let rootClipping = Rectangle.copy clipping in
  let () = 
    let open Rectangle in
    adjustClipping baseTexture where
      rec adjustClipping texture =
        match texture#base with
        [ None -> ()
        | Some (baseTexture,baseClipping) ->
            (
              rootClipping.x := baseClipping.x +. rootClipping.x *. baseClipping.width;
              rootClipping.y := baseClipping.y +. rootClipping.y *. baseClipping.height;
              rootClipping.width := rootClipping.width *. baseClipping.width;
              rootClipping.height := rootClipping.height *. baseClipping.height;
              adjustClipping baseTexture
            )
        ]
  in
  object
    method width = baseTexture#width *. clipping.Rectangle.width;
    method height = baseTexture#height *. clipping.Rectangle.height;
    method textureID = baseTexture#textureID;
    method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
    method scale = baseTexture#scale;
    method base = Some (baseTexture,clipping);
    method adjustTextureCoordinates (texCoords:float_array) = 
      for i = 0 to (Bigarray.Array1.dim texCoords) / 2 - 1 do
        texCoords.{2*i} := rootClipping.Rectangle.x +. texCoords.{2*i} *. rootClipping.Rectangle.width;
        texCoords.{2*i+1} := rootClipping.Rectangle.y +. texCoords.{2*i+1} *. rootClipping.Rectangle.height;
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


value load path : c = 
  try
    ((Cache.find cache path) :> c)
  with 
  [ Not_found ->
    let textureInfo = 
      proftimer "Loading texture [%F]" loadImage 0 path 1. 
    in
    let () = 
      debug
        "load texture: %s [%d->%d; %d->%d] [pma=%s]\n%!" 
        path textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.premultipliedAlpha) 
    in
(*     let textureID = GLTexture.create textureInfo in *)
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
        method hasPremultipliedAlpha = hasPremultipliedAlpha;
        method scale = scale;
        value mutable textureID = textureID;
        method setTextureID tid = textureID := tid;
        method textureID = textureID;
        method base = None;
        method adjustTextureCoordinates texCoords = ();
        method update path = ignore(loadImage textureID path 1.);  (* fixme cache it *)
      end
    in
    (
      Gc.finalise (fun _ -> let () = debug "finalize texture" in glDeleteTextures 1 [| textureID |]) res;
      let res = 
        if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
        then _createSubTexture (Rectangle.create 0. 0. (float textureInfo.realWidth) (float textureInfo.realHeight)) res
        else res
      in
      (
        Cache.add cache path res;
        (res :> c)
      )
    )
  ];


