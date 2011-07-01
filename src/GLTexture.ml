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
    imgData: ubyte_array;
  };


type tinfo = 
  {
    compressed: bool;
    glTexType: int;
    bitsPerPixel: int;
    glTexFormat: int
  };

value create textureInfo = 
  let repeat = False in
  let info =
    let info = 
      {
        compressed = False;
        glTexType = gl_unsigned_byte;
        bitsPerPixel = 8;
        glTexFormat = gl_rgba
      }
    in
    match textureInfo.texFormat with (*{{{*)
    [ TextureFormatRGBA -> info
    | TextureFormatRGB -> {(info) with glTexFormat = gl_rgb }
    | TextureFormatAlpha ->
        {(info)  with
          bitsPerPixel = 8;
          glTexFormat = gl_alpha
        }
    | TextureFormatPvrtcRGBA2 ->
        IFDEF GLES THEN
          {(info) with
            compressed = True;
            bitsPerPixel = 2;
            glTexFormat = gl_compressed_rgba_pvrtc_2bppv1_img
          }
        ELSE failwith "PVRTC not supported on this platform" END
    | TextureFormatPvrtcRGB2 ->
        IFDEF GLES THEN
          {(info) with
            compressed = True;
            bitsPerPixel = 2;
            glTexFormat = gl_compressed_rgb_pvrtc_2bppv1_img
          }
        ELSE failwith "PVRTC not supported on this platform" END
    | TextureFormatPvrtcRGBA4 ->
        IFDEF GLES THEN
          {(info) with
            compressed = True;
            bitsPerPixel = 4;
            glTexFormat = gl_compressed_rgba_pvrtc_4bppv1_img
          }
        ELSE failwith "PVRTC not supported on this platform" END
    | TextureFormatPvrtcRGB4 ->
        IFDEF GLES THEN
          {(info) with
            compressed = True;
            bitsPerPixel = 4;
            glTexFormat = gl_compressed_rgb_pvrtc_4bppv1_img
          }
        ELSE failwith "PVRTC not supported on this platform" END
    | TextureFormat565 ->
        {(info) with
          bitsPerPixel = 16;
          glTexFormat = gl_rgb;
          glTexType = gl_unsigned_short_5_6_5
        }
    | TextureFormat5551 ->
        {(info) with
          bitsPerPixel = 16;
          glTexFormat = gl_rgba;
          glTexType = gl_unsigned_short_5_5_5_1
        }
    | TextureFormat4444 ->
        {(info) with
          bitsPerPixel = 16;
          glTexFormat = gl_rgba;
          glTexType = gl_unsigned_short_4_4_4_4                   
        }
    ](*}}}*)
  in
  let texturesID = Array.make 1 0 in
  (
    glGenTextures 1 texturesID;
    let textureID = texturesID.(0) in
    (
      glBindTexture gl_texture_2d textureID;
      glTexParameteri gl_texture_2d gl_texture_mag_filter gl_linear; 
      glTexParameteri gl_texture_2d gl_texture_wrap_s (if repeat then gl_repeat else gl_clamp_to_edge);
      glTexParameteri gl_texture_2d gl_texture_wrap_t (if repeat then gl_repeat else gl_clamp_to_edge);
      match info.compressed with
      [ False ->
        (
          if textureInfo.numMipmaps > 0 || textureInfo.generateMipmaps
          then
            glTexParameteri gl_texture_2d gl_texture_min_filter gl_linear_mipmap_nearest
          else
            glTexParameteri gl_texture_2d gl_texture_min_filter gl_linear;
          
          if textureInfo.numMipmaps = 0 && textureInfo.generateMipmaps
          then
              glTexParameteri gl_texture_2d gl_generate_mipmap gl_true
          else ();
          
          let levelWidth = ref textureInfo.width and levelHeight = ref textureInfo.height and levelPtr = ref 0 in
          for level = 0 to textureInfo.numMipmaps do
            (
              let size = !levelWidth * !levelHeight * info.bitsPerPixel / 8 in
              (
                let levelData = Bigarray.Array1.sub textureInfo.imgData !levelPtr size in
                glTexImage2D gl_texture_2d level info.glTexFormat !levelWidth !levelHeight 0 info.glTexFormat info.glTexType levelData;
                levelPtr.val := !levelPtr + size;
              );
              levelWidth.val  := !levelWidth / 2; 
              levelHeight.val := !levelHeight / 2;
            )
          done
        )
      | True ->
        (
          (* 'generateMipmaps' not supported for compressed textures *)
          glTexParameteri gl_texture_2d gl_texture_min_filter (if textureInfo.numMipmaps = 0 then gl_linear else gl_linear_mipmap_nearest);
          let levelWidth = ref textureInfo.width and levelHeight = ref textureInfo.height and levelPtr = ref 0 in
          for level = 0 to textureInfo.numMipmaps do
            (
              let size = max 32 (!levelWidth * !levelHeight * info.bitsPerPixel / 8) in
              (
                let levelData = Bigarray.Array1.sub textureInfo.imgData !levelPtr size in
                glCompressedTexImage2D gl_texture_2d level info.glTexFormat !levelWidth !levelHeight 0 size levelData;
                levelPtr.val := !levelPtr + size;
              );
              levelWidth.val := !levelWidth / 2; 
              levelHeight.val := !levelHeight / 2;
            )
          done
        )
      ];
      glBindTexture gl_texture_2d 0;
      ignore(RenderSupport.checkForOpenGLError());
      textureID;
    );
  );
