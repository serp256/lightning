open LightCommon;
exception Texture_not_found of string;

type t = 
  {
    regions: Hashtbl.t string (int * Rectangle.t);
    textures: array Texture.c;
  };


value load xmlpath = 
  let path = resource_path xmlpath in
  let scale = 
  try 
    let _ = ExtString.String.find path "@2x" in 2.0
  with [ ExtString.Invalid_string -> 1.0 ] 
  in
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
  let regions = Hashtbl.create 3 in
  let () = XmlParser.accept (`Dtd None) in
  let textures = 
    match XmlParser.next () with
    [ `El_start ((_,"TextureAtlases"),_) ->
      parseTextures 0 [] where
        rec parseTextures cnt textures = 
          match XmlParser.next () with
          [ `El_start ((_,"TextureAtlas"),attributes) ->
            match XmlParser.get_attribute "imagePath" attributes with
            [ Some image_path ->
              (
                parseSubTextures () where
                  rec parseSubTextures () = 
                    match XmlParser.parse_element "SubTexture" ["name";"x";"y";"width";"height"] with
                    [ Some [ name;x;y;width;height] _ ->
                      (
                        Hashtbl.add regions name (cnt,(Rectangle.create ((float_of_string x) /. scale) ((float_of_string y) /. scale) ((float_of_string width) /. scale) ((float_of_string height) /. scale)));
                        parseSubTextures ()
                      )
                    | None -> ()
                    | _ -> assert False
                    ];
                parseTextures (cnt + 1) [ Texture.load image_path :: textures ]
              )
          | _ -> XmlParser.error "not found imagePath"
          ]
          | `El_end -> textures
          | _ -> XmlParser.error "TextureAtlas not found"
          ]
    | _ -> XmlParser.error "not found TextureAtlases"
    ]
  in
  let () = XmlParser.close () in
  {regions; textures = Array.of_list (List.rev textures)};




value texture atlas name = 
  let (num,region) = 
    try
      Hashtbl.find atlas.regions name
    with [ Not_found -> raise (Texture_not_found name) ]
  in
  Texture.createSubTexture region atlas.textures.(num);

