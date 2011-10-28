open LightCommon;
open Gl;

class type renderObject =
  object
    method render: option Rectangle.t -> unit;
    method transformGLMatrix: unit -> unit;
  end;

type framebufferID;
external create_render_texture: float -> float -> (framebufferID,Texture.textureID) = "ml_create_render_texture";

class c ?(color=0) ?(alpha=0.) width height = 
  let (frameBufferID,textureID) = create_render_texture width height in
  object
    method width = width;
    method height = height;
    method hasPremultipliedAlpha = False;
    method scale = 1.;
    method textureID = textureID;
    method base = None;
    method clipping = None;
    method subTexture region = assert False;
    method drawObject obj = 
    method release () = 
    (
      delete_framebuffer frameBufferID;
      delete_texture textureID;
    );
  end;

(*

IFDEF SDL THEN
value glGenFramebuffers = glGenFramebuffersEXT;
value glBindFramebuffer = glBindFramebufferEXT;
value glFramebufferTexture2D = glFramebufferTexture2DEXT;
value glDeleteFramebuffers = glDeleteFramebuffersEXT;
value gl_framebuffer_l = gl_framebuffer_ext;
value gl_color_attachment0 = gl_color_attachment0_ext;
value glCheckFramebufferStatus = glCheckFramebufferStatusEXT;
value gl_framebuffer_complete_l = gl_framebuffer_complete_ext;
value gl_framebuffer_binding = gl_framebuffer_binding_ext;
ELSE
value glGenFramebuffers = glGenFramebuffersOES;
value glBindFramebuffer = glBindFramebufferOES;
value glFramebufferTexture2D = glFramebufferTexture2DOES;
value glDeleteFramebuffers = glDeleteFramebuffersOES;
value gl_framebuffer_l = gl_framebuffer_oes;
value gl_color_attachment0 = gl_color_attachment0_oes;
value glCheckFramebufferStatus = glCheckFramebufferStatusOES;
value gl_framebuffer_complete_l = gl_framebuffer_complete_oes;
value gl_framebuffer_binding = gl_framebuffer_binding_oes;
ENDIF;

class c ?(color=0) ?(alpha=0.) ?(scale=1.) width height =
  (*
  let textureID = 
    let texturesID = Array.make 1 0 in
    (
      glGenTextures 1 texturesID;
      texturesID.(0)
    )
  in
  let iWidth = truncate width
  and iHeight = truncate height in
  let legalWidth = nextPowerOfTwo iWidth
  and legalHeight = nextPowerOfTwo iHeight in
  let _texture = 
    (
      glBindTexture gl_texture_2d textureID;
      glTexParameteri gl_texture_2d gl_texture_mag_filter gl_linear; 
      glTexParameteri gl_texture_2d gl_texture_min_filter gl_linear;
      glTexParameteri gl_texture_2d gl_texture_wrap_s gl_clamp_to_edge;
      glTexParameteri gl_texture_2d gl_texture_wrap_t gl_clamp_to_edge;
      glTexImage2D gl_texture_2d 0 gl_rgba legalWidth legalHeight 0 gl_rgba gl_unsigned_byte 0;
      glBindTexture gl_texture_2d 0;
      let tWidth = float legalWidth
      and tHeight = float legalHeight in
      let texture = 
        object 
          method bindGL = glBindTexture gl_texture_2d textureID;
          method width = tWidth;
          method height = tHeight;
          method hasPremultipliedAlpha = False;
          method scale = scale;
          method textureID = textureID;
          method base = None;
          method adjustTextureCoordinates texCoords = ();
          method update path = ();
        end
      in
      if legalWidth <> iWidth || legalHeight <> iHeight
      then Texture.createSubTexture (Rectangle.create 0. 0. width height) texture
      else texture
    )
  in
  *)
  let texture = Texture.create Texture.TextureFormatRGBA (truncate width) (truncate height) None in
  let textureID = Texture.glid_of_textureID texture#textureID in
  let framebufferID = 
  (
    let () = debug "render textureID: %d" textureID in
    let framebuffers = Array.make 1 0 in
    (
      glGenFramebuffers 1 framebuffers;
      let framebufferID = framebuffers.(0) in
      (
        glBindFramebuffer gl_framebuffer_l framebufferID;
        glFramebufferTexture2D gl_framebuffer_l gl_color_attachment0 gl_texture_2d textureID 0;
        if glCheckFramebufferStatus gl_framebuffer_l <> gl_framebuffer_complete_l
        then failwith("failed to create frame buffer for render texture")
        else ();
        RenderSupport.clear color alpha;
        glBindFramebuffer gl_framebuffer_l 0;
        framebufferID;
      )
    )
  )
  in
  let () = debug "textureID: %d, framebufferID: %d" textureID framebufferID in

  object(self)
    method texture = texture;
    value framebufferID = framebufferID;
    value mutable framebufferIsActive = False;

    method private renderToFramebuffer draw = 
      let stdFramebuffer = ref ~-1 in
      (
        match framebufferIsActive with
        [ False ->
          (
            debug "bind framebuffer %d" framebufferID;
            framebufferIsActive := True;
            let stdBuffer = Array.make 1 0 in
            (
              glGetIntegerv gl_framebuffer_binding stdBuffer;
              (* remember standard frame buffer  *)
              debug "std buffer: %d" stdBuffer.(0);
              stdFramebuffer.val := stdBuffer.(0);
            );
            (* switch to the texture's framebuffer for rendering *)
            glBindFramebuffer gl_framebuffer_l framebufferID;
            let scale = texture#scale 
            and width = texture#width
            and height = texture#height in
            (
              glViewport 0 0 (truncate (width *. scale)) (truncate (height *. scale));
              RenderSupport.setupOrthographicRendering 0. width 0. height;
            )
            (* reset here *)
          )
        | True -> ()
        ];
        draw();
        if !stdFramebuffer <> -1 
        then
        (
          framebufferIsActive := False;
          glBindFramebuffer gl_framebuffer_l !stdFramebuffer
        )
        else ()
      );


    method clear color alpha = 
      self#renderToFramebuffer (fun () -> RenderSupport.clear color alpha);

    method drawObject: !'ro. (#renderObject as 'ro) -> unit = fun dp ->
      let f () =
        (
          glPushMatrix();
          dp#transformGLMatrix();
          dp#render None;
          glPopMatrix();
        )
      in
      self#renderToFramebuffer f;

    initializer Gc.finalise (fun _ -> glDeleteFramebuffers 1 [| framebufferID |]) self;

  end;
*)



value create = new c;
