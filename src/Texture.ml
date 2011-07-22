open Gl;

class type c = 
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: int;
    method base : option (c * Rectangle.t);
    method adjustTextureCoordinates: float_array -> unit;
  end;



IFDEF SDL THEN
value rec nextPowerOfTwo number =
  let rec loop result = 
    if result < number 
    then loop (result * 2)
    else result
  in 
  loop 1;

(*
value loadImage ~path ~contentScaleFactor = 
  let surface = Sdl_image.load (LightCommon.resource_path path 1.) in
  let width = Sdl.Video.surface_width surface in
  let height = Sdl.Video.surface_height surface in
  let textureInfo = 
    let open GLTexture in 
    {
        texFormat = TextureFormatRGBA;
        realWidth = width;
        width = width;
        realHeight = height;
        height = height;
        numMipmaps = 0;
        generateMipmaps = True;
        premultipliedAlpha = True;
        scale = 1.0; (* FIXME: *)
        imgData = Sdl.Video.surface_pixels surface
    }
  in
  (
    Gc.finalise (fun _ -> Sdl.Video.free_surface surface) textureInfo;
    textureInfo
  );
*)

value loadImage ~path ~contentScaleFactor = 
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
      let open GLTexture in 
      {
        texFormat = TextureFormatRGBA;
        realWidth = width;
        width = legalWidth;
        realHeight = height;
        height = legalHeight;
        numMipmaps = 0;
        generateMipmaps = True;
        premultipliedAlpha = False;
        scale = 1.0; (* FIXME: *)
        imgData = Sdl.Video.surface_pixels rgbSurface
      }
    in
    (
      Gc.finalise (fun _ -> Sdl.Video.free_surface rgbSurface) textureInfo;
      textureInfo
    );
  );

ELSE IFDEF IOS THEN
external loadImage: ~path:string -> ~contentScaleFactor:float -> GLTexture.textureInfo = "ml_loadImage";
ELSE IFDEF ANDROID THEN
external loadImage: ~path:string -> ~contentScaleFactor:float -> GLTexture.textureInfo = "ml_loadImage";
(*
value loadImage ~path ~contentScaleFactor = 
  let ba =  (* Gl.make_ubyte_array (8 * 8 * 4) in *)
    Bigarray.Array1.of_array Bigarray.int8_unsigned Bigarray.c_layout 
    [| 
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;
        0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF;  0xFF; 0xFF; 0xFF; 0xFF
    |]
  in
  (
    let open GLTexture in 
    {
      texFormat = TextureFormatRGBA;
      realWidth = 8; width = 8;
      realHeight = 8; height = 8;
      numMipmaps = 0; generateMipmaps = True;
      premultipliedAlpha = False; scale = 1.0;
      imgData = ba
    };
  );
*)
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
  end;

value createSubTexture = new subtexture;

value _createSubTexture region (baseTexture:r) =
  object 
    inherit subtexture region (baseTexture :> c);
    method setTextureID tid = baseTexture#setTextureID tid;
  end;


value cache = Cache.create 11;



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


value load path : c = 
  try
    ((Cache.find cache path) :> c)
  with 
  [ Not_found ->
    let open GLTexture in
    let textureInfo = loadImage path 1. in
    let () = 
      debug
        "load texture: %s [%d->%d; %d->%d] [pma=%s] [bytes=%d]\n%!" 
        path textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height 
        (string_of_bool textureInfo.premultipliedAlpha) (Bigarray.Array1.dim textureInfo.imgData) 
    in
    let () = print_endline "now create gl texture" in
    let textureID = GLTexture.create textureInfo in
    let () = print_endline "GLTexture loaded" in
    let width = float textureInfo.width
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
      end
    in
    (
      Gc.finalise (fun _ -> glDeleteTextures 1 [| textureID |]) res;
      let res = 
        if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
        then _createSubTexture (Rectangle.create 0. 0. (float textureInfo.realWidth) (float textureInfo.realHeight)) res
        else res
      in
      (
        Cache.add cache path res);
        (res :> c)
    )
  ];


