#include <string.h>
#include "texture_common.h"
#include "render_stub.h"
#include <kazmath/GL/matrix.h>


#ifdef IOS
#define glDeleteVertexArrays glDeleteVertexArraysOES
#define glGenVertexArrays glGenVertexArraysOES
#define glBindVertexArray glBindVertexArrayOES
#else
#ifdef PC
#ifdef __APPLE__
#define glDeleteVertexArrays glDeleteVertexArraysAPPLE
#define glGenVertexArrays glGenVertexArraysAPPLE
#define glBindVertexArray glBindVertexArrayAPPLE
#else
#define glDeleteVertexArrays glDeleteVertexArrays
#define glGenVertexArrays glGenVertexArrays
#define glBindVertexArray glBindVertexArray
#endif
#endif
#endif

#define HAS_VAO
#if defined(ANDROID) || defined(linux)
#undef HAS_VAO
#endif

//////////////////////////////////
/// COLORS


#define COLOR(r, g, b)     (((int)(r) << 16) | ((int)(g) << 8) | (int)(b))

#define COLOR_FROM_INT(c,alpha) (color4B){COLOR_PART_RED(c),COLOR_PART_GREEN(c),COLOR_PART_BLUE(c),(GLubyte)(alpha * 255.)}
#define COLOR_FROM_INT32(c, alpha) (color4B){COLOR_PART_RED(c),COLOR_PART_GREEN(c),COLOR_PART_BLUE(c),(GLubyte)((double)COLOR_PART_ALPHA(c) * alpha)}
#define COLOR_FROM_INT_PMA(c,alpha) (color4B){(GLubyte)((double)COLOR_PART_RED(c) * alpha),(GLubyte)((double)COLOR_PART_GREEN(c) * alpha),(GLubyte)(COLOR_PART_BLUE(c) * alpha),(GLubyte)(alpha*255)}
#define COLOR_FROM_INT32_PMA(res, c, alpha) { double a = (double)COLOR_PART_ALPHA(c) / 255. * alpha; res->r = (GLubyte)(COLOR_PART_RED(c) * a); res->g = (GLubyte)(COLOR_PART_GREEN(c) * a); res->b = (GLubyte)(COLOR_PART_BLUE(c) * a); res->a = (GLubyte)(a * 255); }
#define UPDATE_PMA_ALPHA(color, alpha, quad) extract_color(color, alpha, 1., &quad->tl.c, &quad->tr.c, &quad->bl.c, &quad->br.c)
#define UPDATE_PMA_ALPHA_MUL(c,alpha) { c.r = (GLubyte)(c.r * alpha); c.g = (GLubyte)(c.g * alpha); c.b = (GLubyte)(c.b * alpha); c.a = (GLubyte)(c.a * alpha);}
#define setDefaultGLBlend setPMAGLBlend


value ml_checkGLErrors(value p) {
	checkGLErrors("%s",String_val(p));
	return Val_unit;
}

GLfloat viewport[4];

void setupOrthographicRendering(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, uint8_t save_vp);

void restore_default_viewport() {
	setupOrthographicRendering(viewport[0], viewport[1], viewport[2], viewport[3], 0);
	caml_callback(*caml_named_value("resetScissor"), Val_unit);
}

void setupOrthographicRendering(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, uint8_t save_vp) {
	//fprintf(stderr,"set ortho rendering [%f:%f:%f:%f]\n",left,right,bottom,top);
  //glDisable(GL_DEPTH_TEST);
	if (save_vp) {
		viewport[0] = left;
		viewport[1] = right;
		viewport[2] = bottom;
		viewport[3] = top;
	}


  glEnable(GL_BLEND);
  
	glViewport(left, top, (GLsizei)(right), (GLsizei)(bottom));
      
	setDefaultGLBlend();
	glClearColor(1.0,1.0,1.0,1.0);
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLLoadIdentity();
      
	kmMat4 orthoMatrix;
	kmMat4OrthographicProjection(&orthoMatrix, left, right, bottom, top, -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );

	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLLoadIdentity();

	checkGLErrors("set ortho rendering");
}


value ml_setupOrthographicRendering(value left,value right,value bottom,value top) {
	setupOrthographicRendering(Double_val(left),Double_val(right),Double_val(bottom),Double_val(top), 1);
	return Val_unit;
}

value ml_clear(value color,value alpha) {
	int clr = Int_val(color);
	color3F c = COLOR3F_FROM_INT(clr);
	glClearColor(c.r,c.g,c.b,Double_val(alpha));
	glClear(GL_COLOR_BUFFER_BIT); // | GL_DEPTH_BUFFER_BIT);
	return Val_unit;
}

/////////
/// Matrix
/////////

/*
{
  // | m[0] m[4] m[8]  m[12] |     | m11 m21 m31 m41 |     | a c 0 tx |
  // | m[1] m[5] m[9]  m[13] |     | m12 m22 m32 m42 |     | b d 0 ty |
  // | m[2] m[6] m[10] m[14] | <=> | m13 m23 m33 m43 | <=> | 0 0 1  0 |
  // | m[3] m[7] m[11] m[15] |     | m14 m24 m34 m44 |     | 0 0 0  1 |

  m[2] = m[3] = m[6] = m[7] = m[8] = m[9] = m[11] = m[14] = 0.0f;
  m[10] = m[15] = 1.0f;
  m[0] = t->a; m[4] = t->c; m[12] = t->tx;
  m[1] = t->b; m[5] = t->d; m[13] = t->ty;
}*/

void applyTransformMatrix(value matrix) {
	kmMat4 transfrom4x4;
  // Convert 3x3 into 4x4 matrix
	GLfloat *m = transfrom4x4.mat;
  m[2] = m[3] = m[6] = m[7] = m[8] = m[9] = m[11] = m[14] = 0.0f;
  m[10] = m[15] = 1.0f;
  m[0] = (GLfloat)Double_field(matrix,0); m[4] = (GLfloat)Double_field(matrix,2); m[12] = (GLfloat)Double_field(matrix,4);
  m[1] = (GLfloat)Double_field(matrix,1); m[5] = (GLfloat)Double_field(matrix,3); m[13] = (GLfloat)Double_field(matrix,5);

	//fprintf(stderr,"applyTransformMatrix: %f:%f\n",m[12],m[13]);

  kmGLMultMatrix( &transfrom4x4 );
}

value ml_push_matrix(value matrix) {
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	return Val_unit;
}


value ml_restore_matrix(value p) {
	kmGLPopMatrix();
	return Val_unit;
}


/////////////////////////////////////
/// SHADERS
//

typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint* params);
typedef void (*GLLogFunction) (GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

char* logForOpenGLObject(GLuint object, GLInfoFunction infoFunc, GLLogFunction logFunc) {
    GLint logLength = 0, charsWritten = 0;
    infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength < 1) return NULL;

    char *logBytes = caml_stat_alloc(logLength);
    logFunc(object, logLength, &charsWritten, logBytes);
		return logBytes;
}

char* programLog(GLuint program) {
	return (logForOpenGLObject(program,(GLInfoFunction)&glGetProgramiv,(GLLogFunction)&glGetProgramInfoLog));
}

char* shaderLog(GLuint shader) {
  return (logForOpenGLObject(shader,(GLInfoFunction)&glGetShaderiv,(GLLogFunction)&glGetShaderInfoLog));
}

//

#define GLUINT(v) ((GLuint*)Data_custom_val(v))

static int gluint_compare(value gluint1,value gluint2) {
	GLuint t1 = *GLUINT(gluint1);
	GLuint t2 = *GLUINT(gluint2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}
}

