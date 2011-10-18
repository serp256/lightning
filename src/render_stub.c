
#ifdef ANDROID
#include <GLES/gl.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
//#include <OpenGLES/ES1/glext.h>
#else
#include <SDL/SDL_opengl.h>
#endif
#endif



/*
#ifdef __APPLE__
#include <OpenGL/gl.h>
#else // this is linux
#include <GL/gl.h>
#endif
*/

#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>

#include <kazmath/GL/matrix.h>

void checkGLErrors(char *where) {
	GLenum error = glGetError();
	while (error != GL_NO_ERROR) {
		printf("%s: gl error: %d\n",where,error);
		error = glGetError();
	};
}

GLuint boundTextureID = 0;
int PMA = 0;

void setDefaultGLBlend () {
	if (PMA != 1) {
		glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
		PMA = 1;
	};
}

void setupOrthographicRendering(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top) {
	printf("set ortho rendering [%f:%f:%f:%f]\n",left,right,bottom,top);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  
	glViewport(left, top, right, bottom);
      
	setDefaultGLBlend();
	glClearColor(1.0,1.0,1.0,1.0);
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLLoadIdentity();
      
	kmMat4 orthoMatrix;
	//kmMat4OrthographicProjection(&orthoMatrix, left, right, bottom, top, -1024, 1024 );
	kmMat4OrthographicProjection(&orthoMatrix, left, right, bottom, top, -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );

	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLLoadIdentity();

	checkGLErrors("set ortho rendering");
	/*
  glMatrixMode gl_projection;
  glLoadIdentity();
  IFDEF GLES THEN
    glOrthof left right bottom top ~-.1.0 1.0
  ELSE
    glOrtho left right bottom top ~-.1.0 1.0
  END;
  glMatrixMode gl_modelview;
  glLoadIdentity(); 
	*/
}


void ml_setupOrthographicRendering(value left,value right,value bottom,value top) {
	setupOrthographicRendering(Double_val(left),Double_val(right),Double_val(bottom),Double_val(top));
}

void ml_clear(value color) {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
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

  kmGLMultMatrix( &transfrom4x4 );
}

void ml_push_matrix(value matrix) {
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
}


void ml_restore_matrix(value p) {
	kmGLPopMatrix();
}

//////////////////////////////////
/// COLORS

#define COLOR_PART_ALPHA(color)  (((color) >> 24) & 0xff)
#define COLOR_PART_RED(color)    (((color) >> 16) & 0xff)
#define COLOR_PART_GREEN(color)  (((color) >>  8) & 0xff)
#define COLOR_PART_BLUE(color)   ( (color)        & 0xff)

#define COLOR(r, g, b)     (((int)(r) << 16) | ((int)(g) << 8) | (int)(b))



typedef struct
{
  GLfloat x;
  GLfloat y;
} vertex2F;

typedef struct 
{
  GLfloat r;
  GLfloat g;
  GLfloat b;
} color3F;

#define COLOR3F_FROM_INT(c) (color3F){(GLfloat)(COLOR_PART_RED(c)/255.),(GLfloat)(COLOR_PART_GREEN(c)/255.),(GLfloat)(COLOR_PART_BLUE(c)/255.)}

typedef struct 
{
  GLubyte r;
  GLubyte g;
  GLubyte b;
  GLubyte a;
} color4B;

#define COLOR_FROM_INT(c,alpha) (color4B){COLOR_PART_RED(c),COLOR_PART_GREEN(c),COLOR_PART_BLUE(c),alpha}

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

char* vertexShaderLog(GLuint vertShader) {
	return (logForOpenGLObject(vertShader,(GLInfoFunction)&glGetProgramiv,(GLLogFunction)&glGetProgramInfoLog));
}

char* fragmentShaderLog(GLuint fragShader) {
  return (logForOpenGLObject(fragShader,(GLInfoFunction)&glGetShaderiv,(GLLogFunction)&glGetShaderInfoLog));
}

