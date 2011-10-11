
#ifdef ANDROID
#include <GLES/gl.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
//#include <OpenGLES/ES1/glext.h>
#else
#ifdef __APPLE__
#include <OpenGL/gl.h>
#else // this is linux
#include <GL/gl.h>
#endif
#endif
#endif

#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>

#include <kazmath/GL/matrix.h>

void setupOrthographicRendering(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top) {
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  
	glViewport(left, bottom, right, top);
      
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLLoadIdentity();
      
	kmMat4 orthoMatrix;
	kmMat4OrthographicProjection(&orthoMatrix, left, right, bottom, top, -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );

	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLLoadIdentity();

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
		GLenum error = glGetError();
		if (error != GL_NO_ERROR) {
			printf("gl error\n");
		};
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
	*GLUINT(res) = shader;
	return res;
}

static GLuint currentShaderProgram = -1;
static char   vertexAttribPosition = 0;
static char   vertexAttribColor = 0;
static char   vertexAttribTexCoords = 0;

/* vertex attribs */
enum {
  lgVertexAttrib_Position = 0,
  lgVertexAttrib_Color = 1,
  lgVertexAttrib_TexCoords = 2,
  lgVertexAttrib_MAX,
};  

enum {
  lgUniformMVPMatrix,
  lgUniformSampler,

  lgUniform_MAX = 5,
};


static value mlUniformMPVMatrix = 0;
static value mlUniformSampler = 0;


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
	GLint attributes[lgVertexAttrib_MAX];
	GLint uniforms[lgUniform_MAX];
} sprogram;

#define SPROGRAM(v) *((sprogram**)Data_custom_val(v))

static void program_finalize(value program) {
	sprogram *p = SPROGRAM(program);
  if( program == currentShaderProgram ) currentShaderProgram = -1;
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


value ml_create_program(value vShader,value fShader,value attributes,value uniforms) {
	CAMLparam4(vShader,fShader,attributes,uniforms);
	CAMLlocal4(lst,ruel,runiforms,res);
	GLuint program =  glCreateProgram();
	glAttachShader(program, Int_val(vShader)); 
	glAttachShader(program, Int_val(fShader)); 
	// bind attributes
	sprogram *sp = caml_stat_alloc(sizeof(sprogram));
	lst = attributes;
	value el;
	GLuint index = 0;
	while (lst != 1) {
		el = Field(lst,0);
		value attr = Field(el,0);
		value name = Field(el,1);
		glBindAttribLocation(program,index,String_val(name));
		sp->attributes[Int_val(attr)] = index;
		lst = Field(lst,1);
		index++;
	}
	printf("AFTER ATTRIBS\n");
	for (int i = 0; i < lgVertexAttrib_MAX; i++) {
		printf("attrib: %d = %d\n",i,sp->attributes[i]);
	}
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
	if (mlUniformMPVMatrix == 0) mlUniformMPVMatrix = caml_hash_variant("UniformMPVMatrix");
	if (mlUniformSampler == 0) mlUniformMPVMatrix = caml_hash_variant("UniformSampler");
	lst = uniforms;
	runiforms = 1;
	value rel;
	while (lst != 1) {
		el = Field(lst,0);
		value attr = Field(el,0);
		value name = Field(el,1);
		GLint loc = glGetUniformLocation(program, String_val(name));
		if (attr == mlUniformMPVMatrix) {
			sp->uniforms[lgUniformMVPMatrix] = loc;
		} else if (attr == mlUniformSampler) {
			sp->uniforms[lgUniformSampler] = loc;
		};
		rel = caml_alloc_tuple(2);
		Field(rel,0) = attr; Field(rel,1) = Val_int(loc);
		ruel = caml_alloc_tuple(2);
		Field(ruel,0) = rel;
		Field(ruel,1) = runiforms;
		runiforms = ruel;
		lst = Field(lst,1);
	}
	printf("AFTER UNIFORMS\n");
	for (int i = 0; i < lgVertexAttrib_MAX; i++) {
		printf("attrib: %d = %d\n",i,sp->attributes[i]);
	}
	sp->program = program;
	// return res
	res = caml_alloc_tuple(2);
	Store_field(res,0,caml_alloc_custom(&program_ops,sizeof(*sp),0,1));
	SPROGRAM(Field(res,0)) = sp;
	Field(res,1) = runiforms;
	CAMLreturn(res);
}


void lgGLUseProgram( GLuint program ) {
  if( program != currentShaderProgram ) {
    currentShaderProgram = program;
    glUseProgram(program);
  }
}

void lgGLUniformModelViewProjectionMatrix(sprogram *sp) {
  kmMat4 matrixP;
  kmMat4 matrixMV;
  kmMat4 matrixMVP;

  kmGLGetMatrix(KM_GL_PROJECTION, &matrixP );
  kmGLGetMatrix(KM_GL_MODELVIEW, &matrixMV );

  kmMat4Multiply(&matrixMVP, &matrixP, &matrixMV);

  glUniformMatrix4fv( sp->uniforms[lgUniformMVPMatrix], 1, GL_FALSE, matrixMVP.mat);
}


void lgGLEnableVertexAttribs( unsigned int flags ) {   
  /* Position */
  char enablePosition = flags & lgVertexAttribFlag_Position;

  if( enablePosition != vertexAttribPosition ) {
    if( enablePosition )
      glEnableVertexAttribArray( lgVertexAttrib_Position );
    else
      glDisableVertexAttribArray( lgVertexAttrib_Position );
  
    vertexAttribPosition = enablePosition;
  } 
    
  /* Color */
  char enableColor = flags & lgVertexAttribFlag_Color;
  
  if( enableColor != vertexAttribColor ) {
    if( enableColor )
      glEnableVertexAttribArray( lgVertexAttrib_Color );
    else
      glDisableVertexAttribArray( lgVertexAttrib_Color );
    
    vertexAttribColor = enableColor;
  }

  /* Tex Coords */
  char enableTexCoords = flags & lgVertexAttribFlag_TexCoords;
  
  if( enableTexCoords != vertexAttribTexCoords ) {
    if( enableTexCoords ) 
      glEnableVertexAttribArray( lgVertexAttrib_TexCoords );
    else
      glDisableVertexAttribArray( lgVertexAttrib_TexCoords );
    
    vertexAttribTexCoords = enableTexCoords;
  }
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
  GLubyte r;
  GLubyte g;
  GLubyte b;
  GLubyte a;
} color4B;

#define COLOR_FROM_INT(c,alpha) (color4B){COLOR_PART_RED(c),COLOR_PART_GREEN(c),COLOR_PART_BLUE(c),alpha}


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
	color4B c = COLOR_FROM_INT(clr,255);
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
	q->bl.c.a = a;
	q->br.c.a = a;
	q->tl.c.a = a;
	q->tr.c.a = a;
}