static void shader_finalize(value shader) {
	PRINT_DEBUG("finzalied shader %d",*GLUINT(shader));
	GLuint s = *GLUINT(shader);
	glDeleteShader(s);
}

struct custom_operations shader_ops = {
  "pointer to shader id",
  shader_finalize,
 	gluint_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


value ml_compile_shader(value stype,value shader_src) {
	GLenum type;
	if (stype == 1) type = GL_VERTEX_SHADER; else type = GL_FRAGMENT_SHADER;
	GLuint shader = glCreateShader(type);
	const char *sh_src = String_val(shader_src);
	glShaderSource(shader, 1, &sh_src, NULL);
	glCompileShader(shader);
   
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
 
  if( ! status ) {
		char msg[1024];
		char *log = shaderLog(shader);
    if( type == GL_VERTEX_SHADER ) {
			sprintf(msg,"vertex shader compilation failed: [%s]",log);
		} else {
      sprintf(msg,"frament shader compilation failed: [%s]",log);
		};
		caml_stat_free(log);
		glDeleteShader(shader);
		caml_failwith(msg);
  }
	value res = caml_alloc_custom(&shader_ops,sizeof(GLuint),0,1);
	//printf("created shader: %d\n",shader);
	PRINT_DEBUG("shader compiled: %d",shader);
	*GLUINT(res) = shader;
	return res;
}

GLuint currentShaderProgram = 0;

/*
static char   vertexAttribPosition = 0;
static char   vertexAttribColor = 0;
static char   vertexAttribTexCoords = 0;
*/



static char vertexAttribPosition  = 0;
static char vertexAttribColor = 0;
static char vertexAttribTexCoords = 0;


void render_clear_cached_values () {
	vertexAttribPosition  = 0;
	vertexAttribColor = 0;
	vertexAttribTexCoords = 0;
}

void lgGLEnableVertexAttribs( unsigned int flags ) {   

  // Position
  char enablePosition = flags & lgVertexAttribFlag_Position;

  if( enablePosition != vertexAttribPosition ) {
    if( enablePosition ) {
			//printf("enable vertex attrib array\n");
      glEnableVertexAttribArray( lgVertexAttrib_Position );
		}
    else {
			//printf("disable vertex attrib array\n");
      glDisableVertexAttribArray( lgVertexAttrib_Position );
		}
  
    vertexAttribPosition = enablePosition;
  } 
    
  // Color
  char enableColor = flags & lgVertexAttribFlag_Color;
  
  if( enableColor != vertexAttribColor ) {
    if( enableColor )
      glEnableVertexAttribArray( lgVertexAttrib_Color );
    else
      glDisableVertexAttribArray( lgVertexAttrib_Color );
    
    vertexAttribColor = enableColor;
  }

  // Tex Coords
  char enableTexCoords = flags & lgVertexAttribFlag_TexCoords;
  
  if( enableTexCoords != vertexAttribTexCoords ) {
    if( enableTexCoords ) 
      glEnableVertexAttribArray( lgVertexAttrib_TexCoords );
    else
      glDisableVertexAttribArray( lgVertexAttrib_TexCoords );
    
    vertexAttribTexCoords = enableTexCoords;
  }
} 


/*static int texture_enabled = 1;
#define ENABLE_TEXTURE() if (!texture_enabled) {glEnable(GL_TEXTURE_2D); texture_enabled = 1;};
#define DISABLE_TEXTURE() if (texture_enabled) {glDisable(GL_TEXTURE_2D); texture_enabled = 0;};
void glEnableTexture() {
	ENABLE_TEXTURE();
}
void glDisableTexture() {
	DISABLE_TEXTURE();
}*/

/*
	void *specUniforms;
	uniformFun bindUniforms;
*/

#define SPROGRAM(v) ((sprogram*)Data_custom_val(v))

static void program_finalize(value program) {
	sprogram *p = SPROGRAM(program);
	PRINT_DEBUG("finalize prg: %d\n",p->program);
	if (p->uniforms != NULL) caml_stat_free(p->uniforms);
  if( p->program == currentShaderProgram ) currentShaderProgram = 0;
	glDeleteProgram(p->program);
	//caml_stat_free(p);
}

static int program_compare(value p1,value p2) {
	sprogram *pr1 = SPROGRAM(p1);
	sprogram *pr2 = SPROGRAM(p2);
	if (pr1->program == pr2->program) return 0;
	else {
		if (pr1->program < pr2->program) return -1;
		return 1;
	}
}

struct custom_operations program_ops = {
  "pointer to program id",
  program_finalize,
 	program_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

void lgGLUseProgram( GLuint program ) {
  if (program != currentShaderProgram) {
		//PRINT_DEBUG("!!!real use program %d",program);
    currentShaderProgram = program;
    glUseProgram(program);
  }
}


value ml_program_create(value vShader,value fShader,value attributes,value uniforms) {
	CAMLparam4(vShader,fShader,attributes,uniforms);
	CAMLlocal2(prg,res);
	GLuint program =  glCreateProgram();
	PRINT_DEBUG("create program %d\n",program);
	glAttachShader(program, *GLUINT(vShader)); 
	checkGLErrors("attach shader 1");
	glAttachShader(program, *GLUINT(fShader)); 
	checkGLErrors("attach shader 2");
	// bind attributes
	value lst = attributes;
	value el;
	while (lst != 1) {
		el = Field(lst,0);
		int attr = Int_val(Field(el,0));
		value name = Field(el,1);
		glBindAttribLocation(program,attr,String_val(name));
		PRINT_DEBUG("attribute: %d - %s\n",attr,String_val(name));
		lst = Field(lst,1);
	}
	checkGLErrors("locations binded");
	/*printf("AFTER ATTRIBS\n");
	for (int i = 0; i < lgVertexAttrib_MAX; i++) {
		printf("attrib: %d = %d\n",i,sp->attributes[i]);
	}*/
	// Link
	glLinkProgram(program);
	// DEBUG
	GLint status;
	glValidateProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if (status == GL_FALSE) {
    glDeleteProgram( program );
    caml_failwith("Failed to link program");
  }

	prg = caml_alloc_custom(&program_ops,sizeof(sprogram),0,1);
	sprogram *sp = SPROGRAM(prg);

	checkGLErrors("before uniforms");

	sp->std_uniforms[lgUniformMVPMatrix] = glGetUniformLocation(program, "u_MVPMatrix");
	//printf("std_uniform: matrix: %d\n",sp->std_uniforms[lgUniformMVPMatrix]);
	sp->std_uniforms[lgUniformAlpha] = glGetUniformLocation(program, "u_parentAlpha");
	//printf("std_uniform: parentAlpha: %d\n",sp->std_uniforms[lgUniformAlpha]);
	/*
	if (has_texture) {
		GLint loc = glGetUniformLocation(program,"u_texture");
		sp->uniforms[lgUniformSampler] = loc;
		lgGLUseProgram( program );
		glUniform1i(loc, 0 );
	};
	*/

	checkGLErrors("create program bind uniforms");

	int uniformsLen = Wosize_val(uniforms);
	if (uniformsLen > 0) {
		PRINT_DEBUG("uniformsLen: %d",uniformsLen);
		lgGLUseProgram(program);
		checkGLErrors("use program before uniforms");
		sp->uniforms = (GLint*)caml_stat_alloc(sizeof(GLuint)*uniformsLen);
		GLuint loc;
		int idx;
		for (idx = 0; idx < uniformsLen; idx++) {
			value el = Field(uniforms,idx);
			loc = glGetUniformLocation(program, String_val(Field(el,0)));
			checkGLErrors("get uiform location"); 
			PRINT_DEBUG("uniform: '%s' = %d\n",String_val(Field(el,0)),loc);
			sp->uniforms[idx] = loc;
			value u = Field(el,1);
			if (Is_block(u)) {
				value v = Field(u,0);
				switch Tag_val(u) {
					case 0: 
						glUniform1i(loc,Long_val(v)); 
						break;
					case 1: 
						PRINT_DEBUG("this is 2i");
						glUniform2i(loc,Long_val(Field(v,0)),Long_val(Field(v,1)));
						break;
					case 2:
						PRINT_DEBUG("this is 3i");
						glUniform3i(loc,Long_val(Field(v,0)),Long_val(Field(v,1)),Long_val(Field(v,2)));
						break;
					case 3:
						PRINT_DEBUG("this is 1f");
						glUniform1f(loc,Double_val(v));
						break;
					case 4:
						PRINT_DEBUG("this is 2f");
						glUniform2f(loc,Double_val(Field(v,0)),Double_val(Field(v,1)));
						break;
					default: printf("unimplemented uniform value\n");
				};
			};
			checkGLErrors("uniform %d binded", idx);
		};
	} else sp->uniforms = NULL;
	checkGLErrors("uniform binded");
	sp->program = program;
	res = caml_alloc_tuple(3);
	Store_field(res,0,prg);
	Store_field(res,1,vShader);
	Store_field(res,2,fShader);
	CAMLreturn(res);
}



void lgGLUniformModelViewProjectionMatrix(sprogram *sp) {
  kmMat4 matrixP;
  kmMat4 matrixMV;
  kmMat4 matrixMVP;

  kmGLGetMatrix(KM_GL_PROJECTION, &matrixP );

  kmGLGetMatrix(KM_GL_MODELVIEW, &matrixMV );
	// RENDER SUBPIXEL FIX HERE
	//fprintf(stderr,"matrix: tx=%f,ty=%f\n",matrixMV.mat[12],matrixMV.mat[13]);
	if (matrixMV.mat[0] == 1.0 && matrixMV.mat[5] == 1.0) {
		//matrixMV.mat[12] = (GLint)matrixMV.mat[12];
		//matrixMV.mat[13] = (GLint)matrixMV.mat[13];
		matrixMV.mat[12] = round(matrixMV.mat[12]);
		matrixMV.mat[13] = round(matrixMV.mat[13]);
	};
	//matrixMV.mat[12] = round(matrixMV.mat[12]);
	//matrixMV.mat[13] = round(matrixMV.mat[13]);
	//fprintf(stderr,"-->matrix: tx=%f,ty=%f\n",matrixMV.mat[12],matrixMV.mat[13]);

  kmMat4Multiply(&matrixMVP, &matrixP, &matrixMV);

	//printf("matrix uniform location: %d\n",sp->uniforms[lgUniformMVPMatrix]);
  glUniformMatrix4fv(sp->std_uniforms[lgUniformMVPMatrix], 1, GL_FALSE, matrixMVP.mat);
}

static value caml_hash_Color = 0;

static inline void extract_color(value color,GLfloat alpha,int pma,color4B *tl,color4B *tr,color4B *bl,color4B *br) {
	if (Is_long(color)) { // white
		GLubyte a = alpha * 255.;
		color4B clr;
		if (pma) clr = (color4B){a,a,a,a};
		else clr = (color4B){255,255,255,a};
		*tl = *tr = *bl = *br = clr;
	} else {
		if (caml_hash_Color == 0) caml_hash_Color = caml_hash_variant("Color");
		if (Field(color,0) == caml_hash_Color) {
			color4B clr;
			int c = Long_val(Field(color,1));
      //fprintf(stderr,"extract_color: Color - %x,%f\n",c,alpha);
			if (pma) clr = COLOR_FROM_INT_PMA(c,alpha);
			else clr = COLOR_FROM_INT(c,alpha);
			*tl = *tr = *bl = *br = clr;
		} else { // QColors
      //fprintf(stderr,"extract_color: QColors\n");
/*			value qcolor = Field(color,1);
			int c = Long_val(Field(qcolor,0));
			*tl = pma ? COLOR_FROM_INT_PMA(c,alpha) : COLOR_FROM_INT(c,alpha);
			c = Long_val(Field(qcolor,1));
			*tr = pma ? COLOR_FROM_INT_PMA(c,alpha) : COLOR_FROM_INT(c,alpha);
			c = Long_val(Field(qcolor,2));
			*bl = pma ? COLOR_FROM_INT_PMA(c,alpha) : COLOR_FROM_INT(c,alpha);
			c = Long_val(Field(qcolor,3));
			*br = pma ? COLOR_FROM_INT_PMA(c,alpha) : COLOR_FROM_INT(c,alpha);*/

			value qcolor = Field(color,1);
			int32 c = Int32_val(Field(qcolor,0));

			if (pma) {
				PRINT_DEBUG("PMA QCOLOR");
				COLOR_FROM_INT32_PMA(tl, c, alpha);

				c = Int32_val(Field(qcolor,1));
				COLOR_FROM_INT32_PMA(tr, c, alpha);

				c = Int32_val(Field(qcolor,2));
				COLOR_FROM_INT32_PMA(bl, c, alpha);

				c = Int32_val(Field(qcolor,3));
				COLOR_FROM_INT32_PMA(br, c, alpha);
			} else {
				*tl = COLOR_FROM_INT32(c,alpha);
				c = Int32_val(Field(qcolor,1));
				*tr = COLOR_FROM_INT32(c,alpha);
				c = Int32_val(Field(qcolor,2));
				*bl = COLOR_FROM_INT32(c,alpha);
				c = Int32_val(Field(qcolor,3));
				*br = COLOR_FROM_INT32(c,alpha);				
			}
		}
	};
}


////////////////////////////////////
/////// QUADS 
//! a Point with a vertex point, and color 4B
typedef struct 
{ 
  //! vertices (2F)
  vertex2F    v;
  //! colors (4B)   
  color4B   c;
} lgQVertex;

#define QVertexSize sizeof(lgQVertex)

//! 4 ccV3F_C4F_T2F
typedef struct 
{
  //! top left
  lgQVertex tl;
  //! bottom left
  lgQVertex bl;
  //! top right
  lgQVertex tr;
  //! bottom right
  lgQVertex br;
} lgQuad;


#define QUAD(v) ((lgQuad*)Data_custom_val(v))

/*
static void quad_finalize(value quad) {
	lgQuad *q = QUAD(quad);
	PRINT_DEBUG("quad finalize");
	//caml_stat_free(q);
}
*/

struct custom_operations quad_ops = {
  "pointer to a quad",
  //quad_finalize,
	custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value ml_quad_create(value width,value height,value color,value alpha) {
	CAMLparam4(width,height,color,alpha);
	value res = caml_alloc_custom(&quad_ops,sizeof(lgQuad),0,1); // 
	lgQuad *q = QUAD(res);
  extract_color(color,Double_val(alpha),0,&q->tl.c,&q->tr.c,&q->bl.c,&q->br.c);
	//printf("quad color: [%hhu,%hhu,%hhu]\n",q->tl.c.r,q->tl.c.g,q->tl.c.b);
	q->bl.v = (vertex2F) { 0, 0 };
	q->br.v = (vertex2F) { Double_val(width)};
	q->tl.v = (vertex2F) { 0, Double_val(height)};
	q->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	CAMLreturn(res);
}

value ml_quad_points(value quad) { 
	CAMLparam1(quad);
	CAMLlocal4(p1,p2,p3,p4);
	lgQuad *q = QUAD(quad);
	int s = 2 * Double_wosize;
	p1 = caml_alloc(s,Double_array_tag);
	Store_double_field(p1, 0, (double)q->bl.v.x);
	Store_double_field(p1, 1, (double)q->bl.v.y);
	p2 = caml_alloc(s,Double_array_tag);
	Store_double_field(p2, 0, (double)q->br.v.x);
	Store_double_field(p2, 1, (double)q->br.v.y);
	p3 = caml_alloc(s,Double_array_tag);
	Store_double_field(p3, 0, (double)q->tl.v.x);
	Store_double_field(p3, 1, (double)q->tl.v.y);
	p4 = caml_alloc(s,Double_array_tag);
	Store_double_field(p4, 0, (double)q->tr.v.x);
	Store_double_field(p4, 1, (double)q->tr.v.y);
	value res = caml_alloc_small(4,0);
	Field(res,0) = p1;
	Field(res,1) = p2;
	Field(res,2) = p3;
	Field(res,3) = p4;
	CAMLreturn(res);
}

/*
value ml_quad_color(value quad) {
	lgQuad *q = *QUAD(quad);
	return Int_val((COLOR(q->bl.c.r,q->bl.c.b,q->bl.c.g)));
}
*/

value ml_quad_set_color(value quad,value color) {
	lgQuad *q = QUAD(quad);
	extract_color(color,((double)q->bl.c.a / 255.),0,&q->tl.c,&q->tr.c,&q->bl.c,&q->br.c);
	return Val_unit;
}

value ml_quad_alpha(value quad) {
	lgQuad *q = QUAD(quad);
	return (caml_copy_double((double)(q->bl.c.a / 255)));
}

value ml_quad_set_alpha(value quad,value alpha) {
	lgQuad *q = QUAD(quad);
	double a = Double_val(alpha);
	//printf("set quad alpha to: %d\n",a);

	q->bl.c.a = (GLubyte)(255. * a);
	q->br.c.a = (GLubyte)(255. * a);
	q->tl.c.a = (GLubyte)(255. * a);
	q->tr.c.a = (GLubyte)(255. * a);

	return Val_unit;
}

////////////////////
///// IMAGES 
///////////////////


void print_vertex(lgQVertex *qv) {
	printf("v = [%f:%f], c = [%hhu,%hhu,%hhu,%hhu]\n",qv->v.x,qv->v.y,qv->c.r,qv->c.g,qv->c.b,qv->c.a);
}

void print_quad(lgQuad *q) {
	printf("==== quad =====\n");
	printf("bl: ");
	print_vertex(&(q->bl));
	printf("br: ");
	print_vertex(&(q->br));
	printf("tl: ");
	print_vertex(&(q->tl));
	printf("tr: ");
	print_vertex(&(q->tr));
}

static inline void apply_blend(value mlblend) {
	value p = Field(mlblend,0);
	switch (Tag_val(mlblend)) {
		case 0: // BlendFunc
			glBlendFunc(Int_val(Field(p,0)),Int_val(Field(p,1)));
			break;
		case 1: // BlendFuncSeparate
			glBlendFuncSeparate(Int_val(Field(p,0)),Int_val(Field(p,1)),Int_val(Field(p,2)),Int_val(Field(p,3)));
			break;
	};
}

value ml_quad_render(value matrix, value program, value alpha, value quad) {
	lgQuad *q = QUAD(quad);
	PRINT_DEBUG("RENDER QUAD");
	checkGLErrors("start render quad");

	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);
	checkGLErrors("quad render use program");

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("image render bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosColor);

	setNotPMAGLBlend();
	long offset = (long)q;

  // vertex
  int diff = offsetof( lgQVertex, v);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, QVertexSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgQVertex, c);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, QVertexSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw quad arrays");

