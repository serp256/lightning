
static GLuint getFbTexSize() {
    static GLint size = 0;
    if (!size) {
#ifdef PC
		size = 512;
#else
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, &size);
		size = size / 4;
#endif
    }
    return size;
}


typedef struct {
	GLuint tid;
	GLuint fbid;
	rbint_t bin;
} shtex;


int shtex_count = 0;
shtex *shtexs = NULL;


/*
value findPos w h =
	let newRenderbuffTex () =
		let (fb,tid) = create_renderbuffer () in
		let bin = Bin.create (renderbufferTexSize ()) (renderbufferTexSize ()) in (
			bins.val := [ (tid, bin) :: !bins ];

			match Bin.add bin w h with
			[ Some pos -> (tid, pos)
			| _ -> assert False
			];
		)    
	in

	let rec tryWithNeedRepair repairsCnt binsLst =
		match binsLst with
		[ [] -> newRenderbuffTex ()
		| binsLst when repairsCnt > 3 -> newRenderbuffTex ()
		| [ (tid, bin) :: binsLst ] ->
			if Bin.needRepair bin
			then (
				Bin.repair bin;
				match Bin.add bin w h with
				[ Some pos -> (tid, pos)
				| _ -> tryWithNeedRepair (repairsCnt + 1) binsLst
				]          
			)
			else tryWithNeedRepair repairsCnt binsLst
		]      
	in

	let rec tryWithRepaired binsLst =
		match binsLst with
		[ [] ->
			let rec shuffle bins cnt times = if cnt = times then bins else shuffle (List.sort ~cmp:(fun _ _ -> (Random.int 3) - 1) bins) (cnt + 1) times in
			let needRepair = shuffle (List.filter (fun (tid, bin) -> Bin.needRepair bin) !bins) 0 5 in
				tryWithNeedRepair 0 needRepair
		| [ (tid, bin) :: binsLst ] ->
			if not (Bin.needRepair bin)
			then
				match Bin.add bin w h with
				[ Some pos -> (tid, pos)
				| _ -> tryWithRepaired binsLst
				]
			else tryWithRepaired binsLst
		]
	in

	let rec tryReuse binsLst =
		match binsLst with
		[ [] -> tryWithRepaired !bins
		| [ (tid, bin) :: binsLst ] ->
			match Bin.reuse bin w h with
			[ Some pos -> (tid, pos)
			| _ -> tryReuse binsLst
			]
		]
	in
		tryReuse !bins;
*/


int shared_texture_get_rect(GLuint width,GLuint height,renderbuffer_t *rb) {
	int i = 0;
	pnt_t pnt;
	shtex *tex;
	GLuint fbtexsize = getFbTexSize();
	GLuint widthCrrcnt = 8 - width % 8;
	GLuint heightCrrcnt = 8 - height % 8;
	GLuint rectw = width + widthCrrcnt;
	GLuint recth = height + heightCrrcnt;
	// try reuse
	for (i = 0; i < shtex_count; i++) {
		if (bin_reuse_rect(&shtexs[i].bin,rectw,recth,&pnt)) {
			tex = shtexs + i;
			goto FINDED;
		}
	};
	// try add
	uint8_t repair_idx = 0;
	for (i = 0; i < shtex_count; i++) {
		if (!bin_need_repair(&(shtexs[i].bin))) {
			if (bin_add_rect(&shtexs[i].bin,rectw,recth,&pnt)) {
				tex = shtexs + i;
				goto FINDED;
			}
		} else {
			bint_t *tmp = &shtexs[repair_idx];
			shtexs[repair_idx] = shtexs[i];
			shtexs[i] = tmp;
			repair_idx++;
		}
	};
	// try repair
	if (repair_idx > 3) repair_idx = 3;
	for (i = 0; i < repair_idx; i++) {
		bin_repair(&shtexs[i].bin);
		if (bin_add_rect(&shtexs[i].bin,rectw,recth,&pnt)) {
			tex = shtexs + i;
			goto FINDED;
		}
	};
	// alloc new 
	shtex_count++;
	shtexs = realloc(shtexs,sizeof(shtex)*shtex_count);
	tex = shtexs + (shtex_count - 1);
	glGenTextures(1,&tex->tid);
	glBindTexture(GL_TEXTURE_2D, tex->tid);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fbtexsize, fbtexsize, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glGenFramebuffers(1,&tex->fbid);
	glBindFramebuffer(GL_FRAMEBUFFER,tex->fbid);
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tid, 0);
	rbin_init(&tex->bin);
	bin_add_rect(&tex->bin,rectw,recth,&pnt);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return 1;
FINDED:
	// заполняем структуру rb
	rb->fbid = tex->fbid;
	rb->tid = tex->tid;
	rb->width = width;
	rb->height = height;
	rb->realWidth = rectw;
	rb->realHeight = recth;
	rb->vp = (viewport){ (GLuint)pnt.x + widthCrrcnt / 2, (GLuint)pnt.y + heightCrrcnt / 2, (GLuint)width, (GLuint)height };
	rb->clp = (clipping){ (double)rb->vp.x / (double)fbtexsize, (double)rb->vp.y / (double)fbtexsize, width / (double)fbtexsize, height / (double)fbtexsize };
	// set viewport for full rect for clearing
	glViewport(pnt.x,pnt.y,rectw,recth);
	return 0;
}


