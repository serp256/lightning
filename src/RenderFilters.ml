open LightCommon;

external glow_make: Texture.renderbuffer -> Filters.glow -> unit = "ml_glow_make";
external glow2_make: Texture.renderbuffer -> Filters.glow -> unit = "ml_glow2_make";