	kmGLPopMatrix();
	return Val_unit;
}

///////////////
// Images
//


#define IMAGE(v) ((lgImage*)Data_custom_val(v))

/*
static void image_finalize(value image) {
	PRINT_DEBUG("image finalize");
	//lgImage *img = IMAGE(image);
	//caml_stat_free(img);
}
*/

struct custom_operations image_ops = {
  "pointer to a image",
  //image_finalize,
	custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


static inline void set_image_uv(lgTexQuad *tq, value clipping) {

	if (clipping != 1) {
		value c = Field(clipping,0);
		double x = Double_field(c,0);
		double y = Double_field(c,1);
		double width = Double_field(c,2);
		double height = Double_field(c,3);
		tq->bl.tex.u = x;
		tq->bl.tex.v = y;
		tq->br.tex.u = x + width;
		tq->br.tex.v = y;
		tq->tl.tex.u = x;
		tq->tl.tex.v = y + height;
		tq->tr.tex.u = x + width;
		tq->tr.tex.v = y + height;
	} else {
		tq->bl.tex = (tex2F){0,0};
		tq->br.tex = (tex2F){1,0};
		tq->tl.tex = (tex2F){0,1};
		tq->tr.tex = (tex2F){1,1};
	};
}


void print_tex_vertex(lgTexVertex *qv) {
	printf("v = [%f:%f], c = [%hhu,%hhu,%hhu,%hhu], tex = [%f:%f] \n",qv->v.x,qv->v.y,qv->c.r,qv->c.g,qv->c.b,qv->c.a,qv->tex.u,qv->tex.v);
}

void print_image(lgImage *img) {
	printf("==== image =====\n");
	lgTexQuad *tq = &(img->quad);
	printf("bl: ");
	print_tex_vertex(&(tq->bl));
	printf("br: ");
	print_tex_vertex(&(tq->br));
	printf("tl: ");
	print_tex_vertex(&(tq->tl));
	printf("tr: ");
	print_tex_vertex(&(tq->tr));
}


#define APPLY_TEXTURE_INFO_KIND(img,textureInfo) \
	value kind = Field(textureInfo,4); \
	if (Is_long(kind)) { \
		if (Int_val(kind) < 2) { \
			img->pallete = 0;\
			img->pma = 1; \
		} else { \
			fprintf(stderr,"unknown texture kind\n"); \
			exit(3); \
		} \
	} else { \
		switch (Tag_val(kind)) { \
			case 0: \
				img->pallete = 0; \
				img->pma = Bool_val(Field(kind,0)); \
				break; \
			case 1: \
			case 2: \
				img->pallete = TEXTURE_ID(Field(Field(kind,0),7)); \
				img->pma = Bool_val(Field(Field(kind,0),5)); \
				break; \
			default: \
				fprintf(stderr,"unknown texture kind\n"); \
				exit(3); \
		};\
	}

#define TEX_SIZE(w) (Double_val(w))
//
//


value ml_image_create(value textureInfo,value color,value oalpha) {
	CAMLparam3(textureInfo,color,oalpha);
	PRINT_DEBUG("create image");
	value res = caml_alloc_custom(&image_ops,sizeof(lgImage),0,1); // 
	lgImage *img = IMAGE(res);
	lgTexQuad *tq = &(img->quad);
	extract_color(color,Double_val(oalpha),1.,&tq->tl.c,&tq->tr.c,&tq->bl.c,&tq->br.c);
	value width = Field(textureInfo,1);
	value height = Field(textureInfo,2);
	//fprintf(stderr,"width: %f, height: %f\n",TEX_SIZE(width),TEX_SIZE(height));
	tq->bl.v = (vertex2F){0,0};
	tq->br.v = (vertex2F) { TEX_SIZE(width),0.};
	tq->tl.v = (vertex2F) { 0, TEX_SIZE(height)};
	tq->tr.v = (vertex2F) { tq->br.v.x, tq->tl.v.y};
	set_image_uv(tq,Field(textureInfo,3));
	img->textureID = TEXTURE_ID(Field(textureInfo,0));
	APPLY_TEXTURE_INFO_KIND(img,textureInfo);
	CAMLreturn(res);
}

value ml_image_points(value image) {
	CAMLparam1(image);
	CAMLlocal4(p1,p2,p3,p4);
	lgImage *img = IMAGE(image);
	int s = 2 * Double_wosize;
	p1 = caml_alloc(s,Double_array_tag);
	Store_double_field(p1, 0, (double)img->quad.bl.v.x);
	Store_double_field(p1, 1, (double)img->quad.bl.v.y);
	p2 = caml_alloc(s,Double_array_tag);
	Store_double_field(p2, 0, (double)img->quad.br.v.x);
	Store_double_field(p2, 1, (double)img->quad.br.v.y);
	p3 = caml_alloc(s,Double_array_tag);
	Store_double_field(p3, 0, (double)img->quad.tl.v.x);
	Store_double_field(p3, 1, (double)img->quad.tl.v.y);
	p4 = caml_alloc(s,Double_array_tag);
	Store_double_field(p4, 0, (double)(img->quad.tr.v.x));
	Store_double_field(p4, 1, (double)(img->quad.tr.v.y));
	value res = caml_alloc_small(4,0);
	Field(res,0) = p1;
	Field(res,1) = p2;
	Field(res,2) = p3;
	Field(res,3) = p4;
	CAMLreturn(res);
}


value ml_image_set_color(value image,value color) {
	lgImage *img = IMAGE(image);
	lgTexQuad *tq = &img->quad;
	// extract_color(color,(((GLfloat)tq->bl.c.a) / 255.),1,&tq->tl.c,&tq->tr.c,&tq->bl.c,&tq->br.c);
	extract_color(color,1.,1,&tq->tl.c,&tq->tr.c,&tq->bl.c,&tq->br.c);
	return Val_unit;
}

/*
value ml_image_color(value image) {
	lgImage *img = *IMAGE(image);
	return Int_val((COLOR(img->quad.bl.c.r,img->quad.bl.c.b,img->quad.bl.c.g)));
}


void ml_image_set_color(value image,value color) {
	lgImage *img = *IMAGE(image);
	long clr = Int_val(color);
	double alpha = (double)(img->quad.bl.c.a) / 255;
	color4B c = COLOR_FROM_INT_PMA(clr,alpha);
	img->quad.bl.c = c;
	img->quad.br.c = c;
	img->quad.tl.c = c;
	img->quad.tr.c = c;
}


void ml_image_set_colors(value image,value colors) {
	lgImage *img = *IMAGE(image);
	double alpha = (double)img->quad.bl.c.a / 255;
	int c = Int_val(Field(colors,0));
	img->quad.bl.c = COLOR_FROM_INT_PMA(c,alpha);
	c = Int_val(Field(colors,1));
	img->quad.br.c = COLOR_FROM_INT_PMA(c,alpha);
	c = Int_val(Field(colors,2));
	img->quad.tl.c = COLOR_FROM_INT_PMA(c,alpha);
	c = Int_val(Field(colors,3));
	img->quad.tr.c = COLOR_FROM_INT_PMA(c,alpha);
}
*/

value ml_image_set_alpha(value image, value color, value alpha,value qcolor) {
	lgImage *img = IMAGE(image);
	lgTexQuad *tq = &(img->quad);
	double a = Double_val(alpha);

	if (qcolor == Val_true) {
		UPDATE_PMA_ALPHA_MUL(tq->bl.c,a);
		UPDATE_PMA_ALPHA_MUL(tq->br.c,a);
		UPDATE_PMA_ALPHA_MUL(tq->tl.c,a);
		UPDATE_PMA_ALPHA_MUL(tq->tr.c,a);
	} else {
		UPDATE_PMA_ALPHA(color, a, tq);
	}

	return Val_unit;
}

value ml_image_update(value image, value textureInfo, value flipX, value flipY) {
	lgImage *img = IMAGE(image);
	lgTexQuad *tq = &(img->quad);
	value width = Field(textureInfo,1);
	value height = Field(textureInfo,2);
	tq->br.v = (vertex2F) { TEX_SIZE(width)};
	tq->tl.v = (vertex2F) { 0, TEX_SIZE(height)};
	tq->tr.v = (vertex2F) { TEX_SIZE(width), TEX_SIZE(height) };
	set_image_uv(tq,Field(textureInfo,3));
	if (Bool_val(flipX)) {
		tex2F tmp = tq->tl.tex;
		tq->tl.tex = tq->tr.tex;
		tq->tr.tex = tmp;
		tmp = tq->bl.tex;
		tq->bl.tex = tq->br.tex;
		tq->br.tex = tmp;
	};
	if (Bool_val(flipY)) {
		tex2F tmp = tq->tl.tex;
		tq->tl.tex = tq->bl.tex;
		tq->bl.tex = tmp;
		tmp = tq->tr.tex;
		tq->tr.tex = tq->br.tex;
		tq->br.tex = tmp;
	};
	img->textureID = TEXTURE_ID(Field(textureInfo,0));
	APPLY_TEXTURE_INFO_KIND(img,textureInfo);
	return Val_unit;
}


#define SWAP_TEX_COORDS(c1,c2) {tex2F tmp = tq->c1.tex, tq->c1.tex = tq->c2.tex,tq->c2.tex = tmp}


value ml_image_flip_tex_x(value image) {
	lgImage *img = IMAGE(image);
	lgTexQuad *tq = &(img->quad);
	tex2F tmp = tq->tl.tex;
	tq->tl.tex = tq->tr.tex;
	tq->tr.tex = tmp;
	tmp = tq->bl.tex;
	tq->bl.tex = tq->br.tex;
	tq->br.tex = tmp;
	return Val_unit;
}

value ml_image_flip_tex_y(value image) {
	lgImage *img = IMAGE(image);
	lgTexQuad *tq = &(img->quad);
	tex2F tmp = tq->tl.tex;
	tq->tl.tex = tq->bl.tex;
	tq->bl.tex = tmp;
	tmp = tq->tr.tex;
	tq->tr.tex = tq->br.tex;
	tq->br.tex = tmp;
	return Val_unit;
}

value ml_image_render(value matrix, value program, value alpha, value blend, value image) {
	//fprintf(stderr,"render image\n");

	// PRINT_DEBUG("RENDER IMAGE");
	lgImage *img = IMAGE(image);
	checkGLErrors("start image render");

	//print_image(tq);

	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	//fprintf(stderr,"render image: %d with prg %d\n",img->textureID,sp->program);
	lgGLUseProgram(sp->program);
	checkGLErrors("image render use program");

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTexColor);
	checkGLErrors("render image: uniforms and attribs");

