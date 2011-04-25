open LightCommon;
exception Texture_not_found of string;

type t = 
  {
    regions: Hashtbl.t string Rectangle.t;
    texture: Texture.c;
  };

value createFromFile file = 
  let path = resource_path file 1. in
  let input = open_in path in
  let xmlinput = Xmlm.make_input ~strip:True (`Channel input) in
  let regions = Hashtbl.create 3 in
  let rec parseSubTextures () =
    match Xmlm.input xmlinput with
    [ `El_start ((_,"SubTexture"),attributes) ->
      (
        let name = get_xml_attribute "name" attributes 
        and x = get_xml_attribute "x" attributes
        and y = get_xml_attribute "y" attributes
        and width = get_xml_attribute "width" attributes
        and height = get_xml_attribute "height" attributes
        in
        Hashtbl.add regions name (Rectangle.create (float_of_string x) (float_of_string y) (float_of_string width) (float_of_string height));
        match Xmlm.input xmlinput with
        [ `El_end -> parseSubTextures()
        | _ -> assert False
        ]
      )
    | `El_end -> ()
    | _ -> assert False
    ]
  in
  let rec parse () = 
    match Xmlm.input xmlinput with
    [ `El_start ((_,"TextureAtlas"),attributes) ->
      let image_path = get_xml_attribute "imagePath" attributes in
      let () = parseSubTextures () in
      image_path
    | `Dtd _ -> parse ()
    | _ -> assert False
    ]
  in
  let imagePath = parse () in
  let () = close_in input in
  {regions; texture = Texture.createFromFile imagePath};

value textureByName atlas name = 
  let region = 
    try
      Hashtbl.find atlas.regions name
    with [ Not_found -> raise (Texture_not_found name) ]
  in
  Texture.createSubTexture region atlas.texture;

