
external push_matrix: Matrix.t -> unit = "ml_push_matrix";
external restore_matrix: unit -> unit = "ml_restore_matrix";
external clear: int -> unit = "ml_clear";


module Program = struct

  type shader_type = [ Vertex | Fragment ];
  type shader;

  external compile_shader: shader_type -> string -> shader = "ml_compile_shader";


  type program;
  type t 'uniform =
    { 
      program: program;
      uniforms: list ('uniform * int)
    };

  type attribute = [ AttribPosition | AttribColor | AttribTexCoords ]; (* с атриббутами пока так *)

  external create_program: shader -> shader -> list (attribute * string) -> list ('uniform * string) -> t 'uniform = "ml_create_program";


  value load vs fs attributes uniforms = 
    let vshader = compile_shader Vertex (Std.input_all (LightCommon.open_resource (Filename.concat "Shaders" vs) 0.)) 
    and fshader = compile_shader Fragment (Std.input_all (LightCommon.open_resource (Filename.concat "Shaders" fs) 0.))
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
  external render: Matrix.t -> Program.t 'a -> Texture.textureID -> ~pma:bool -> ?uniforms:(list (int * 'b)) -> ?alpha:float -> t -> unit = "ml_image_render_byte" "ml_image_render";

end;

