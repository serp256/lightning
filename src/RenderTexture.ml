open LightCommon;
open Texture;
open ExtList;

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";

type framebuffer;

external rendertex_save: renderInfo -> string -> bool = "rendertex_save";

type data = Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;
external rendertex_data: renderInfo -> data = "rendertex_data"; (* create backend for this func!!! *)
external rendertex_release: renderInfo -> unit = "rendertex_release";

module Renderers = Weak.Make(struct type t = renderer; value equal r1 r2 = r1 = r2; value hash = Hashtbl.hash; end);

class virtual base renderInfo = 
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

    method subTexture region =
      let scale = !scale in
      let clipping = 
        let tw = renderInfo.rwidth /. scale
        and th = renderInfo.rheight /. scale in
        Rectangle.create 
          (region.Rectangle.x /. tw) 
          (region.Rectangle.y /. th) 
          (region.Rectangle.width /. tw) 
          (region.Rectangle.height /. th) 
      in
        Texture.createSubtex region clipping scale (self :> c);

    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;

    value mutable released = False;
    method released = released;
    method virtual release: unit -> unit;
    method virtual draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method data () = rendertex_data renderInfo;
    method save filename = rendertex_save renderInfo filename;
  end; (*}}}*)

external rendertexDraw: ?clear:(int * float) -> ?width:float -> ?height:float -> renderInfo -> (framebuffer -> unit) -> bool -> bool = "rendertex_draw_byte" "rendertex_draw";

class shared renderInfo =
  object(self)
    inherit base renderInfo;

    method release () =
      if released
      then ()
      else
        (
          rendertex_release renderInfo;
          released := True;
        );

    method draw ?clear ?width ?height (f:(framebuffer -> unit)) =
      let resized = rendertexDraw ?clear ?width ?height renderInfo f False in
        (
          Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers;
          resized;
        ); 
  end;

class dedicated renderInfo =
  object(self)
    inherit base renderInfo;

    method release () = released := True;

    method draw ?clear ?width ?height (f:(framebuffer -> unit)) =
      let resized = rendertexDraw ?clear ?width ?height renderInfo f True in
        (
          Renderers.iter (fun r -> r#onTextureEvent resized (self :> Texture.c)) renderers;
          resized;
        );
  end;

class type c =
  object
    inherit Texture.c;
    method asTexture: Texture.c;
    method draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method texture: Texture.c;
    method save: string -> bool;
    method data: unit -> data; 
  end;  

type kind = [ Shared | Dedicated of Texture.filter ];

external rendertexCreate: ?color:int -> ?alpha:float -> kind -> float -> float -> (framebuffer -> unit) -> (renderInfo * bool) = "rendertex_create_byte" "rendertex_create";

value draw ?(kind=Shared) ?color ?alpha width height f =
  let (renderInfo, dedicated) = rendertexCreate ?color ?alpha kind width height f in
    if dedicated
    then new dedicated renderInfo
    else
      let tex = new shared renderInfo in
        (
          Gc.finalise (fun tex -> let () = debug "shared release" in tex#release () ) tex;
          tex;
        );
