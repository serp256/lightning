open LightCommon;

exception GL_error of string;
Callback.register_exception "gl_error" (GL_error "no error");

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


value int_of_blend_factor = fun
  [ `GL_ZERO                -> 0
  | `GL_ONE                 -> 1
  | `GL_SRC_COLOR           -> 0x0300
  | `GL_ONE_MINUS_SRC_COLOR -> 0x0301
  | `GL_SRC_ALPHA           -> 0x0302
  | `GL_ONE_MINUS_SRC_ALPHA -> 0x0303
  | `GL_DST_ALPHA           -> 0x0304
  | `GL_ONE_MINUS_DST_ALPHA -> 0x0305
  | `GL_DST_COLOR           -> 0x0306
  | `GL_ONE_MINUS_DST_COLOR -> 0x0307
  | `GL_SRC_ALPHA_SATURATE  -> 0x0308
  ];

type blend = [ BlendSimple of (blend_sfactor * blend_dfactor) | BlendSeparate of (blend_sfactor * blend_dfactor * blend_sfactor * blend_dfactor) ];
type intblend = [ IntBlendSimple of (int*int) | IntBlendSeparate of (int*int*int*int) ];
value intblend_of_blend = fun
  [ BlendSimple s d -> IntBlendSimple ((int_of_blend_factor s),(int_of_blend_factor d))
  | BlendSeparate sc dc sa da -> IntBlendSeparate ((int_of_blend_factor sc),(int_of_blend_factor dc),(int_of_blend_factor sa),(int_of_blend_factor da))
  ];

module Program = struct (*{{{*)

  type shader_type = [ Vertex | Fragment ];
  type shader;

  external compile_shader: shader_type -> string -> shader = "ml_compile_shader";

  module ShaderCache = WeakHashtbl.Make (struct
    type t = string;
    value equal = (=);
    value hash = Hashtbl.hash;
  end);


  value shader_cache = ShaderCache.create 5;

  value get_shader shader_type shader_file =
    try
      ShaderCache.find shader_cache shader_file 
    with [ Not_found -> 
      let () = debug "try compile shader: %s" shader_file in
      let s = compile_shader shader_type (LightCommon.read_resource ~with_suffix:False (Filename.concat "Shaders" shader_file)) in
      (
        ShaderCache.add shader_cache shader_file s;
        s;
      )
    ];

  type attribute = [ AttribPosition |  AttribTexCoords | AttribColor ]; (* с атриббутами пока так *)
  type t;
  type id = int;

  value gen_id = 
    let _program_id = ref 0 in
    fun () ->
      let res = !_program_id in
      (
        incr _program_id;
        res;
      );

  module Cache = WeakHashtbl.Make (struct
    type t = int;
    value equal = (=);
    value hash = Hashtbl.hash;
  end);

  value cache = Cache.create 3;

  type uniform = [ UNone | UInt of int | UInt2 of (int*int) | UInt3 of (int*int*int) | UFloat of float | UFloat2 of (float*float) ];
  external create_program: ~vertex:shader -> ~fragment:shader -> ~attributes:list (attribute * string) -> ~uniforms:array (string * uniform) -> t = "ml_program_create";

  value load_force ~vertex:vertexf ~fragment:fragmentf ~attributes ~uniforms = 
    let vertex = get_shader Vertex vertexf
    and fragment = get_shader Fragment fragmentf
    in
    let () = debug "create program: %s:%s" vertexf fragmentf in
    create_program ~vertex ~fragment ~attributes ~uniforms;

  value load id ~vertex ~fragment ~attributes ~uniforms = 
    try
      Cache.find cache id
    with [ Not_found -> 
      let () = debug "create program %d with %s:%s" id vertex fragment in
      let p = load_force ~vertex ~fragment ~attributes ~uniforms in
      (
        Cache.add cache id p;
        p
      )
    ];

  value clear () = 
  (
    ShaderCache.clear shader_cache;
    Cache.clear cache;
  );
  Callback.register "programs_cache_clear" clear;


end;(*}}}*)

type filter;
(*
module Filter = struct (* remove it from here *)

  type t;
(*   external glow: int -> int -> t = "ml_filter_glow"; *)
(*   external glow_make: framebufferID -> textureID -> float -> float -> option Rectangle.t -> option (textureID * float * float * option Rectangle.t) -> int -> unit = "ml_glow_make_byte"
 *   "ml_glow_make"; *)
(*   type color_matrix_filter; *)
(*   type color_matrix = t color_matrix_filter; *)
  external color_matrix: Filters.colorMatrix -> t = "ml_filter_cmatrix";

end;
*)

type prg = (Program.t * (option filter));

module Quad = struct
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


module Image = struct

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

