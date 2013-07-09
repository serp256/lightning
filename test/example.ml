open LightCommon;

let stage width height = 
  object(self)
    inherit Stage.c width height as super;
    value bgColor = 0xCCCCCC;
    initializer begin
      let quad = new Quad.c 100. 100. in
        self#addChild quad;
    end;
  end
in
  Lightning.init stage;
