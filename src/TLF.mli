module Make(Image:Image.S)(Atlas:Atlas.S with module D = Image.D)(Sprite:Sprite.S with module D = Image.D) : TLFT.S with module D = Image.D;