	value fs = Field(program,1);
	if (fs != Val_unit) {
		filter *f = FILTER(Field(fs,0));
		f->render(sp,f->data);
		checkGLErrors("apply filters");
	};

	int pma = -1;
	if (blend == Val_none) {
		pma = img->pma;
	} else {
		PRINT_DEBUG("some blend");
		apply_blend(Field(blend,0));
	};
	if (img->pallete) {
		lgGLBindTextures(img->textureID,img->pallete,pma);
	} else lgGLBindTexture(img->textureID,pma);
	checkGLErrors("bind texture");

	//print_image(tq);

	long offset = (long)(&(img->quad));

  // vertex
  int diff = offsetof( lgTexVertex, v);
	//glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgTexVertex, c);
	//glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (void*)(offset + diff));

  // texture coords
  diff = offsetof( lgTexVertex, tex);
	//glEnableVertexAttribArray(lgVertexAttrib_TexCoords);
  glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw arrays image");
	kmGLPopMatrix();

	// PRINT_DEBUG("RENDER IMAGE end");

	return Val_unit;
};


/////////////////////////////
//// RENDER TEXTURE
////////////////////




/////////////////////////////////////////////////////
// ATLASES
///////////////////////
//
//////
/// BUFFERS

// For now 2 buffers in 1 element
struct glbuffer_el
{
	GLuint buffers[2];
	struct glbuffer_el *next;
};

static struct glbuffer_el *glbuffers = NULL;

void getGLBuffers(GLuint buffers[2]) {
	// First try get from our list
	if (glbuffers != NULL) {
		memcpy(buffers,glbuffers->buffers,2 * sizeof(GLuint));
		struct glbuffer_el *tmp = glbuffers;
		glbuffers = glbuffers->next;
		free(tmp);
	} else glGenBuffers(2,buffers);
	PRINT_DEBUG("GET GL BUFFERS: %d:%d",buffers[0],buffers[1]);
}

void backGLBuffers(GLuint buffers[2]) {
	struct glbuffer_el *e = (struct glbuffer_el*)malloc(sizeof(struct glbuffer_el));
	memcpy(e->buffers,buffers,2 * sizeof(GLuint));
	e->next = glbuffers;
	glbuffers = e;
	PRINT_DEBUG("BACK BUFFERS: %d:%d",buffers[0],buffers[1]);
}



//////////////

typedef struct {
	GLuint textureID;
	unsigned char pma;
	GLuint pallete;
	GLuint vaoname;
	GLuint buffersVBO[2];
	int n_of_quads;
	int index_size;
} atlas_t;


#define ATLAS(v) ((atlas_t*)Data_custom_val(v))

static void atlas_finalize(value atlas) {
	PRINT_DEBUG("atlas finalize");
	atlas_t *atl = ATLAS(atlas);
	//glDeleteBuffers(2,atl->buffersVBO);
	backGLBuffers(atl->buffersVBO);
#ifdef HAS_VAO
    glDeleteVertexArrays(1, &atl->vaoname);
#endif    
	//caml_stat_free(atl);
}

struct custom_operations atlas_ops = {
  "pointer to atlas gl buffers",
  atlas_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/// ATLAS
value ml_atlas_init(value textureInfo) { 
	CAMLparam1(textureInfo);
	value result = caml_alloc_custom(&atlas_ops,sizeof(atlas_t),0,1);

	atlas_t *atl = ATLAS(result);
	atl->textureID = TEXTURE_ID(Field(textureInfo,0));
	APPLY_TEXTURE_INFO_KIND(atl,textureInfo);
	/*
	value kind = Field(textureInfo,4);
	if (Is_long(kind)) atl->pallete = 0;
	else atl->pallete = Long_val(Field(Field(kind,0),7));
	*/

#ifdef HAS_VAO
  glGenVertexArrays(1, &atl->vaoname);
  glBindVertexArray(atl->vaoname);
#endif

  //glGenBuffers(2, atl->buffersVBO);
	getGLBuffers(atl->buffersVBO);

  atl->index_size = 0;
  atl->n_of_quads = 0;

#ifdef HAS_VAO
  glBindBuffer(GL_ARRAY_BUFFER, atl->buffersVBO[0]);
  //glBufferData(GL_ARRAY_BUFFER, sizeof(quads_[0]) * capacity_, quads_, GL_DYNAMIC_DRAW);

  // vertices
  glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, v));
 
