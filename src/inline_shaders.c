#include <stdio.h>
#include "texture_common.h"
#include "inline_shaders.h"

// Shaders

GLuint compile_shader(GLenum sType, const char* shaderSource) {
	GLuint shader = glCreateShader(sType);
	glShaderSource(shader, 1, &shaderSource, NULL);
	glCompileShader(shader);
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

	PRINT_DEBUG("COMPILE SHADER %d", status);
  if(!status)
	{
		GLint logLength = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
		char *shaderInfoLog = (char *)malloc(logLength);
		glGetShaderInfoLog(shader, logLength, &logLength, shaderInfoLog);
		PRINT_DEBUG("shader error: <%s> -> [%s]\n",shaderSource,shaderInfoLog);
		fprintf(stderr,"shader error: <%s> -> [%s]\n",shaderSource,shaderInfoLog);
		free(shaderInfoLog);
		glDeleteShader(shader);
		return 0;
	};
	return shader;
}

#define SHADER(fun_name, shader_type, shader_src_macro)							\
	GLuint fun_name() {															\
		static GLuint shader = 0;												\
		if (!shader) shader = compile_shader(shader_type, shader_src_macro);	\
		return shader;															\
	}

#define CLEAR_QUAD_VSHADER			\
	"#ifdef GL_ES\n 				\
	precision lowp float;\n			\
	#endif\n						\
	attribute vec4 a_position;		\
	void main()	{					\
		gl_Position = a_position;	\
	}"

#define CLEAR_QUAD_FSHADER		\
	"#ifdef GL_ES\n 			\
	precision lowp float;\n		\
	#endif\n					\
	uniform vec4 u_color;		\
	void main() {				\
		gl_FragColor = u_color;	\
	}"

SHADER(clear_quad_vshader, GL_VERTEX_SHADER, CLEAR_QUAD_VSHADER)
SHADER(clear_quad_fshader, GL_FRAGMENT_SHADER, CLEAR_QUAD_FSHADER)

prg_t* clear_quad_progr() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		PRINT_DEBUG("prg.prg == 0 = TRUE");

		char* attribs[1] = { "a_position" };
		prg.prg = create_program(clear_quad_vshader(), clear_quad_fshader(), 1, attribs);

		if (prg.prg) {
			glUseProgram(prg.prg);
			prg.uniforms[0] = glGetUniformLocation(prg.prg, "u_color");
		}
	}
	else {
		PRINT_DEBUG("use clear quad progr");
		glUseProgram(prg.prg);
	}

	return &prg;
}

GLuint simple_vertex_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_VERTEX_SHADER,
			"attribute vec4 a_position; attribute vec2 a_texCoord; varying vec2 v_texCoord; \
			void main(void) { \
			gl_Position = a_position; \
			v_texCoord = a_texCoord; \
			}");
	};
	return shader;
}

GLuint simple_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision lowp float; \n#endif\n\
				varying vec2 v_texCoord; uniform sampler2D u_texture;\
				void main() {\
					 gl_FragColor = texture2D(u_texture, v_texCoord);\
				}");
	};
	return shader;
}


GLuint create_program(GLuint vShader, GLuint fShader, int cntattribs, char* attribs[]) {
	PRINT_DEBUG("create_program %d %d", vShader, fShader);
	GLuint program =  glCreateProgram();
	glAttachShader(program, vShader);
	glAttachShader(program, fShader); 
	int i;

	for (i = 0; i < cntattribs; i++) {
		glBindAttribLocation(program,i,attribs[i]);
	};

  	glLinkProgram(program);
	int IsLinked;
  	glGetProgramiv(program, GL_LINK_STATUS, (int *)&IsLinked);

	if (IsLinked == 0) {
		int maxLength;
	    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &maxLength);
	    char *shaderProgramInfoLog = (char *)malloc(maxLength);
	    glGetProgramInfoLog(program, maxLength, &maxLength, shaderProgramInfoLog);
	    fprintf(stderr,"program error: %s\n",shaderProgramInfoLog);
	    glDetachShader(program,vShader);
	    glDetachShader(program,fShader);
	    glDeleteProgram(program);
	    free(shaderProgramInfoLog);
	    return 0;
  	}

  	return program;
}

prg_t* simple_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		PRINT_DEBUG("create new program\n");
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),simple_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

GLuint glow_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform vec3 u_color;\n"\
				"void main() {"\
					"gl_FragColor = vec4(u_color,texture2D(u_texture,v_texCoord).a);"\
				"}");
	};
	return shader;
};

const prg_t* glow_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),glow_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg, "u_color");
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

GLuint final_glow_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform float u_strength;\n"\
				"void main() {"\
					"vec4 color = texture2D(u_texture,v_texCoord);\n"\
					"color.a *= u_strength;\n"\
					"gl_FragColor = color;"\
				"}");
	};
	return shader;
};


const prg_t* final_glow_program() {
	static prg_t prg = {0,{0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),final_glow_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg,"u_strength");
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

GLuint glow2_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform int u_twidth; uniform int u_theight; uniform vec3 u_gcolor; uniform float u_strength;\n"\
				"void main() {"\
					"float px = 1. / float(u_twidth);"\
					"float py = 1. / float(u_theight);"\
					"float a = texture2D(u_texture,v_texCoord + vec2(-px,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(0,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,0)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(0,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(-px,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(-px,0)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord).a * 0.6;"\
					"gl_FragColor = vec4(u_gcolor,a * u_strength);"
				"}");
	};
	return shader;
					//"gl_FragColor = vec4(u_gcolor,a * float(u_strength));"
};

const prg_t* glow2_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),glow2_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg,"u_gcolor");
			prg.uniforms[1] = glGetUniformLocation(prg.prg,"u_twidth");
			prg.uniforms[2] = glGetUniformLocation(prg.prg,"u_theight");
			prg.uniforms[3] = glGetUniformLocation(prg.prg,"u_strength");
			glUniform1f(prg.uniforms[3],1.);
		}
	} else glUseProgram(prg.prg);
	return &prg;
}
