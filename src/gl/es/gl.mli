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
value gl_depth_buffer_bit : int;
value gl_stencil_buffer_bit : int;
value gl_color_buffer_bit : int;
value gl_false : int;
value gl_true : int;
value gl_points : int;
value gl_lines : int;
value gl_line_loop : int;
value gl_line_strip : int;
value gl_triangles : int;
value gl_triangle_strip : int;
value gl_triangle_fan : int;
value gl_never : int;
value gl_less : int;
value gl_equal : int;
value gl_lequal : int;
value gl_greater : int;
value gl_notequal : int;
value gl_gequal : int;
value gl_always : int;
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
value gl_clip_plane0 : int;
value gl_clip_plane1 : int;
value gl_clip_plane2 : int;
value gl_clip_plane3 : int;
value gl_clip_plane4 : int;
value gl_clip_plane5 : int;
value gl_front : int;
value gl_back : int;
value gl_front_and_back : int;
value gl_fog : int;
value gl_lighting : int;
value gl_texture_2d : int;
value gl_cull_face : int;
value gl_alpha_test : int;
value gl_blend : int;
value gl_color_logic_op : int;
value gl_dither : int;
value gl_stencil_test : int;
value gl_depth_test : int;
value gl_point_smooth : int;
value gl_line_smooth : int;
value gl_color_material : int;
value gl_normalize : int;
value gl_rescale_normal : int;
value gl_vertex_array : int;
value gl_normal_array : int;
value gl_color_array : int;
value gl_texture_coord_array : int;
value gl_multisample : int;
value gl_sample_alpha_to_coverage : int;
value gl_sample_alpha_to_one : int;
value gl_sample_coverage : int;
value gl_no_error : int;
value gl_invalid_enum : int;
value gl_invalid_value : int;
value gl_invalid_operation : int;
value gl_stack_overflow : int;
value gl_stack_underflow : int;
value gl_out_of_memory : int;
value gl_exp : int;
value gl_exp2 : int;
value gl_fog_density : int;
value gl_fog_start : int;
value gl_fog_end : int;
value gl_fog_mode : int;
value gl_fog_color : int;
value gl_cw : int;
value gl_ccw : int;
value gl_current_color : int;
value gl_current_normal : int;
value gl_current_texture_coords : int;
value gl_point_size : int;
value gl_point_size_min : int;
value gl_point_size_max : int;
value gl_point_fade_threshold_size : int;
value gl_point_distance_attenuation : int;
value gl_smooth_point_size_range : int;
value gl_line_width : int;
value gl_smooth_line_width_range : int;
value gl_aliased_point_size_range : int;
value gl_aliased_line_width_range : int;
value gl_cull_face_mode : int;
value gl_front_face : int;
value gl_shade_model : int;
value gl_depth_range : int;
value gl_depth_writemask : int;
value gl_depth_clear_value : int;
value gl_depth_func : int;
value gl_stencil_clear_value : int;
value gl_stencil_func : int;
value gl_stencil_value_mask : int;
value gl_stencil_fail : int;
value gl_stencil_pass_depth_fail : int;
value gl_stencil_pass_depth_pass : int;
value gl_stencil_ref : int;
value gl_stencil_writemask : int;
value gl_matrix_mode : int;
value gl_viewport : int;
value gl_modelview_stack_depth : int;
value gl_projection_stack_depth : int;
value gl_texture_stack_depth : int;
value gl_modelview_matrix : int;
value gl_projection_matrix : int;
value gl_texture_matrix : int;
value gl_alpha_test_func : int;
value gl_alpha_test_ref : int;
value gl_blend_dst : int;
value gl_blend_src : int;
value gl_logic_op_mode : int;
value gl_scissor_box : int;
value gl_scissor_test : int;
value gl_color_clear_value : int;
value gl_color_writemask : int;
value gl_max_lights : int;
value gl_max_clip_planes : int;
value gl_max_texture_size : int;
value gl_max_modelview_stack_depth : int;
value gl_max_projection_stack_depth : int;
value gl_max_texture_stack_depth : int;
value gl_max_viewport_dims : int;
value gl_max_texture_units : int;
value gl_subpixel_bits : int;
value gl_red_bits : int;
value gl_green_bits : int;
value gl_blue_bits : int;
value gl_alpha_bits : int;
value gl_depth_bits : int;
value gl_stencil_bits : int;
value gl_polygon_offset_units : int;
value gl_polygon_offset_fill : int;
value gl_polygon_offset_factor : int;
value gl_texture_binding_2d : int;
value gl_vertex_array_size : int;
value gl_vertex_array_type : int;
value gl_vertex_array_stride : int;
value gl_normal_array_type : int;
value gl_normal_array_stride : int;
value gl_color_array_size : int;
value gl_color_array_type : int;
value gl_color_array_stride : int;
value gl_texture_coord_array_size : int;
value gl_texture_coord_array_type : int;
value gl_texture_coord_array_stride : int;
value gl_vertex_array_pointer : int;
value gl_normal_array_pointer : int;
value gl_color_array_pointer : int;
value gl_texture_coord_array_pointer : int;
value gl_sample_buffers : int;
value gl_samples : int;
value gl_sample_coverage_value : int;
value gl_sample_coverage_invert : int;
value gl_implementation_color_read_type_oes : int;
value gl_implementation_color_read_format_oes : int;
value gl_num_compressed_texture_formats : int;
value gl_compressed_texture_formats : int;
value gl_dont_care : int;
value gl_fastest : int;
value gl_nicest : int;
value gl_perspective_correction_hint : int;
value gl_point_smooth_hint : int;
value gl_line_smooth_hint : int;
value gl_fog_hint : int;
value gl_generate_mipmap_hint : int;
value gl_light_model_ambient : int;
value gl_light_model_two_side : int;
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
value gl_byte : int;
value gl_unsigned_byte : int;
value gl_short : int;
value gl_unsigned_short : int;
value gl_float : int;
value gl_fixed : int;
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
value gl_modelview : int;
value gl_projection : int;
value gl_texture : int;
value gl_alpha : int;
value gl_rgb : int;
value gl_rgba : int;
value gl_luminance : int;
value gl_luminance_alpha : int;
value gl_unpack_alignment : int;
value gl_pack_alignment : int;
value gl_unsigned_short_4_4_4_4 : int;
value gl_unsigned_short_5_5_5_1 : int;
value gl_unsigned_short_5_6_5 : int;
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
value gl_modulate : int;
value gl_decal : int;
value gl_add : int;
value gl_texture_env_mode : int;
value gl_texture_env_color : int;
value gl_texture_env : int;
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
value gl_generate_mipmap : int;
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
value gl_repeat : int;
value gl_clamp_to_edge : int;
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
value gl_light0 : int;
value gl_light1 : int;
value gl_light2 : int;
value gl_light3 : int;
value gl_light4 : int;
value gl_light5 : int;
value gl_light6 : int;
value gl_light7 : int;
value gl_array_buffer : int;
value gl_element_array_buffer : int;
value gl_array_buffer_binding : int;
value gl_element_array_buffer_binding : int;
value gl_vertex_array_buffer_binding : int;
value gl_normal_array_buffer_binding : int;
value gl_color_array_buffer_binding : int;
value gl_texture_coord_array_buffer_binding : int;
value gl_static_draw : int;
value gl_dynamic_draw : int;
value gl_buffer_size : int;
value gl_buffer_usage : int;
value gl_subtract : int;
value gl_combine : int;
value gl_combine_rgb : int;
value gl_combine_alpha : int;
value gl_rgb_scale : int;
value gl_add_signed : int;
value gl_interpolate : int;
value gl_constant : int;
value gl_primary_color : int;
value gl_previous : int;
value gl_operand0_rgb : int;
value gl_operand1_rgb : int;
value gl_operand2_rgb : int;
value gl_operand0_alpha : int;
value gl_operand1_alpha : int;
value gl_operand2_alpha : int;
value gl_alpha_scale : int;
value gl_src0_rgb : int;
value gl_src1_rgb : int;
value gl_src2_rgb : int;
value gl_src0_alpha : int;
value gl_src1_alpha : int;
value gl_src2_alpha : int;
value gl_dot3_rgb : int;
value gl_dot3_rgba : int;
value gl_texture_crop_rect_oes : int;
value gl_modelview_matrix_float_as_int_bits_oes : int;
value gl_projection_matrix_float_as_int_bits_oes : int;
value gl_texture_matrix_float_as_int_bits_oes : int;
value gl_max_vertex_units_oes : int;
value gl_max_palette_matrices_oes : int;
value gl_matrix_palette_oes : int;
value gl_matrix_index_array_oes : int;
value gl_weight_array_oes : int;
value gl_current_palette_matrix_oes : int;
value gl_matrix_index_array_size_oes : int;
value gl_matrix_index_array_type_oes : int;
value gl_matrix_index_array_stride_oes : int;
value gl_matrix_index_array_pointer_oes : int;
value gl_matrix_index_array_buffer_binding_oes : int;
value gl_weight_array_size_oes : int;
value gl_weight_array_type_oes : int;
value gl_weight_array_stride_oes : int;
value gl_weight_array_pointer_oes : int;
value gl_weight_array_buffer_binding_oes : int;
value gl_point_size_array_oes : int;
value gl_point_size_array_type_oes : int;
value gl_point_size_array_stride_oes : int;
value gl_point_size_array_pointer_oes : int;
value gl_point_size_array_buffer_binding_oes : int;
value gl_point_sprite_oes : int;
value gl_coord_replace_oes : int;
value gl_compressed_rgb_pvrtc_4bppv1_img : int;
value gl_compressed_rgb_pvrtc_2bppv1_img : int;
value gl_compressed_rgba_pvrtc_4bppv1_img : int;
value gl_compressed_rgba_pvrtc_2bppv1_img : int;
value gl_framebuffer_oes : int;
value gl_color_attachment0_oes : int;
value gl_depth_attachment_oes : int;
value gl_stencil_attachment_oes : int;
value gl_framebuffer_complete_oes : int;
value gl_framebuffer_binding_oes : int;
external glActiveTexture : int -> unit = "glstub_glActiveTexture"
  "glstub_glActiveTexture";
