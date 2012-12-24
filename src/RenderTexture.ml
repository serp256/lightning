open LightCommon;
open Texture;

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";
external delete_textureID: textureID -> unit = "ml_render_texture_id_delete" "noalloc";
(* external rendertexture_resize: renderInfo -> float -> float -> bool = "ml_rendertexture_resize"; *)


type framebuffer;
external renderbuffer_draw: ~filter:filter -> ?color:int -> ?alpha:float -> float -> float -> (framebuffer -> unit) -> renderInfo = "ml_renderbuffer_draw_byte" "ml_renderbuffer_draw";
external renderbuffer_draw_to_texture: ?clear:(int*float) -> ?width:float -> ?height:float -> renderInfo -> (framebuffer -> unit) -> bool = "ml_renderbuffer_draw_to_texture";

external renderbuffer_save: renderInfo -> string -> bool = "ml_renderbuffer_save";

module Renderers = Weak.Make(struct type t = renderer; value equal r1 r2 = r1 = r2; value hash = Hashtbl.hash; end);

class c renderInfo = 
  let () = debug "create rendered texture <%ld>" (int32_of_textureID renderInfo.rtextureID) in
  object(self)
    method renderInfo = renderInfo;
    method kind = renderInfo.kind;
    method asTexture = (self :> Texture.c);
    method scale = 1.;
    method texture = (self :> Texture.c);
    method width = renderInfo.rwidth;
    method height = renderInfo.rheight;
    method hasPremultipliedAlpha = match renderInfo.kind with [ Simple v -> v | _ -> assert False ];
    method textureID = renderInfo.rtextureID;
    method base : option Texture.c = None;
    method clipping = renderInfo.clipping;
    method rootClipping = renderInfo.clipping;
    method subTexture (region:Rectangle.t) : Texture.c = assert False;
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;


    value mutable released = False;
    method released = released;
    method release () = 
      match released with
      [ False ->
        (
(*           debug:gc "release rendered texture: [%d] <%ld>" framebufferID (int32_of_textureID renderInfo.rtextureID); *)
          delete_textureID renderInfo.rtextureID;
          released := True;
        )
      | True -> ()
      ];


    (*

    method clone () = 
      let rb = renderbuffer_clone rb.renderbuffer in
      new rbt rb;

    method resize w h = 
      match rendertexture_resize renderInfo w h with
      [ True -> 
        (
          Gc.compact ();
          Renderers.iter (fun r -> r#onTextureEvent `RESIZE (self :> Texture.c)) renderers
        )
      | False -> ()
      ];

    *)

    method draw ?clear ?width ?height (f:(framebuffer -> unit)) = 
      let resized = renderbuffer_draw_to_texture ?clear ?width ?height renderInfo f in
      (
        Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers;
        resized;
      );

    method save filename = renderbuffer_save renderInfo filename;


  end; (*}}}*)


value draw ~filter ?color ?alpha width height f = new c (renderbuffer_draw ~filter ?color ?alpha width height f);
