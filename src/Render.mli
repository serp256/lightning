open LightCommon;

exception GL_error of string;

external push_matrix: Matrix.t -> unit = "ml_push_matrix";
external restore_matrix: unit -> unit = "ml_restore_matrix";
external clear: int -> float -> unit = "ml_clear";
external checkErrors: string -> unit = "ml_checkGLErrors";

external get_gl_extensions: unit -> string = "ml_get_gl_extensions";

type blend_dfactor =
  [= `GL_ZERO
  | `GL_ONE
  | `GL_SRC_COLOR
  | `GL_ONE_MINUS_SRC_COLOR
  | `GL_DST_COLOR
  | `GL_ONE_MINUS_DST_COLOR
  | `GL_SRC_ALPHA
  | `GL_ONE_MINUS_SRC_ALPHA
  | `GL_DST_ALPHA
  | `GL_ONE_MINUS_DST_ALPHA
  (*
  | `GL_CONSTANT_COLOR
  | `GL_ONE_MINUS_CONSTANT_COLOR
  | `GL_CONSTANT_ALPHA
  | `GL_ONE_MINUS_CONSTANT_ALPHA
  *)
  ];

type blend_sfactor = [= blend_dfactor | `GL_SRC_ALPHA_SATURATE ];

type blend = [ BlendSimple of (blend_sfactor * blend_dfactor) | BlendSeparate of (blend_sfactor * blend_dfactor * blend_sfactor * blend_dfactor) ];
type intblend;
value intblend_of_blend: blend -> intblend;


module Program: sig 
  type t;
  type id;
  type attribute = [ AttribPosition |  AttribTexCoords | AttribColor ]; (* с атриббутами пока так *)
  type uniform = [ UNone | UInt of int | UInt2 of (int*int) | UInt3 of (int*int*int) | UFloat of float | UFloat2 of (float*float) ];

  value gen_id: unit -> id;
  value load: id -> ~vertex:string -> ~fragment:string -> ~attributes:list (attribute*string) -> ~uniforms:array (string * uniform) -> t;
end;

type filter;
type prg = (Program.t * (option filter));

module Quad: sig
  type t;
  external create: ~w:float -> ~h:float -> ~color:color -> ~alpha:float -> t = "ml_quad_create";
  external points: t -> array Point.t = "ml_quad_points";
(*   external color: t -> int = "ml_quad_color"; *)
  external set_color: t -> color -> unit = "ml_quad_set_color";
(*   external colors: t -> array int = "ml_quad_colors"; *)
  external alpha: t -> float = "ml_quad_alpha";
  external set_alpha: t -> float -> unit = "ml_quad_set_alpha";
  external render: Matrix.t -> prg -> ?alpha:float -> t -> unit = "ml_quad_render" "noalloc";
end;



module Image: sig

  type t;

  external create: Texture.renderInfo -> ~color:color -> ~alpha:float -> t = "ml_image_create";
  external flipTexX: t -> unit = "ml_image_flip_tex_x" "noalloc";
  external flipTexY: t -> unit = "ml_image_flip_tex_y" "noalloc";
  external points: t -> array Point.t = "ml_image_points";
  external set_color: t -> color -> unit = "ml_image_set_color" "noalloc";
(*   external set_color: t -> int -> unit = "ml_image_set_color" "noalloc"; *)
(*   external set_colors: t -> array int -> unit = "ml_image_set_colors"; *)
(*   external color: t -> int = "ml_image_color"; *)
  external set_alpha: t -> float -> unit = "ml_image_set_alpha" "noalloc";
(*   external colors: t -> array int = "ml_quad_colors"; *)
  external update: t -> Texture.renderInfo -> ~flipX:bool -> ~flipY:bool -> unit =  "ml_image_update" "noalloc";
  external render: Matrix.t -> prg -> ?alpha:float -> ?blend:intblend -> t -> unit = "ml_image_render" "noalloc"; 

end;