  // colors
	glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, c));
 
  // tex coords
	glEnableVertexAttribArray(lgVertexAttrib_TexCoords);
  glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, tex));
 
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,atl->buffersVBO[1]);

  glBindVertexArray(0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);

	checkGLErrors("atlas init");
#endif
	CAMLreturn(result);
}

// TODO: finalizlie this static arrays 
static GLushort *atlas_indices = NULL;
static int atlas_indices_len = 0;

static lgTexQuad *atlas_quads = NULL;
static int atlas_quads_len = 0;


#define RENDER_SUBPIXEL(x) round(x)

// assume that quads it's dynarray
value ml_atlas_render(value atlas, value matrix,value program, value alpha, value atlasInfo) {
	// PRINT_DEBUG("RENDER ATLAS");
	atlas_t *atl = ATLAS(atlas);
	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(Double_val(alpha)));

	value fs = Field(program,1);
	if (fs != Val_unit) {
		filter *f = FILTER(Field(fs,0));
		f->render(sp,f->data);
	};

	if (atl->pallete == 0)
		lgGLBindTexture(atl->textureID,atl->pma);
	else lgGLBindTextures(atl->textureID,atl->pallete,atl->pma);

	if (atlasInfo != Val_unit) { // it's not None array is dirty, resend it to gl
		value children = Field(Field(atlasInfo,0),0);
		value arr = Field(children,0);
		int len = Int_val(Field(children,1));
		int arrlen = Wosize_val(arr);
		//fprintf(stderr,"upgrade quads. indexlen: %d, quadslen: %d\n",arrlen,len);
		int i;

		if (arrlen != atl->index_size) { // we need resend index
			if (atlas_indices_len < arrlen) {
				atlas_indices = realloc(atlas_indices,sizeof(GLushort) * arrlen * 6);
				atlas_indices_len = arrlen;
			};
			for(i = 0; i < arrlen; i++) {
				atlas_indices[i*6+0] = i*4+0;
				atlas_indices[i*6+1] = i*4+0;
				atlas_indices[i*6+2] = i*4+2;
				atlas_indices[i*6+3] = i*4+1;
				atlas_indices[i*6+4] = i*4+3;
				atlas_indices[i*6+5] = i*4+3;
			};
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atl->buffersVBO[1]);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * arrlen * 6, atlas_indices, GL_STATIC_DRAW);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
			atl->index_size = arrlen;
		};

		if (len > atlas_quads_len) atlas_quads = realloc(atlas_quads,len * sizeof(lgTexQuad));

		value acolor = Field(Field(atlasInfo,0),1);

		color4B tlc,trc,blc,brc;
		if (!Is_long(acolor)) {
			if (caml_hash_Color == 0) caml_hash_Color = caml_hash_variant("Color");
			if (Field(acolor,0) == caml_hash_Color) {
        		int c = Long_val(Field(acolor,1));
				tlc = COLOR_FROM_INT(c,1.);// alpha = 1. PMA not need
			} else {
				value qcolor = Field(acolor,1);

				color4B* vclr = &tlc;
				int c = Int32_val(Field(qcolor,0));
				COLOR_FROM_INT32_PMA(vclr, c,1.);

				vclr = &trc;
				c = Int32_val(Field(qcolor,1));
				COLOR_FROM_INT32_PMA(vclr, c,1.);

				vclr = &blc;
				c = Int32_val(Field(qcolor,2));
				COLOR_FROM_INT32_PMA(vclr, c,1.);

				vclr = &brc;
				c = Int32_val(Field(qcolor,3));
				COLOR_FROM_INT32_PMA(vclr, c,1.);
			}
		};

		lgTexQuad *q;
		value child,points,clipping,clr,qclr;
		double alpha;
		int ic;
		for (i = 0; i < len; i++) {
			child = Field(arr,i);
			points = Field(Field(child,1),0);
			clipping = Field(child,2);
			clr = Field(child,6);
			alpha = Double_val(Field(child,7));

			q = atlas_quads + i;

			if (Is_long(acolor)) extract_color(clr,alpha,1,&q->tl.c,&q->tr.c,&q->bl.c,&q->br.c);
			else {
				if (Is_long(clr)) {
					if (Field(acolor,0) == caml_hash_Color)
						q->tl.c = q->tr.c = q->bl.c = q->br.c = tlc;
					else {
						PRINT_DEBUG("SKDFHASLKDJFAS;DFA");
						q->tl.c = tlc;
						q->tr.c = trc;
						q->bl.c = blc;
						q->br.c = brc;

						UPDATE_PMA_ALPHA_MUL(q->tl.c, alpha);
						UPDATE_PMA_ALPHA_MUL(q->tr.c, alpha);
						UPDATE_PMA_ALPHA_MUL(q->bl.c, alpha);
						UPDATE_PMA_ALPHA_MUL(q->br.c, alpha);
					}
				} else {
					#define MULTIPLY_COLORS(c,cm) (c.r = (c.r * cm.r) / 255, c.g = (c.g * cm.g) / 255, c.b = (c.b * cm.b) / 255, c.a = (c.a * cm.a) / 255 )

					if (Field(acolor,0) == caml_hash_Color) {
						if (Field(clr,0) == caml_hash_Color) {
							ic = Long_val(Field(clr,1));
							q->tl.c = COLOR_FROM_INT_PMA(ic,alpha);
							MULTIPLY_COLORS(q->tl.c,tlc);
							q->tr.c = q->bl.c = q->br.c = q->tl.c;
						} else {
							qclr = Field(clr,1);
							
							color4B* vclr = &q->tl.c;
							ic = Int32_val(Field(qclr,0));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->tl.c,tlc);

							vclr = &q->tr.c;
							ic = Int32_val(Field(qclr,1));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->tr.c,trc);

							vclr = &q->bl.c;
							ic = Int32_val(Field(qclr,2));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->bl.c,blc);

							vclr = &q->br.c;
							ic = Int32_val(Field(qclr,3));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->br.c,brc);
						}
					} else {
				        if (Field(clr,0) == caml_hash_Color) {
							ic = Long_val(Field(clr,1));
							q->tl.c = COLOR_FROM_INT_PMA(ic,alpha);
							q->tr.c = q->bl.c = q->br.c = q->tl.c;
							MULTIPLY_COLORS(q->tl.c,tlc);
							MULTIPLY_COLORS(q->tr.c,trc);
							MULTIPLY_COLORS(q->bl.c,blc);
							MULTIPLY_COLORS(q->br.c,brc);
				        } else {
				          qclr = Field(clr,1);

							color4B* vclr = &q->tl.c;
							ic = Int32_val(Field(qclr,0));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->tl.c,tlc);

							vclr = &q->tr.c;
							ic = Int32_val(Field(qclr,1));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->tr.c,trc);

							vclr = &q->bl.c;
							ic = Int32_val(Field(qclr,2));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->bl.c,blc);

							vclr = &q->br.c;
							ic = Int32_val(Field(qclr,3));
							COLOR_FROM_INT32_PMA(vclr, ic,alpha);
							MULTIPLY_COLORS(q->br.c,brc);
						}
				    }
				}
				#undef MULTIPLY_COLORS
			};

			/*
			quad[0] = Double_field(bounds,0);
			quad[1] = Double_field(bounds,1);
			quad[2] = Double_field(bounds,2);
			quad[3] = Double_field(bounds,3);
			*/

			//fprintf(stderr,"atals quad: %f:%f:%f:%f\n",quad[0],quad[1],quad[2],quad[3]);

			q->bl.v = (vertex2F){RENDER_SUBPIXEL(Double_field(points,0)),RENDER_SUBPIXEL(Double_field(points,1))};
			q->bl.tex = (tex2F){Double_field(clipping,0),Double_field(clipping,1)};

			q->br.v = (vertex2F){RENDER_SUBPIXEL(Double_field(points,2)),RENDER_SUBPIXEL(Double_field(points,3))};
			q->br.tex = (tex2F){q->bl.tex.u + Double_field(clipping,2),q->bl.tex.v};

			q->tl.v = (vertex2F){RENDER_SUBPIXEL(Double_field(points,4)),RENDER_SUBPIXEL(Double_field(points,5))};
			q->tl.tex = (tex2F){q->bl.tex.u,q->bl.tex.v + Double_field(clipping,3)};

			q->tr.v = (vertex2F){RENDER_SUBPIXEL(Double_field(points,6)),RENDER_SUBPIXEL(Double_field(points,7))};
			q->tr.tex = (tex2F){q->br.tex.u,q->tl.tex.v};

			PRINT_DEBUG("atlas node verts: [%f:%f] [%f:%f] [%f:%f] [%f:%f]",q->bl.v.x,q->bl.v.y,q->br.v.x,q->br.v.y,q->tl.v.x,q->tl.v.y,q->tr.v.x,q->tr.v.y);
			PRINT_DEBUG("atlas node uv: [%f:%f] [%f:%f] [%f:%f] [%f:%f]",q->bl.tex.u,q->bl.tex.v,q->br.tex.u,q->br.tex.v,q->tl.tex.u,q->tl.tex.v,q->tr.tex.u,q->tr.tex.v);

		};


		/*
		for (i = 0; i < len; i++) {
			print_image(atlas_quads + i);
		}; */

		glBindBuffer(GL_ARRAY_BUFFER, atl->buffersVBO[0]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(lgTexQuad) * len, atlas_quads, GL_DYNAMIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		atl->n_of_quads = len;
		
		//fprintf(stderr,"atals end quads\n");

	};
	