external glAlphaFunc : int -> float -> unit = "glstub_glAlphaFunc"
  "glstub_glAlphaFunc";
external glBindBuffer : int -> int -> unit = "glstub_glBindBuffer"
  "glstub_glBindBuffer";
external glBindFramebufferOES : int -> int -> unit =
  "glstub_glBindFramebufferOES" "glstub_glBindFramebufferOES";
external glBindTexture : int -> int -> unit = "glstub_glBindTexture"
  "glstub_glBindTexture";
external glBlendFunc : int -> int -> unit = "glstub_glBlendFunc"
  "glstub_glBlendFunc";
external glBufferData : int -> int -> 'a -> int -> unit =
  "glstub_glBufferData" "glstub_glBufferData";
external glBufferSubData : int -> int -> int -> 'a -> unit =
  "glstub_glBufferSubData" "glstub_glBufferSubData";
external glCheckFramebufferStatusOES : int -> int =
  "glstub_glCheckFramebufferStatusOES" "glstub_glCheckFramebufferStatusOES";
external glClear : int -> unit = "glstub_glClear" "glstub_glClear";
external glClearColor : float -> float -> float -> float -> unit =
  "glstub_glClearColor" "glstub_glClearColor";
external glClearDepthf : float -> unit = "glstub_glClearDepthf"
  "glstub_glClearDepthf";
