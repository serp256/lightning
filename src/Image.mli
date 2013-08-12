open LightCommon;

(*
type glow = 
  {
    g_texture: mutable option RenderTexture.c;
    g_image: mutable option Render.Image.t;
    g_make_program: Render.prg;
    g_program: mutable Render.prg;
    g_matrix: mutable Matrix.t;
    g_valid: mutable bool;
    g_params: Filters.glow
  };
*)

class virtual base: [ Texture.c ] ->
  object
    inherit DisplayObject.c;
    value blend: option Render.intblend;
    method setBlend: option Render.blend -> unit;
    method texture: Texture.c;
    method filters: list Filters.t;
    method setFilters: list Filters.t -> unit;
(*     value glowFilter: option glow; *)
    value shaderProgram: Render.prg;
    method virtual private removeGlowFilter: unit -> unit;
    method virtual private setGlowFilter: Render.prg -> Filters.glow -> unit;
    method virtual private updateGlowFilter: unit -> unit;
  end;

class _c : [ Texture.c ] ->
  object
    inherit base;
    value texture: Texture.c;
    method setColor: color -> unit;
    method color: color;
    (*method setColors: array int -> unit;*)

    method texFlipX: bool;
    method setTexFlipX: bool -> unit;
    method texFlipY: bool;
    method setTexFlipY: bool -> unit;

    (*
    method texRotation: option [= `left | `right];
    method setTexRotation: option [= `left | `right] -> unit;
    method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
    *)

(*     method texture: Texture.c; *)
    method onTextureEvent: bool -> Texture.c -> unit;
    method setTexture: Texture.c -> unit;

    method private removeGlowFilter: unit -> unit;
    method private setGlowFilter: Render.prg -> Filters.glow -> unit;
    method private updateGlowFilter: unit -> unit;
(*       method setTexScale: float -> unit; *)

    method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: DisplayObject.c; .. > as 'space) -> Rectangle.t;
(*     method filters: list Filters.t; *)
(*     method setFilters: list Filters.t -> unit; *)

  end;

(* value cast: #DisplayObject.c -> option c; *)

class c : [ Texture.c ] ->
  object
    inherit _c;
    method ccast: [= `Image of c ];
  end;

value create: Texture.c -> c;
value load: ?filter:Texture.filter -> string -> c;
value load_async: string -> ?filter:Texture.filter -> ?ecallback:(string -> unit) -> (c -> unit) -> unit;
