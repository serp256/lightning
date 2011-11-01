
module Make(Image:Image.S)(Sprite:Sprite.S with module D = Image.D) : sig

type img_valign = [= `baseLine | `center | `lineCenter ];
type img_attribute = 
  [= `width of float
  | `height of float
  | `paddingLeft of float
  | `paddingRight of float
  | `paddingTop of float
  | `valign of img_valign
  ];

type img_attributes = list img_attribute;

type span_attribute = 
  [= `fontFamily of string
  | `fontSize of int
  | `color of int
  | `alpha of float
  | `backgroundColor of int (* как это замутить то я забыла *)
  | `backgroundAlpha of float 
  ];

type span_attributes = list span_attribute;

type simple_element = [= `img of (img_attributes * Image.c) | `span of (span_attributes * simple_elements) | `br | `text of string ]
and simple_elements = list simple_element;

type p_halign = [= `left | `right | `center ];
type p_valign = [= `top | `bottom | `center ];
type p_attribute = 
  [= span_attribute
  | `halign of p_halign
  | `valign of p_valign
  | `spaceBefore of float
  | `spaceAfter of float
  ];

type p_attributes = list p_attribute;

type div_attribute = 
  [= span_attribute 
  | p_attribute
  | `paddingTop of float
  | `paddingLeft of float
  ];


type div_attributes = list div_attribute;


(* type attribute = [= div_attribute | p_attribute | span_attribute ]; *)

type main = 
  [= `div of (div_attributes * (list main))
  | `p of (p_attributes * simple_elements)
  ];

value img: ?width:float -> ?height:float -> ?paddingLeft:float -> ?paddingTop:float -> ?paddingRight:float -> ?paddingLeft:float -> ?valign:img_valign -> Image.c -> simple_element;
value span: ?fontFamily:string -> ?fontSize:int -> ?color:int -> ?alpha:float -> simple_elements -> simple_element;
value p: ?fontFamily:string -> ?fontSize:int -> ?color:int -> ?alpha:float -> ?halign:p_halign -> ?valign:p_valign -> ?spaceBefore:float -> ?spaceAfter:float -> simple_elements -> main;
value parse: ?imgLoader:(string -> Image.c) -> string -> main;
value create: ?width:float -> ?height:float -> ?border:int -> ?dest:#Sprite.c -> main -> Sprite.c;

end;