#ifndef HAS_VAO
	glBindBuffer(GL_ARRAY_BUFFER,atl->buffersVBO[0]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,atl->buffersVBO[1]);
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTexColor);

	// vertices
	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, v));
	// colors
	glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, c));
	// tex coords
	glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, tex));

	//glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)(atl->n_of_quads * 6),GL_UNSIGNED_SHORT,0);

	glBindBuffer(GL_ARRAY_BUFFER,0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);	
#else
	glBindVertexArray(atl->vaoname);
	checkGLErrors("before render atlas");
	glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)(atl->n_of_quads * 6),GL_UNSIGNED_SHORT,0);
	glBindVertexArray(0);
#endif
	checkGLErrors("after draw atlas");
	kmGLPopMatrix();

	return Val_unit;
}

/*
void ml_atlas_render_byte(value * argv, int n) {
	ml_atlas_render(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6]);
}
*/

void ml_atlas_clear(value atlas) {
	atlas_t *atl = ATLAS(atlas);
	glBindBuffer(GL_ARRAY_BUFFER,atl->buffersVBO[0]);
	checkGLErrors("atlas clear bindBuffer");
	glBufferData(GL_ARRAY_BUFFER,0,NULL,GL_DYNAMIC_DRAW);
	checkGLErrors("atlas clear BufferData");
	glBindBuffer(GL_ARRAY_BUFFER,0);
	checkGLErrors("atlas bind 0 buffer");
	atl->n_of_quads = 0;
}