/*
- (NSString *)programLog
{
    return [self logForOpenGLObject:program_
                       infoCallback:(GLInfoFunction)&glGetProgramiv
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}
*/

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
    if( type == GL_VERTEX_SHADER ) {
			char *log = vertexShaderLog(shader);
			sprintf(msg,"vertex shader compilation failed: [%s]",log);
			caml_stat_free(log);
		} else {
			char *log = vertexShaderLog(shader);
      sprintf(msg,"frament shader compilation failed: [%s]",log);
			caml_stat_free(log);
		};
		glDeleteShader(shader);
		caml_failwith(msg);
  }
	value res = caml_alloc_custom(&shader_ops,sizeof(GLuint),0,1);
	printf("created shader: %d\n",shader);
	*GLUINT(res) = shader;
	return res;
}

static GLuint currentShaderProgram = -1;
/*
static char   vertexAttribPosition = 0;
static char   vertexAttribColor = 0;
static char   vertexAttribTexCoords = 0;
*/


/* vertex attribs */
enum {
  lgVertexAttrib_Position = 0,
  lgVertexAttrib_Color = 1,
  lgVertexAttrib_TexCoords = 2,
};  

enum {
  lgUniformMVPMatrix,
  lgUniformSampler,
  lgUniform_MAX,
};



/** vertex attrib flags */
enum {
  lgVertexAttribFlag_None    = 0,

  lgVertexAttribFlag_Position  = 1 << 0,
  lgVertexAttribFlag_Color   = 1 << 1,
  lgVertexAttribFlag_TexCoords = 1 << 2,
  
	lgVertexAttribFlag_PosColor = (lgVertexAttribFlag_Position | lgVertexAttribFlag_Color),
	lgVertexAttribFlag_PosColorTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_Color | lgVertexAttribFlag_TexCoords )
};


typedef struct {
	GLuint program;
	//GLint attributes[lgVertexAttrib_MAX];
	GLint uniforms[lgUniform_MAX];
	GLint *other_uniforms;
} sprogram;

/*
	void *specUniforms;
	uniformFun bindUniforms;
*/

#define SPROGRAM(v) *((sprogram**)Data_custom_val(v))

static void program_finalize(value program) {
	sprogram *p = SPROGRAM(program);
	if (p->other_uniforms != NULL) caml_stat_free(p->other_uniforms);
  if( p->program == currentShaderProgram ) currentShaderProgram = -1;
	glDeleteProgram(p->program);
	caml_stat_free(p);
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
  if( program != currentShaderProgram ) {
    currentShaderProgram = program;
    glUseProgram(program);
  }
}

void lgGLBindTexture(GLuint newTextureID, int newPMA) {
	if (boundTextureID != newTextureID) {
		glBindTexture(GL_TEXTURE_2D,newTextureID);
		boundTextureID = newTextureID;
	};
	if (newPMA != PMA) {
		if (newPMA) glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA); else glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		PMA = newPMA;
	}
}

