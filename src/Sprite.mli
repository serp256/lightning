
class c ['event_type,'event_data]:
  object
    inherit DisplayObject.container ['event_type,'event_data];
  end;


value create: unit -> c 'event_type 'event_data;
