type textureID;

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


class type c = 
  object
    method bindGL: unit -> unit;
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: textureID;
    method base : option (c * Rectangle.t);
(*     method adjustTextureCoordinates: Gl.float_array -> unit; *)
    method clipping: option Rectangle.t;
    method update: string -> unit;
  end;



external glid_of_textureID: textureID -> int = "ml_glid_of_textureID" "noalloc";
value create: textureFormat -> int -> int -> option (Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout) -> c;
value load: string -> c;
value createSubTexture: Rectangle.t -> c -> c;
