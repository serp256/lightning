class c () =
	object(self)
		inherit Stage.base as super;

		value mutable rendertex:option RenderTexture.c = None;

		method texture () =
			(
				self#stageDispatchEnterFrame 0.;
				self#stageRunPrerender ();

				let render _ =
					let bounds = self#bounds in
						(
							self#setPos (-.(bounds.Rectangle.x)) (-.(bounds.Rectangle.y));
							self#render None;
						)
				in
					match rendertex with
					[ Some tex ->
						(
							ignore(tex#draw ~clear:(0, 0.) ~width:self#width ~height:self#height render);
							tex;
						)
					| _ ->
						let tex = RenderTexture.(draw ~kind:(Dedicated Texture.FilterLinear) self#width self#height render) in
							(
								rendertex := Some tex;
								tex;
							)
					];
			);
	end;