external glClearStencil : int -> unit = "glstub_glClearStencil"
  "glstub_glClearStencil";
external glClientActiveTexture : int -> unit = "glstub_glClientActiveTexture"
  "glstub_glClientActiveTexture";
value glClipPlanef : int -> array float -> unit;
external glColor4f : float -> float -> float -> float -> unit =
  "glstub_glColor4f" "glstub_glColor4f";
external glColor4ub : int -> int -> int -> int -> unit = "glstub_glColor4ub"
  "glstub_glColor4ub";
external glColorMask : bool -> bool -> bool -> bool -> unit =
  "glstub_glColorMask" "glstub_glColorMask";
external glColorPointer : int -> int -> int -> 'a -> unit =
  "glstub_glColorPointer" "glstub_glColorPointer";
external glCompressedTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage2D_byte" "glstub_glCompressedTexImage2D";
external glCompressedTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage2D_byte" "glstub_glCompressedTexSubImage2D";
external glCopyTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexImage2D_byte" "glstub_glCopyTexImage2D";
external glCopyTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexSubImage2D_byte" "glstub_glCopyTexSubImage2D";
external glCullFace : int -> unit = "glstub_glCullFace" "glstub_glCullFace";
external glCurrentPaletteMatrixOES : int -> unit =
  "glstub_glCurrentPaletteMatrixOES" "glstub_glCurrentPaletteMatrixOES";
value glDeleteBuffers : int -> array int -> unit;
value glDeleteFramebuffersOES : int -> array int -> unit;
value glDeleteTextures : int -> array int -> unit;
external glDepthFunc : int -> unit = "glstub_glDepthFunc"
  "glstub_glDepthFunc";
external glDepthMask : bool -> unit = "glstub_glDepthMask"
  "glstub_glDepthMask";