value ml_gl_scissor_enable(value left,value top, value width, value height) {
	glEnable(GL_SCISSOR_TEST);
	glScissor(Long_val(left),Long_val(top),Long_val(width),Long_val(height));
	checkGLErrors("enable scissor");
	return Val_unit;
}


value ml_gl_scissor_disable(value unit) {
	glDisable(GL_SCISSOR_TEST);
	checkGLErrors("disable scissor");
	return Val_unit;
}

value ml_get_gl_extensions(value unit) {
	const char *ext = (char*)glGetString(GL_EXTENSIONS);
	value res = caml_copy_string(ext);
	return res;
}


///////////////////////////
/// Shapes
/////////////////////

typedef struct {
	GLfloat color[3];
	GLfloat alpha;
	GLenum method;
	GLfloat line_width;
} shape_layer_t;

typedef struct {
	GLuint buffer;
	GLuint layers_num;
	shape_layer_t* layers;
	GLuint len;
} shape_t;

#define SHAPE(v) ((shape_t*)Data_custom_val(v))

static void shape_finalize(value mlshape) {
	PRINT_DEBUG("shape finalize");
	shape_t *shape = SHAPE(mlshape);
	glDeleteBuffers(1,&shape->buffer);
}

struct custom_operations shape_ops = {
  "pointer to shape gl buffers",
  shape_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static int shape_data_len = 0;
static vertex2F *shape_vertexes = NULL;

GLuint buffer_of_mlpoints(value mlpoints) {
	GLuint buf_id;
	glGenBuffers(1, &buf_id);
	glBindBuffer(GL_ARRAY_BUFFER, buf_id);

	// Прохуячить по окамльному массиву и загнать нахуй все в буффер блядь
	mlsize_t len = caml_array_length(mlpoints);

	if (len > shape_data_len) {
		PRINT_DEBUG("realloc1 before");
		shape_vertexes = realloc(shape_vertexes,sizeof(vertex2F) * len);
		PRINT_DEBUG("realloc1 after");
		shape_data_len = len;
	}

	glBindBuffer(GL_ARRAY_BUFFER, buf_id);
	value point;

	int i;
	for (i = 0; i < len; i++) {
		point = Field(mlpoints, i);
		shape_vertexes[i].x = Double_field(point,0);
		shape_vertexes[i].y = Double_field(point,1);
	};

	glBufferData(GL_ARRAY_BUFFER, sizeof(vertex2F) * len, shape_vertexes, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	return buf_id;
}

value ml_shape_create (value mlpoints, value mllayers) {
	CAMLparam2(mlpoints, mllayers);

	value result = caml_alloc_custom(&shape_ops,sizeof(shape_t),0,1);
	shape_t *shape = SHAPE(result);

	shape->buffer = buffer_of_mlpoints(mlpoints);
	shape->layers = NULL;

	int layers_num = 0;
	value mllayer = mllayers;
	value _mllayer;
	shape_layer_t* layer;
	int color;

	while (Is_block(mllayer)) {
		_mllayer = Field(mllayer, 0);

		PRINT_DEBUG("realloc2 before");
		shape->layers = realloc(shape->layers, sizeof(shape_layer_t) * ++layers_num);
		PRINT_DEBUG("realloc2 after");
		layer = &shape->layers[layers_num - 1];

		switch Int_val(Field(_mllayer, 0)) {
			case 0: layer->method = GL_POINTS;break;
			case 1: layer->method = GL_LINES;break;
			case 2: layer->method = GL_LINE_LOOP;break;
			case 3: layer->method = GL_LINE_STRIP;break;
			case 4: layer->method = GL_TRIANGLES;break;
			case 5: layer->method = GL_TRIANGLE_STRIP;break;
			case 6: layer->method = GL_TRIANGLE_FAN;break;
		};

		color = Int_val(Field(_mllayer, 1));

		int clr_cmpnnt = COLOR_PART_RED(color);
		layer->color[0] = (GLfloat)clr_cmpnnt / 255.;

		clr_cmpnnt = COLOR_PART_GREEN(color);
		layer->color[1] = (GLfloat)clr_cmpnnt / 255.;

		clr_cmpnnt = COLOR_PART_BLUE(color);
		layer->color[2] = (GLfloat)clr_cmpnnt / 255.;		

		layer->alpha = Double_val(Field(_mllayer, 2));
		layer->line_width = Double_val(Field(_mllayer, 3));

		mllayer = Field(mllayer, 1);
	}

	shape->layers_num = layers_num;
	shape->len = caml_array_length(mlpoints);

	CAMLreturn(result);
}

value ml_shape_render(value matrix,value program,value alpha, value mlshape) {
	shape_t *shape = SHAPE(mlshape);
	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));

