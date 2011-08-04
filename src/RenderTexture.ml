open LightCommon;
open Gl;

class type renderObject =
  object
    method render: option Rectangle.t -> unit;
    method transformGLMatrix: unit -> unit;
  end;



IFDEF SDL THEN
value glGenFramebuffers = glGenFramebuffersEXT;
value glBindFramebuffer = glBindFramebufferEXT;
value glFramebufferTexture2D = glFramebufferTexture2DEXT;
value gl_framebuffer_l = gl_framebuffer_ext;
value gl_color_attachment0 = gl_color_attachment0_ext;
value glCheckFramebufferStatus = glCheckFramebufferStatusEXT;
value gl_framebuffer_complete_l = gl_framebuffer_complete_ext;
value gl_framebuffer_binding = gl_framebuffer_binding_ext;
ELSE
value glGenFramebuffers = glGenFramebuffersOES;
value glBindFramebuffer = glBindFramebufferOES;
value glFramebufferTexture2D = glFramebufferTexture2DOES;
value gl_framebuffer_l = gl_framebuffer_oes;
value gl_color_attachment0 = gl_color_attachment0_oes;
value glCheckFramebufferStatus = glCheckFramebufferStatusOES;
value gl_framebuffer_complete_l = gl_framebuffer_complete_oes;
value gl_framebuffer_binding = gl_framebuffer_binding_oes;
ENDIF;

class c ?(color=0) ?(alpha=0.) ?(scale=1.) width height =
  let textureID = 
    let texturesID = Array.make 1 0 in
    (
      glGenTextures 1 texturesID;
      texturesID.(0)
    )
  in
  let legalWidth = nextPowerOfTwo width
  and legalHeight = nextPowerOfTwo height in
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
      if legalWidth <> width || legalHeight <> height
      then Texture.createSubTexture (Rectangle.create 0. 0. (float width) (float height)) texture
      else texture
    )
  in
  let framebufferID = 
  (
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
    value texture : Texture.c = _texture;
    method texture = texture;
    value framebufferID = framebufferID;
    value mutable framebufferIsActive = False;

    method private renderToFramebuffer draw = 
      let stdFramebuffer = ref ~-1 in
      (
        match framebufferIsActive with
        [ False ->
          (
            debug "bind framebuffer";
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

  end;
