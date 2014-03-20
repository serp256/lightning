open LightCommon;
open Texture;
open ExtList;

external set_texture_filter: textureID -> filter -> unit = "ml_texture_set_filter" "noalloc";
(* external delete_textureID: textureID -> unit = "ml_render_texture_id_delete" "noalloc"; *)

type framebuffer;

(*
external renderbuffer_draw_dedicated: ~filter:filter -> ?clear:(int*float) -> textureID -> int -> int -> float -> float -> (framebuffer -> unit) -> renderInfo = "ml_renderbuffer_draw_dedicated_byte"
"ml_renderbuffer_draw_dedicated";
external renderbuffer_draw: ~filter:filter -> ~clear:(int*float) -> textureID -> int -> int -> float -> float -> (framebuffer -> unit) -> renderInfo = "ml_renderbuffer_draw_byte" "ml_renderbuffer_draw";
*)
(* external renderbuffer_draw_to_texture: ?clear:(int*float) -> ?new_params:(int * int * float * float) -> ?new_tid:textureID -> renderInfo -> (framebuffer -> unit) -> unit = "ml_renderbuffer_draw_to_texture"; *)
(* external renderbuffer_draw_to_dedicated_texture: ?clear:(int*float) -> ?width:float -> ?height:float -> renderInfo -> (framebuffer -> unit) -> bool = "ml_renderbuffer_draw_to_dedicated_texture"; *)


(* external create_renderbuffer_tex: ?size:(int * int) -> unit -> textureID = "ml_create_renderbuffer_tex"; *)
(* external create_renderbuffer: unit -> (framebuffer * textureID) = "ml_create_renderbuffer"; *)
(* external _renderbuffer_tex_size: unit -> int = "ml_renderbuffer_tex_size"; *)

(* value lazy_renderbuffer_tex_size = 
  Lazy.from_fun (
    debug (fun () -> let res = _renderbuffer_tex_size () in (debug "renderbuffer_tex_size %d" res; res))
    else _renderbuffer_tex_size;
  );

value renderbufferTexSize () = Lazy.force lazy_renderbuffer_tex_size; *)

(* external renderbuffer_save: renderInfo -> string -> bool = "ml_renderbuffer_save";
external dumptex: textureID -> unit = "ml_dumptex"; *)

type data = Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;
external renderbuffer_data: renderInfo -> data = "ml_renderbuffer_data";

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
    method subTexture (region:Rectangle.t) : Texture.c = assert False;
    value renderers = Renderers.create 1;
    method addRenderer r = Renderers.add renderers r;
    method removeRenderer r = Renderers.remove renderers r;
    method setFilter filter = set_texture_filter renderInfo.rtextureID filter;

    value mutable released = False;
    method released = released;
    method virtual release: unit -> unit;
    method virtual draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method data () = renderbuffer_data renderInfo;
    (* method save filename = renderbuffer_save renderInfo filename; *)
    method save (filename:string) = False;
  end; (*}}}*)

external rendertexDraw: ?clear:(int * float) -> ?width:float -> ?height:float -> renderInfo -> (framebuffer -> unit) -> bool -> bool = "rendertex_draw_byte" "rendertex_draw";

class shared renderInfo =
  object(self)
    inherit base renderInfo;

    method release () = ();
(*       match released with 
      [ False ->
        let rx = renderInfo.rx - (texRectDimCorrection (int_of_float (ceil renderInfo.rwidth))) / 2 in
        let ry = renderInfo.ry - (texRectDimCorrection (int_of_float (ceil renderInfo.rheight))) / 2 in
        (
          FramebufferTexture.freeRect renderInfo.rtextureID rx ry;
          released := True;
        )
      | True -> ()
      ]; *)

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

    method release () = ();
(*       match released with
      [ False ->
        (
          delete_textureID renderInfo.rtextureID;
          released := True;
        )
      | True -> ()
      ]; *)

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

external rendertexCreate: ?kind:kind -> ?color:int -> ?alpha:float -> float -> float -> (framebuffer -> unit) -> (renderInfo * bool) = "rendertex_create_byte" "rendertex_create";

value draw ?(kind=Shared) ?color ?alpha width height f =
  let (renderInfo, dedicated) = rendertexCreate ~kind ?color ?alpha width height f in
    if dedicated
    then new dedicated renderInfo
    else new shared renderInfo;

(* value draw ?(kind=Shared) ?color ?alpha width height f =
  let width = int_of_float (ceil width) in
  let height = int_of_float (ceil height) in

  let clear =
    match (color, alpha) with
    [ (Some color, Some alpha) -> (color, alpha)
    | (Some color, _) -> (color, 0.)
    | (_, Some alpha) -> (0x000000, alpha)
    | _ -> (0x000000, 0.)
    ]
  in

  let dedicated = dedicated || (width > (renderbufferTexSize ()) / 2) || (height > (renderbufferTexSize ()) / 2) in

  match dedicated with
  [ True ->
      let rectw = nextPowerOfTwo width
      and recth = nextPowerOfTwo height in
      let offsetx = (rectw - width) / 2
      and offsety = (recth - height) / 2 in
      let tid = create_renderbuffer_tex ~size:(rectw, recth) in
      let renderInfo = renderbuffer_draw ~filter ~clear tid offsetx offsety (float width) (float height) f
      new dedicated renderInfo;
  | False ->
      let (rectw,recth,offsetx,offsety) =
        let widthCrrcnt = texRectDimCorrection width in
        let heightCrrcnt = texRectDimCorrection height in
          (width + widthCrrcnt, height + heightCrrcnt, widthCrrcnt / 2, heightCrrcnt / 2)
      in

      let ((fb,tid), pos) = proftimer:perfomance "FramebufferTexture.getRect %f" (FramebufferTexture.getRect rectw recth) in
      let posx = FramebufferTexture.Point.x pos + offsetx
      and posy = FramebufferTexture.Point.y pos + offsety
      in
      let renderInfo = 
        proftimer:perfomance "renderbuffer_draw %f" (
          renderbuffer_draw_shared fb ~filter ~clear posx posy (float width) (float height) f
        ) in
      let tex = new shared renderInfo in (
        Gc.finalise (fun tex -> tex#release () ) tex;
        tex;        
      )
  ]; *)
