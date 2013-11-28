typedef struct {
	GLuint prg;
	GLint uniforms[4];
} prg_t;

prg_t* clear_quad_progr();
GLuint compile_shader(GLenum sType, const char* shaderSource);
GLuint simple_vertex_shader();
GLuint simple_fragment_shader();
GLuint create_program(GLuint vShader, GLuint fShader, int cntattribs, char* attribs[]);
prg_t* simple_program();
GLuint glow_fragment_shader();
const prg_t* glow_program();
GLuint final_glow_fragment_shader();
const prg_t* final_glow_program();
GLuint glow2_fragment_shader();
const prg_t* glow2_program();
GLuint normal_horizontal_blur_fsh();
GLuint normal_vertical_blur_fsh();
GLuint horizontal_blur_fsh();
GLuint vertical_blur_fsh();
prg_t* shadow_vertical_blur_prog();
prg_t* shadow_horizontal_blur_prog();