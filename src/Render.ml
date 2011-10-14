
external push_matrix: Matrix.t -> unit = "ml_push_matrix";
external restore_matrix: unit -> unit = "ml_restore_matrix";
external clear: int -> unit = "ml_clear";


module Program = struct

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
      Cache.find shader_cache shader_file 
    with [ Not_found -> 
      let s = compile_shader shader_type (Std.input_all (LightCommon.open_resource (Filename.concat "Shaders" shader_file) 0.)) in
      (
        Cache.add shader_cache shader_file s;
        s;
      )
    ];


  value gen_id = 
    let _program_id = ref 0 in
    fun () ->
      let res = !_program_id in
      (
        succ _program_id;
        res;
      );


  type program;
  type t 'uniform =
    { 
      program: program;
      uniforms: array int;
    };

  type attribute = [ AttribPosition | AttribColor | AttribTexCoords ]; (* с атриббутами пока так *)


  external create_program: shader -> shader -> list (attribute * string) -> array string -> t 'uniform = "ml_create_program";

  value load ~vertex ~fragment attributes uniforms = 
    let vshader = get_shader Vertex vertex
    and fshader = get_shader Fragment framgent
    in
    create_program vshader fshader attributes uniforms;

end;

module Quad = struct
  type t;

  external create: ~w:float -> ~h:float -> ~color:int -> ~alpha:float -> t = "ml_quad_create";
  external points: t -> array Point.t = "ml_quad_points";
  external color: t -> int = "ml_quad_color";
  external set_color: t -> int -> unit = "ml_quad_set_color";
  external alpha: t -> float = "ml_quad_alpha";
  external set_alpha: t -> float -> unit = "ml_quad_set_alpha";
  external colors: t -> array int = "ml_quad_colors";
  external render: Matrix.t -> Program.t 'a -> ?uniforms:(list (int * 'b)) -> ?alpha:float -> t -> unit = "ml_quad_render";

end;


module Image = struct
  type t;

  external create: ~w:float -> ~h:float -> ~clipping:option Rectangle.t -> ~color:int -> ~alpha:float -> t = "ml_image_create";
  external set_color: t -> int -> unit = "ml_image_set_color";
  external color: t -> int = "ml_image_color";
  external set_alpha: t -> float -> unit = "ml_image_set_alpha";
  external colors: t -> array int = "ml_quad_colors";
  external update: t -> ~w:float -> ~h:float -> ~clipping:option Rectangle.t -> unit = "ml_image_update";
  external render: Matrix.t -> Program.t 'a -> Texture.textureID -> ~pma:bool -> ?uniforms:(list (int * 'b)) -> ?alpha:float -> t -> unit = "ml_image_render_byte" "ml_image_render";

end;