value ml_program_create(value vShader,value fShader,value attributes,value uniforms) {
	CAMLparam4(vShader,fShader,attributes,uniforms);
	GLuint program =  glCreateProgram();
	glAttachShader(program, *GLUINT(vShader)); 
	//checkGLErrors("attach shader 1");
	glAttachShader(program, *GLUINT(fShader)); 
	//checkGLErrors("attach shader 2");
	// bind attributes
	sprogram *sp = caml_stat_alloc(sizeof(sprogram));
	value lst = attributes;
	value el;
	int has_texture = 0;
	while (lst != 1) {
		el = Field(lst,0);
		int attr = Int_val(Field(el,0));
		value name = Field(el,1);
		glBindAttribLocation(program,attr,String_val(name));
		printf("attribute: %d\n",attr);
		if (attr == lgVertexAttrib_TexCoords) has_texture = 1;
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

	checkGLErrors("before uniforms");

	sp->uniforms[lgUniformMVPMatrix] = glGetUniformLocation(program, "u_MVPMatrix");
	printf("u_matrix: %d\n",sp->uniforms[lgUniformMVPMatrix]);
	if (has_texture) {
		GLint loc = glGetUniformLocation(program,"u_texture");
		sp->uniforms[lgUniformSampler] = loc;
		lgGLUseProgram( program );
		glUniform1i(loc, 0 );
	};

	checkGLErrors("create program bind uniforms");

	int otherUniformsLen = Wosize_val(uniforms);
	if (otherUniformsLen > 0) {
		printf("otherUniformsLen = %d\n",otherUniformsLen);
		sp->other_uniforms = (GLint*)caml_stat_alloc(sizeof(GLuint)*otherUniformsLen);
		for (int idx = 0; idx < otherUniformsLen; idx++) {
			value el = Field(uniforms,idx);
			sp->other_uniforms[idx] = glGetUniformLocation(program, String_val(el));
			printf("ou: %s = %d\n",String_val(el),sp->other_uniforms[idx]);
		};
	} else sp->other_uniforms = NULL;
	sp->program = program;
	value res = caml_alloc_custom(&program_ops,sizeof(*sp),0,1);
	SPROGRAM(res) = sp;
	CAMLreturn(res);
}



void lgGLUniformModelViewProjectionMatrix(sprogram *sp) {
  kmMat4 matrixP;
  kmMat4 matrixMV;
  kmMat4 matrixMVP;

  kmGLGetMatrix(KM_GL_PROJECTION, &matrixP );
  kmGLGetMatrix(KM_GL_MODELVIEW, &matrixMV );

  kmMat4Multiply(&matrixMVP, &matrixP, &matrixMV);

	//printf("matrix uniform location: %d\n",sp->uniforms[lgUniformMVPMatrix]);
  glUniformMatrix4fv( sp->uniforms[lgUniformMVPMatrix], 1, GL_FALSE, matrixMVP.mat);
}


/*
void lgGLEnableVertexAttribs( unsigned int flags ) {   
  // Position
  char enablePosition = flags & lgVertexAttribFlag_Position;

  if( enablePosition != vertexAttribPosition ) {
    if( enablePosition ) {
			printf("enable vertex attrib array\n");
      glEnableVertexAttribArray( lgVertexAttrib_Position );
		}
    else {
			printf("disable vertex attrib array\n");
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
*/


///// FILTERS 
////////////
//

typedef void (*filterFun)(sprogram *sp,void *data);

typedef struct {
	filterFun f_fun;
	void *f_data;
} filter;

#define FILTER(v) *((filter**)Data_custom_val(v))

static void filter_finalize(value fltr) {
	filter *f = FILTER(fltr);
	caml_stat_free(f->f_data);
	caml_stat_free(f);
}

struct custom_operations filter_ops = {
  "pointer to a filter",
  filter_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


struct glowData 
{
	GLfloat glowSize;
	GLfloat glowStrenght;
	color3F glowColor;
};

void glowFilter(sprogram *sp,void *data) {
	struct glowData *d = (struct glowData*)data;
	glUniform1f(sp->other_uniforms[0],d->glowSize);
	glUniform1f(sp->other_uniforms[1],d->glowStrenght);
	glUniform3fv(sp->other_uniforms[2],1,(GLfloat*)&(d->glowColor));
}

value make_filter(filterFun fun,void *data) {
	filter *f = (filter *)caml_stat_alloc(sizeof(filter));
	f->f_fun = fun;
	f->f_data = data;
	value res = caml_alloc_custom(&filter_ops,sizeof(filter*),1,0);
	FILTER(res) = f;
	return res;
}

value ml_filter_glow(value glow) {
	struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->glowSize = Double_val(Field(glow,0)) / 1000.;
	gd->glowStrenght = Double_val(Field(glow,1));
	gd->glowColor = COLOR3F_FROM_INT(Field(glow,2));
	printf("glow filter: %f,%f,%d\n",gd->glowSize,gd->glowStrenght,gd->glowColor);
	return make_filter(&glowFilter,gd);
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


#define QUAD(v) ((lgQuad**)Data_custom_val(v))

static void quad_finalize(value quad) {
	lgQuad *q = *QUAD(quad);
	caml_stat_free(q);
}

struct custom_operations quad_ops = {
  "pointer to a quad",
  quad_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value ml_quad_create(value width,value height,value color,value alpha) {
	lgQuad *q = (lgQuad*)caml_stat_alloc(sizeof(lgQuad));
	int clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,(GLubyte)(Double_val(alpha) * 255));
	printf("quad color: [%hhu,%hhu,%hhu,%hhu]\n",c.r,c.g,c.b,c.a);
	q->bl.v = (vertex2F) { 0, 0 };
	q->bl.c = c;
	q->br.v = (vertex2F) { Double_val(width)};
	q->br.c = c;
	q->tl.v = (vertex2F) { 0, Double_val(height)};
	q->tl.c = c;
	q->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	q->tr.c = c;
	value res = caml_alloc_custom(&quad_ops,sizeof(lgQuad*),0,1); // 
	*QUAD(res) = q;
	return res;
}

value ml_quad_points(value quad) { // FIXME to array of points
	CAMLparam1(quad);
	CAMLlocal1(res);
	lgQuad *q = *QUAD(quad);
	res = caml_alloc(Double_array_tag,8);
	Store_double_field(res, 0, q->bl.v.x);
	Store_double_field(res, 1, q->bl.v.y);
	Store_double_field(res, 2, q->br.v.x);
	Store_double_field(res, 3, q->br.v.y);
	Store_double_field(res, 4, q->tl.v.x);
	Store_double_field(res, 5, q->tl.v.y);
	Store_double_field(res, 6, q->tr.v.x);
	Store_double_field(res, 7, q->tr.v.y);
	// нужно сделать массив точек 
	CAMLreturn(res);
}

value ml_quad_color(value quad) {
	lgQuad *q = *QUAD(quad);
	return Int_val((COLOR(q->bl.c.r,q->bl.c.b,q->bl.c.g)));
}

void ml_quad_set_color(value quad,value color) {
	lgQuad *q = *QUAD(quad);
	long clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,q->bl.c.a);
	q->bl.c = c;
	q->br.c = c;
	q->tl.c = c;
	q->tr.c = c;
}

value ml_quad_alpha(value quad) {
	lgQuad *q = *QUAD(quad);
	return (caml_copy_double((double)(q->bl.c.a / 255)));
}

void ml_quad_set_alpha(value quad,value alpha) {
	lgQuad *q = *QUAD(quad);
	GLubyte a = (GLubyte)(Double_val(alpha) * 255.0);
	printf("set quad alpha to: %d\n",a);
	q->bl.c.a = a;
	q->br.c.a = a;
	q->tl.c.a = a;
	q->tr.c.a = a;
}

void ml_quad_colors(value quad) {
}


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

void ml_quad_render(value matrix, value program, value alpha, value quad) {
	lgQuad *q = *QUAD(quad);
	checkGLErrors("start");
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	sprogram *sp = SPROGRAM(Field(program,0));
	printf("use program: %d\n",sp->program);
	lgGLUseProgram(sp->program);
	checkGLErrors("quad render use program");
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");
	//lgGLEnableVertexAttribs(lgVertexAttribFlag_PosColor);

	setDefaultGLBlend();
	long offset = (long)q;

	#define kQuadSize sizeof(q->bl)

  // vertex
  int diff = offsetof( lgQVertex, v);
	glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgQVertex, c);
	glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw arrays");
	kmGLPopMatrix();
}

///////////////
// Images
//

typedef struct _ccTex2F {
   GLfloat u;
   GLfloat v;
} tex2F;

typedef struct 
{ 
  //! vertices (2F)
  vertex2F    v;
  //! colors (4B)   
  color4B   c;
  //! tex coords (2F)
  tex2F     tex;
} lgTexVertex;

typedef struct
{
  //! top left
  lgTexVertex tl;
  //! bottom left
  lgTexVertex bl;
  //! top right
  lgTexVertex tr;
  //! bottom right
  lgTexVertex br;
} lgTexQuad;


#define TEXQUAD(v) ((lgTexQuad**)Data_custom_val(v))

static void tex_quad_finalize(value tquad) {
	lgTexQuad *tq = *TEXQUAD(tquad);
	caml_stat_free(tq);
}

struct custom_operations tex_quad_ops = {
  "pointer to a quad",
  tex_quad_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


void set_image_uv(lgTexQuad *tq, value clipping) {
	if (clipping != 1) {
		printf("non default clipping\n");
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
		printf("clipping default\n");
		tq->bl.tex = (tex2F){0,0};
		tq->br.tex = (tex2F){1,0};
		tq->tl.tex = (tex2F){0,1};
		tq->tr.tex = (tex2F){1,1};
	};
}

value ml_image_create(value width,value height,value clipping,value color,value alpha) {
	CAMLparam5(width,height,clipping,color,alpha);
	lgTexQuad *tq = (lgTexQuad*)caml_stat_alloc(sizeof(lgTexQuad));
	int clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,(GLubyte)(Double_val(alpha) * 255));
	tq->bl.v = (vertex2F){0,0};
	tq->bl.c = c;
	tq->br.v = (vertex2F) { Double_val(width)};
	tq->br.c = c;
	tq->tl.v = (vertex2F) { 0, Double_val(height)};
	tq->tl.c = c;
	tq->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	tq->tr.c = c;
	set_image_uv(tq,clipping);
	value res = caml_alloc_custom(&tex_quad_ops,sizeof(lgTexQuad*),0,1); // 
	*TEXQUAD(res) = tq;
	CAMLreturn(res);
}

value ml_image_color(value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	return Int_val((COLOR(tq->bl.c.r,tq->bl.c.b,tq->bl.c.g)));
}


void ml_image_set_color(value image,value color) {
	lgTexQuad *tq = *TEXQUAD(image);
	long clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,tq->bl.c.a);
	tq->bl.c = c;
	tq->br.c = c;
	tq->tl.c = c;
	tq->tr.c = c;
}

