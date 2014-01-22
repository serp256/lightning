open LightCommon;
 value onImageMove obj handler = 
   obj#addEventListener Stage.ev_TOUCH begin fun ev (_,target) _ ->
    match Stage.touches_of_data ev.Ev.data with
    [  Some [ {Touch.phase=Touch.TouchPhaseEnded; _ } :: _ ] -> handler target
    | _ -> ()
    ]
  end |> ignore;


  value dropCubeTimer = Timer.create 0.01 "dropCubeTimer";
  value dropCubesTestTimer = Timer.create 0.4 "dropCubesTestTimer";  
 let stage width height =
	object(self)
		inherit Stage.c width height;
		value bgColor = 0xFFFFFF;
    value mutable imageXOffset = 0.0;
    value mutable imageOffsetY = 10.0;
    value mutable imagesList = [];
    value mutable imagesSpeed = [];
    initializer (

      Random.self_init ();

    (*  ignore(dropCubesTestTimer#addEventListener Timer.ev_TIMER (fun _ _ _ -> (
        let testImage = Image.load "letris/cube.png" in ( 
          testImage#setY imageOffsetY;
          imageXOffset := imageXOffset +. testImage#width;
          testImage#setX imageXOffset;
          let imageSpeed = (Random.int 10) in 
            imagesSpeed := [imageSpeed::imagesSpeed];
          
          onImageMove testImage begin fun img -> (
            debug "i was touched %f" (img#x /. img#width); 
            img#setVisible False;
          )
          end;
          
          imagesList := [testImage::imagesList];
          self#addChild testImage;
        )
      )));
*)
(*    	let image = Image.load "letris/cube.png" in
			(
        ignore(dropCubeTimer#addEventListener Timer.ev_TIMER (fun _ _ _ -> (
          imageOffsetY := imageOffsetY +. 5.0;
          image#setY imageOffsetY;

          let rec setImagesOffset speedList imgsList = 
            if imgsList = [] then ()
            else 
              let headSpeed = (List.hd speedList) in 
                let headImage = (List.hd imgsList) in 
                  let newY = headImage#y +. (float_of_int headSpeed) in
                  (
                    if newY < 970.0 then (
                       headImage#setY newY;
                       setImagesOffset (List.tl speedList) (List.tl imgsList);
                    ) 
                    else ();
                  );
          
          setImagesOffset imagesSpeed imagesList;
          
          if imageOffsetY > 970.0 then (
            dropCubeTimer#stop ();
            dropCubesTestTimer#stop ();
          )
          else 
            ();
        )));

				onImageMove image begin fun img -> (
           debug "start drop timer";
           if not dropCubeTimer#running then (
             dropCubeTimer#start ();
             dropCubesTestTimer#start (); 
           )
           else 
             ();
           );
        end;
			
        self#addChild image;
      );
*)
    );			
	end
in
Lightning.init stage;