external glDepthRangef : float -> float -> unit = "glstub_glDepthRangef"
  "glstub_glDepthRangef";
external glDisable : int -> unit = "glstub_glDisable" "glstub_glDisable";
external glDisableClientState : int -> unit = "glstub_glDisableClientState"
  "glstub_glDisableClientState";
external glDrawArrays : int -> int -> int -> unit = "glstub_glDrawArrays"
  "glstub_glDrawArrays";
external glDrawElements : int -> int -> int -> 'a -> unit =
  "glstub_glDrawElements" "glstub_glDrawElements";
external glDrawTexfOES : float -> float -> float -> float -> float -> unit =
  "glstub_glDrawTexfOES" "glstub_glDrawTexfOES";
value glDrawTexfvOES : array float -> unit;
external glDrawTexiOES : int -> int -> int -> int -> int -> unit =
  "glstub_glDrawTexiOES" "glstub_glDrawTexiOES";
value glDrawTexivOES : array int -> unit;
external glDrawTexsOES : int -> int -> int -> int -> int -> unit =
  "glstub_glDrawTexsOES" "glstub_glDrawTexsOES";
value glDrawTexsvOES : array int -> unit;
external glEnable : int -> unit = "glstub_glEnable" "glstub_glEnable";
external glEnableClientState : int -> unit = "glstub_glEnableClientState"
  "glstub_glEnableClientState";
external glFinish : unit -> unit = "glstub_glFinish" "glstub_glFinish";
external glFlush : unit -> unit = "glstub_glFlush" "glstub_glFlush";
external glFogf : int -> float -> unit = "glstub_glFogf" "glstub_glFogf";
value glFogfv : int -> array float -> unit;
external glFramebufferRenderbufferOES : int -> int -> int -> int -> unit =
  "glstub_glFramebufferRenderbufferOES"
  "glstub_glFramebufferRenderbufferOES";
external glFramebufferTexture2DOES :
  int -> int -> int -> int -> int -> unit =
  "glstub_glFramebufferTexture2DOES" "glstub_glFramebufferTexture2DOES";
external glFrontFace : int -> unit = "glstub_glFrontFace"
  "glstub_glFrontFace";
external glFrustumf :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glFrustumf_byte" "glstub_glFrustumf";
value glGenBuffers : int -> array int -> unit;
value glGenFramebuffersOES : int -> array int -> unit;
value glGenTextures : int -> array int -> unit;
external glGenerateMipmapOES : int -> unit = "glstub_glGenerateMipmapOES"
  "glstub_glGenerateMipmapOES";
value glGetBooleanv : int -> array bool -> unit;
value glGetBufferParameteriv : int -> int -> array int -> unit;
value glGetClipPlanef : int -> array float -> unit;
external glGetError : unit -> int = "glstub_glGetError" "glstub_glGetError";
value glGetFloatv : int -> array float -> unit;
value glGetIntegerv : int -> array int -> unit;
value glGetLightfv : int -> int -> array float -> unit;
value glGetMaterialfv : int -> int -> array float -> unit;
value glGetTexEnvfv : int -> int -> array float -> unit;
value glGetTexEnviv : int -> int -> array int -> unit;
value glGetTexParameterfv : int -> int -> array float -> unit;
value glGetTexParameteriv : int -> int -> array int -> unit;
external glHint : int -> int -> unit = "glstub_glHint" "glstub_glHint";
external glIsBuffer : int -> bool = "glstub_glIsBuffer" "glstub_glIsBuffer";
external glIsEnabled : int -> bool = "glstub_glIsEnabled"
  "glstub_glIsEnabled";
external glIsTexture : int -> bool = "glstub_glIsTexture"
  "glstub_glIsTexture";
external glLightModelf : int -> float -> unit = "glstub_glLightModelf"
  "glstub_glLightModelf";
value glLightModelfv : int -> array float -> unit;
external glLightf : int -> int -> float -> unit = "glstub_glLightf"
  "glstub_glLightf";
value glLightfv : int -> int -> array float -> unit;
external glLineWidth : float -> unit = "glstub_glLineWidth"
  "glstub_glLineWidth";
external glLoadIdentity : unit -> unit = "glstub_glLoadIdentity"
  "glstub_glLoadIdentity";
value glLoadMatrixf : array float -> unit;
external glLoadPaletteFromModelViewMatrixOES : unit -> unit =
  "glstub_glLoadPaletteFromModelViewMatrixOES"
  "glstub_glLoadPaletteFromModelViewMatrixOES";