void ml_quad_colors(value quad) {
}


void ml_quad_render(value matrix, value program, value uniforms, value alpha, value quad) {
	lgQuad *q = *QUAD(quad);
	lgGLUseProgram(program);
	sprogram *sp = SPROGRAM(Field(program,0));
	lgGLUniformModelViewProjectionMatrix(sp);
	lgGLEnableVertexAttribs( lgVertexAttribFlag_PosColor);

	long offset = (long)&q;

	/*
	printf("RENDER\n");
	for (int i = 0; i < lgVertexAttrib_MAX; i++) {
		printf("attrib: %d = %d\n",i,sp->attributes[i]);
	}*/

	#define kQuadSize sizeof(q->bl)
  // vertex
  int diff = offsetof( lgQVertex, v);
	//printf("vertex attrib position: %d, diff = %d\n",sp->attributes[lgVertexAttrib_Position],diff);
  glVertexAttribPointer(sp->attributes[lgVertexAttrib_Position], 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
  
  // color
  diff = offsetof( lgQVertex, c);
	//printf("vertex color position: %d, diff = %d\n",sp->attributes[lgVertexAttrib_Color],diff);
  glVertexAttribPointer(sp->attributes[lgVertexAttrib_Color], 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

/*
//! a Point with a vertex point, a tex coord point and a color 4B
typedef struct _ccV2F_C4B_T2F
{ 
  //! vertices (2F)
  vertex2F    vertices;
  //! colors (4B)   
  color4B   colors;
  //! tex coords (2F)
  tex2F     texCoords;
} image;





/// IMAGES 
typedef struct _ccTex2F {
   GLfloat u;
   GLfloat v;
} tex2F;

void renderImage(matrix,vertexes,colors,texCoords) {

}
*/
