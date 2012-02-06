open LightCommon;

external glow_make: textureID -> float -> float -> bool -> option Rectangle.t -> Filters.glow -> Texture.c = "ml_glow_make2_byte" "ml_glow_make2";