	PRINT_DEBUG("ml_shape_render %d %f", alpha == Val_unit, (GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));

	lgGLEnableVertexAttribs(lgVertexAttribFlag_Position);
	lgGLBindTexture(0,0);
	glBindBuffer(GL_ARRAY_BUFFER,shape->buffer);
	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, sizeof(vertex2F), (GLvoid*) 0);

	int i;
	shape_layer_t layer;
	for (i = 0; i < shape->layers_num; i++) {
		layer = shape->layers[i];
		glLineWidth(layer.line_width);

		glUniform3fv(sp->uniforms[0], 1, layer.color);
		glUniform1f(sp->uniforms[1], layer.alpha);

		glDrawArrays(layer.method, 0, shape->len);
	}
  	
	checkGLErrors("draw shape arrays");
	glBindBuffer(GL_ARRAY_BUFFER,0);

	kmGLPopMatrix();

	return Val_unit;
}

value ml_shape_set_points(value mlshape, value mlpoints) {
	CAMLparam2(mlshape, mlpoints);

	shape_t *shape = SHAPE(mlshape);
	glDeleteBuffers(1, &shape->buffer);
	shape->buffer = buffer_of_mlpoints(mlpoints);
	shape->len = caml_array_length(mlpoints);

	CAMLreturn(Val_unit);
}

////////////////////////
// GRID
////////////////////////

struct pt{
	GLfloat x;
	GLfloat y;
};
typedef struct pt Pt;

struct arrays{
	int len;
	GLuint bufferTex;
	GLuint bufferCol;
	GLuint bufferVert;
};
typedef struct arrays Arrays;

#define prerr(a) printf("log: %s\n",(a)); fflush(stdout);
#define mulP(p,m) p.x *= m; p.y *= m;
#define SZ 10

// ренденринг для BezierObject
value ml_render_grid(value matrix, value vGrid, value vTexId, value program){
	Arrays *ars = Data_custom_val(vGrid);
	int qty = ars -> len;

	GLint texId  = ((struct tex*)Data_custom_val(vTexId)) -> tid;
	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);
	
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	checkGLErrors("image render use program");
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)1);
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTexColor);
	checkGLErrors("render image: uniforms and attribs");
	
	int pma = -1;
	lgGLBindTexture(texId,pma);
	/* типа inline */

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTexColor);
	// VERTEX
	glBindBuffer(GL_ARRAY_BUFFER, ars -> bufferVert);
	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, NULL);
	// TEXTURE COORD
	glBindBuffer(GL_ARRAY_BUFFER, ars -> bufferTex);	
	glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, NULL);
	// COLORS
	glBindBuffer(GL_ARRAY_BUFFER, ars -> bufferCol);
	glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_FALSE, 0, NULL);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, qty);
	checkGLErrors("draw");
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	/* inline end */
	kmGLPopMatrix();
	return Val_unit;
}
