open LightCommon;
exception Texture_not_found of string;

type t = 
  {
    regions: Hashtbl.t string (int * Rectangle.t);
    textures: array Texture.c;
  };


(*
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
*)


value load binpath = 
  let dirname = Filename.dirname binpath in
  let path = resource_path binpath in
  let inp = open_in_bin path in
  (
    let bininp = IO.input_channel inp in
    let cnt_atlases = IO.read_byte bininp in
    let regions = Hashtbl.create 3 in
    let textures = Array.make cnt_atlases Texture.zero in
    (
      let f = float_of_int in
      for i = 0 to cnt_atlases - 1 do
        let path = IO.read_string bininp in
        textures.(i) := Texture.load (Filename.concat dirname path);
        let cnt_items = IO.read_ui16 bininp in
        for j = 0 to cnt_items - 1 do
          let name = IO.read_string bininp in
          let x = IO.read_ui16 bininp in
          let y = IO.read_ui16 bininp in
          let w = IO.read_ui16 bininp in
          let h = IO.read_ui16 bininp in
          let _r = IO.read_byte bininp in
          Hashtbl.add regions name (i,Rectangle.create (f x) (f y) (f w) (f h));
        done;
      done;
      close_in inp;
      {textures;regions};
    )
  );


value loadxml xmlpath = 
  let xmlpath = resource_path xmlpath in
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
            match XmlParser.get_attribute "path" attributes with
            [ Some image_path ->
              (
                parseSubTextures () where
                  rec parseSubTextures () = 
                    match XmlParser.parse_element "SubTexture" ["id";"x";"y";"w";"h"] with
                    [ Some [ name;x;y;width;height] _ ->
                      (
                        Hashtbl.add regions name (cnt,(Rectangle.create ((float_of_string x)) ((float_of_string y)) ((float_of_string width)) ((float_of_string height))));
                        parseSubTextures ()
                      )
                    | None -> ()
                    | _ -> assert False
                    ];
                parseTextures (cnt + 1) [ Texture.load image_path :: textures ]
              )
          | _ -> XmlParser.error "not found path"
          ]
          | `El_end -> textures
          | _ -> XmlParser.error "TextureAtlas not found"
          ]
    | _ -> XmlParser.error "not found TextureAtlases"
    ]
  in
  let () = XmlParser.close () in
  {regions; textures = Array.of_list (List.rev textures)};

value texture atlas num = atlas.textures.(num); (* FIXME: check *)

value subTexture atlas name = 
  let (num,region) = 
    try
      Hashtbl.find atlas.regions name
    with [ Not_found -> raise (Texture_not_found name) ]
  in
  atlas.textures.(num)#subTexture region;

value atlasNode atlas name ?pos ?scaleX ?scaleY ?color ?flipX ?flipY ?alpha () =
  let (num,region) = 
    try
      Hashtbl.find atlas.regions name
    with [ Not_found -> raise (Texture_not_found name) ]
  in
  AtlasNode.create atlas.textures.(num) region ?pos ?scaleX ?scaleY ?color ?flipX ?flipY ?alpha ();


value description atlas name = 
  try
    Hashtbl.find atlas.regions name
  with [ Not_found -> raise (Texture_not_found name) ];

