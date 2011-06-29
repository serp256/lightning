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
(* external loadImage: ~path:string -> ~contentScaleFactor:float -> GLTexture.textureInfo = "ml_loadImage"; *)
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
ENDIF;
ENDIF;
ENDIF;

module Cache = WeakHashtbl.Make (struct
  type t = string;
  value equal = (=);
  value hash = Hashtbl.hash;
end);

value createSubTexture region baseTexture = 
  let tw = baseTexture#width
  and th = baseTexture#height in
  let open Rectangle in 
  let clipping = Rectangle.create (region.x /. tw) (region.y /. th) (region.width /. tw)  (region.height /. th) in
  let rootClipping = Rectangle.copy clipping in
  (
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
      ];
    object
      method width = baseTexture#width *. clipping.width;
      method height = baseTexture#height *. clipping.height;
      method textureID = baseTexture#textureID;
      method hasPremultipliedAlpha = baseTexture#hasPremultipliedAlpha;
      method scale = baseTexture#scale;
      method base = Some (baseTexture,clipping);
      method adjustTextureCoordinates texCoords = 
        for i = 0 to (Bigarray.Array1.dim texCoords) / 2 - 1 do
          texCoords.{2*i} := rootClipping.x +. texCoords.{2*i} *. rootClipping.width;
          texCoords.{2*i+1} := rootClipping.y +. texCoords.{2*i+1} *. rootClipping.height;
        done;
        
    end;
  );

value cache = Cache.create 11;

value load path : c = 
  try
    Cache.find cache path
  with 
  [ Not_found ->
    let open GLTexture in
    let textureInfo = loadImage path 1. in
    let () = Printf.eprintf "load texture: %s [%d->%d; %d->%d]\n%!" path textureInfo.realWidth textureInfo.width textureInfo.realHeight textureInfo.height in
    let textureID = GLTexture.create textureInfo in
    let width = float textureInfo.width
    and height = float textureInfo.height
    and hasPremultipliedAlpha = textureInfo.premultipliedAlpha
    and scale = textureInfo.scale 
    in
    let res = 
      object
        method width = width;
        method height = height;
        method hasPremultipliedAlpha = hasPremultipliedAlpha;
        method scale = scale;
        method textureID = textureID;
        method base = None;
        method adjustTextureCoordinates texCoords = ();
      end
    in
    (
      Gc.finalise (fun _ -> glDeleteTextures 1 [| textureID |]) res;
      let res = 
        if textureInfo.realHeight <> textureInfo.height || textureInfo.realWidth <> textureInfo.width 
        then
          createSubTexture (Rectangle.create 0. 0. (float textureInfo.realWidth) (float textureInfo.realHeight)) res
        else
          res
      in
      (
        Cache.add cache path res;
        res;
      );
    )
  ];


(*
value createFromFile path : c =
  let (width,height,hasPremultipliedAlpha,scale,textureID) = _createFromFile path 1. in
  let res = 
    object
      method width = width;
      method height = height;
      method hasPremultipliedAlpha = hasPremultipliedAlpha;
      method scale = scale;
      method textureID = textureID;
      method base = None;
      method adjustTextureCoordinates texCoords = ();
    end
  in
  (
    Gc.finalise (fun _ -> glDeleteTextures 1 [| textureID |]) res;
    res;
  );
*)


