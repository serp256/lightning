open LightCommon;
exception Texture_not_found of string;

type t = 
  {
    regions: Hashtbl.t string Rectangle.t;
    texture: Texture.c;
  };

value load xmlpath = 
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
  let regions = Hashtbl.create 3 in
  let rec parseSubTextures () =
    match XmlParser.parse_element "SubTexture" ["name";"x";"y";"width";"height"] with
    [ Some [ name;x;y;width;height] _ ->
      (
        Hashtbl.add regions name (Rectangle.create (float_of_string x) (float_of_string y) (float_of_string width) (float_of_string height));
        parseSubTextures ()
      )
    | None -> ()
    | _ -> assert False
    ]
  in
  let () = XmlParser.accept (`Dtd None) in
  let imagePath = 
    match XmlParser.next () with
    [ `El_start ((_,"TextureAtlas"),attributes) ->
      match XmlParser.get_attribute "imagePath" attributes with
      [ Some image_path ->
        let () = parseSubTextures () in
        image_path
      | _ -> XmlParser.error "not found imagePath"
      ]
    | _ -> XmlParser.error "TextureAtlas not found"
    ]
  in
  let () = XmlParser.close () in
  {regions; texture = Texture.load imagePath};

value texture atlas name = 
  let region = 
    try
      Hashtbl.find atlas.regions name
    with [ Not_found -> raise (Texture_not_found name) ]
  in
  Texture.createSubTexture region atlas.texture;

