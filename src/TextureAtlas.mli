
exception Texture_not_found of string;
type t;
value load: string -> t;
value texture: t -> string -> Texture.c;