external glLogicOp : int -> unit = "glstub_glLogicOp" "glstub_glLogicOp";
external glMaterialf : int -> int -> float -> unit = "glstub_glMaterialf"
  "glstub_glMaterialf";
value glMaterialfv : int -> int -> array float -> unit;
external glMatrixIndexPointerOES : int -> int -> int -> 'a -> unit =
  "glstub_glMatrixIndexPointerOES" "glstub_glMatrixIndexPointerOES";
external glMatrixMode : int -> unit = "glstub_glMatrixMode"
  "glstub_glMatrixMode";
value glMultMatrixf : array float -> unit;
external glMultiTexCoord4f :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4f" "glstub_glMultiTexCoord4f";
external glNormal3f : float -> float -> float -> unit = "glstub_glNormal3f"
  "glstub_glNormal3f";
external glNormalPointer : int -> int -> 'a -> unit =
  "glstub_glNormalPointer" "glstub_glNormalPointer";
external glOrthof :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glOrthof_byte" "glstub_glOrthof";
external glPixelStorei : int -> int -> unit = "glstub_glPixelStorei"
  "glstub_glPixelStorei";
external glPointParameterf : int -> float -> unit =
  "glstub_glPointParameterf" "glstub_glPointParameterf";
value glPointParameterfv : int -> array float -> unit;
external glPointSize : float -> unit = "glstub_glPointSize"
  "glstub_glPointSize";
external glPointSizePointerOES : int -> int -> 'a -> unit =
  "glstub_glPointSizePointerOES" "glstub_glPointSizePointerOES";
external glPolygonOffset : float -> float -> unit = "glstub_glPolygonOffset"
  "glstub_glPolygonOffset";
external glPopMatrix : unit -> unit = "glstub_glPopMatrix"
  "glstub_glPopMatrix";
external glPushMatrix : unit -> unit = "glstub_glPushMatrix"
  "glstub_glPushMatrix";
external glReadPixels :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glReadPixels_byte" "glstub_glReadPixels";
external glRotatef : float -> float -> float -> float -> unit =
  "glstub_glRotatef" "glstub_glRotatef";
external glSampleCoverage : float -> bool -> unit = "glstub_glSampleCoverage"
  "glstub_glSampleCoverage";
external glScalef : float -> float -> float -> unit = "glstub_glScalef"
  "glstub_glScalef";
external glScissor : int -> int -> int -> int -> unit = "glstub_glScissor"
  "glstub_glScissor";
external glShadeModel : int -> unit = "glstub_glShadeModel"
  "glstub_glShadeModel";
external glStencilFunc : int -> int -> int -> unit = "glstub_glStencilFunc"
  "glstub_glStencilFunc";
external glStencilMask : int -> unit = "glstub_glStencilMask"
  "glstub_glStencilMask";
external glStencilOp : int -> int -> int -> unit = "glstub_glStencilOp"
  "glstub_glStencilOp";
external glTexCoordPointer : int -> int -> int -> 'a -> unit =
  "glstub_glTexCoordPointer" "glstub_glTexCoordPointer";
external glTexEnvf : int -> int -> float -> unit = "glstub_glTexEnvf"
  "glstub_glTexEnvf";
value glTexEnvfv : int -> int -> array float -> unit;
external glTexEnvi : int -> int -> int -> unit = "glstub_glTexEnvi"
  "glstub_glTexEnvi";
value glTexEnviv : int -> int -> array int -> unit;
external glTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexImage2D_byte" "glstub_glTexImage2D";
external glTexParameterf : int -> int -> float -> unit =
  "glstub_glTexParameterf" "glstub_glTexParameterf";
value glTexParameterfv : int -> int -> array float -> unit;
external glTexParameteri : int -> int -> int -> unit =
  "glstub_glTexParameteri" "glstub_glTexParameteri";
value glTexParameteriv : int -> int -> array int -> unit;
external glTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexSubImage2D_byte" "glstub_glTexSubImage2D";
external glTranslatef : float -> float -> float -> unit =
  "glstub_glTranslatef" "glstub_glTranslatef";
external glVertexPointer : int -> int -> int -> 'a -> unit =
  "glstub_glVertexPointer" "glstub_glVertexPointer";
external glViewport : int -> int -> int -> int -> unit = "glstub_glViewport"
  "glstub_glViewport";
external glWeightPointerOES : int -> int -> int -> 'a -> unit =
  "glstub_glWeightPointerOES" "glstub_glWeightPointerOES";

