(**
 GLCaml - Objective Caml interface for OpenGL 1.1, 1.2, 1.3, 1.4, 1.5, 2.0 and 2.1
 plus ARB and vendor-specific extensions 
 *)
(* Copyright (C) 2007, 2008 Elliott OTI
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided 
 * that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright notice, this list of conditions 
 *    and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
 *    and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  - The name Elliott Oti may not be used to endorse or promote products derived from this software 
 *    without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)
(**
The OpenGL reference manuals can be found at http://www.opengl.org/documentation/specs/.

In GLCaml, OpenGL constants have the same names as in C, but are written in lower case.

OpenGL functions have the same names as in C, but the signatures may differ slightly. 
The parameters are translated according to the following table:

- GLboolean  	-> bool
- void    		-> unit
- GLvoid    	-> unit
- GLuint     	-> int
- GLint      	-> int
- GLintptr   	-> int
- GLenum     	-> int
- GLsizei   	-> int
- GLsizeiptr 	-> int
- GLfloat    	-> float
- GLdouble   	-> float
- GLchar     	-> int
- GLclampf   	-> float
- GLclampd   	-> float
- GLshort    	-> int
- GLubyte    	-> int
- GLbitfield 	-> int
- GLushort   	-> int
- GLbyte     	-> int
- GLstring		-> string
- GLbyte*    	-> int array
- GLubyte*    	-> int array
- void*    		-> 'a
- GLvoid*    	-> 'a
- GLvoid**   	-> 'a
- GLuint*    	-> int array
- GLint*    	-> int array
- GLfloat*   	-> float array
- GLdouble*  	-> float array
- GLchar*    	-> string
- GLchar**   	-> string array
- GLclampf*  	-> float array
- GLclampd*  	-> float array
- GLshort*   	-> int array
- GLushort*  	-> int array
- GLboolean*  	-> bool array
- GLboolean** 	-> word_matrix
- GLsizei*   	-> int array
- GLenum*    	-> int array


Void pointers are represented by the polymorphic type ['a], but in the FFI only strings, Bigarrays, or foreign-function interface bindings to C arrays 
are actually processed properly (such as [SDLCaml.surface_pixels] which returns in essence a pointer to an array containing the bitmap contents).
Passing other types will most likely result in a segfault. 

There is one function ([glEdgeFlagPointerListIBM]) which requires an array of arrays of Booleans. The array of array of GLbooleans is in GLCaml
in this single instance represented by a 2-dimensional Bigarray of 32-bit integers, so manual conversion from and to bools need to take place.
All other conversions are handled automatically by GLCaml.

The parameter conversion convention means that a lot of the OpenGL functions are superfluous in GLCaml, since they have the same Ocaml signature
despite having different C signatures. [glVertex2i] and [glVertex2s], for instance, take int and short arguments respectively in C, but both take native 
integers in Ocaml. Likewise [glVertex2f] (single-precision floats) and [glVertex2d] (double precision floats) both translate to having double precision float arguments
in the Ocaml bindings. This also means that precision may be lost or overflow may occur when using integer arguments for an OpenGL function that
uses 8-bit or 16-bit integers; likewise when using Ocaml floats for OpenGL functions using single-precision floats.

Note that most OpenGL implementations use single-precision floating point internally, even if the call is made with an API function using doubles.
OpenGL 3.0, due to be released in 2008, will only support single precision floating point.

*)
type byte_array =
  Bigarray.Array1.t int Bigarray.int8_signed_elt Bigarray.c_layout;
type ubyte_array =
  Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
type short_array =
  Bigarray.Array1.t int Bigarray.int16_signed_elt Bigarray.c_layout;
type ushort_array =
  Bigarray.Array1.t int Bigarray.int16_unsigned_elt Bigarray.c_layout;
type word_array =
  Bigarray.Array1.t int32 Bigarray.int32_elt Bigarray.c_layout;
type dword_array =
  Bigarray.Array1.t int64 Bigarray.int64_elt Bigarray.c_layout;
type int_array = Bigarray.Array1.t int Bigarray.int_elt Bigarray.c_layout;
type float_array =
  Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
type double_array =
  Bigarray.Array1.t float Bigarray.float64_elt Bigarray.c_layout;
type byte_matrix =
  Bigarray.Array2.t int Bigarray.int8_signed_elt Bigarray.c_layout;
type ubyte_matrix =
  Bigarray.Array2.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
type short_matrix =
  Bigarray.Array2.t int Bigarray.int16_signed_elt Bigarray.c_layout;
type ushort_matrix =
  Bigarray.Array2.t int Bigarray.int16_unsigned_elt Bigarray.c_layout;
type word_matrix =
  Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;
type dword_matrix =
  Bigarray.Array2.t int64 Bigarray.int64_elt Bigarray.c_layout;
type int_matrix = Bigarray.Array2.t int Bigarray.int_elt Bigarray.c_layout;
type float_matrix =
  Bigarray.Array2.t float Bigarray.float32_elt Bigarray.c_layout;
type double_matrix =
  Bigarray.Array2.t float Bigarray.float64_elt Bigarray.c_layout;
value make_byte_array :
  int -> Bigarray.Array1.t int Bigarray.int8_signed_elt Bigarray.c_layout;
value make_ubyte_array :
  int -> Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
value make_short_array :
  int -> Bigarray.Array1.t int Bigarray.int16_signed_elt Bigarray.c_layout;
value make_ushort_array :
  int -> Bigarray.Array1.t int Bigarray.int16_unsigned_elt Bigarray.c_layout;
value make_word_array :
  int -> Bigarray.Array1.t int32 Bigarray.int32_elt Bigarray.c_layout;
value make_dword_array :
  int -> Bigarray.Array1.t int64 Bigarray.int64_elt Bigarray.c_layout;
value make_int_array :
  int -> Bigarray.Array1.t int Bigarray.int_elt Bigarray.c_layout;
value make_float_array :
  int -> Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
value make_double_array :
  int -> Bigarray.Array1.t float Bigarray.float64_elt Bigarray.c_layout;
value make_byte_matrix :
  int ->
    int -> Bigarray.Array2.t int Bigarray.int8_signed_elt Bigarray.c_layout;
value make_ubyte_matrix :
  int ->
    int -> Bigarray.Array2.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
value make_short_matrix :
  int ->
    int -> Bigarray.Array2.t int Bigarray.int16_signed_elt Bigarray.c_layout;
value make_ushort_matrix :
  int ->
    int ->
      Bigarray.Array2.t int Bigarray.int16_unsigned_elt Bigarray.c_layout;
value make_word_matrix :
  int -> int -> Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;
value make_dword_matrix :
  int -> int -> Bigarray.Array2.t int64 Bigarray.int64_elt Bigarray.c_layout;
value make_int_matrix :
  int -> int -> Bigarray.Array2.t int Bigarray.int_elt Bigarray.c_layout;
value make_float_matrix :
  int ->
    int -> Bigarray.Array2.t float Bigarray.float32_elt Bigarray.c_layout;
value make_double_matrix :
  int ->
    int -> Bigarray.Array2.t float Bigarray.float64_elt Bigarray.c_layout;
value to_byte_array :
  array int ->
    Bigarray.Array1.t int Bigarray.int8_signed_elt Bigarray.c_layout;
value to_ubyte_array :
  array int ->
    Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
value to_short_array :
  array int ->
    Bigarray.Array1.t int Bigarray.int16_signed_elt Bigarray.c_layout;
value to_ushort_array :
  array int ->
    Bigarray.Array1.t int Bigarray.int16_unsigned_elt Bigarray.c_layout;
value to_word_array :
  array int -> Bigarray.Array1.t int32 Bigarray.int32_elt Bigarray.c_layout;
value to_dword_array :
  array int -> Bigarray.Array1.t int64 Bigarray.int64_elt Bigarray.c_layout;
value to_int_array :
  array int -> Bigarray.Array1.t int Bigarray.int_elt Bigarray.c_layout;
value to_float_array :
  array float ->
    Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
value to_double_array :
  array float ->
    Bigarray.Array1.t float Bigarray.float64_elt Bigarray.c_layout;
value copy_byte_array : Bigarray.Array1.t 'a 'b 'c -> array 'a -> unit;
value copy_ubyte_array : Bigarray.Array1.t 'a 'b 'c -> array 'a -> unit;
value copy_short_array : Bigarray.Array1.t 'a 'b 'c -> array 'a -> unit;
value copy_ushort_array : Bigarray.Array1.t 'a 'b 'c -> array 'a -> unit;
value copy_word_array : Bigarray.Array1.t int32 'a 'b -> array int -> unit;
value copy_dword_array : Bigarray.Array1.t int64 'a 'b -> array int -> unit;
value copy_float_array :
  'a -> 'b -> Bigarray.Array1.t 'c 'd 'e -> array 'c -> unit;
value copy_double_array :
  'a -> 'b -> Bigarray.Array1.t 'c 'd 'e -> array 'c -> unit;
value to_string : Bigarray.Array1.t char 'a 'b -> string;
value int_of_bool : bool -> int;
value bool_of_int : int -> bool;
value bool_to_int_array : array bool -> array int;
value int_to_bool_array : array int -> array bool;
value copy_to_bool_array : array int -> array bool -> array unit;
value gl_constant_color : int;
value gl_one_minus_constant_color : int;
value gl_constant_alpha : int;
value gl_one_minus_constant_alpha : int;
value gl_blend_color : int;
value gl_func_add : int;
value gl_min : int;
value gl_max : int;
value gl_blend_equation : int;
value gl_func_subtract : int;
value gl_func_reverse_subtract : int;
value gl_convolution_1d : int;
value gl_convolution_2d : int;
value gl_separable_2d : int;
value gl_convolution_border_mode : int;
value gl_convolution_filter_scale : int;
value gl_convolution_filter_bias : int;
value gl_reduce : int;
value gl_convolution_format : int;
value gl_convolution_width : int;
value gl_convolution_height : int;
value gl_max_convolution_width : int;
value gl_max_convolution_height : int;
value gl_post_convolution_red_scale : int;
value gl_post_convolution_green_scale : int;
value gl_post_convolution_blue_scale : int;
value gl_post_convolution_alpha_scale : int;
value gl_post_convolution_red_bias : int;
value gl_post_convolution_green_bias : int;
value gl_post_convolution_blue_bias : int;
value gl_post_convolution_alpha_bias : int;
value gl_histogram : int;
value gl_proxy_histogram : int;
value gl_histogram_width : int;
value gl_histogram_format : int;
value gl_histogram_red_size : int;
value gl_histogram_green_size : int;
value gl_histogram_blue_size : int;
value gl_histogram_alpha_size : int;
value gl_histogram_luminance_size : int;
value gl_histogram_sink : int;
value gl_minmax : int;
value gl_minmax_format : int;
value gl_minmax_sink : int;
value gl_table_too_large : int;
value gl_color_matrix : int;
value gl_color_matrix_stack_depth : int;
value gl_max_color_matrix_stack_depth : int;
value gl_post_color_matrix_red_scale : int;
value gl_post_color_matrix_green_scale : int;
value gl_post_color_matrix_blue_scale : int;
value gl_post_color_matrix_alpha_scale : int;
value gl_post_color_matrix_red_bias : int;
value gl_post_color_matrix_green_bias : int;
value gl_post_color_matrix_blue_bias : int;
value gl_post_color_matrix_alpha_bias : int;
value gl_color_table : int;
value gl_post_convolution_color_table : int;
value gl_post_color_matrix_color_table : int;
value gl_proxy_color_table : int;
value gl_proxy_post_convolution_color_table : int;
value gl_proxy_post_color_matrix_color_table : int;
value gl_color_table_scale : int;
value gl_color_table_bias : int;
value gl_color_table_format : int;
value gl_color_table_width : int;
value gl_color_table_red_size : int;
value gl_color_table_green_size : int;
value gl_color_table_blue_size : int;
value gl_color_table_alpha_size : int;
value gl_color_table_luminance_size : int;
value gl_color_table_intensity_size : int;
value gl_ignore_border : int;
value gl_constant_border : int;
value gl_wrap_border : int;
value gl_replicate_border : int;
value gl_convolution_border_color : int;
value gl_texture0_arb : int;
value gl_texture1_arb : int;
value gl_texture2_arb : int;
value gl_texture3_arb : int;
value gl_texture4_arb : int;
value gl_texture5_arb : int;
value gl_texture6_arb : int;
value gl_texture7_arb : int;
value gl_texture8_arb : int;
value gl_texture9_arb : int;
value gl_texture10_arb : int;
value gl_texture11_arb : int;
value gl_texture12_arb : int;
value gl_texture13_arb : int;
value gl_texture14_arb : int;
value gl_texture15_arb : int;
value gl_texture16_arb : int;
value gl_texture17_arb : int;
value gl_texture18_arb : int;
value gl_texture19_arb : int;
value gl_texture20_arb : int;
value gl_texture21_arb : int;
value gl_texture22_arb : int;
value gl_texture23_arb : int;
value gl_texture24_arb : int;
value gl_texture25_arb : int;
value gl_texture26_arb : int;
value gl_texture27_arb : int;
value gl_texture28_arb : int;
value gl_texture29_arb : int;
value gl_texture30_arb : int;
value gl_texture31_arb : int;
value gl_active_texture_arb : int;
value gl_client_active_texture_arb : int;
value gl_max_texture_units_arb : int;
value gl_depth_component16_arb : int;
value gl_depth_component24_arb : int;
value gl_depth_component32_arb : int;
value gl_texture_depth_size_arb : int;
value gl_depth_texture_mode_arb : int;
value gl_max_draw_buffers_arb : int;
value gl_draw_buffer0_arb : int;
value gl_draw_buffer1_arb : int;
value gl_draw_buffer2_arb : int;
value gl_draw_buffer3_arb : int;
value gl_draw_buffer4_arb : int;
value gl_draw_buffer5_arb : int;
value gl_draw_buffer6_arb : int;
value gl_draw_buffer7_arb : int;
value gl_draw_buffer8_arb : int;
value gl_draw_buffer9_arb : int;
value gl_draw_buffer10_arb : int;
value gl_draw_buffer11_arb : int;
value gl_draw_buffer12_arb : int;
value gl_draw_buffer13_arb : int;
value gl_draw_buffer14_arb : int;
value gl_draw_buffer15_arb : int;
value gl_fragment_program_arb : int;
value gl_program_alu_instructions_arb : int;
value gl_program_tex_instructions_arb : int;
value gl_program_tex_indirections_arb : int;
value gl_program_native_alu_instructions_arb : int;
value gl_program_native_tex_instructions_arb : int;
value gl_program_native_tex_indirections_arb : int;
value gl_max_program_alu_instructions_arb : int;
value gl_max_program_tex_instructions_arb : int;
value gl_max_program_tex_indirections_arb : int;
value gl_max_program_native_alu_instructions_arb : int;
value gl_max_program_native_tex_instructions_arb : int;
value gl_max_program_native_tex_indirections_arb : int;
value gl_max_texture_coords_arb : int;
value gl_max_texture_image_units_arb : int;
value gl_fragment_shader_arb : int;
value gl_max_fragment_uniform_components_arb : int;
value gl_fragment_shader_derivative_hint_arb : int;
value gl_half_float_arb : int;
value gl_multisample_arb : int;
value gl_sample_alpha_to_coverage_arb : int;
value gl_sample_alpha_to_one_arb : int;
value gl_sample_coverage_arb : int;
value gl_sample_buffers_arb : int;
value gl_samples_arb : int;
value gl_sample_coverage_value_arb : int;
value gl_sample_coverage_invert_arb : int;
value gl_multisample_bit_arb : int;
value gl_query_counter_bits_arb : int;
value gl_current_query_arb : int;
value gl_query_result_arb : int;
value gl_query_result_available_arb : int;
value gl_samples_passed_arb : int;
value gl_pixel_pack_buffer_arb : int;
value gl_pixel_unpack_buffer_arb : int;
value gl_pixel_pack_buffer_binding_arb : int;
value gl_pixel_unpack_buffer_binding_arb : int;
value gl_point_size_min_arb : int;
value gl_point_size_max_arb : int;
value gl_point_fade_threshold_size_arb : int;
value gl_point_distance_attenuation_arb : int;
value gl_point_sprite_arb : int;
value gl_coord_replace_arb : int;
value gl_program_object_arb : int;
value gl_shader_object_arb : int;
value gl_object_type_arb : int;
value gl_object_subtype_arb : int;
value gl_float_vec2_arb : int;
value gl_float_vec3_arb : int;
value gl_float_vec4_arb : int;
value gl_int_vec2_arb : int;
value gl_int_vec3_arb : int;
value gl_int_vec4_arb : int;
value gl_bool_arb : int;
value gl_bool_vec2_arb : int;
value gl_bool_vec3_arb : int;
value gl_bool_vec4_arb : int;
value gl_float_mat2_arb : int;
value gl_float_mat3_arb : int;
value gl_float_mat4_arb : int;
value gl_sampler_1d_arb : int;
value gl_sampler_2d_arb : int;
value gl_sampler_3d_arb : int;
value gl_sampler_cube_arb : int;
value gl_sampler_1d_shadow_arb : int;
value gl_sampler_2d_shadow_arb : int;
value gl_sampler_2d_rect_arb : int;
value gl_sampler_2d_rect_shadow_arb : int;
value gl_object_delete_status_arb : int;
value gl_object_compile_status_arb : int;
value gl_object_link_status_arb : int;
value gl_object_validate_status_arb : int;
value gl_object_info_log_length_arb : int;
value gl_object_attached_objects_arb : int;
value gl_object_active_uniforms_arb : int;
value gl_object_active_uniform_max_length_arb : int;
value gl_object_shader_source_length_arb : int;
value gl_shading_language_version_arb : int;
value gl_texture_compare_mode_arb : int;
value gl_texture_compare_func_arb : int;
value gl_compare_r_to_texture_arb : int;
value gl_texture_compare_fail_value_arb : int;
value gl_clamp_to_border_arb : int;
value gl_compressed_alpha_arb : int;
value gl_compressed_luminance_arb : int;
value gl_compressed_luminance_alpha_arb : int;
value gl_compressed_intensity_arb : int;
value gl_compressed_rgb_arb : int;
value gl_compressed_rgba_arb : int;
value gl_texture_compression_hint_arb : int;
value gl_texture_compressed_image_size_arb : int;
value gl_texture_compressed_arb : int;
value gl_num_compressed_texture_formats_arb : int;
value gl_compressed_texture_formats_arb : int;
value gl_normal_map_arb : int;
value gl_reflection_map_arb : int;
value gl_texture_cube_map_arb : int;
value gl_texture_binding_cube_map_arb : int;
value gl_texture_cube_map_positive_x_arb : int;
value gl_texture_cube_map_negative_x_arb : int;
value gl_texture_cube_map_positive_y_arb : int;
value gl_texture_cube_map_negative_y_arb : int;
value gl_texture_cube_map_positive_z_arb : int;
value gl_texture_cube_map_negative_z_arb : int;
value gl_proxy_texture_cube_map_arb : int;
value gl_max_cube_map_texture_size_arb : int;
value gl_subtract_arb : int;
value gl_combine_arb : int;
value gl_combine_rgb_arb : int;
value gl_combine_alpha_arb : int;
value gl_rgb_scale_arb : int;
value gl_add_signed_arb : int;
value gl_interpolate_arb : int;
value gl_constant_arb : int;
value gl_primary_color_arb : int;
value gl_previous_arb : int;
value gl_source0_rgb_arb : int;
value gl_source1_rgb_arb : int;
value gl_source2_rgb_arb : int;
value gl_source0_alpha_arb : int;
value gl_source1_alpha_arb : int;
value gl_source2_alpha_arb : int;
value gl_operand0_rgb_arb : int;
value gl_operand1_rgb_arb : int;
value gl_operand2_rgb_arb : int;
value gl_operand0_alpha_arb : int;
value gl_operand1_alpha_arb : int;
value gl_operand2_alpha_arb : int;
value gl_dot3_rgb_arb : int;
value gl_dot3_rgba_arb : int;
value gl_rgba32f_arb : int;
value gl_rgb32f_arb : int;
value gl_alpha32f_arb : int;
value gl_intensity32f_arb : int;
value gl_luminance32f_arb : int;
value gl_luminance_alpha32f_arb : int;
value gl_rgba16f_arb : int;
value gl_rgb16f_arb : int;
value gl_alpha16f_arb : int;
value gl_intensity16f_arb : int;
value gl_luminance16f_arb : int;
value gl_luminance_alpha16f_arb : int;
value gl_texture_red_type_arb : int;
value gl_texture_green_type_arb : int;
value gl_texture_blue_type_arb : int;
value gl_texture_alpha_type_arb : int;
value gl_texture_luminance_type_arb : int;
value gl_texture_intensity_type_arb : int;
value gl_texture_depth_type_arb : int;
value gl_unsigned_normalized_arb : int;
value gl_mirrored_repeat_arb : int;
value gl_texture_rectangle_arb : int;
value gl_texture_binding_rectangle_arb : int;
value gl_proxy_texture_rectangle_arb : int;
value gl_max_rectangle_texture_size_arb : int;
value gl_transpose_modelview_matrix_arb : int;
value gl_transpose_projection_matrix_arb : int;
value gl_transpose_texture_matrix_arb : int;
value gl_transpose_color_matrix_arb : int;
value gl_buffer_size_arb : int;
value gl_buffer_usage_arb : int;
value gl_array_buffer_arb : int;
value gl_element_array_buffer_arb : int;
value gl_array_buffer_binding_arb : int;
value gl_element_array_buffer_binding_arb : int;
value gl_vertex_array_buffer_binding_arb : int;
value gl_normal_array_buffer_binding_arb : int;
value gl_color_array_buffer_binding_arb : int;
value gl_index_array_buffer_binding_arb : int;
value gl_texture_coord_array_buffer_binding_arb : int;
value gl_edge_flag_array_buffer_binding_arb : int;
value gl_secondary_color_array_buffer_binding_arb : int;
value gl_fog_coordinate_array_buffer_binding_arb : int;
value gl_weight_array_buffer_binding_arb : int;
value gl_vertex_attrib_array_buffer_binding_arb : int;
value gl_read_only_arb : int;
value gl_write_only_arb : int;
value gl_read_write_arb : int;
value gl_buffer_access_arb : int;
value gl_buffer_mapped_arb : int;
value gl_buffer_map_pointer_arb : int;
value gl_stream_draw_arb : int;
value gl_stream_read_arb : int;
value gl_stream_copy_arb : int;
value gl_static_draw_arb : int;
value gl_static_read_arb : int;
value gl_static_copy_arb : int;
value gl_dynamic_draw_arb : int;
value gl_dynamic_read_arb : int;
value gl_dynamic_copy_arb : int;
value gl_color_sum_arb : int;
value gl_vertex_program_arb : int;
value gl_vertex_attrib_array_enabled_arb : int;
value gl_vertex_attrib_array_size_arb : int;
value gl_vertex_attrib_array_stride_arb : int;
value gl_vertex_attrib_array_type_arb : int;
value gl_current_vertex_attrib_arb : int;
value gl_program_length_arb : int;
value gl_program_string_arb : int;
value gl_max_program_matrix_stack_depth_arb : int;
value gl_max_program_matrices_arb : int;
value gl_current_matrix_stack_depth_arb : int;
value gl_current_matrix_arb : int;
value gl_vertex_program_point_size_arb : int;
value gl_vertex_program_two_side_arb : int;
value gl_vertex_attrib_array_pointer_arb : int;
value gl_program_error_position_arb : int;
value gl_program_binding_arb : int;
value gl_max_vertex_attribs_arb : int;
value gl_vertex_attrib_array_normalized_arb : int;
value gl_program_error_string_arb : int;
value gl_program_format_ascii_arb : int;
value gl_program_format_arb : int;
value gl_program_instructions_arb : int;
value gl_max_program_instructions_arb : int;
value gl_program_native_instructions_arb : int;
value gl_max_program_native_instructions_arb : int;
value gl_program_temporaries_arb : int;
value gl_max_program_temporaries_arb : int;
value gl_program_native_temporaries_arb : int;
value gl_max_program_native_temporaries_arb : int;
value gl_program_parameters_arb : int;
value gl_max_program_parameters_arb : int;
value gl_program_native_parameters_arb : int;
value gl_max_program_native_parameters_arb : int;
value gl_program_attribs_arb : int;
value gl_max_program_attribs_arb : int;
value gl_program_native_attribs_arb : int;
value gl_max_program_native_attribs_arb : int;
value gl_program_address_registers_arb : int;
value gl_max_program_address_registers_arb : int;
value gl_program_native_address_registers_arb : int;
value gl_max_program_native_address_registers_arb : int;
value gl_max_program_local_parameters_arb : int;
value gl_max_program_env_parameters_arb : int;
value gl_program_under_native_limits_arb : int;
value gl_transpose_current_matrix_arb : int;
value gl_matrix0_arb : int;
value gl_matrix1_arb : int;
value gl_matrix2_arb : int;
value gl_matrix3_arb : int;
value gl_matrix4_arb : int;
value gl_matrix5_arb : int;
value gl_matrix6_arb : int;
value gl_matrix7_arb : int;
value gl_matrix8_arb : int;
value gl_matrix9_arb : int;
value gl_matrix10_arb : int;
value gl_matrix11_arb : int;
value gl_matrix12_arb : int;
value gl_matrix13_arb : int;
value gl_matrix14_arb : int;
value gl_matrix15_arb : int;
value gl_matrix16_arb : int;
value gl_matrix17_arb : int;
value gl_matrix18_arb : int;
value gl_matrix19_arb : int;
value gl_matrix20_arb : int;
value gl_matrix21_arb : int;
value gl_matrix22_arb : int;
value gl_matrix23_arb : int;
value gl_matrix24_arb : int;
value gl_matrix25_arb : int;
value gl_matrix26_arb : int;
value gl_matrix27_arb : int;
value gl_matrix28_arb : int;
value gl_matrix29_arb : int;
value gl_matrix30_arb : int;
value gl_matrix31_arb : int;
value gl_vertex_shader_arb : int;
value gl_max_vertex_uniform_components_arb : int;
value gl_max_varying_floats_arb : int;
value gl_max_vertex_texture_image_units_arb : int;
value gl_max_combined_texture_image_units_arb : int;
value gl_object_active_attributes_arb : int;
value gl_object_active_attribute_max_length_arb : int;
value gl_422_ext : int;
value gl_422_rev_ext : int;
value gl_422_average_ext : int;
value gl_422_rev_average_ext : int;
value gl_abgr_ext : int;
value gl_bgr_ext : int;
value gl_bgra_ext : int;
value gl_constant_color_ext : int;
value gl_one_minus_constant_color_ext : int;
value gl_constant_alpha_ext : int;
value gl_one_minus_constant_alpha_ext : int;
value gl_blend_color_ext : int;
value gl_blend_equation_rgb_ext : int;
value gl_blend_equation_alpha_ext : int;
value gl_blend_dst_rgb_ext : int;
value gl_blend_src_rgb_ext : int;
value gl_blend_dst_alpha_ext : int;
value gl_blend_src_alpha_ext : int;
value gl_func_add_ext : int;
value gl_min_ext : int;
value gl_max_ext : int;
value gl_blend_equation_ext : int;
value gl_func_subtract_ext : int;
value gl_func_reverse_subtract_ext : int;
value gl_clip_volume_clipping_hint_ext : int;
value gl_cmyk_ext : int;
value gl_cmyka_ext : int;
value gl_pack_cmyk_hint_ext : int;
value gl_unpack_cmyk_hint_ext : int;
value gl_occlusion_test_result_hp : int;
value gl_occlusion_test_hp : int;
value gl_red_min_clamp_ingr : int;
value gl_green_min_clamp_ingr : int;
value gl_blue_min_clamp_ingr : int;
value gl_alpha_min_clamp_ingr : int;
value gl_red_max_clamp_ingr : int;
value gl_green_max_clamp_ingr : int;
value gl_blue_max_clamp_ingr : int;
value gl_alpha_max_clamp_ingr : int;
value gl_interlace_read_ingr : int;
value gl_palette4_rgb8_oes : int;
value gl_palette4_rgba8_oes : int;
value gl_palette4_r5_g6_b5_oes : int;
value gl_palette4_rgba4_oes : int;
value gl_palette4_rgb5_a1_oes : int;
value gl_palette8_rgb8_oes : int;
value gl_palette8_rgba8_oes : int;
value gl_palette8_r5_g6_b5_oes : int;
value gl_palette8_rgba4_oes : int;
value gl_palette8_rgb5_a1_oes : int;
value gl_implementation_color_read_type_oes : int;
value gl_implementation_color_read_format_oes : int;
value gl_interlace_oml : int;
value gl_interlace_read_oml : int;
value gl_pack_resample_oml : int;
value gl_unpack_resample_oml : int;
value gl_resample_replicate_oml : int;
value gl_resample_zero_fill_oml : int;
value gl_resample_average_oml : int;
value gl_resample_decimate_oml : int;
value gl_format_subsample_24_24_oml : int;
value gl_format_subsample_244_244_oml : int;
value gl_prefer_doublebuffer_hint_pgi : int;
value gl_conserve_memory_hint_pgi : int;
value gl_reclaim_memory_hint_pgi : int;
value gl_native_graphics_handle_pgi : int;
value gl_native_graphics_begin_hint_pgi : int;
value gl_native_graphics_end_hint_pgi : int;
value gl_always_fast_hint_pgi : int;
value gl_always_soft_hint_pgi : int;
value gl_allow_draw_obj_hint_pgi : int;
value gl_allow_draw_win_hint_pgi : int;
value gl_allow_draw_frg_hint_pgi : int;
value gl_allow_draw_mem_hint_pgi : int;
value gl_strict_depthfunc_hint_pgi : int;
value gl_strict_lighting_hint_pgi : int;
value gl_strict_scissor_hint_pgi : int;
value gl_full_stipple_hint_pgi : int;
value gl_clip_near_hint_pgi : int;
value gl_clip_far_hint_pgi : int;
value gl_wide_line_hint_pgi : int;
value gl_back_normals_hint_pgi : int;
value gl_vertex23_bit_pgi : int;
value gl_vertex4_bit_pgi : int;
value gl_color3_bit_pgi : int;
value gl_color4_bit_pgi : int;
value gl_edgeflag_bit_pgi : int;
value gl_index_bit_pgi : int;
value gl_mat_ambient_bit_pgi : int;
value gl_vertex_data_hint_pgi : int;
value gl_vertex_consistent_hint_pgi : int;
value gl_material_side_hint_pgi : int;
value gl_max_vertex_hint_pgi : int;
value gl_mat_ambient_and_diffuse_bit_pgi : int;
value gl_mat_diffuse_bit_pgi : int;
value gl_mat_emission_bit_pgi : int;
value gl_mat_color_indexes_bit_pgi : int;
value gl_mat_shininess_bit_pgi : int;
value gl_mat_specular_bit_pgi : int;
value gl_normal_bit_pgi : int;
value gl_texcoord1_bit_pgi : int;
value gl_texcoord2_bit_pgi : int;
value gl_texcoord3_bit_pgi : int;
value gl_screen_coordinates_rend : int;
value gl_inverted_screen_w_rend : int;
value gl_rgb_s3tc : int;
value gl_rgb4_s3tc : int;
value gl_rgba_s3tc : int;
value gl_rgba4_s3tc : int;
value gl_rgba_dxt5_s3tc : int;
value gl_rgba4_dxt5_s3tc : int;
value gl_color_matrix_sgi : int;
value gl_color_matrix_stack_depth_sgi : int;
value gl_max_color_matrix_stack_depth_sgi : int;
value gl_post_color_matrix_red_scale_sgi : int;
value gl_post_color_matrix_green_scale_sgi : int;
value gl_post_color_matrix_blue_scale_sgi : int;
value gl_post_color_matrix_alpha_scale_sgi : int;
value gl_post_color_matrix_red_bias_sgi : int;
value gl_post_color_matrix_green_bias_sgi : int;
value gl_post_color_matrix_blue_bias_sgi : int;
value gl_post_color_matrix_alpha_bias_sgi : int;
value gl_extended_range_sgis : int;
value gl_min_red_sgis : int;
value gl_max_red_sgis : int;
value gl_min_green_sgis : int;
value gl_max_green_sgis : int;
value gl_min_blue_sgis : int;
value gl_max_blue_sgis : int;
value gl_min_alpha_sgis : int;
value gl_max_alpha_sgis : int;
value gl_accum : int;
value gl_load : int;
value gl_return : int;
value gl_mult : int;
value gl_add : int;
value gl_never : int;
value gl_less : int;
value gl_equal : int;
value gl_lequal : int;
value gl_greater : int;
value gl_notequal : int;
value gl_gequal : int;
value gl_always : int;
value gl_current_bit : int;
value gl_point_bit : int;
value gl_line_bit : int;
value gl_polygon_bit : int;
value gl_polygon_stipple_bit : int;
value gl_pixel_mode_bit : int;
value gl_lighting_bit : int;
value gl_fog_bit : int;
value gl_depth_buffer_bit : int;
value gl_accum_buffer_bit : int;
value gl_stencil_buffer_bit : int;
value gl_viewport_bit : int;
value gl_transform_bit : int;
value gl_enable_bit : int;
value gl_color_buffer_bit : int;
value gl_hint_bit : int;
value gl_eval_bit : int;
value gl_list_bit : int;
value gl_texture_bit : int;
value gl_scissor_bit : int;
value gl_all_attrib_bits : int;
value gl_points : int;
value gl_lines : int;
value gl_line_loop : int;
value gl_line_strip : int;
value gl_triangles : int;
value gl_triangle_strip : int;
value gl_triangle_fan : int;
value gl_quads : int;
value gl_quad_strip : int;
value gl_polygon : int;
value gl_zero : int;
value gl_one : int;
value gl_src_color : int;
value gl_one_minus_src_color : int;
value gl_src_alpha : int;
value gl_one_minus_src_alpha : int;
value gl_dst_alpha : int;
value gl_one_minus_dst_alpha : int;
value gl_dst_color : int;
value gl_one_minus_dst_color : int;
value gl_src_alpha_saturate : int;
value gl_true : int;
value gl_false : int;
value gl_clip_plane0 : int;
value gl_clip_plane1 : int;
value gl_clip_plane2 : int;
value gl_clip_plane3 : int;
value gl_clip_plane4 : int;
value gl_clip_plane5 : int;
value gl_byte : int;
value gl_unsigned_byte : int;
value gl_short : int;
value gl_unsigned_short : int;
value gl_int : int;
value gl_unsigned_int : int;
value gl_float : int;
value gl_2_bytes : int;
value gl_3_bytes : int;
value gl_4_bytes : int;
value gl_double : int;
value gl_none : int;
value gl_front_left : int;
value gl_front_right : int;
value gl_back_left : int;
value gl_back_right : int;
value gl_front : int;
value gl_back : int;
value gl_left : int;
value gl_right : int;
value gl_front_and_back : int;
value gl_aux0 : int;
value gl_aux1 : int;
value gl_aux2 : int;
value gl_aux3 : int;
value gl_no_error : int;
value gl_invalid_enum : int;
value gl_invalid_value : int;
value gl_invalid_operation : int;
value gl_stack_overflow : int;
value gl_stack_underflow : int;
value gl_out_of_memory : int;
value gl_2d : int;
value gl_3d : int;
value gl_3d_color : int;
value gl_3d_color_texture : int;
value gl_4d_color_texture : int;
value gl_pass_through_token : int;
value gl_point_token : int;
value gl_line_token : int;
value gl_polygon_token : int;
value gl_bitmap_token : int;
value gl_draw_pixel_token : int;
value gl_copy_pixel_token : int;
value gl_line_reset_token : int;
value gl_exp : int;
value gl_exp2 : int;
value gl_cw : int;
value gl_ccw : int;
value gl_coeff : int;
value gl_order : int;
value gl_domain : int;
value gl_current_color : int;
value gl_current_index : int;
value gl_current_normal : int;
value gl_current_texture_coords : int;
value gl_current_raster_color : int;
value gl_current_raster_index : int;
value gl_current_raster_texture_coords : int;
value gl_current_raster_position : int;
value gl_current_raster_position_valid : int;
value gl_current_raster_distance : int;
value gl_point_smooth : int;
value gl_point_size : int;
value gl_point_size_range : int;
value gl_point_size_granularity : int;
value gl_line_smooth : int;
value gl_line_width : int;
value gl_line_width_range : int;
value gl_line_width_granularity : int;
value gl_line_stipple : int;
value gl_line_stipple_pattern : int;
value gl_line_stipple_repeat : int;
value gl_list_mode : int;
value gl_max_list_nesting : int;
value gl_list_base : int;
value gl_list_index : int;
value gl_polygon_mode : int;
value gl_polygon_smooth : int;
value gl_polygon_stipple : int;
value gl_edge_flag : int;
value gl_cull_face : int;
value gl_cull_face_mode : int;
value gl_front_face : int;
value gl_lighting : int;
value gl_light_model_local_viewer : int;
value gl_light_model_two_side : int;
value gl_light_model_ambient : int;
value gl_shade_model : int;
value gl_color_material_face : int;
value gl_color_material_parameter : int;
value gl_color_material : int;
value gl_fog : int;
value gl_fog_index : int;
value gl_fog_density : int;
value gl_fog_start : int;
value gl_fog_end : int;
value gl_fog_mode : int;
value gl_fog_color : int;
value gl_depth_range : int;
value gl_depth_test : int;
value gl_depth_writemask : int;
value gl_depth_clear_value : int;
value gl_depth_func : int;
value gl_accum_clear_value : int;
value gl_stencil_test : int;
value gl_stencil_clear_value : int;
value gl_stencil_func : int;
value gl_stencil_value_mask : int;
value gl_stencil_fail : int;
value gl_stencil_pass_depth_fail : int;
value gl_stencil_pass_depth_pass : int;
value gl_stencil_ref : int;
value gl_stencil_writemask : int;
value gl_matrix_mode : int;
value gl_normalize : int;
value gl_viewport : int;
value gl_modelview_stack_depth : int;
value gl_projection_stack_depth : int;
value gl_texture_stack_depth : int;
value gl_modelview_matrix : int;
value gl_projection_matrix : int;
value gl_texture_matrix : int;
value gl_attrib_stack_depth : int;
value gl_client_attrib_stack_depth : int;
value gl_alpha_test : int;
value gl_alpha_test_func : int;
value gl_alpha_test_ref : int;
value gl_dither : int;
value gl_blend_dst : int;
value gl_blend_src : int;
value gl_blend : int;
value gl_logic_op_mode : int;
value gl_index_logic_op : int;
value gl_color_logic_op : int;
value gl_aux_buffers : int;
value gl_draw_buffer : int;
value gl_read_buffer : int;
value gl_scissor_box : int;
value gl_scissor_test : int;
value gl_index_clear_value : int;
value gl_index_writemask : int;
value gl_color_clear_value : int;
value gl_color_writemask : int;
value gl_index_mode : int;
value gl_rgba_mode : int;
value gl_doublebuffer : int;
value gl_stereo : int;
value gl_render_mode : int;
value gl_perspective_correction_hint : int;
value gl_point_smooth_hint : int;
value gl_line_smooth_hint : int;
value gl_polygon_smooth_hint : int;
value gl_fog_hint : int;
value gl_texture_gen_s : int;
value gl_texture_gen_t : int;
value gl_texture_gen_r : int;
value gl_texture_gen_q : int;
value gl_pixel_map_i_to_i : int;
value gl_pixel_map_s_to_s : int;
value gl_pixel_map_i_to_r : int;
value gl_pixel_map_i_to_g : int;
value gl_pixel_map_i_to_b : int;
value gl_pixel_map_i_to_a : int;
value gl_pixel_map_r_to_r : int;
value gl_pixel_map_g_to_g : int;
value gl_pixel_map_b_to_b : int;
value gl_pixel_map_a_to_a : int;
value gl_pixel_map_i_to_i_size : int;
value gl_pixel_map_s_to_s_size : int;
value gl_pixel_map_i_to_r_size : int;
value gl_pixel_map_i_to_g_size : int;
value gl_pixel_map_i_to_b_size : int;
value gl_pixel_map_i_to_a_size : int;
value gl_pixel_map_r_to_r_size : int;
value gl_pixel_map_g_to_g_size : int;
value gl_pixel_map_b_to_b_size : int;
value gl_pixel_map_a_to_a_size : int;
value gl_unpack_swap_bytes : int;
value gl_unpack_lsb_first : int;
value gl_unpack_row_length : int;
value gl_unpack_skip_rows : int;
value gl_unpack_skip_pixels : int;
value gl_unpack_alignment : int;
value gl_pack_swap_bytes : int;
value gl_pack_lsb_first : int;
value gl_pack_row_length : int;
value gl_pack_skip_rows : int;
value gl_pack_skip_pixels : int;
value gl_pack_alignment : int;
value gl_map_color : int;
value gl_map_stencil : int;
value gl_index_shift : int;
value gl_index_offset : int;
value gl_red_scale : int;
value gl_red_bias : int;
value gl_zoom_x : int;
value gl_zoom_y : int;
value gl_green_scale : int;
value gl_green_bias : int;
value gl_blue_scale : int;
value gl_blue_bias : int;
value gl_alpha_scale : int;
value gl_alpha_bias : int;
value gl_depth_scale : int;
value gl_depth_bias : int;
value gl_max_eval_order : int;
value gl_max_lights : int;
value gl_max_clip_planes : int;
value gl_max_texture_size : int;
value gl_max_pixel_map_table : int;
value gl_max_attrib_stack_depth : int;
value gl_max_modelview_stack_depth : int;
value gl_max_name_stack_depth : int;
value gl_max_projection_stack_depth : int;
value gl_max_texture_stack_depth : int;
value gl_max_viewport_dims : int;
value gl_max_client_attrib_stack_depth : int;
value gl_subpixel_bits : int;
value gl_index_bits : int;
value gl_red_bits : int;
value gl_green_bits : int;
value gl_blue_bits : int;
value gl_alpha_bits : int;
value gl_depth_bits : int;
value gl_stencil_bits : int;
value gl_accum_red_bits : int;
value gl_accum_green_bits : int;
value gl_accum_blue_bits : int;
value gl_accum_alpha_bits : int;
value gl_name_stack_depth : int;
value gl_auto_normal : int;
value gl_map1_color_4 : int;
value gl_map1_index : int;
value gl_map1_normal : int;
value gl_map1_texture_coord_1 : int;
value gl_map1_texture_coord_2 : int;
value gl_map1_texture_coord_3 : int;
value gl_map1_texture_coord_4 : int;
value gl_map1_vertex_3 : int;
value gl_map1_vertex_4 : int;
value gl_map2_color_4 : int;
value gl_map2_index : int;
value gl_map2_normal : int;
value gl_map2_texture_coord_1 : int;
value gl_map2_texture_coord_2 : int;
value gl_map2_texture_coord_3 : int;
value gl_map2_texture_coord_4 : int;
value gl_map2_vertex_3 : int;
value gl_map2_vertex_4 : int;
value gl_map1_grid_domain : int;
value gl_map1_grid_segments : int;
value gl_map2_grid_domain : int;
value gl_map2_grid_segments : int;
value gl_texture_1d : int;
value gl_texture_2d : int;
value gl_feedback_buffer_pointer : int;
value gl_feedback_buffer_size : int;
value gl_feedback_buffer_type : int;
value gl_selection_buffer_pointer : int;
value gl_selection_buffer_size : int;
value gl_texture_width : int;
value gl_texture_height : int;
value gl_texture_internal_format : int;
value gl_texture_border_color : int;
value gl_texture_border : int;
value gl_dont_care : int;
value gl_fastest : int;
value gl_nicest : int;
value gl_light0 : int;
value gl_light1 : int;
value gl_light2 : int;
value gl_light3 : int;
value gl_light4 : int;
value gl_light5 : int;
value gl_light6 : int;
value gl_light7 : int;
value gl_ambient : int;
value gl_diffuse : int;
value gl_specular : int;
value gl_position : int;
value gl_spot_direction : int;
value gl_spot_exponent : int;
value gl_spot_cutoff : int;
value gl_constant_attenuation : int;
value gl_linear_attenuation : int;
value gl_quadratic_attenuation : int;
value gl_compile : int;
value gl_compile_and_execute : int;
value gl_clear : int;
value gl_and : int;
value gl_and_reverse : int;
value gl_copy : int;
value gl_and_inverted : int;
value gl_noop : int;
value gl_xor : int;
value gl_or : int;
value gl_nor : int;
value gl_equiv : int;
value gl_invert : int;
value gl_or_reverse : int;
value gl_copy_inverted : int;
value gl_or_inverted : int;
value gl_nand : int;
value gl_set : int;
value gl_emission : int;
value gl_shininess : int;
value gl_ambient_and_diffuse : int;
value gl_color_indexes : int;
value gl_modelview : int;
value gl_projection : int;
value gl_texture : int;
value gl_color : int;
value gl_depth : int;
value gl_stencil : int;
value gl_color_index : int;
value gl_stencil_index : int;
value gl_depth_component : int;
value gl_red : int;
value gl_green : int;
value gl_blue : int;
value gl_alpha : int;
value gl_rgb : int;
value gl_rgba : int;
value gl_luminance : int;
value gl_luminance_alpha : int;
value gl_bitmap : int;
value gl_point : int;
value gl_line : int;
value gl_fill : int;
value gl_render : int;
value gl_feedback : int;
value gl_select : int;
value gl_flat : int;
value gl_smooth : int;
value gl_keep : int;
value gl_replace : int;
value gl_incr : int;
value gl_decr : int;
value gl_vendor : int;
value gl_renderer : int;
value gl_version : int;
value gl_extensions : int;
value gl_s : int;
value gl_t : int;
value gl_r : int;
value gl_q : int;
value gl_modulate : int;
value gl_decal : int;
value gl_texture_env_mode : int;
value gl_texture_env_color : int;
value gl_texture_env : int;
value gl_eye_linear : int;
value gl_object_linear : int;
value gl_sphere_map : int;
value gl_texture_gen_mode : int;
value gl_object_plane : int;
value gl_eye_plane : int;
value gl_nearest : int;
value gl_linear : int;
value gl_nearest_mipmap_nearest : int;
value gl_linear_mipmap_nearest : int;
value gl_nearest_mipmap_linear : int;
value gl_linear_mipmap_linear : int;
value gl_texture_mag_filter : int;
value gl_texture_min_filter : int;
value gl_texture_wrap_s : int;
value gl_texture_wrap_t : int;
value gl_clamp : int;
value gl_repeat : int;
value gl_client_pixel_store_bit : int;
value gl_client_vertex_array_bit : int;
value gl_client_all_attrib_bits : int;
value gl_polygon_offset_factor : int;
value gl_polygon_offset_units : int;
value gl_polygon_offset_point : int;
value gl_polygon_offset_line : int;
value gl_polygon_offset_fill : int;
value gl_alpha4 : int;
value gl_alpha8 : int;
value gl_alpha12 : int;
value gl_alpha16 : int;
value gl_luminance4 : int;
value gl_luminance8 : int;
value gl_luminance12 : int;
value gl_luminance16 : int;
value gl_luminance4_alpha4 : int;
value gl_luminance6_alpha2 : int;
value gl_luminance8_alpha8 : int;
value gl_luminance12_alpha4 : int;
value gl_luminance12_alpha12 : int;
value gl_luminance16_alpha16 : int;
value gl_intensity : int;
value gl_intensity4 : int;
value gl_intensity8 : int;
value gl_intensity12 : int;
value gl_intensity16 : int;
value gl_r3_g3_b2 : int;
value gl_rgb4 : int;
value gl_rgb5 : int;
value gl_rgb8 : int;
value gl_rgb10 : int;
value gl_rgb12 : int;
value gl_rgb16 : int;
value gl_rgba2 : int;
value gl_rgba4 : int;
value gl_rgb5_a1 : int;
value gl_rgba8 : int;
value gl_rgb10_a2 : int;
value gl_rgba12 : int;
value gl_rgba16 : int;
value gl_texture_red_size : int;
value gl_texture_green_size : int;
value gl_texture_blue_size : int;
value gl_texture_alpha_size : int;
value gl_texture_luminance_size : int;
value gl_texture_intensity_size : int;
value gl_proxy_texture_1d : int;
value gl_proxy_texture_2d : int;
value gl_texture_priority : int;
value gl_texture_resident : int;
value gl_texture_binding_1d : int;
value gl_texture_binding_2d : int;
value gl_vertex_array : int;
value gl_normal_array : int;
value gl_color_array : int;
value gl_index_array : int;
value gl_texture_coord_array : int;
value gl_edge_flag_array : int;
value gl_vertex_array_size : int;
value gl_vertex_array_type : int;
value gl_vertex_array_stride : int;
value gl_normal_array_type : int;
value gl_normal_array_stride : int;
value gl_color_array_size : int;
value gl_color_array_type : int;
value gl_color_array_stride : int;
value gl_index_array_type : int;
value gl_index_array_stride : int;
value gl_texture_coord_array_size : int;
value gl_texture_coord_array_type : int;
value gl_texture_coord_array_stride : int;
value gl_edge_flag_array_stride : int;
value gl_vertex_array_pointer : int;
value gl_normal_array_pointer : int;
value gl_color_array_pointer : int;
value gl_index_array_pointer : int;
value gl_texture_coord_array_pointer : int;
value gl_edge_flag_array_pointer : int;
value gl_v2f : int;
value gl_v3f : int;
value gl_c4ub_v2f : int;
value gl_c4ub_v3f : int;
value gl_c3f_v3f : int;
value gl_n3f_v3f : int;
value gl_c4f_n3f_v3f : int;
value gl_t2f_v3f : int;
value gl_t4f_v4f : int;
value gl_t2f_c4ub_v3f : int;
value gl_t2f_c3f_v3f : int;
value gl_t2f_n3f_v3f : int;
value gl_t2f_c4f_n3f_v3f : int;
value gl_t4f_c4f_n3f_v4f : int;
value gl_logic_op : int;
value gl_texture_components : int;
value gl_color_index1_ext : int;
value gl_color_index2_ext : int;
value gl_color_index4_ext : int;
value gl_color_index8_ext : int;
value gl_color_index12_ext : int;
value gl_color_index16_ext : int;
value gl_unsigned_byte_3_3_2 : int;
value gl_unsigned_short_4_4_4_4 : int;
value gl_unsigned_short_5_5_5_1 : int;
value gl_unsigned_int_8_8_8_8 : int;
value gl_unsigned_int_10_10_10_2 : int;
value gl_rescale_normal : int;
value gl_unsigned_byte_2_3_3_rev : int;
value gl_unsigned_short_5_6_5 : int;
value gl_unsigned_short_5_6_5_rev : int;
value gl_unsigned_short_4_4_4_4_rev : int;
value gl_unsigned_short_1_5_5_5_rev : int;
value gl_unsigned_int_8_8_8_8_rev : int;
value gl_unsigned_int_2_10_10_10_rev : int;
value gl_bgr : int;
value gl_bgra : int;
value gl_max_elements_vertices : int;
value gl_max_elements_indices : int;
value gl_clamp_to_edge : int;
value gl_texture_min_lod : int;
value gl_texture_max_lod : int;
value gl_texture_base_level : int;
value gl_texture_max_level : int;
value gl_light_model_color_control : int;
value gl_single_color : int;
value gl_separate_specular_color : int;
value gl_smooth_point_size_range : int;
value gl_smooth_point_size_granularity : int;
value gl_smooth_line_width_range : int;
value gl_smooth_line_width_granularity : int;
value gl_aliased_point_size_range : int;
value gl_aliased_line_width_range : int;
value gl_pack_skip_images : int;
value gl_pack_image_height : int;
value gl_unpack_skip_images : int;
value gl_unpack_image_height : int;
value gl_texture_3d : int;
value gl_proxy_texture_3d : int;
value gl_texture_depth : int;
value gl_texture_wrap_r : int;
value gl_max_3d_texture_size : int;
value gl_texture_binding_3d : int;
value gl_texture0 : int;
value gl_texture1 : int;
value gl_texture2 : int;
value gl_texture3 : int;
value gl_texture4 : int;
value gl_texture5 : int;
value gl_texture6 : int;
value gl_texture7 : int;
value gl_texture8 : int;
value gl_texture9 : int;
value gl_texture10 : int;
value gl_texture11 : int;
value gl_texture12 : int;
value gl_texture13 : int;
value gl_texture14 : int;
value gl_texture15 : int;
value gl_texture16 : int;
value gl_texture17 : int;
value gl_texture18 : int;
value gl_texture19 : int;
value gl_texture20 : int;
value gl_texture21 : int;
value gl_texture22 : int;
value gl_texture23 : int;
value gl_texture24 : int;
value gl_texture25 : int;
value gl_texture26 : int;
value gl_texture27 : int;
value gl_texture28 : int;
value gl_texture29 : int;
value gl_texture30 : int;
value gl_texture31 : int;
value gl_active_texture : int;
value gl_client_active_texture : int;
value gl_max_texture_units : int;
value gl_normal_map : int;
value gl_reflection_map : int;
value gl_texture_cube_map : int;
value gl_texture_binding_cube_map : int;
value gl_texture_cube_map_positive_x : int;
value gl_texture_cube_map_negative_x : int;
value gl_texture_cube_map_positive_y : int;
value gl_texture_cube_map_negative_y : int;
value gl_texture_cube_map_positive_z : int;
value gl_texture_cube_map_negative_z : int;
value gl_proxy_texture_cube_map : int;
value gl_max_cube_map_texture_size : int;
value gl_compressed_alpha : int;
value gl_compressed_luminance : int;
value gl_compressed_luminance_alpha : int;
value gl_compressed_intensity : int;
value gl_compressed_rgb : int;
value gl_compressed_rgba : int;
value gl_texture_compression_hint : int;
value gl_texture_compressed_image_size : int;
value gl_texture_compressed : int;
value gl_num_compressed_texture_formats : int;
value gl_compressed_texture_formats : int;
value gl_multisample : int;
value gl_sample_alpha_to_coverage : int;
value gl_sample_alpha_to_one : int;
value gl_sample_coverage : int;
value gl_sample_buffers : int;
value gl_samples : int;
value gl_sample_coverage_value : int;
value gl_sample_coverage_invert : int;
value gl_multisample_bit : int;
value gl_transpose_modelview_matrix : int;
value gl_transpose_projection_matrix : int;
value gl_transpose_texture_matrix : int;
value gl_transpose_color_matrix : int;
value gl_combine : int;
value gl_combine_rgb : int;
value gl_combine_alpha : int;
value gl_source0_rgb : int;
value gl_source1_rgb : int;
value gl_source2_rgb : int;
value gl_source0_alpha : int;
value gl_source1_alpha : int;
value gl_source2_alpha : int;
value gl_operand0_rgb : int;
value gl_operand1_rgb : int;
value gl_operand2_rgb : int;
value gl_operand0_alpha : int;
value gl_operand1_alpha : int;
value gl_operand2_alpha : int;
value gl_rgb_scale : int;
value gl_add_signed : int;
value gl_interpolate : int;
value gl_subtract : int;
value gl_constant : int;
value gl_primary_color : int;
value gl_previous : int;
value gl_dot3_rgb : int;
value gl_dot3_rgba : int;
value gl_clamp_to_border : int;
value gl_generate_mipmap : int;
value gl_generate_mipmap_hint : int;
value gl_depth_component16 : int;
value gl_depth_component24 : int;
value gl_depth_component32 : int;
value gl_texture_depth_size : int;
value gl_depth_texture_mode : int;
value gl_texture_compare_mode : int;
value gl_texture_compare_func : int;
value gl_compare_r_to_texture : int;
value gl_fog_coordinate_source : int;
value gl_fog_coordinate : int;
value gl_fragment_depth : int;
value gl_current_fog_coordinate : int;
value gl_fog_coordinate_array_type : int;
value gl_fog_coordinate_array_stride : int;
value gl_fog_coordinate_array_pointer : int;
value gl_fog_coordinate_array : int;
value gl_point_size_min : int;
value gl_point_size_max : int;
value gl_point_fade_threshold_size : int;
value gl_point_distance_attenuation : int;
value gl_color_sum : int;
value gl_current_secondary_color : int;
value gl_secondary_color_array_size : int;
value gl_secondary_color_array_type : int;
value gl_secondary_color_array_stride : int;
value gl_secondary_color_array_pointer : int;
value gl_secondary_color_array : int;
value gl_blend_dst_rgb : int;
value gl_blend_src_rgb : int;
value gl_blend_dst_alpha : int;
value gl_blend_src_alpha : int;
value gl_incr_wrap : int;
value gl_decr_wrap : int;
value gl_texture_filter_control : int;
value gl_texture_lod_bias : int;
value gl_max_texture_lod_bias : int;
value gl_mirrored_repeat : int;
value gl_buffer_size : int;
value gl_buffer_usage : int;
value gl_query_counter_bits : int;
value gl_current_query : int;
value gl_query_result : int;
value gl_query_result_available : int;
value gl_array_buffer : int;
value gl_element_array_buffer : int;
value gl_array_buffer_binding : int;
value gl_element_array_buffer_binding : int;
value gl_vertex_array_buffer_binding : int;
value gl_normal_array_buffer_binding : int;
value gl_color_array_buffer_binding : int;
value gl_index_array_buffer_binding : int;
value gl_texture_coord_array_buffer_binding : int;
value gl_edge_flag_array_buffer_binding : int;
value gl_secondary_color_array_buffer_binding : int;
value gl_fog_coordinate_array_buffer_binding : int;
value gl_weight_array_buffer_binding : int;
value gl_vertex_attrib_array_buffer_binding : int;
value gl_read_only : int;
value gl_write_only : int;
value gl_read_write : int;
value gl_buffer_access : int;
value gl_buffer_mapped : int;
value gl_buffer_map_pointer : int;
value gl_stream_draw : int;
value gl_stream_read : int;
value gl_stream_copy : int;
value gl_static_draw : int;
value gl_static_read : int;
value gl_static_copy : int;
value gl_dynamic_draw : int;
value gl_dynamic_read : int;
value gl_dynamic_copy : int;
value gl_samples_passed : int;
value gl_fog_coord_src : int;
value gl_fog_coord : int;
value gl_current_fog_coord : int;
value gl_fog_coord_array_type : int;
value gl_fog_coord_array_stride : int;
value gl_fog_coord_array_pointer : int;
value gl_fog_coord_array : int;
value gl_fog_coord_array_buffer_binding : int;
value gl_src0_rgb : int;
value gl_src1_rgb : int;
value gl_src2_rgb : int;
value gl_src0_alpha : int;
value gl_src1_alpha : int;
value gl_src2_alpha : int;
value gl_blend_equation_rgb : int;
value gl_vertex_attrib_array_enabled : int;
value gl_vertex_attrib_array_size : int;
value gl_vertex_attrib_array_stride : int;
value gl_vertex_attrib_array_type : int;
value gl_current_vertex_attrib : int;
value gl_vertex_program_point_size : int;
value gl_vertex_program_two_side : int;
value gl_vertex_attrib_array_pointer : int;
value gl_stencil_back_func : int;
value gl_stencil_back_fail : int;
value gl_stencil_back_pass_depth_fail : int;
value gl_stencil_back_pass_depth_pass : int;
value gl_max_draw_buffers : int;
value gl_draw_buffer0 : int;
value gl_draw_buffer1 : int;
value gl_draw_buffer2 : int;
value gl_draw_buffer3 : int;
value gl_draw_buffer4 : int;
value gl_draw_buffer5 : int;
value gl_draw_buffer6 : int;
value gl_draw_buffer7 : int;
value gl_draw_buffer8 : int;
value gl_draw_buffer9 : int;
value gl_draw_buffer10 : int;
value gl_draw_buffer11 : int;
value gl_draw_buffer12 : int;
value gl_draw_buffer13 : int;
value gl_draw_buffer14 : int;
value gl_draw_buffer15 : int;
value gl_blend_equation_alpha : int;
value gl_point_sprite : int;
value gl_coord_replace : int;
value gl_max_vertex_attribs : int;
value gl_vertex_attrib_array_normalized : int;
value gl_max_texture_coords : int;
value gl_max_texture_image_units : int;
value gl_fragment_shader : int;
value gl_vertex_shader : int;
value gl_max_fragment_uniform_components : int;
value gl_max_vertex_uniform_components : int;
value gl_max_varying_floats : int;
value gl_max_vertex_texture_image_units : int;
value gl_max_combined_texture_image_units : int;
value gl_shader_type : int;
value gl_float_vec2 : int;
value gl_float_vec3 : int;
value gl_float_vec4 : int;
value gl_int_vec2 : int;
value gl_int_vec3 : int;
value gl_int_vec4 : int;
value gl_bool : int;
value gl_bool_vec2 : int;
value gl_bool_vec3 : int;
value gl_bool_vec4 : int;
value gl_float_mat2 : int;
value gl_float_mat3 : int;
value gl_float_mat4 : int;
value gl_sampler_1d : int;
value gl_sampler_2d : int;
value gl_sampler_3d : int;
value gl_sampler_cube : int;
value gl_sampler_1d_shadow : int;
value gl_sampler_2d_shadow : int;
value gl_delete_status : int;
value gl_compile_status : int;
value gl_link_status : int;
value gl_validate_status : int;
value gl_info_log_length : int;
value gl_attached_shaders : int;
value gl_active_uniforms : int;
value gl_active_uniform_max_length : int;
value gl_shader_source_length : int;
value gl_active_attributes : int;
value gl_active_attribute_max_length : int;
value gl_fragment_shader_derivative_hint : int;
value gl_shading_language_version : int;
value gl_current_program : int;
value gl_point_sprite_coord_origin : int;
value gl_lower_left : int;
value gl_upper_left : int;
value gl_stencil_back_ref : int;
value gl_stencil_back_value_mask : int;
value gl_stencil_back_writemask : int;
value gl_current_raster_secondary_color : int;
value gl_pixel_pack_buffer : int;
value gl_pixel_unpack_buffer : int;
value gl_pixel_pack_buffer_binding : int;
value gl_pixel_unpack_buffer_binding : int;
value gl_srgb : int;
value gl_srgb8 : int;
value gl_srgb_alpha : int;
value gl_srgb8_alpha8 : int;
value gl_sluminance_alpha : int;
value gl_sluminance8_alpha8 : int;
value gl_sluminance : int;
value gl_sluminance8 : int;
value gl_compressed_srgb : int;
value gl_compressed_srgb_alpha : int;
value gl_compressed_sluminance : int;
value gl_compressed_sluminance_alpha : int;
value gl_framebuffer_ext : int;
value gl_color_attachment0_ext : int;
value gl_framebuffer_complete_ext : int;
value gl_framebuffer_binding_ext : int;
external glAccum : int -> float -> unit = "glstub_glAccum" "glstub_glAccum";
external glActiveTexture : int -> unit = "glstub_glActiveTexture"
  "glstub_glActiveTexture";
external glActiveTextureARB : int -> unit = "glstub_glActiveTextureARB"
  "glstub_glActiveTextureARB";
external glAlphaFunc : int -> float -> unit = "glstub_glAlphaFunc"
  "glstub_glAlphaFunc";
value glAreTexturesResident : int -> array int -> array bool -> bool;
external glArrayElement : int -> unit = "glstub_glArrayElement"
  "glstub_glArrayElement";
external glAttachShader : int -> int -> unit = "glstub_glAttachShader"
  "glstub_glAttachShader";
external glBegin : int -> unit = "glstub_glBegin" "glstub_glBegin";
external glBeginQuery : int -> int -> unit = "glstub_glBeginQuery"
  "glstub_glBeginQuery";
external glBeginQueryARB : int -> int -> unit = "glstub_glBeginQueryARB"
  "glstub_glBeginQueryARB";
external glBindAttribLocation : int -> int -> string -> unit =
  "glstub_glBindAttribLocation" "glstub_glBindAttribLocation";
external glBindBuffer : int -> int -> unit = "glstub_glBindBuffer"
  "glstub_glBindBuffer";
external glBindBufferARB : int -> int -> unit = "glstub_glBindBufferARB"
  "glstub_glBindBufferARB";
external glBindFramebufferEXT : int -> int -> unit =
  "glstub_glBindFramebufferEXT" "glstub_glBindFramebufferEXT";
external glBindProgramARB : int -> int -> unit = "glstub_glBindProgramARB"
  "glstub_glBindProgramARB";
external glBindTexture : int -> int -> unit = "glstub_glBindTexture"
  "glstub_glBindTexture";
value glBitmap :
  int -> int -> float -> float -> float -> float -> array int -> unit;
external glBlendColor : float -> float -> float -> float -> unit =
  "glstub_glBlendColor" "glstub_glBlendColor";
external glBlendColorEXT : float -> float -> float -> float -> unit =
  "glstub_glBlendColorEXT" "glstub_glBlendColorEXT";
external glBlendEquation : int -> unit = "glstub_glBlendEquation"
  "glstub_glBlendEquation";
external glBlendEquationEXT : int -> unit = "glstub_glBlendEquationEXT"
  "glstub_glBlendEquationEXT";
external glBlendEquationSeparate : int -> int -> unit =
  "glstub_glBlendEquationSeparate" "glstub_glBlendEquationSeparate";
external glBlendFunc : int -> int -> unit = "glstub_glBlendFunc"
  "glstub_glBlendFunc";
external glBlendFuncSeparate : int -> int -> int -> int -> unit =
  "glstub_glBlendFuncSeparate" "glstub_glBlendFuncSeparate";
external glBlendFuncSeparateEXT : int -> int -> int -> int -> unit =
  "glstub_glBlendFuncSeparateEXT" "glstub_glBlendFuncSeparateEXT";
external glBufferData : int -> int -> 'a -> int -> unit =
  "glstub_glBufferData" "glstub_glBufferData";
external glBufferDataARB : int -> int -> 'a -> int -> unit =
  "glstub_glBufferDataARB" "glstub_glBufferDataARB";
external glBufferSubData : int -> int -> int -> 'a -> unit =
  "glstub_glBufferSubData" "glstub_glBufferSubData";
external glBufferSubDataARB : int -> int -> int -> 'a -> unit =
  "glstub_glBufferSubDataARB" "glstub_glBufferSubDataARB";
external glCallList : int -> unit = "glstub_glCallList" "glstub_glCallList";
external glCallLists : int -> int -> 'a -> unit = "glstub_glCallLists"
  "glstub_glCallLists";
external glCheckFramebufferStatusEXT : int -> int =
  "glstub_glCheckFramebufferStatusEXT" "glstub_glCheckFramebufferStatusEXT";
external glClear : int -> unit = "glstub_glClear" "glstub_glClear";
external glClearAccum : float -> float -> float -> float -> unit =
  "glstub_glClearAccum" "glstub_glClearAccum";
external glClearColor : float -> float -> float -> float -> unit =
  "glstub_glClearColor" "glstub_glClearColor";
external glClearDepth : float -> unit = "glstub_glClearDepth"
  "glstub_glClearDepth";
external glClearIndex : float -> unit = "glstub_glClearIndex"
  "glstub_glClearIndex";
external glClearStencil : int -> unit = "glstub_glClearStencil"
  "glstub_glClearStencil";
external glClientActiveTexture : int -> unit = "glstub_glClientActiveTexture"
  "glstub_glClientActiveTexture";
external glClientActiveTextureARB : int -> unit =
  "glstub_glClientActiveTextureARB" "glstub_glClientActiveTextureARB";
external glClipPlane : int -> array float -> unit = "glstub_glClipPlane"
  "glstub_glClipPlane";
external glColor3b : int -> int -> int -> unit = "glstub_glColor3b"
  "glstub_glColor3b";
value glColor3bv : array int -> unit;
external glColor3d : float -> float -> float -> unit = "glstub_glColor3d"
  "glstub_glColor3d";
external glColor3dv : array float -> unit = "glstub_glColor3dv"
  "glstub_glColor3dv";
external glColor3f : float -> float -> float -> unit = "glstub_glColor3f"
  "glstub_glColor3f";
value glColor3fv : array float -> unit;
external glColor3i : int -> int -> int -> unit = "glstub_glColor3i"
  "glstub_glColor3i";
value glColor3iv : array int -> unit;
external glColor3s : int -> int -> int -> unit = "glstub_glColor3s"
  "glstub_glColor3s";
value glColor3sv : array int -> unit;
external glColor3ub : int -> int -> int -> unit = "glstub_glColor3ub"
  "glstub_glColor3ub";
value glColor3ubv : array int -> unit;
external glColor3ui : int -> int -> int -> unit = "glstub_glColor3ui"
  "glstub_glColor3ui";
value glColor3uiv : array int -> unit;
external glColor3us : int -> int -> int -> unit = "glstub_glColor3us"
  "glstub_glColor3us";
value glColor3usv : array int -> unit;
external glColor4b : int -> int -> int -> int -> unit = "glstub_glColor4b"
  "glstub_glColor4b";
value glColor4bv : array int -> unit;
external glColor4d : float -> float -> float -> float -> unit =
  "glstub_glColor4d" "glstub_glColor4d";
external glColor4dv : array float -> unit = "glstub_glColor4dv"
  "glstub_glColor4dv";
external glColor4f : float -> float -> float -> float -> unit =
  "glstub_glColor4f" "glstub_glColor4f";
value glColor4fv : array float -> unit;
external glColor4i : int -> int -> int -> int -> unit = "glstub_glColor4i"
  "glstub_glColor4i";
value glColor4iv : array int -> unit;
external glColor4s : int -> int -> int -> int -> unit = "glstub_glColor4s"
  "glstub_glColor4s";
value glColor4sv : array int -> unit;
external glColor4ub : int -> int -> int -> int -> unit = "glstub_glColor4ub"
  "glstub_glColor4ub";
value glColor4ubv : array int -> unit;
external glColor4ui : int -> int -> int -> int -> unit = "glstub_glColor4ui"
  "glstub_glColor4ui";
value glColor4uiv : array int -> unit;
external glColor4us : int -> int -> int -> int -> unit = "glstub_glColor4us"
  "glstub_glColor4us";
value glColor4usv : array int -> unit;
external glColorMask : bool -> bool -> bool -> bool -> unit =
  "glstub_glColorMask" "glstub_glColorMask";
external glColorMaterial : int -> int -> unit = "glstub_glColorMaterial"
  "glstub_glColorMaterial";
external glColorPointer : int -> int -> int -> 'a -> unit =
  "glstub_glColorPointer" "glstub_glColorPointer";
external glColorSubTable : int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glColorSubTable_byte" "glstub_glColorSubTable";
external glColorTable : int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glColorTable_byte" "glstub_glColorTable";
value glColorTableParameterfv : int -> int -> array float -> unit;
value glColorTableParameteriv : int -> int -> array int -> unit;
external glCompileShader : int -> unit = "glstub_glCompileShader"
  "glstub_glCompileShader";
external glCompressedTexImage1D :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage1D_byte" "glstub_glCompressedTexImage1D";
external glCompressedTexImage1DARB :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage1DARB_byte" "glstub_glCompressedTexImage1DARB";
external glCompressedTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage2D_byte" "glstub_glCompressedTexImage2D";
external glCompressedTexImage2DARB :
  int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage2DARB_byte" "glstub_glCompressedTexImage2DARB";
external glCompressedTexImage3D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage3D_byte" "glstub_glCompressedTexImage3D";
external glCompressedTexImage3DARB :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage3DARB_byte" "glstub_glCompressedTexImage3DARB";
external glCompressedTexSubImage1D :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage1D_byte" "glstub_glCompressedTexSubImage1D";
external glCompressedTexSubImage1DARB :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage1DARB_byte"
  "glstub_glCompressedTexSubImage1DARB";
external glCompressedTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage2D_byte" "glstub_glCompressedTexSubImage2D";
external glCompressedTexSubImage2DARB :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage2DARB_byte"
  "glstub_glCompressedTexSubImage2DARB";
external glCompressedTexSubImage3D :
  int ->
    int -> int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage3D_byte" "glstub_glCompressedTexSubImage3D";
external glCompressedTexSubImage3DARB :
  int ->
    int -> int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage3DARB_byte"
  "glstub_glCompressedTexSubImage3DARB";
external glConvolutionFilter1D :
  int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glConvolutionFilter1D_byte" "glstub_glConvolutionFilter1D";
external glConvolutionFilter2D :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glConvolutionFilter2D_byte" "glstub_glConvolutionFilter2D";
external glConvolutionParameterf : int -> int -> float -> unit =
  "glstub_glConvolutionParameterf" "glstub_glConvolutionParameterf";
value glConvolutionParameterfv : int -> int -> array float -> unit;
external glConvolutionParameteri : int -> int -> int -> unit =
  "glstub_glConvolutionParameteri" "glstub_glConvolutionParameteri";
value glConvolutionParameteriv : int -> int -> array int -> unit;
external glCopyColorSubTable : int -> int -> int -> int -> int -> unit =
  "glstub_glCopyColorSubTable" "glstub_glCopyColorSubTable";
external glCopyColorTable : int -> int -> int -> int -> int -> unit =
  "glstub_glCopyColorTable" "glstub_glCopyColorTable";
external glCopyConvolutionFilter1D :
  int -> int -> int -> int -> int -> unit =
  "glstub_glCopyConvolutionFilter1D" "glstub_glCopyConvolutionFilter1D";
external glCopyConvolutionFilter2D :
  int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyConvolutionFilter2D_byte" "glstub_glCopyConvolutionFilter2D";
external glCopyPixels : int -> int -> int -> int -> int -> unit =
  "glstub_glCopyPixels" "glstub_glCopyPixels";
external glCopyTexImage1D :
  int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexImage1D_byte" "glstub_glCopyTexImage1D";
external glCopyTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexImage2D_byte" "glstub_glCopyTexImage2D";
external glCopyTexSubImage1D :
  int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexSubImage1D_byte" "glstub_glCopyTexSubImage1D";
external glCopyTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexSubImage2D_byte" "glstub_glCopyTexSubImage2D";
external glCopyTexSubImage3D :
  int -> int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexSubImage3D_byte" "glstub_glCopyTexSubImage3D";
external glCreateProgram : unit -> int = "glstub_glCreateProgram"
  "glstub_glCreateProgram";
external glCreateShader : int -> int = "glstub_glCreateShader"
  "glstub_glCreateShader";
external glCullFace : int -> unit = "glstub_glCullFace" "glstub_glCullFace";
value glDeleteBuffers : int -> array int -> unit;
value glDeleteBuffersARB : int -> array int -> unit;
value glDeleteFramebuffersEXT : int -> array int -> unit;
external glDeleteLists : int -> int -> unit = "glstub_glDeleteLists"
  "glstub_glDeleteLists";
external glDeleteProgram : int -> unit = "glstub_glDeleteProgram"
  "glstub_glDeleteProgram";
value glDeleteProgramsARB : int -> array int -> unit;
value glDeleteQueries : int -> array int -> unit;
value glDeleteQueriesARB : int -> array int -> unit;
external glDeleteShader : int -> unit = "glstub_glDeleteShader"
  "glstub_glDeleteShader";
value glDeleteTextures : int -> array int -> unit;
external glDepthFunc : int -> unit = "glstub_glDepthFunc"
  "glstub_glDepthFunc";
external glDepthMask : bool -> unit = "glstub_glDepthMask"
  "glstub_glDepthMask";
external glDepthRange : float -> float -> unit = "glstub_glDepthRange"
  "glstub_glDepthRange";
external glDetachShader : int -> int -> unit = "glstub_glDetachShader"
  "glstub_glDetachShader";
external glDisable : int -> unit = "glstub_glDisable" "glstub_glDisable";
external glDisableClientState : int -> unit = "glstub_glDisableClientState"
  "glstub_glDisableClientState";
external glDisableVertexAttribArray : int -> unit =
  "glstub_glDisableVertexAttribArray" "glstub_glDisableVertexAttribArray";
external glDisableVertexAttribArrayARB : int -> unit =
  "glstub_glDisableVertexAttribArrayARB"
  "glstub_glDisableVertexAttribArrayARB";
external glDrawArrays : int -> int -> int -> unit = "glstub_glDrawArrays"
  "glstub_glDrawArrays";
external glDrawBuffer : int -> unit = "glstub_glDrawBuffer"
  "glstub_glDrawBuffer";
value glDrawBuffers : int -> array int -> unit;
value glDrawBuffersARB : int -> array int -> unit;
external glDrawElements : int -> int -> int -> 'a -> unit =
  "glstub_glDrawElements" "glstub_glDrawElements";
external glDrawPixels : int -> int -> int -> int -> 'a -> unit =
  "glstub_glDrawPixels" "glstub_glDrawPixels";
external glDrawRangeElements :
  int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glDrawRangeElements_byte" "glstub_glDrawRangeElements";
external glEdgeFlag : bool -> unit = "glstub_glEdgeFlag" "glstub_glEdgeFlag";
external glEdgeFlagPointer : int -> 'a -> unit = "glstub_glEdgeFlagPointer"
  "glstub_glEdgeFlagPointer";
value glEdgeFlagv : array bool -> unit;
external glEnable : int -> unit = "glstub_glEnable" "glstub_glEnable";
external glEnableClientState : int -> unit = "glstub_glEnableClientState"
  "glstub_glEnableClientState";
external glEnableVertexAttribArray : int -> unit =
  "glstub_glEnableVertexAttribArray" "glstub_glEnableVertexAttribArray";
external glEnableVertexAttribArrayARB : int -> unit =
  "glstub_glEnableVertexAttribArrayARB"
  "glstub_glEnableVertexAttribArrayARB";
external glEnd : unit -> unit = "glstub_glEnd" "glstub_glEnd";
external glEndList : unit -> unit = "glstub_glEndList" "glstub_glEndList";
external glEndQuery : int -> unit = "glstub_glEndQuery" "glstub_glEndQuery";
external glEndQueryARB : int -> unit = "glstub_glEndQueryARB"
  "glstub_glEndQueryARB";
external glEvalCoord1d : float -> unit = "glstub_glEvalCoord1d"
  "glstub_glEvalCoord1d";
external glEvalCoord1dv : array float -> unit = "glstub_glEvalCoord1dv"
  "glstub_glEvalCoord1dv";
external glEvalCoord1f : float -> unit = "glstub_glEvalCoord1f"
  "glstub_glEvalCoord1f";
value glEvalCoord1fv : array float -> unit;
external glEvalCoord2d : float -> float -> unit = "glstub_glEvalCoord2d"
  "glstub_glEvalCoord2d";
external glEvalCoord2dv : array float -> unit = "glstub_glEvalCoord2dv"
  "glstub_glEvalCoord2dv";
external glEvalCoord2f : float -> float -> unit = "glstub_glEvalCoord2f"
  "glstub_glEvalCoord2f";
value glEvalCoord2fv : array float -> unit;
external glEvalMesh1 : int -> int -> int -> unit = "glstub_glEvalMesh1"
  "glstub_glEvalMesh1";
external glEvalMesh2 : int -> int -> int -> int -> int -> unit =
  "glstub_glEvalMesh2" "glstub_glEvalMesh2";
external glEvalPoint1 : int -> unit = "glstub_glEvalPoint1"
  "glstub_glEvalPoint1";
external glEvalPoint2 : int -> int -> unit = "glstub_glEvalPoint2"
  "glstub_glEvalPoint2";
value glFeedbackBuffer : int -> int -> array float -> unit;
external glFinish : unit -> unit = "glstub_glFinish" "glstub_glFinish";
external glFlush : unit -> unit = "glstub_glFlush" "glstub_glFlush";
external glFogCoordPointer : int -> int -> 'a -> unit =
  "glstub_glFogCoordPointer" "glstub_glFogCoordPointer";
external glFogCoordd : float -> unit = "glstub_glFogCoordd"
  "glstub_glFogCoordd";
external glFogCoorddv : array float -> unit = "glstub_glFogCoorddv"
  "glstub_glFogCoorddv";
external glFogCoordf : float -> unit = "glstub_glFogCoordf"
  "glstub_glFogCoordf";
value glFogCoordfv : array float -> unit;
external glFogf : int -> float -> unit = "glstub_glFogf" "glstub_glFogf";
value glFogfv : int -> array float -> unit;
external glFogi : int -> int -> unit = "glstub_glFogi" "glstub_glFogi";
value glFogiv : int -> array int -> unit;
external glFramebufferTexture1DEXT :
  int -> int -> int -> int -> int -> unit =
  "glstub_glFramebufferTexture1DEXT" "glstub_glFramebufferTexture1DEXT";
external glFramebufferTexture2DEXT :
  int -> int -> int -> int -> int -> unit =
  "glstub_glFramebufferTexture2DEXT" "glstub_glFramebufferTexture2DEXT";
external glFrontFace : int -> unit = "glstub_glFrontFace"
  "glstub_glFrontFace";
external glFrustum :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glFrustum_byte" "glstub_glFrustum";
value glGenBuffers : int -> array int -> unit;
value glGenBuffersARB : int -> array int -> unit;
value glGenFramebuffersEXT : int -> array int -> unit;
external glGenLists : int -> int = "glstub_glGenLists" "glstub_glGenLists";
value glGenProgramsARB : int -> array int -> unit;
value glGenQueries : int -> array int -> unit;
value glGenQueriesARB : int -> array int -> unit;
value glGenTextures : int -> array int -> unit;
value glGetActiveAttrib :
  int -> int -> int -> array int -> array int -> array int -> string -> unit;
value glGetActiveUniform :
  int -> int -> int -> array int -> array int -> array int -> string -> unit;
value glGetAttachedShaders : int -> int -> array int -> array int -> unit;
external glGetAttribLocation : int -> string -> int =
  "glstub_glGetAttribLocation" "glstub_glGetAttribLocation";
value glGetBooleanv : int -> array bool -> unit;
value glGetBufferParameteriv : int -> int -> array int -> unit;
value glGetBufferParameterivARB : int -> int -> array int -> unit;
external glGetBufferPointerv : int -> int -> 'a -> unit =
  "glstub_glGetBufferPointerv" "glstub_glGetBufferPointerv";
external glGetBufferPointervARB : int -> int -> 'a -> unit =
  "glstub_glGetBufferPointervARB" "glstub_glGetBufferPointervARB";
external glGetBufferSubData : int -> int -> int -> 'a -> unit =
  "glstub_glGetBufferSubData" "glstub_glGetBufferSubData";
external glGetBufferSubDataARB : int -> int -> int -> 'a -> unit =
  "glstub_glGetBufferSubDataARB" "glstub_glGetBufferSubDataARB";
external glGetClipPlane : int -> array float -> unit =
  "glstub_glGetClipPlane" "glstub_glGetClipPlane";
external glGetColorTable : int -> int -> int -> 'a -> unit =
  "glstub_glGetColorTable" "glstub_glGetColorTable";
value glGetColorTableParameterfv : int -> int -> array float -> unit;
value glGetColorTableParameteriv : int -> int -> array int -> unit;
external glGetCompressedTexImage : int -> int -> 'a -> unit =
  "glstub_glGetCompressedTexImage" "glstub_glGetCompressedTexImage";
external glGetCompressedTexImageARB : int -> int -> 'a -> unit =
  "glstub_glGetCompressedTexImageARB" "glstub_glGetCompressedTexImageARB";
external glGetConvolutionFilter : int -> int -> int -> 'a -> unit =
  "glstub_glGetConvolutionFilter" "glstub_glGetConvolutionFilter";
value glGetConvolutionParameterfv : int -> int -> array float -> unit;
value glGetConvolutionParameteriv : int -> int -> array int -> unit;
external glGetDoublev : int -> array float -> unit = "glstub_glGetDoublev"
  "glstub_glGetDoublev";
external glGetError : unit -> int = "glstub_glGetError" "glstub_glGetError";
value glGetFloatv : int -> array float -> unit;
external glGetHistogram : int -> bool -> int -> int -> 'a -> unit =
  "glstub_glGetHistogram" "glstub_glGetHistogram";
value glGetHistogramParameterfv : int -> int -> array float -> unit;
value glGetHistogramParameteriv : int -> int -> array int -> unit;
value glGetIntegerv : int -> array int -> unit;
value glGetLightfv : int -> int -> array float -> unit;
value glGetLightiv : int -> int -> array int -> unit;
external glGetMapdv : int -> int -> array float -> unit = "glstub_glGetMapdv"
  "glstub_glGetMapdv";
value glGetMapfv : int -> int -> array float -> unit;
value glGetMapiv : int -> int -> array int -> unit;
value glGetMaterialfv : int -> int -> array float -> unit;
value glGetMaterialiv : int -> int -> array int -> unit;
external glGetMinmax : int -> bool -> int -> int -> 'a -> unit =
  "glstub_glGetMinmax" "glstub_glGetMinmax";
value glGetMinmaxParameterfv : int -> int -> array float -> unit;
value glGetMinmaxParameteriv : int -> int -> array int -> unit;
value glGetPixelMapfv : int -> array float -> unit;
value glGetPixelMapuiv : int -> array int -> unit;
value glGetPixelMapusv : int -> array int -> unit;
external glGetPointerv : int -> 'a -> unit = "glstub_glGetPointerv"
  "glstub_glGetPointerv";
value glGetPolygonStipple : array int -> unit;
external glGetProgramEnvParameterdvARB : int -> int -> array float -> unit =
  "glstub_glGetProgramEnvParameterdvARB"
  "glstub_glGetProgramEnvParameterdvARB";
value glGetProgramEnvParameterfvARB : int -> int -> array float -> unit;
value glGetProgramInfoLog : int -> int -> array int -> string -> unit;
external glGetProgramLocalParameterdvARB :
  int -> int -> array float -> unit =
  "glstub_glGetProgramLocalParameterdvARB"
  "glstub_glGetProgramLocalParameterdvARB";
value glGetProgramLocalParameterfvARB : int -> int -> array float -> unit;
external glGetProgramStringARB : int -> int -> 'a -> unit =
  "glstub_glGetProgramStringARB" "glstub_glGetProgramStringARB";
value glGetProgramiv : int -> int -> array int -> unit;
value glGetProgramivARB : int -> int -> array int -> unit;
value glGetQueryObjectiv : int -> int -> array int -> unit;
value glGetQueryObjectivARB : int -> int -> array int -> unit;
value glGetQueryObjectuiv : int -> int -> array int -> unit;
value glGetQueryObjectuivARB : int -> int -> array int -> unit;
value glGetQueryiv : int -> int -> array int -> unit;
value glGetQueryivARB : int -> int -> array int -> unit;
external glGetSeparableFilter : int -> int -> int -> 'a -> 'a -> 'a -> unit =
  "glstub_glGetSeparableFilter_byte" "glstub_glGetSeparableFilter";
value glGetShaderInfoLog : int -> int -> array int -> string -> unit;
value glGetShaderSource : int -> int -> array int -> string -> unit;
value glGetShaderiv : int -> int -> array int -> unit;
value glGetTexEnvfv : int -> int -> array float -> unit;
value glGetTexEnviv : int -> int -> array int -> unit;
external glGetTexGendv : int -> int -> array float -> unit =
  "glstub_glGetTexGendv" "glstub_glGetTexGendv";
value glGetTexGenfv : int -> int -> array float -> unit;
value glGetTexGeniv : int -> int -> array int -> unit;
external glGetTexImage : int -> int -> int -> int -> 'a -> unit =
  "glstub_glGetTexImage" "glstub_glGetTexImage";
value glGetTexLevelParameterfv : int -> int -> int -> array float -> unit;
value glGetTexLevelParameteriv : int -> int -> int -> array int -> unit;
value glGetTexParameterfv : int -> int -> array float -> unit;
value glGetTexParameteriv : int -> int -> array int -> unit;
external glGetUniformLocation : int -> string -> int =
  "glstub_glGetUniformLocation" "glstub_glGetUniformLocation";
value glGetUniformfv : int -> int -> array float -> unit;
value glGetUniformiv : int -> int -> array int -> unit;
external glGetVertexAttribPointerv : int -> int -> 'a -> unit =
  "glstub_glGetVertexAttribPointerv" "glstub_glGetVertexAttribPointerv";
external glGetVertexAttribPointervARB : int -> int -> 'a -> unit =
  "glstub_glGetVertexAttribPointervARB"
  "glstub_glGetVertexAttribPointervARB";
external glGetVertexAttribdv : int -> int -> array float -> unit =
  "glstub_glGetVertexAttribdv" "glstub_glGetVertexAttribdv";
external glGetVertexAttribdvARB : int -> int -> array float -> unit =
  "glstub_glGetVertexAttribdvARB" "glstub_glGetVertexAttribdvARB";
value glGetVertexAttribfv : int -> int -> array float -> unit;
value glGetVertexAttribfvARB : int -> int -> array float -> unit;
value glGetVertexAttribiv : int -> int -> array int -> unit;
value glGetVertexAttribivARB : int -> int -> array int -> unit;
external glHint : int -> int -> unit = "glstub_glHint" "glstub_glHint";
external glHistogram : int -> int -> int -> bool -> unit =
  "glstub_glHistogram" "glstub_glHistogram";
external glIndexMask : int -> unit = "glstub_glIndexMask"
  "glstub_glIndexMask";
external glIndexPointer : int -> int -> 'a -> unit = "glstub_glIndexPointer"
  "glstub_glIndexPointer";
external glIndexd : float -> unit = "glstub_glIndexd" "glstub_glIndexd";
external glIndexdv : array float -> unit = "glstub_glIndexdv"
  "glstub_glIndexdv";
external glIndexf : float -> unit = "glstub_glIndexf" "glstub_glIndexf";
value glIndexfv : array float -> unit;
external glIndexi : int -> unit = "glstub_glIndexi" "glstub_glIndexi";
value glIndexiv : array int -> unit;
external glIndexs : int -> unit = "glstub_glIndexs" "glstub_glIndexs";
value glIndexsv : array int -> unit;
external glIndexub : int -> unit = "glstub_glIndexub" "glstub_glIndexub";
value glIndexubv : array int -> unit;
external glInitNames : unit -> unit = "glstub_glInitNames"
  "glstub_glInitNames";
external glInterleavedArrays : int -> int -> 'a -> unit =
  "glstub_glInterleavedArrays" "glstub_glInterleavedArrays";
external glIsBuffer : int -> bool = "glstub_glIsBuffer" "glstub_glIsBuffer";
external glIsBufferARB : int -> bool = "glstub_glIsBufferARB"
  "glstub_glIsBufferARB";
external glIsEnabled : int -> bool = "glstub_glIsEnabled"
  "glstub_glIsEnabled";
external glIsFramebufferEXT : int -> bool = "glstub_glIsFramebufferEXT"
  "glstub_glIsFramebufferEXT";
external glIsList : int -> bool = "glstub_glIsList" "glstub_glIsList";
external glIsProgram : int -> bool = "glstub_glIsProgram"
  "glstub_glIsProgram";
external glIsProgramARB : int -> bool = "glstub_glIsProgramARB"
  "glstub_glIsProgramARB";
external glIsQuery : int -> bool = "glstub_glIsQuery" "glstub_glIsQuery";
external glIsQueryARB : int -> bool = "glstub_glIsQueryARB"
  "glstub_glIsQueryARB";
external glIsShader : int -> bool = "glstub_glIsShader" "glstub_glIsShader";
external glIsTexture : int -> bool = "glstub_glIsTexture"
  "glstub_glIsTexture";
external glLightModelf : int -> float -> unit = "glstub_glLightModelf"
  "glstub_glLightModelf";
value glLightModelfv : int -> array float -> unit;
external glLightModeli : int -> int -> unit = "glstub_glLightModeli"
  "glstub_glLightModeli";
value glLightModeliv : int -> array int -> unit;
external glLightf : int -> int -> float -> unit = "glstub_glLightf"
  "glstub_glLightf";
value glLightfv : int -> int -> array float -> unit;
external glLighti : int -> int -> int -> unit = "glstub_glLighti"
  "glstub_glLighti";
value glLightiv : int -> int -> array int -> unit;
external glLineStipple : int -> int -> unit = "glstub_glLineStipple"
  "glstub_glLineStipple";
external glLineWidth : float -> unit = "glstub_glLineWidth"
  "glstub_glLineWidth";
external glLinkProgram : int -> unit = "glstub_glLinkProgram"
  "glstub_glLinkProgram";
external glListBase : int -> unit = "glstub_glListBase" "glstub_glListBase";
external glLoadIdentity : unit -> unit = "glstub_glLoadIdentity"
  "glstub_glLoadIdentity";
external glLoadMatrixd : array float -> unit = "glstub_glLoadMatrixd"
  "glstub_glLoadMatrixd";
value glLoadMatrixf : array float -> unit;
external glLoadName : int -> unit = "glstub_glLoadName" "glstub_glLoadName";
external glLoadTransposeMatrixd : array float -> unit =
  "glstub_glLoadTransposeMatrixd" "glstub_glLoadTransposeMatrixd";
external glLoadTransposeMatrixdARB : array float -> unit =
  "glstub_glLoadTransposeMatrixdARB" "glstub_glLoadTransposeMatrixdARB";
value glLoadTransposeMatrixf : array float -> unit;
value glLoadTransposeMatrixfARB : array float -> unit;
external glLockArraysEXT : int -> int -> unit = "glstub_glLockArraysEXT"
  "glstub_glLockArraysEXT";
external glLogicOp : int -> unit = "glstub_glLogicOp" "glstub_glLogicOp";
external glMap1d :
  int -> float -> float -> int -> int -> array float -> unit =
  "glstub_glMap1d_byte" "glstub_glMap1d";
value glMap1f : int -> float -> float -> int -> int -> array float -> unit;
external glMap2d :
  int ->
    float ->
      float ->
        int -> int -> float -> float -> int -> int -> array float -> unit =
  "glstub_glMap2d_byte" "glstub_glMap2d";
value glMap2f :
  int ->
    float ->
      float ->
        int -> int -> float -> float -> int -> int -> array float -> unit;
external glMapBuffer : int -> int -> 'a = "glstub_glMapBuffer"
  "glstub_glMapBuffer";
external glMapBufferARB : int -> int -> 'a = "glstub_glMapBufferARB"
  "glstub_glMapBufferARB";
external glMapGrid1d : int -> float -> float -> unit = "glstub_glMapGrid1d"
  "glstub_glMapGrid1d";
external glMapGrid1f : int -> float -> float -> unit = "glstub_glMapGrid1f"
  "glstub_glMapGrid1f";
external glMapGrid2d :
  int -> float -> float -> int -> float -> float -> unit =
  "glstub_glMapGrid2d_byte" "glstub_glMapGrid2d";
external glMapGrid2f :
  int -> float -> float -> int -> float -> float -> unit =
  "glstub_glMapGrid2f_byte" "glstub_glMapGrid2f";
external glMaterialf : int -> int -> float -> unit = "glstub_glMaterialf"
  "glstub_glMaterialf";
value glMaterialfv : int -> int -> array float -> unit;
external glMateriali : int -> int -> int -> unit = "glstub_glMateriali"
  "glstub_glMateriali";
value glMaterialiv : int -> int -> array int -> unit;
external glMatrixMode : int -> unit = "glstub_glMatrixMode"
  "glstub_glMatrixMode";
external glMinmax : int -> int -> bool -> unit = "glstub_glMinmax"
  "glstub_glMinmax";
external glMultMatrixd : array float -> unit = "glstub_glMultMatrixd"
  "glstub_glMultMatrixd";
value glMultMatrixf : array float -> unit;
external glMultTransposeMatrixd : array float -> unit =
  "glstub_glMultTransposeMatrixd" "glstub_glMultTransposeMatrixd";
external glMultTransposeMatrixdARB : array float -> unit =
  "glstub_glMultTransposeMatrixdARB" "glstub_glMultTransposeMatrixdARB";
value glMultTransposeMatrixf : array float -> unit;
value glMultTransposeMatrixfARB : array float -> unit;
value glMultiDrawArrays : int -> array int -> array int -> int -> unit;
external glMultiTexCoord1d : int -> float -> unit =
  "glstub_glMultiTexCoord1d" "glstub_glMultiTexCoord1d";
external glMultiTexCoord1dARB : int -> float -> unit =
  "glstub_glMultiTexCoord1dARB" "glstub_glMultiTexCoord1dARB";
external glMultiTexCoord1dv : int -> array float -> unit =
  "glstub_glMultiTexCoord1dv" "glstub_glMultiTexCoord1dv";
external glMultiTexCoord1dvARB : int -> array float -> unit =
  "glstub_glMultiTexCoord1dvARB" "glstub_glMultiTexCoord1dvARB";
external glMultiTexCoord1f : int -> float -> unit =
  "glstub_glMultiTexCoord1f" "glstub_glMultiTexCoord1f";
external glMultiTexCoord1fARB : int -> float -> unit =
  "glstub_glMultiTexCoord1fARB" "glstub_glMultiTexCoord1fARB";
value glMultiTexCoord1fv : int -> array float -> unit;
value glMultiTexCoord1fvARB : int -> array float -> unit;
external glMultiTexCoord1i : int -> int -> unit = "glstub_glMultiTexCoord1i"
  "glstub_glMultiTexCoord1i";
external glMultiTexCoord1iARB : int -> int -> unit =
  "glstub_glMultiTexCoord1iARB" "glstub_glMultiTexCoord1iARB";
value glMultiTexCoord1iv : int -> array int -> unit;
value glMultiTexCoord1ivARB : int -> array int -> unit;
external glMultiTexCoord1s : int -> int -> unit = "glstub_glMultiTexCoord1s"
  "glstub_glMultiTexCoord1s";
external glMultiTexCoord1sARB : int -> int -> unit =
  "glstub_glMultiTexCoord1sARB" "glstub_glMultiTexCoord1sARB";
value glMultiTexCoord1sv : int -> array int -> unit;
value glMultiTexCoord1svARB : int -> array int -> unit;
external glMultiTexCoord2d : int -> float -> float -> unit =
  "glstub_glMultiTexCoord2d" "glstub_glMultiTexCoord2d";
external glMultiTexCoord2dARB : int -> float -> float -> unit =
  "glstub_glMultiTexCoord2dARB" "glstub_glMultiTexCoord2dARB";
external glMultiTexCoord2dv : int -> array float -> unit =
  "glstub_glMultiTexCoord2dv" "glstub_glMultiTexCoord2dv";
external glMultiTexCoord2dvARB : int -> array float -> unit =
  "glstub_glMultiTexCoord2dvARB" "glstub_glMultiTexCoord2dvARB";
external glMultiTexCoord2f : int -> float -> float -> unit =
  "glstub_glMultiTexCoord2f" "glstub_glMultiTexCoord2f";
external glMultiTexCoord2fARB : int -> float -> float -> unit =
  "glstub_glMultiTexCoord2fARB" "glstub_glMultiTexCoord2fARB";
value glMultiTexCoord2fv : int -> array float -> unit;
value glMultiTexCoord2fvARB : int -> array float -> unit;
external glMultiTexCoord2i : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2i" "glstub_glMultiTexCoord2i";
external glMultiTexCoord2iARB : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2iARB" "glstub_glMultiTexCoord2iARB";
value glMultiTexCoord2iv : int -> array int -> unit;
value glMultiTexCoord2ivARB : int -> array int -> unit;
external glMultiTexCoord2s : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2s" "glstub_glMultiTexCoord2s";
external glMultiTexCoord2sARB : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2sARB" "glstub_glMultiTexCoord2sARB";
value glMultiTexCoord2sv : int -> array int -> unit;
value glMultiTexCoord2svARB : int -> array int -> unit;
external glMultiTexCoord3d : int -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord3d" "glstub_glMultiTexCoord3d";
external glMultiTexCoord3dARB : int -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord3dARB" "glstub_glMultiTexCoord3dARB";
external glMultiTexCoord3dv : int -> array float -> unit =
  "glstub_glMultiTexCoord3dv" "glstub_glMultiTexCoord3dv";
external glMultiTexCoord3dvARB : int -> array float -> unit =
  "glstub_glMultiTexCoord3dvARB" "glstub_glMultiTexCoord3dvARB";
external glMultiTexCoord3f : int -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord3f" "glstub_glMultiTexCoord3f";
external glMultiTexCoord3fARB : int -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord3fARB" "glstub_glMultiTexCoord3fARB";
value glMultiTexCoord3fv : int -> array float -> unit;
value glMultiTexCoord3fvARB : int -> array float -> unit;
external glMultiTexCoord3i : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3i" "glstub_glMultiTexCoord3i";
external glMultiTexCoord3iARB : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3iARB" "glstub_glMultiTexCoord3iARB";
value glMultiTexCoord3iv : int -> array int -> unit;
value glMultiTexCoord3ivARB : int -> array int -> unit;
external glMultiTexCoord3s : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3s" "glstub_glMultiTexCoord3s";
external glMultiTexCoord3sARB : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3sARB" "glstub_glMultiTexCoord3sARB";
value glMultiTexCoord3sv : int -> array int -> unit;
value glMultiTexCoord3svARB : int -> array int -> unit;
external glMultiTexCoord4d :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4d" "glstub_glMultiTexCoord4d";
external glMultiTexCoord4dARB :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4dARB" "glstub_glMultiTexCoord4dARB";
external glMultiTexCoord4dv : int -> array float -> unit =
  "glstub_glMultiTexCoord4dv" "glstub_glMultiTexCoord4dv";
external glMultiTexCoord4dvARB : int -> array float -> unit =
  "glstub_glMultiTexCoord4dvARB" "glstub_glMultiTexCoord4dvARB";
external glMultiTexCoord4f :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4f" "glstub_glMultiTexCoord4f";
external glMultiTexCoord4fARB :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4fARB" "glstub_glMultiTexCoord4fARB";
value glMultiTexCoord4fv : int -> array float -> unit;
value glMultiTexCoord4fvARB : int -> array float -> unit;
external glMultiTexCoord4i : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4i" "glstub_glMultiTexCoord4i";
external glMultiTexCoord4iARB : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4iARB" "glstub_glMultiTexCoord4iARB";
value glMultiTexCoord4iv : int -> array int -> unit;
value glMultiTexCoord4ivARB : int -> array int -> unit;
external glMultiTexCoord4s : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4s" "glstub_glMultiTexCoord4s";
external glMultiTexCoord4sARB : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4sARB" "glstub_glMultiTexCoord4sARB";
value glMultiTexCoord4sv : int -> array int -> unit;
value glMultiTexCoord4svARB : int -> array int -> unit;
external glNewList : int -> int -> unit = "glstub_glNewList"
  "glstub_glNewList";
external glNormal3b : int -> int -> int -> unit = "glstub_glNormal3b"
  "glstub_glNormal3b";
value glNormal3bv : array int -> unit;
external glNormal3d : float -> float -> float -> unit = "glstub_glNormal3d"
  "glstub_glNormal3d";
external glNormal3dv : array float -> unit = "glstub_glNormal3dv"
  "glstub_glNormal3dv";
external glNormal3f : float -> float -> float -> unit = "glstub_glNormal3f"
  "glstub_glNormal3f";
value glNormal3fv : array float -> unit;
external glNormal3i : int -> int -> int -> unit = "glstub_glNormal3i"
  "glstub_glNormal3i";
value glNormal3iv : array int -> unit;
external glNormal3s : int -> int -> int -> unit = "glstub_glNormal3s"
  "glstub_glNormal3s";
value glNormal3sv : array int -> unit;
external glNormalPointer : int -> int -> 'a -> unit =
  "glstub_glNormalPointer" "glstub_glNormalPointer";
external glOrtho :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glOrtho_byte" "glstub_glOrtho";
external glPassThrough : float -> unit = "glstub_glPassThrough"
  "glstub_glPassThrough";
value glPixelMapfv : int -> int -> array float -> unit;
value glPixelMapuiv : int -> int -> array int -> unit;
value glPixelMapusv : int -> int -> array int -> unit;
external glPixelStoref : int -> float -> unit = "glstub_glPixelStoref"
  "glstub_glPixelStoref";
external glPixelStorei : int -> int -> unit = "glstub_glPixelStorei"
  "glstub_glPixelStorei";
external glPixelTransferf : int -> float -> unit = "glstub_glPixelTransferf"
  "glstub_glPixelTransferf";
external glPixelTransferi : int -> int -> unit = "glstub_glPixelTransferi"
  "glstub_glPixelTransferi";
external glPixelZoom : float -> float -> unit = "glstub_glPixelZoom"
  "glstub_glPixelZoom";
external glPointParameterf : int -> float -> unit =
  "glstub_glPointParameterf" "glstub_glPointParameterf";
external glPointParameterfARB : int -> float -> unit =
  "glstub_glPointParameterfARB" "glstub_glPointParameterfARB";
value glPointParameterfv : int -> array float -> unit;
value glPointParameterfvARB : int -> array float -> unit;
external glPointSize : float -> unit = "glstub_glPointSize"
  "glstub_glPointSize";
external glPolygonMode : int -> int -> unit = "glstub_glPolygonMode"
  "glstub_glPolygonMode";
external glPolygonOffset : float -> float -> unit = "glstub_glPolygonOffset"
  "glstub_glPolygonOffset";
value glPolygonStipple : array int -> unit;
external glPopAttrib : unit -> unit = "glstub_glPopAttrib"
  "glstub_glPopAttrib";
external glPopClientAttrib : unit -> unit = "glstub_glPopClientAttrib"
  "glstub_glPopClientAttrib";
external glPopMatrix : unit -> unit = "glstub_glPopMatrix"
  "glstub_glPopMatrix";
external glPopName : unit -> unit = "glstub_glPopName" "glstub_glPopName";
value glPrioritizeTextures : int -> array int -> array float -> unit;
external glProgramEnvParameter4dARB :
  int -> int -> float -> float -> float -> float -> unit =
  "glstub_glProgramEnvParameter4dARB_byte"
  "glstub_glProgramEnvParameter4dARB";
external glProgramEnvParameter4dvARB : int -> int -> array float -> unit =
  "glstub_glProgramEnvParameter4dvARB" "glstub_glProgramEnvParameter4dvARB";
external glProgramEnvParameter4fARB :
  int -> int -> float -> float -> float -> float -> unit =
  "glstub_glProgramEnvParameter4fARB_byte"
  "glstub_glProgramEnvParameter4fARB";
value glProgramEnvParameter4fvARB : int -> int -> array float -> unit;
external glProgramLocalParameter4dARB :
  int -> int -> float -> float -> float -> float -> unit =
  "glstub_glProgramLocalParameter4dARB_byte"
  "glstub_glProgramLocalParameter4dARB";
external glProgramLocalParameter4dvARB : int -> int -> array float -> unit =
  "glstub_glProgramLocalParameter4dvARB"
  "glstub_glProgramLocalParameter4dvARB";
external glProgramLocalParameter4fARB :
  int -> int -> float -> float -> float -> float -> unit =
  "glstub_glProgramLocalParameter4fARB_byte"
  "glstub_glProgramLocalParameter4fARB";
value glProgramLocalParameter4fvARB : int -> int -> array float -> unit;
external glProgramStringARB : int -> int -> int -> 'a -> unit =
  "glstub_glProgramStringARB" "glstub_glProgramStringARB";
external glPushAttrib : int -> unit = "glstub_glPushAttrib"
  "glstub_glPushAttrib";
external glPushClientAttrib : int -> unit = "glstub_glPushClientAttrib"
  "glstub_glPushClientAttrib";
external glPushMatrix : unit -> unit = "glstub_glPushMatrix"
  "glstub_glPushMatrix";
external glPushName : int -> unit = "glstub_glPushName" "glstub_glPushName";
external glRasterPos2d : float -> float -> unit = "glstub_glRasterPos2d"
  "glstub_glRasterPos2d";
external glRasterPos2dv : array float -> unit = "glstub_glRasterPos2dv"
  "glstub_glRasterPos2dv";
external glRasterPos2f : float -> float -> unit = "glstub_glRasterPos2f"
  "glstub_glRasterPos2f";
value glRasterPos2fv : array float -> unit;
external glRasterPos2i : int -> int -> unit = "glstub_glRasterPos2i"
  "glstub_glRasterPos2i";
value glRasterPos2iv : array int -> unit;
external glRasterPos2s : int -> int -> unit = "glstub_glRasterPos2s"
  "glstub_glRasterPos2s";
value glRasterPos2sv : array int -> unit;
external glRasterPos3d : float -> float -> float -> unit =
  "glstub_glRasterPos3d" "glstub_glRasterPos3d";
external glRasterPos3dv : array float -> unit = "glstub_glRasterPos3dv"
  "glstub_glRasterPos3dv";
external glRasterPos3f : float -> float -> float -> unit =
  "glstub_glRasterPos3f" "glstub_glRasterPos3f";
value glRasterPos3fv : array float -> unit;
external glRasterPos3i : int -> int -> int -> unit = "glstub_glRasterPos3i"
  "glstub_glRasterPos3i";
value glRasterPos3iv : array int -> unit;
external glRasterPos3s : int -> int -> int -> unit = "glstub_glRasterPos3s"
  "glstub_glRasterPos3s";
value glRasterPos3sv : array int -> unit;
external glRasterPos4d : float -> float -> float -> float -> unit =
  "glstub_glRasterPos4d" "glstub_glRasterPos4d";
external glRasterPos4dv : array float -> unit = "glstub_glRasterPos4dv"
  "glstub_glRasterPos4dv";
external glRasterPos4f : float -> float -> float -> float -> unit =
  "glstub_glRasterPos4f" "glstub_glRasterPos4f";
value glRasterPos4fv : array float -> unit;
external glRasterPos4i : int -> int -> int -> int -> unit =
  "glstub_glRasterPos4i" "glstub_glRasterPos4i";
value glRasterPos4iv : array int -> unit;
external glRasterPos4s : int -> int -> int -> int -> unit =
  "glstub_glRasterPos4s" "glstub_glRasterPos4s";
value glRasterPos4sv : array int -> unit;
external glReadBuffer : int -> unit = "glstub_glReadBuffer"
  "glstub_glReadBuffer";
external glReadPixels :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glReadPixels_byte" "glstub_glReadPixels";
external glRectd : float -> float -> float -> float -> unit =
  "glstub_glRectd" "glstub_glRectd";
external glRectdv : array float -> array float -> unit = "glstub_glRectdv"
  "glstub_glRectdv";
external glRectf : float -> float -> float -> float -> unit =
  "glstub_glRectf" "glstub_glRectf";
value glRectfv : array float -> array float -> unit;
external glRecti : int -> int -> int -> int -> unit = "glstub_glRecti"
  "glstub_glRecti";
value glRectiv : array int -> array int -> unit;
external glRects : int -> int -> int -> int -> unit = "glstub_glRects"
  "glstub_glRects";
value glRectsv : array int -> array int -> unit;
external glRenderMode : int -> int = "glstub_glRenderMode"
  "glstub_glRenderMode";
external glResetHistogram : int -> unit = "glstub_glResetHistogram"
  "glstub_glResetHistogram";
external glResetMinmax : int -> unit = "glstub_glResetMinmax"
  "glstub_glResetMinmax";
external glRotated : float -> float -> float -> float -> unit =
  "glstub_glRotated" "glstub_glRotated";
external glRotatef : float -> float -> float -> float -> unit =
  "glstub_glRotatef" "glstub_glRotatef";
external glSampleCoverage : float -> bool -> unit = "glstub_glSampleCoverage"
  "glstub_glSampleCoverage";
external glSampleCoverageARB : float -> bool -> unit =
  "glstub_glSampleCoverageARB" "glstub_glSampleCoverageARB";
external glScaled : float -> float -> float -> unit = "glstub_glScaled"
  "glstub_glScaled";
external glScalef : float -> float -> float -> unit = "glstub_glScalef"
  "glstub_glScalef";
external glScissor : int -> int -> int -> int -> unit = "glstub_glScissor"
  "glstub_glScissor";
external glSecondaryColor3b : int -> int -> int -> unit =
  "glstub_glSecondaryColor3b" "glstub_glSecondaryColor3b";
value glSecondaryColor3bv : array int -> unit;
external glSecondaryColor3d : float -> float -> float -> unit =
  "glstub_glSecondaryColor3d" "glstub_glSecondaryColor3d";
external glSecondaryColor3dv : array float -> unit =
  "glstub_glSecondaryColor3dv" "glstub_glSecondaryColor3dv";
external glSecondaryColor3f : float -> float -> float -> unit =
  "glstub_glSecondaryColor3f" "glstub_glSecondaryColor3f";
value glSecondaryColor3fv : array float -> unit;
external glSecondaryColor3i : int -> int -> int -> unit =
  "glstub_glSecondaryColor3i" "glstub_glSecondaryColor3i";
value glSecondaryColor3iv : array int -> unit;
external glSecondaryColor3s : int -> int -> int -> unit =
  "glstub_glSecondaryColor3s" "glstub_glSecondaryColor3s";
value glSecondaryColor3sv : array int -> unit;
external glSecondaryColor3ub : int -> int -> int -> unit =
  "glstub_glSecondaryColor3ub" "glstub_glSecondaryColor3ub";
value glSecondaryColor3ubv : array int -> unit;
external glSecondaryColor3ui : int -> int -> int -> unit =
  "glstub_glSecondaryColor3ui" "glstub_glSecondaryColor3ui";
value glSecondaryColor3uiv : array int -> unit;
external glSecondaryColor3us : int -> int -> int -> unit =
  "glstub_glSecondaryColor3us" "glstub_glSecondaryColor3us";
value glSecondaryColor3usv : array int -> unit;
external glSecondaryColorPointer : int -> int -> int -> 'a -> unit =
  "glstub_glSecondaryColorPointer" "glstub_glSecondaryColorPointer";
value glSelectBuffer : int -> array int -> unit;
external glSeparableFilter2D :
  int -> int -> int -> int -> int -> int -> 'a -> 'a -> unit =
  "glstub_glSeparableFilter2D_byte" "glstub_glSeparableFilter2D";
external glShadeModel : int -> unit = "glstub_glShadeModel"
  "glstub_glShadeModel";
external glStencilFunc : int -> int -> int -> unit = "glstub_glStencilFunc"
  "glstub_glStencilFunc";
external glStencilFuncSeparate : int -> int -> int -> int -> unit =
  "glstub_glStencilFuncSeparate" "glstub_glStencilFuncSeparate";
external glStencilMask : int -> unit = "glstub_glStencilMask"
  "glstub_glStencilMask";
external glStencilMaskSeparate : int -> int -> unit =
  "glstub_glStencilMaskSeparate" "glstub_glStencilMaskSeparate";
external glStencilOp : int -> int -> int -> unit = "glstub_glStencilOp"
  "glstub_glStencilOp";
external glStencilOpSeparate : int -> int -> int -> int -> unit =
  "glstub_glStencilOpSeparate" "glstub_glStencilOpSeparate";
external glTexCoord1d : float -> unit = "glstub_glTexCoord1d"
  "glstub_glTexCoord1d";
external glTexCoord1dv : array float -> unit = "glstub_glTexCoord1dv"
  "glstub_glTexCoord1dv";
external glTexCoord1f : float -> unit = "glstub_glTexCoord1f"
  "glstub_glTexCoord1f";
value glTexCoord1fv : array float -> unit;
external glTexCoord1i : int -> unit = "glstub_glTexCoord1i"
  "glstub_glTexCoord1i";
value glTexCoord1iv : array int -> unit;
external glTexCoord1s : int -> unit = "glstub_glTexCoord1s"
  "glstub_glTexCoord1s";
value glTexCoord1sv : array int -> unit;
external glTexCoord2d : float -> float -> unit = "glstub_glTexCoord2d"
  "glstub_glTexCoord2d";
external glTexCoord2dv : array float -> unit = "glstub_glTexCoord2dv"
  "glstub_glTexCoord2dv";
external glTexCoord2f : float -> float -> unit = "glstub_glTexCoord2f"
  "glstub_glTexCoord2f";
value glTexCoord2fv : array float -> unit;
external glTexCoord2i : int -> int -> unit = "glstub_glTexCoord2i"
  "glstub_glTexCoord2i";
value glTexCoord2iv : array int -> unit;
external glTexCoord2s : int -> int -> unit = "glstub_glTexCoord2s"
  "glstub_glTexCoord2s";
value glTexCoord2sv : array int -> unit;
external glTexCoord3d : float -> float -> float -> unit =
  "glstub_glTexCoord3d" "glstub_glTexCoord3d";
external glTexCoord3dv : array float -> unit = "glstub_glTexCoord3dv"
  "glstub_glTexCoord3dv";
external glTexCoord3f : float -> float -> float -> unit =
  "glstub_glTexCoord3f" "glstub_glTexCoord3f";
value glTexCoord3fv : array float -> unit;
external glTexCoord3i : int -> int -> int -> unit = "glstub_glTexCoord3i"
  "glstub_glTexCoord3i";
value glTexCoord3iv : array int -> unit;
external glTexCoord3s : int -> int -> int -> unit = "glstub_glTexCoord3s"
  "glstub_glTexCoord3s";
value glTexCoord3sv : array int -> unit;
external glTexCoord4d : float -> float -> float -> float -> unit =
  "glstub_glTexCoord4d" "glstub_glTexCoord4d";
external glTexCoord4dv : array float -> unit = "glstub_glTexCoord4dv"
  "glstub_glTexCoord4dv";
external glTexCoord4f : float -> float -> float -> float -> unit =
  "glstub_glTexCoord4f" "glstub_glTexCoord4f";
value glTexCoord4fv : array float -> unit;
external glTexCoord4i : int -> int -> int -> int -> unit =
  "glstub_glTexCoord4i" "glstub_glTexCoord4i";
value glTexCoord4iv : array int -> unit;
external glTexCoord4s : int -> int -> int -> int -> unit =
  "glstub_glTexCoord4s" "glstub_glTexCoord4s";
value glTexCoord4sv : array int -> unit;
external glTexCoordPointer : int -> int -> int -> 'a -> unit =
  "glstub_glTexCoordPointer" "glstub_glTexCoordPointer";
external glTexEnvf : int -> int -> float -> unit = "glstub_glTexEnvf"
  "glstub_glTexEnvf";
value glTexEnvfv : int -> int -> array float -> unit;
external glTexEnvi : int -> int -> int -> unit = "glstub_glTexEnvi"
  "glstub_glTexEnvi";
value glTexEnviv : int -> int -> array int -> unit;
external glTexGend : int -> int -> float -> unit = "glstub_glTexGend"
  "glstub_glTexGend";
external glTexGendv : int -> int -> array float -> unit = "glstub_glTexGendv"
  "glstub_glTexGendv";
external glTexGenf : int -> int -> float -> unit = "glstub_glTexGenf"
  "glstub_glTexGenf";
value glTexGenfv : int -> int -> array float -> unit;
external glTexGeni : int -> int -> int -> unit = "glstub_glTexGeni"
  "glstub_glTexGeni";
value glTexGeniv : int -> int -> array int -> unit;
external glTexImage1D :
  int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexImage1D_byte" "glstub_glTexImage1D";
external glTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexImage2D_byte" "glstub_glTexImage2D";
external glTexImage3D :
  int -> int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexImage3D_byte" "glstub_glTexImage3D";
external glTexParameterf : int -> int -> float -> unit =
  "glstub_glTexParameterf" "glstub_glTexParameterf";
value glTexParameterfv : int -> int -> array float -> unit;
external glTexParameteri : int -> int -> int -> unit =
  "glstub_glTexParameteri" "glstub_glTexParameteri";
value glTexParameteriv : int -> int -> array int -> unit;
external glTexSubImage1D :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexSubImage1D_byte" "glstub_glTexSubImage1D";
external glTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexSubImage2D_byte" "glstub_glTexSubImage2D";
external glTexSubImage3D :
  int ->
    int -> int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexSubImage3D_byte" "glstub_glTexSubImage3D";
external glTranslated : float -> float -> float -> unit =
  "glstub_glTranslated" "glstub_glTranslated";
external glTranslatef : float -> float -> float -> unit =
  "glstub_glTranslatef" "glstub_glTranslatef";
external glUniform1f : int -> float -> unit = "glstub_glUniform1f"
  "glstub_glUniform1f";
external glUniform1fARB : int -> float -> unit = "glstub_glUniform1fARB"
  "glstub_glUniform1fARB";
value glUniform1fv : int -> int -> array float -> unit;
value glUniform1fvARB : int -> int -> array float -> unit;
external glUniform1i : int -> int -> unit = "glstub_glUniform1i"
  "glstub_glUniform1i";
external glUniform1iARB : int -> int -> unit = "glstub_glUniform1iARB"
  "glstub_glUniform1iARB";
value glUniform1iv : int -> int -> array int -> unit;
value glUniform1ivARB : int -> int -> array int -> unit;
external glUniform2f : int -> float -> float -> unit = "glstub_glUniform2f"
  "glstub_glUniform2f";
external glUniform2fARB : int -> float -> float -> unit =
  "glstub_glUniform2fARB" "glstub_glUniform2fARB";
value glUniform2fv : int -> int -> array float -> unit;
value glUniform2fvARB : int -> int -> array float -> unit;
external glUniform2i : int -> int -> int -> unit = "glstub_glUniform2i"
  "glstub_glUniform2i";
external glUniform2iARB : int -> int -> int -> unit = "glstub_glUniform2iARB"
  "glstub_glUniform2iARB";
value glUniform2iv : int -> int -> array int -> unit;
value glUniform2ivARB : int -> int -> array int -> unit;
external glUniform3f : int -> float -> float -> float -> unit =
  "glstub_glUniform3f" "glstub_glUniform3f";
external glUniform3fARB : int -> float -> float -> float -> unit =
  "glstub_glUniform3fARB" "glstub_glUniform3fARB";
value glUniform3fv : int -> int -> array float -> unit;
value glUniform3fvARB : int -> int -> array float -> unit;
external glUniform3i : int -> int -> int -> int -> unit =
  "glstub_glUniform3i" "glstub_glUniform3i";
external glUniform3iARB : int -> int -> int -> int -> unit =
  "glstub_glUniform3iARB" "glstub_glUniform3iARB";
value glUniform3iv : int -> int -> array int -> unit;
value glUniform3ivARB : int -> int -> array int -> unit;
external glUniform4f : int -> float -> float -> float -> float -> unit =
  "glstub_glUniform4f" "glstub_glUniform4f";
external glUniform4fARB : int -> float -> float -> float -> float -> unit =
  "glstub_glUniform4fARB" "glstub_glUniform4fARB";
value glUniform4fv : int -> int -> array float -> unit;
value glUniform4fvARB : int -> int -> array float -> unit;
external glUniform4i : int -> int -> int -> int -> int -> unit =
  "glstub_glUniform4i" "glstub_glUniform4i";
external glUniform4iARB : int -> int -> int -> int -> int -> unit =
  "glstub_glUniform4iARB" "glstub_glUniform4iARB";
value glUniform4iv : int -> int -> array int -> unit;
value glUniform4ivARB : int -> int -> array int -> unit;
value glUniformMatrix2fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix2fvARB : int -> int -> bool -> array float -> unit;
value glUniformMatrix2x3fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix2x4fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix3fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix3fvARB : int -> int -> bool -> array float -> unit;
value glUniformMatrix3x2fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix3x4fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix4fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix4fvARB : int -> int -> bool -> array float -> unit;
value glUniformMatrix4x2fv : int -> int -> bool -> array float -> unit;
value glUniformMatrix4x3fv : int -> int -> bool -> array float -> unit;
external glUnlockArraysEXT : unit -> unit = "glstub_glUnlockArraysEXT"
  "glstub_glUnlockArraysEXT";
external glUnmapBuffer : int -> bool = "glstub_glUnmapBuffer"
  "glstub_glUnmapBuffer";
external glUnmapBufferARB : int -> bool = "glstub_glUnmapBufferARB"
  "glstub_glUnmapBufferARB";
external glUseProgram : int -> unit = "glstub_glUseProgram"
  "glstub_glUseProgram";
external glValidateProgram : int -> unit = "glstub_glValidateProgram"
  "glstub_glValidateProgram";
external glVertex2d : float -> float -> unit = "glstub_glVertex2d"
  "glstub_glVertex2d";
external glVertex2dv : array float -> unit = "glstub_glVertex2dv"
  "glstub_glVertex2dv";
external glVertex2f : float -> float -> unit = "glstub_glVertex2f"
  "glstub_glVertex2f";
value glVertex2fv : array float -> unit;
external glVertex2i : int -> int -> unit = "glstub_glVertex2i"
  "glstub_glVertex2i";
value glVertex2iv : array int -> unit;
external glVertex2s : int -> int -> unit = "glstub_glVertex2s"
  "glstub_glVertex2s";
value glVertex2sv : array int -> unit;
external glVertex3d : float -> float -> float -> unit = "glstub_glVertex3d"
  "glstub_glVertex3d";
external glVertex3dv : array float -> unit = "glstub_glVertex3dv"
  "glstub_glVertex3dv";
external glVertex3f : float -> float -> float -> unit = "glstub_glVertex3f"
  "glstub_glVertex3f";
value glVertex3fv : array float -> unit;
external glVertex3i : int -> int -> int -> unit = "glstub_glVertex3i"
  "glstub_glVertex3i";
value glVertex3iv : array int -> unit;
external glVertex3s : int -> int -> int -> unit = "glstub_glVertex3s"
  "glstub_glVertex3s";
value glVertex3sv : array int -> unit;
external glVertex4d : float -> float -> float -> float -> unit =
  "glstub_glVertex4d" "glstub_glVertex4d";
external glVertex4dv : array float -> unit = "glstub_glVertex4dv"
  "glstub_glVertex4dv";
external glVertex4f : float -> float -> float -> float -> unit =
  "glstub_glVertex4f" "glstub_glVertex4f";
value glVertex4fv : array float -> unit;
external glVertex4i : int -> int -> int -> int -> unit = "glstub_glVertex4i"
  "glstub_glVertex4i";
value glVertex4iv : array int -> unit;
external glVertex4s : int -> int -> int -> int -> unit = "glstub_glVertex4s"
  "glstub_glVertex4s";
value glVertex4sv : array int -> unit;
external glVertexAttrib1d : int -> float -> unit = "glstub_glVertexAttrib1d"
  "glstub_glVertexAttrib1d";
external glVertexAttrib1dARB : int -> float -> unit =
  "glstub_glVertexAttrib1dARB" "glstub_glVertexAttrib1dARB";
external glVertexAttrib1dv : int -> array float -> unit =
  "glstub_glVertexAttrib1dv" "glstub_glVertexAttrib1dv";
external glVertexAttrib1dvARB : int -> array float -> unit =
  "glstub_glVertexAttrib1dvARB" "glstub_glVertexAttrib1dvARB";
external glVertexAttrib1f : int -> float -> unit = "glstub_glVertexAttrib1f"
  "glstub_glVertexAttrib1f";
external glVertexAttrib1fARB : int -> float -> unit =
  "glstub_glVertexAttrib1fARB" "glstub_glVertexAttrib1fARB";
value glVertexAttrib1fv : int -> array float -> unit;
value glVertexAttrib1fvARB : int -> array float -> unit;
external glVertexAttrib1s : int -> int -> unit = "glstub_glVertexAttrib1s"
  "glstub_glVertexAttrib1s";
external glVertexAttrib1sARB : int -> int -> unit =
  "glstub_glVertexAttrib1sARB" "glstub_glVertexAttrib1sARB";
value glVertexAttrib1sv : int -> array int -> unit;
value glVertexAttrib1svARB : int -> array int -> unit;
external glVertexAttrib2d : int -> float -> float -> unit =
  "glstub_glVertexAttrib2d" "glstub_glVertexAttrib2d";
external glVertexAttrib2dARB : int -> float -> float -> unit =
  "glstub_glVertexAttrib2dARB" "glstub_glVertexAttrib2dARB";
external glVertexAttrib2dv : int -> array float -> unit =
  "glstub_glVertexAttrib2dv" "glstub_glVertexAttrib2dv";
external glVertexAttrib2dvARB : int -> array float -> unit =
  "glstub_glVertexAttrib2dvARB" "glstub_glVertexAttrib2dvARB";
external glVertexAttrib2f : int -> float -> float -> unit =
  "glstub_glVertexAttrib2f" "glstub_glVertexAttrib2f";
external glVertexAttrib2fARB : int -> float -> float -> unit =
  "glstub_glVertexAttrib2fARB" "glstub_glVertexAttrib2fARB";
value glVertexAttrib2fv : int -> array float -> unit;
value glVertexAttrib2fvARB : int -> array float -> unit;
external glVertexAttrib2s : int -> int -> int -> unit =
  "glstub_glVertexAttrib2s" "glstub_glVertexAttrib2s";
external glVertexAttrib2sARB : int -> int -> int -> unit =
  "glstub_glVertexAttrib2sARB" "glstub_glVertexAttrib2sARB";
value glVertexAttrib2sv : int -> array int -> unit;
value glVertexAttrib2svARB : int -> array int -> unit;
external glVertexAttrib3d : int -> float -> float -> float -> unit =
  "glstub_glVertexAttrib3d" "glstub_glVertexAttrib3d";
external glVertexAttrib3dARB : int -> float -> float -> float -> unit =
  "glstub_glVertexAttrib3dARB" "glstub_glVertexAttrib3dARB";
external glVertexAttrib3dv : int -> array float -> unit =
  "glstub_glVertexAttrib3dv" "glstub_glVertexAttrib3dv";
external glVertexAttrib3dvARB : int -> array float -> unit =
  "glstub_glVertexAttrib3dvARB" "glstub_glVertexAttrib3dvARB";
external glVertexAttrib3f : int -> float -> float -> float -> unit =
  "glstub_glVertexAttrib3f" "glstub_glVertexAttrib3f";
external glVertexAttrib3fARB : int -> float -> float -> float -> unit =
  "glstub_glVertexAttrib3fARB" "glstub_glVertexAttrib3fARB";
value glVertexAttrib3fv : int -> array float -> unit;
value glVertexAttrib3fvARB : int -> array float -> unit;
external glVertexAttrib3s : int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib3s" "glstub_glVertexAttrib3s";
external glVertexAttrib3sARB : int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib3sARB" "glstub_glVertexAttrib3sARB";
value glVertexAttrib3sv : int -> array int -> unit;
value glVertexAttrib3svARB : int -> array int -> unit;
value glVertexAttrib4Nbv : int -> array int -> unit;
value glVertexAttrib4NbvARB : int -> array int -> unit;
value glVertexAttrib4Niv : int -> array int -> unit;
value glVertexAttrib4NivARB : int -> array int -> unit;
value glVertexAttrib4Nsv : int -> array int -> unit;
value glVertexAttrib4NsvARB : int -> array int -> unit;
external glVertexAttrib4Nub : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4Nub" "glstub_glVertexAttrib4Nub";
external glVertexAttrib4NubARB : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4NubARB" "glstub_glVertexAttrib4NubARB";
value glVertexAttrib4Nubv : int -> array int -> unit;
value glVertexAttrib4NubvARB : int -> array int -> unit;
value glVertexAttrib4Nuiv : int -> array int -> unit;
value glVertexAttrib4NuivARB : int -> array int -> unit;
value glVertexAttrib4Nusv : int -> array int -> unit;
value glVertexAttrib4NusvARB : int -> array int -> unit;
value glVertexAttrib4bv : int -> array int -> unit;
value glVertexAttrib4bvARB : int -> array int -> unit;
external glVertexAttrib4d : int -> float -> float -> float -> float -> unit =
  "glstub_glVertexAttrib4d" "glstub_glVertexAttrib4d";
external glVertexAttrib4dARB :
  int -> float -> float -> float -> float -> unit =
  "glstub_glVertexAttrib4dARB" "glstub_glVertexAttrib4dARB";
external glVertexAttrib4dv : int -> array float -> unit =
  "glstub_glVertexAttrib4dv" "glstub_glVertexAttrib4dv";
external glVertexAttrib4dvARB : int -> array float -> unit =
  "glstub_glVertexAttrib4dvARB" "glstub_glVertexAttrib4dvARB";
external glVertexAttrib4f : int -> float -> float -> float -> float -> unit =
  "glstub_glVertexAttrib4f" "glstub_glVertexAttrib4f";
external glVertexAttrib4fARB :
  int -> float -> float -> float -> float -> unit =
  "glstub_glVertexAttrib4fARB" "glstub_glVertexAttrib4fARB";
value glVertexAttrib4fv : int -> array float -> unit;
value glVertexAttrib4fvARB : int -> array float -> unit;
value glVertexAttrib4iv : int -> array int -> unit;
value glVertexAttrib4ivARB : int -> array int -> unit;
external glVertexAttrib4s : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4s" "glstub_glVertexAttrib4s";
external glVertexAttrib4sARB : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4sARB" "glstub_glVertexAttrib4sARB";
value glVertexAttrib4sv : int -> array int -> unit;
value glVertexAttrib4svARB : int -> array int -> unit;
value glVertexAttrib4ubv : int -> array int -> unit;
value glVertexAttrib4ubvARB : int -> array int -> unit;
value glVertexAttrib4uiv : int -> array int -> unit;
value glVertexAttrib4uivARB : int -> array int -> unit;
value glVertexAttrib4usv : int -> array int -> unit;
value glVertexAttrib4usvARB : int -> array int -> unit;
external glVertexAttribPointer :
  int -> int -> int -> bool -> int -> 'a -> unit =
  "glstub_glVertexAttribPointer_byte" "glstub_glVertexAttribPointer";
external glVertexAttribPointerARB :
  int -> int -> int -> bool -> int -> 'a -> unit =
  "glstub_glVertexAttribPointerARB_byte" "glstub_glVertexAttribPointerARB";
external glVertexPointer : int -> int -> int -> 'a -> unit =
  "glstub_glVertexPointer" "glstub_glVertexPointer";
external glViewport : int -> int -> int -> int -> unit = "glstub_glViewport"
  "glstub_glViewport";
external glWindowPos2d : float -> float -> unit = "glstub_glWindowPos2d"
  "glstub_glWindowPos2d";
external glWindowPos2dARB : float -> float -> unit =
  "glstub_glWindowPos2dARB" "glstub_glWindowPos2dARB";
external glWindowPos2dv : array float -> unit = "glstub_glWindowPos2dv"
  "glstub_glWindowPos2dv";
external glWindowPos2dvARB : array float -> unit = "glstub_glWindowPos2dvARB"
  "glstub_glWindowPos2dvARB";
external glWindowPos2f : float -> float -> unit = "glstub_glWindowPos2f"
  "glstub_glWindowPos2f";
external glWindowPos2fARB : float -> float -> unit =
  "glstub_glWindowPos2fARB" "glstub_glWindowPos2fARB";
value glWindowPos2fv : array float -> unit;
value glWindowPos2fvARB : array float -> unit;
external glWindowPos2i : int -> int -> unit = "glstub_glWindowPos2i"
  "glstub_glWindowPos2i";
external glWindowPos2iARB : int -> int -> unit = "glstub_glWindowPos2iARB"
  "glstub_glWindowPos2iARB";
value glWindowPos2iv : array int -> unit;
value glWindowPos2ivARB : array int -> unit;
external glWindowPos2s : int -> int -> unit = "glstub_glWindowPos2s"
  "glstub_glWindowPos2s";
external glWindowPos2sARB : int -> int -> unit = "glstub_glWindowPos2sARB"
  "glstub_glWindowPos2sARB";
value glWindowPos2sv : array int -> unit;
value glWindowPos2svARB : array int -> unit;
external glWindowPos3d : float -> float -> float -> unit =
  "glstub_glWindowPos3d" "glstub_glWindowPos3d";
external glWindowPos3dARB : float -> float -> float -> unit =
  "glstub_glWindowPos3dARB" "glstub_glWindowPos3dARB";
external glWindowPos3dv : array float -> unit = "glstub_glWindowPos3dv"
  "glstub_glWindowPos3dv";
external glWindowPos3dvARB : array float -> unit = "glstub_glWindowPos3dvARB"
  "glstub_glWindowPos3dvARB";
external glWindowPos3f : float -> float -> float -> unit =
  "glstub_glWindowPos3f" "glstub_glWindowPos3f";
external glWindowPos3fARB : float -> float -> float -> unit =
  "glstub_glWindowPos3fARB" "glstub_glWindowPos3fARB";
value glWindowPos3fv : array float -> unit;
value glWindowPos3fvARB : array float -> unit;
external glWindowPos3i : int -> int -> int -> unit = "glstub_glWindowPos3i"
  "glstub_glWindowPos3i";
external glWindowPos3iARB : int -> int -> int -> unit =
  "glstub_glWindowPos3iARB" "glstub_glWindowPos3iARB";
value glWindowPos3iv : array int -> unit;
value glWindowPos3ivARB : array int -> unit;
external glWindowPos3s : int -> int -> int -> unit = "glstub_glWindowPos3s"
  "glstub_glWindowPos3s";
external glWindowPos3sARB : int -> int -> int -> unit =
  "glstub_glWindowPos3sARB" "glstub_glWindowPos3sARB";
value glWindowPos3sv : array int -> unit;
value glWindowPos3svARB : array int -> unit;