void ml_image_set_alpha(value image,value alpha) {
	lgTexQuad *tq = *TEXQUAD(image);
	GLubyte a = (GLubyte)(Double_val(alpha) * 255.0);
	tq->bl.c.a = a;
	tq->br.c.a = a;
	tq->tl.c.a = a;
	tq->tr.c.a = a;
}

void ml_image_update(value image, value width, value height, value clipping) {
	lgTexQuad *tq = *TEXQUAD(image);
	tq->br.v = (vertex2F) { Double_val(width)};
	tq->tl.v = (vertex2F) { 0, Double_val(height)};
	tq->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	set_image_uv(tq,clipping);
}

void ml_image_render(value matrix,value program, value textureID, value pma, value alpha, value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	checkGLErrors("start");
	//print_quad(q);
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	sprogram *sp = SPROGRAM(Field(program,0));
	lgGLUseProgram(sp->program);
	printf("use program: %d\n",sp->program);
	checkGLErrors("quad render use program");
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");
	//lgGLEnableVertexAttribs(lgVertexAttribFlag_PosColor);
	//
	value fs = Field(program,1);
	if (fs != Val_unit) {
		filter *f = FILTER(Field(fs,0));
		f->f_fun(sp,f->f_data);
	};
	lgGLBindTexture(*GLUINT(textureID),Int_val(pma));

	long offset = (long)tq;

	#define kTexQuadSize sizeof(tq->bl)
  // vertex
  int diff = offsetof( lgTexVertex, v);
	glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, kTexQuadSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgTexVertex, c);
	glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kTexQuadSize, (void*)(offset + diff));

  // texture coords
  diff = offsetof( lgTexVertex, tex);
	glEnableVertexAttribArray(lgVertexAttrib_TexCoords);
  glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, kTexQuadSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw arrays");
	kmGLPopMatrix();
};
