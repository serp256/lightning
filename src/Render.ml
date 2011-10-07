
external push_matrix: Matrix.t -> unit = "ml_push_matrix";
external restore_matrix: unit -> unit = "ml_restore_matrix";
external clear: int -> float = "ml_clear";


module Program = struct

  type shader_type = [ Vertex | Fragment ];
  type shader;

  external compile_shader: shader_type -> string -> shader = "ml_compile_shader";

  type attribute = [ AttribPosition | AttribColor | AttribTexCoords ];

  type t 'uniforms;

  type uniformValue 
  external create_program: shader -> shader -> list (attribute * string) -> list ('uniform * string) -> t 'uniform = "ml_create_program";

end;

module Quad = struct
  type t;

  external create: float -> float -> int -> float -> t = "ml_quad_create";
  external points: t -> array Point.t = "ml_quad_points";
  external color: t -> int = "ml_quad_color";
  external set_color: t -> int -> unit = "ml_quad_set_color";
  external alpha: t -> float = "ml_quad_alpha";
  external set_alpha: t -> float -> unit = "ml_alpha_set_alpha";
  external colors: t -> array int = "ml_quad_colors";
  external render: Matrix.t -> Program.t 'a -> ?uniforms -> ?alpha:float -> t -> unit = "ml_quad_render";

end;


module Image = struct
  type t;
end;


