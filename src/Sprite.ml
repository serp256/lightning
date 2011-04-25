

class c ['event_type,'event_data] =
  object(self)
    inherit DisplayObject.container ['event_type,'event_data] as super;
  end;

value create () = new c;

