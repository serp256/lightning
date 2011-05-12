(*
 * GLCaml - Objective Caml interface for OpenGL 1.1, 1.2, 1.3, 1.4, 1.5, 2.0 and 2.1
 * plus extensions: 
 * 
 * Copyright (C) 2007, 2008 Elliott OTI
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
(** 1-dimensional array definitions for 
	- 8-bit signed bytes
	- 8-bit unsigned bytes
	- 16 bits signed words
	- 16 bits unsigned words
	- 32 bit signed words
	- 64 bit signed words
	- native word size
	- 32 bit IEEE floats 
	- 64 bit IEEE floats *)
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
(** 2-dimensional array definitions for 
	- 8-bit signed bytes
	- 8-bit unsigned bytes
	- 16 bits signed words
	- 16 bits unsigned words
	- 32 bit signed words
	- 64 bit signed words
	- native word size
	- 32 bit IEEE floats 
	- 64 bit IEEE floats *)
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
(** Create 1-dimensional arrays of the following types:
	- 8-bit signed bytes
	- 8-bit unsigned bytes
	- 16 bits signed words
	- 16 bits unsigned words
	- 32 bit signed words
	- 64 bit signed words
	- native word size
	- 32 bit IEEE floats 
	- 64 bit IEEE floats *)
value make_byte_array len =
  Bigarray.Array1.create Bigarray.int8_signed Bigarray.c_layout len;
value make_ubyte_array len =
  Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout len;
value make_short_array len =
  Bigarray.Array1.create Bigarray.int16_signed Bigarray.c_layout len;
value make_ushort_array len =
  Bigarray.Array1.create Bigarray.int16_unsigned Bigarray.c_layout len;
value make_word_array len =
  Bigarray.Array1.create Bigarray.int32 Bigarray.c_layout len;
value make_dword_array len =
  Bigarray.Array1.create Bigarray.int64 Bigarray.c_layout len;
value make_int_array len =
  Bigarray.Array1.create Bigarray.int Bigarray.c_layout len;
value make_float_array len =
  Bigarray.Array1.create Bigarray.float32 Bigarray.c_layout len;
value make_double_array len =
  Bigarray.Array1.create Bigarray.float64 Bigarray.c_layout len;
(** Create 2-dimensional arrays of the following types:
	- 8-bit signed bytes
	- 8-bit unsigned bytes
	- 16 bits signed words
	- 16 bits unsigned words
	- 32 bit signed words
	- 64 bit signed words
	- native word size
	- 32 bit IEEE floats 
	- 64 bit IEEE floats *)
value make_byte_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int8_signed Bigarray.c_layout dim1 dim2;
value make_ubyte_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int8_unsigned Bigarray.c_layout dim1 dim2;
value make_short_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int16_signed Bigarray.c_layout dim1 dim2;
value make_ushort_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int16_unsigned Bigarray.c_layout dim1 dim2;
value make_word_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int32 Bigarray.c_layout dim1 dim2;
value make_dword_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int64 Bigarray.c_layout dim1 dim2;
value make_int_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.int Bigarray.c_layout dim1 dim2;
value make_float_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.float32 Bigarray.c_layout dim1 dim2;
value make_double_matrix dim1 dim2 =
  Bigarray.Array2.create Bigarray.float64 Bigarray.c_layout dim1 dim2;
(** Conversions between native Ocaml arrays and bigarrays for
	- int arrays to byte_arrays
	- int arrays to ubyte_arrays
	- int arrays to short_arrays
	- int arrays to ushort_arrays
	- int arrays to int_arrays
	- float arrays to float_arrays
	- float arrays to double_arrays
*)
value to_byte_array a =
  Bigarray.Array1.of_array Bigarray.int8_signed Bigarray.c_layout a;
value to_ubyte_array a =
  Bigarray.Array1.of_array Bigarray.int8_unsigned Bigarray.c_layout a;
value to_short_array a =
  Bigarray.Array1.of_array Bigarray.int16_signed Bigarray.c_layout a;
value to_ushort_array a =
  Bigarray.Array1.of_array Bigarray.int16_unsigned Bigarray.c_layout a;
value to_word_array a =
  let r = make_word_array (Array.length a) in
  let _ = Array.iteri (fun i a -> Bigarray.Array1.set r i (Int32.of_int a)) a
  in r;
value to_dword_array a =
  let r = make_dword_array (Array.length a) in
  let _ = Array.iteri (fun i a -> Bigarray.Array1.set r i (Int64.of_int a)) a
  in r;
value to_int_array a =
  let r = make_int_array (Array.length a) in
  let _ = Array.iteri (fun i a -> Bigarray.Array1.set r i a) a in r;
value to_float_array a =
  let r = make_float_array (Array.length a) in
  let _ = Array.iteri (fun i a -> Bigarray.Array1.set r i a) a in r;
value to_double_array a =
  let r = make_double_array (Array.length a) in
  let _ = Array.iteri (fun i a -> Bigarray.Array1.set r i a) a in r;
(**	Copy data between bigarrays and preallocated Ocaml arrays of 
	suitable length:
	- byte_array to int array
	- ubyte_array to int array
	- short_array to int array
	- ushort_array to int array
	- word_array to int array
	- dword_array to int array
	- float_array to float array
	- double_array to float array
*)
value copy_byte_array src dst =
  Array.iteri (fun i c -> dst.(i) := Bigarray.Array1.get src i) dst;
value copy_ubyte_array = copy_byte_array;
value copy_short_array = copy_byte_array;
value copy_ushort_array = copy_byte_array;
value copy_word_array src dst =
  Array.iteri
    (fun i c -> dst.(i) := Int32.to_int (Bigarray.Array1.get src i)) dst;
value copy_dword_array src dst =
  Array.iteri
    (fun i c -> dst.(i) := Int64.to_int (Bigarray.Array1.get src i)) dst;
value copy_float_array src dst = copy_byte_array;
value copy_double_array src dst = copy_byte_array;
(** Convert a byte_array or ubyte_array to a string *)
value to_string a =
  let l = Bigarray.Array1.dim a in
  let s = String.create l
  in (for i = 0 to l - 1 do s.[i] := Bigarray.Array1.get a i done; s);
(** Convert between booleans and ints *)
value int_of_bool b = if b then 1 else 0;
value bool_of_int i = not (i = 0);
value bool_to_int_array b = Array.map int_of_bool b;
value int_to_bool_array i = Array.map bool_of_int i;
value copy_to_bool_array src dst =
  Array.mapi (fun i c -> dst.(i) := bool_of_int src.(i)) dst;
value gl_constant_color = 0x00008001;
value gl_one_minus_constant_color = 0x00008002;
value gl_constant_alpha = 0x00008003;
value gl_one_minus_constant_alpha = 0x00008004;
value gl_blend_color = 0x00008005;
value gl_func_add = 0x00008006;
value gl_min = 0x00008007;
value gl_max = 0x00008008;
value gl_blend_equation = 0x00008009;
value gl_func_subtract = 0x0000800a;
value gl_func_reverse_subtract = 0x0000800b;
value gl_convolution_1d = 0x00008010;
value gl_convolution_2d = 0x00008011;
value gl_separable_2d = 0x00008012;
value gl_convolution_border_mode = 0x00008013;
value gl_convolution_filter_scale = 0x00008014;
value gl_convolution_filter_bias = 0x00008015;
value gl_reduce = 0x00008016;
value gl_convolution_format = 0x00008017;
value gl_convolution_width = 0x00008018;
value gl_convolution_height = 0x00008019;
value gl_max_convolution_width = 0x0000801a;
value gl_max_convolution_height = 0x0000801b;
value gl_post_convolution_red_scale = 0x0000801c;
value gl_post_convolution_green_scale = 0x0000801d;
value gl_post_convolution_blue_scale = 0x0000801e;
value gl_post_convolution_alpha_scale = 0x0000801f;
value gl_post_convolution_red_bias = 0x00008020;
value gl_post_convolution_green_bias = 0x00008021;
value gl_post_convolution_blue_bias = 0x00008022;
value gl_post_convolution_alpha_bias = 0x00008023;
value gl_histogram = 0x00008024;
value gl_proxy_histogram = 0x00008025;
value gl_histogram_width = 0x00008026;
value gl_histogram_format = 0x00008027;
value gl_histogram_red_size = 0x00008028;
value gl_histogram_green_size = 0x00008029;
value gl_histogram_blue_size = 0x0000802a;
value gl_histogram_alpha_size = 0x0000802b;
value gl_histogram_luminance_size = 0x0000802c;
value gl_histogram_sink = 0x0000802d;
value gl_minmax = 0x0000802e;
value gl_minmax_format = 0x0000802f;
value gl_minmax_sink = 0x00008030;
value gl_table_too_large = 0x00008031;
value gl_color_matrix = 0x000080b1;
value gl_color_matrix_stack_depth = 0x000080b2;
value gl_max_color_matrix_stack_depth = 0x000080b3;
value gl_post_color_matrix_red_scale = 0x000080b4;
value gl_post_color_matrix_green_scale = 0x000080b5;
value gl_post_color_matrix_blue_scale = 0x000080b6;
value gl_post_color_matrix_alpha_scale = 0x000080b7;
value gl_post_color_matrix_red_bias = 0x000080b8;
value gl_post_color_matrix_green_bias = 0x000080b9;
value gl_post_color_matrix_blue_bias = 0x000080ba;
value gl_post_color_matrix_alpha_bias = 0x000080bb;
value gl_color_table = 0x000080d0;
value gl_post_convolution_color_table = 0x000080d1;
value gl_post_color_matrix_color_table = 0x000080d2;
value gl_proxy_color_table = 0x000080d3;
value gl_proxy_post_convolution_color_table = 0x000080d4;
value gl_proxy_post_color_matrix_color_table = 0x000080d5;
value gl_color_table_scale = 0x000080d6;
value gl_color_table_bias = 0x000080d7;
value gl_color_table_format = 0x000080d8;
value gl_color_table_width = 0x000080d9;
value gl_color_table_red_size = 0x000080da;
value gl_color_table_green_size = 0x000080db;
value gl_color_table_blue_size = 0x000080dc;
value gl_color_table_alpha_size = 0x000080dd;
value gl_color_table_luminance_size = 0x000080de;
value gl_color_table_intensity_size = 0x000080df;
value gl_ignore_border = 0x00008150;
value gl_constant_border = 0x00008151;
value gl_wrap_border = 0x00008152;
value gl_replicate_border = 0x00008153;
value gl_convolution_border_color = 0x00008154;
value gl_texture0_arb = 0x000084c0;
value gl_texture1_arb = 0x000084c1;
value gl_texture2_arb = 0x000084c2;
value gl_texture3_arb = 0x000084c3;
value gl_texture4_arb = 0x000084c4;
value gl_texture5_arb = 0x000084c5;
value gl_texture6_arb = 0x000084c6;
value gl_texture7_arb = 0x000084c7;
value gl_texture8_arb = 0x000084c8;
value gl_texture9_arb = 0x000084c9;
value gl_texture10_arb = 0x000084ca;
value gl_texture11_arb = 0x000084cb;
value gl_texture12_arb = 0x000084cc;
value gl_texture13_arb = 0x000084cd;
value gl_texture14_arb = 0x000084ce;
value gl_texture15_arb = 0x000084cf;
value gl_texture16_arb = 0x000084d0;
value gl_texture17_arb = 0x000084d1;
value gl_texture18_arb = 0x000084d2;
value gl_texture19_arb = 0x000084d3;
value gl_texture20_arb = 0x000084d4;
value gl_texture21_arb = 0x000084d5;
value gl_texture22_arb = 0x000084d6;
value gl_texture23_arb = 0x000084d7;
value gl_texture24_arb = 0x000084d8;
value gl_texture25_arb = 0x000084d9;
value gl_texture26_arb = 0x000084da;
value gl_texture27_arb = 0x000084db;
value gl_texture28_arb = 0x000084dc;
value gl_texture29_arb = 0x000084dd;
value gl_texture30_arb = 0x000084de;
value gl_texture31_arb = 0x000084df;
value gl_active_texture_arb = 0x000084e0;
value gl_client_active_texture_arb = 0x000084e1;
value gl_max_texture_units_arb = 0x000084e2;
value gl_depth_component16_arb = 0x000081a5;
value gl_depth_component24_arb = 0x000081a6;
value gl_depth_component32_arb = 0x000081a7;
value gl_texture_depth_size_arb = 0x0000884a;
value gl_depth_texture_mode_arb = 0x0000884b;
value gl_max_draw_buffers_arb = 0x00008824;
value gl_draw_buffer0_arb = 0x00008825;
value gl_draw_buffer1_arb = 0x00008826;
value gl_draw_buffer2_arb = 0x00008827;
value gl_draw_buffer3_arb = 0x00008828;
value gl_draw_buffer4_arb = 0x00008829;
value gl_draw_buffer5_arb = 0x0000882a;
value gl_draw_buffer6_arb = 0x0000882b;
value gl_draw_buffer7_arb = 0x0000882c;
value gl_draw_buffer8_arb = 0x0000882d;
value gl_draw_buffer9_arb = 0x0000882e;
value gl_draw_buffer10_arb = 0x0000882f;
value gl_draw_buffer11_arb = 0x00008830;
value gl_draw_buffer12_arb = 0x00008831;
value gl_draw_buffer13_arb = 0x00008832;
value gl_draw_buffer14_arb = 0x00008833;
value gl_draw_buffer15_arb = 0x00008834;
value gl_fragment_program_arb = 0x00008804;
value gl_program_alu_instructions_arb = 0x00008805;
value gl_program_tex_instructions_arb = 0x00008806;
value gl_program_tex_indirections_arb = 0x00008807;
value gl_program_native_alu_instructions_arb = 0x00008808;
value gl_program_native_tex_instructions_arb = 0x00008809;
value gl_program_native_tex_indirections_arb = 0x0000880a;
value gl_max_program_alu_instructions_arb = 0x0000880b;
value gl_max_program_tex_instructions_arb = 0x0000880c;
value gl_max_program_tex_indirections_arb = 0x0000880d;
value gl_max_program_native_alu_instructions_arb = 0x0000880e;
value gl_max_program_native_tex_instructions_arb = 0x0000880f;
value gl_max_program_native_tex_indirections_arb = 0x00008810;
value gl_max_texture_coords_arb = 0x00008871;
value gl_max_texture_image_units_arb = 0x00008872;
value gl_fragment_shader_arb = 0x00008b30;
value gl_max_fragment_uniform_components_arb = 0x00008b49;
value gl_fragment_shader_derivative_hint_arb = 0x00008b8b;
value gl_half_float_arb = 0x0000140b;
value gl_multisample_arb = 0x0000809d;
value gl_sample_alpha_to_coverage_arb = 0x0000809e;
value gl_sample_alpha_to_one_arb = 0x0000809f;
value gl_sample_coverage_arb = 0x000080a0;
value gl_sample_buffers_arb = 0x000080a8;
value gl_samples_arb = 0x000080a9;
value gl_sample_coverage_value_arb = 0x000080aa;
value gl_sample_coverage_invert_arb = 0x000080ab;
value gl_multisample_bit_arb = 0x20000000;
value gl_query_counter_bits_arb = 0x00008864;
value gl_current_query_arb = 0x00008865;
value gl_query_result_arb = 0x00008866;
value gl_query_result_available_arb = 0x00008867;
value gl_samples_passed_arb = 0x00008914;
value gl_pixel_pack_buffer_arb = 0x000088eb;
value gl_pixel_unpack_buffer_arb = 0x000088ec;
value gl_pixel_pack_buffer_binding_arb = 0x000088ed;
value gl_pixel_unpack_buffer_binding_arb = 0x000088ef;
value gl_point_size_min_arb = 0x00008126;
value gl_point_size_max_arb = 0x00008127;
value gl_point_fade_threshold_size_arb = 0x00008128;
value gl_point_distance_attenuation_arb = 0x00008129;
value gl_point_sprite_arb = 0x00008861;
value gl_coord_replace_arb = 0x00008862;
value gl_program_object_arb = 0x00008b40;
value gl_shader_object_arb = 0x00008b48;
value gl_object_type_arb = 0x00008b4e;
value gl_object_subtype_arb = 0x00008b4f;
value gl_float_vec2_arb = 0x00008b50;
value gl_float_vec3_arb = 0x00008b51;
value gl_float_vec4_arb = 0x00008b52;
value gl_int_vec2_arb = 0x00008b53;
value gl_int_vec3_arb = 0x00008b54;
value gl_int_vec4_arb = 0x00008b55;
value gl_bool_arb = 0x00008b56;
value gl_bool_vec2_arb = 0x00008b57;
value gl_bool_vec3_arb = 0x00008b58;
value gl_bool_vec4_arb = 0x00008b59;
value gl_float_mat2_arb = 0x00008b5a;
value gl_float_mat3_arb = 0x00008b5b;
value gl_float_mat4_arb = 0x00008b5c;
value gl_sampler_1d_arb = 0x00008b5d;
value gl_sampler_2d_arb = 0x00008b5e;
value gl_sampler_3d_arb = 0x00008b5f;
value gl_sampler_cube_arb = 0x00008b60;
value gl_sampler_1d_shadow_arb = 0x00008b61;
value gl_sampler_2d_shadow_arb = 0x00008b62;
value gl_sampler_2d_rect_arb = 0x00008b63;
value gl_sampler_2d_rect_shadow_arb = 0x00008b64;
value gl_object_delete_status_arb = 0x00008b80;
value gl_object_compile_status_arb = 0x00008b81;
value gl_object_link_status_arb = 0x00008b82;
value gl_object_validate_status_arb = 0x00008b83;
value gl_object_info_log_length_arb = 0x00008b84;
value gl_object_attached_objects_arb = 0x00008b85;
value gl_object_active_uniforms_arb = 0x00008b86;
value gl_object_active_uniform_max_length_arb = 0x00008b87;
value gl_object_shader_source_length_arb = 0x00008b88;
value gl_shading_language_version_arb = 0x00008b8c;
value gl_texture_compare_mode_arb = 0x0000884c;
value gl_texture_compare_func_arb = 0x0000884d;
value gl_compare_r_to_texture_arb = 0x0000884e;
value gl_texture_compare_fail_value_arb = 0x000080bf;
value gl_clamp_to_border_arb = 0x0000812d;
value gl_compressed_alpha_arb = 0x000084e9;
value gl_compressed_luminance_arb = 0x000084ea;
value gl_compressed_luminance_alpha_arb = 0x000084eb;
value gl_compressed_intensity_arb = 0x000084ec;
value gl_compressed_rgb_arb = 0x000084ed;
value gl_compressed_rgba_arb = 0x000084ee;
value gl_texture_compression_hint_arb = 0x000084ef;
value gl_texture_compressed_image_size_arb = 0x000086a0;
value gl_texture_compressed_arb = 0x000086a1;
value gl_num_compressed_texture_formats_arb = 0x000086a2;
value gl_compressed_texture_formats_arb = 0x000086a3;
value gl_normal_map_arb = 0x00008511;
value gl_reflection_map_arb = 0x00008512;
value gl_texture_cube_map_arb = 0x00008513;
value gl_texture_binding_cube_map_arb = 0x00008514;
value gl_texture_cube_map_positive_x_arb = 0x00008515;
value gl_texture_cube_map_negative_x_arb = 0x00008516;
value gl_texture_cube_map_positive_y_arb = 0x00008517;
value gl_texture_cube_map_negative_y_arb = 0x00008518;
value gl_texture_cube_map_positive_z_arb = 0x00008519;
value gl_texture_cube_map_negative_z_arb = 0x0000851a;
value gl_proxy_texture_cube_map_arb = 0x0000851b;
value gl_max_cube_map_texture_size_arb = 0x0000851c;
value gl_subtract_arb = 0x000084e7;
value gl_combine_arb = 0x00008570;
value gl_combine_rgb_arb = 0x00008571;
value gl_combine_alpha_arb = 0x00008572;
value gl_rgb_scale_arb = 0x00008573;
value gl_add_signed_arb = 0x00008574;
value gl_interpolate_arb = 0x00008575;
value gl_constant_arb = 0x00008576;
value gl_primary_color_arb = 0x00008577;
value gl_previous_arb = 0x00008578;
value gl_source0_rgb_arb = 0x00008580;
value gl_source1_rgb_arb = 0x00008581;
value gl_source2_rgb_arb = 0x00008582;
value gl_source0_alpha_arb = 0x00008588;
value gl_source1_alpha_arb = 0x00008589;
value gl_source2_alpha_arb = 0x0000858a;
value gl_operand0_rgb_arb = 0x00008590;
value gl_operand1_rgb_arb = 0x00008591;
value gl_operand2_rgb_arb = 0x00008592;
value gl_operand0_alpha_arb = 0x00008598;
value gl_operand1_alpha_arb = 0x00008599;
value gl_operand2_alpha_arb = 0x0000859a;
value gl_dot3_rgb_arb = 0x000086ae;
value gl_dot3_rgba_arb = 0x000086af;
value gl_rgba32f_arb = 0x00008814;
value gl_rgb32f_arb = 0x00008815;
value gl_alpha32f_arb = 0x00008816;
value gl_intensity32f_arb = 0x00008817;
value gl_luminance32f_arb = 0x00008818;
value gl_luminance_alpha32f_arb = 0x00008819;
value gl_rgba16f_arb = 0x0000881a;
value gl_rgb16f_arb = 0x0000881b;
value gl_alpha16f_arb = 0x0000881c;
value gl_intensity16f_arb = 0x0000881d;
value gl_luminance16f_arb = 0x0000881e;
value gl_luminance_alpha16f_arb = 0x0000881f;
value gl_texture_red_type_arb = 0x00008c10;
value gl_texture_green_type_arb = 0x00008c11;
value gl_texture_blue_type_arb = 0x00008c12;
value gl_texture_alpha_type_arb = 0x00008c13;
value gl_texture_luminance_type_arb = 0x00008c14;
value gl_texture_intensity_type_arb = 0x00008c15;
value gl_texture_depth_type_arb = 0x00008c16;
value gl_unsigned_normalized_arb = 0x00008c17;
value gl_mirrored_repeat_arb = 0x00008370;
value gl_texture_rectangle_arb = 0x000084f5;
value gl_texture_binding_rectangle_arb = 0x000084f6;
value gl_proxy_texture_rectangle_arb = 0x000084f7;
value gl_max_rectangle_texture_size_arb = 0x000084f8;
value gl_transpose_modelview_matrix_arb = 0x000084e3;
value gl_transpose_projection_matrix_arb = 0x000084e4;
value gl_transpose_texture_matrix_arb = 0x000084e5;
value gl_transpose_color_matrix_arb = 0x000084e6;
value gl_buffer_size_arb = 0x00008764;
value gl_buffer_usage_arb = 0x00008765;
value gl_array_buffer_arb = 0x00008892;
value gl_element_array_buffer_arb = 0x00008893;
value gl_array_buffer_binding_arb = 0x00008894;
value gl_element_array_buffer_binding_arb = 0x00008895;
value gl_vertex_array_buffer_binding_arb = 0x00008896;
value gl_normal_array_buffer_binding_arb = 0x00008897;
value gl_color_array_buffer_binding_arb = 0x00008898;
value gl_index_array_buffer_binding_arb = 0x00008899;
value gl_texture_coord_array_buffer_binding_arb = 0x0000889a;
value gl_edge_flag_array_buffer_binding_arb = 0x0000889b;
value gl_secondary_color_array_buffer_binding_arb = 0x0000889c;
value gl_fog_coordinate_array_buffer_binding_arb = 0x0000889d;
value gl_weight_array_buffer_binding_arb = 0x0000889e;
value gl_vertex_attrib_array_buffer_binding_arb = 0x0000889f;
value gl_read_only_arb = 0x000088b8;
value gl_write_only_arb = 0x000088b9;
value gl_read_write_arb = 0x000088ba;
value gl_buffer_access_arb = 0x000088bb;
value gl_buffer_mapped_arb = 0x000088bc;
value gl_buffer_map_pointer_arb = 0x000088bd;
value gl_stream_draw_arb = 0x000088e0;
value gl_stream_read_arb = 0x000088e1;
value gl_stream_copy_arb = 0x000088e2;
value gl_static_draw_arb = 0x000088e4;
value gl_static_read_arb = 0x000088e5;
value gl_static_copy_arb = 0x000088e6;
value gl_dynamic_draw_arb = 0x000088e8;
value gl_dynamic_read_arb = 0x000088e9;
value gl_dynamic_copy_arb = 0x000088ea;
value gl_color_sum_arb = 0x00008458;
value gl_vertex_program_arb = 0x00008620;
value gl_vertex_attrib_array_enabled_arb = 0x00008622;
value gl_vertex_attrib_array_size_arb = 0x00008623;
value gl_vertex_attrib_array_stride_arb = 0x00008624;
value gl_vertex_attrib_array_type_arb = 0x00008625;
value gl_current_vertex_attrib_arb = 0x00008626;
value gl_program_length_arb = 0x00008627;
value gl_program_string_arb = 0x00008628;
value gl_max_program_matrix_stack_depth_arb = 0x0000862e;
value gl_max_program_matrices_arb = 0x0000862f;
value gl_current_matrix_stack_depth_arb = 0x00008640;
value gl_current_matrix_arb = 0x00008641;
value gl_vertex_program_point_size_arb = 0x00008642;
value gl_vertex_program_two_side_arb = 0x00008643;
value gl_vertex_attrib_array_pointer_arb = 0x00008645;
value gl_program_error_position_arb = 0x0000864b;
value gl_program_binding_arb = 0x00008677;
value gl_max_vertex_attribs_arb = 0x00008869;
value gl_vertex_attrib_array_normalized_arb = 0x0000886a;
value gl_program_error_string_arb = 0x00008874;
value gl_program_format_ascii_arb = 0x00008875;
value gl_program_format_arb = 0x00008876;
value gl_program_instructions_arb = 0x000088a0;
value gl_max_program_instructions_arb = 0x000088a1;
value gl_program_native_instructions_arb = 0x000088a2;
value gl_max_program_native_instructions_arb = 0x000088a3;
value gl_program_temporaries_arb = 0x000088a4;
value gl_max_program_temporaries_arb = 0x000088a5;
value gl_program_native_temporaries_arb = 0x000088a6;
value gl_max_program_native_temporaries_arb = 0x000088a7;
value gl_program_parameters_arb = 0x000088a8;
value gl_max_program_parameters_arb = 0x000088a9;
value gl_program_native_parameters_arb = 0x000088aa;
value gl_max_program_native_parameters_arb = 0x000088ab;
value gl_program_attribs_arb = 0x000088ac;
value gl_max_program_attribs_arb = 0x000088ad;
value gl_program_native_attribs_arb = 0x000088ae;
value gl_max_program_native_attribs_arb = 0x000088af;
value gl_program_address_registers_arb = 0x000088b0;
value gl_max_program_address_registers_arb = 0x000088b1;
value gl_program_native_address_registers_arb = 0x000088b2;
value gl_max_program_native_address_registers_arb = 0x000088b3;
value gl_max_program_local_parameters_arb = 0x000088b4;
value gl_max_program_env_parameters_arb = 0x000088b5;
value gl_program_under_native_limits_arb = 0x000088b6;
value gl_transpose_current_matrix_arb = 0x000088b7;
value gl_matrix0_arb = 0x000088c0;
value gl_matrix1_arb = 0x000088c1;
value gl_matrix2_arb = 0x000088c2;
value gl_matrix3_arb = 0x000088c3;
value gl_matrix4_arb = 0x000088c4;
value gl_matrix5_arb = 0x000088c5;
value gl_matrix6_arb = 0x000088c6;
value gl_matrix7_arb = 0x000088c7;
value gl_matrix8_arb = 0x000088c8;
value gl_matrix9_arb = 0x000088c9;
value gl_matrix10_arb = 0x000088ca;
value gl_matrix11_arb = 0x000088cb;
value gl_matrix12_arb = 0x000088cc;
value gl_matrix13_arb = 0x000088cd;
value gl_matrix14_arb = 0x000088ce;
value gl_matrix15_arb = 0x000088cf;
value gl_matrix16_arb = 0x000088d0;
value gl_matrix17_arb = 0x000088d1;
value gl_matrix18_arb = 0x000088d2;
value gl_matrix19_arb = 0x000088d3;
value gl_matrix20_arb = 0x000088d4;
value gl_matrix21_arb = 0x000088d5;
value gl_matrix22_arb = 0x000088d6;
value gl_matrix23_arb = 0x000088d7;
value gl_matrix24_arb = 0x000088d8;
value gl_matrix25_arb = 0x000088d9;
value gl_matrix26_arb = 0x000088da;
value gl_matrix27_arb = 0x000088db;
value gl_matrix28_arb = 0x000088dc;
value gl_matrix29_arb = 0x000088dd;
value gl_matrix30_arb = 0x000088de;
value gl_matrix31_arb = 0x000088df;
value gl_vertex_shader_arb = 0x00008b31;
value gl_max_vertex_uniform_components_arb = 0x00008b4a;
value gl_max_varying_floats_arb = 0x00008b4b;
value gl_max_vertex_texture_image_units_arb = 0x00008b4c;
value gl_max_combined_texture_image_units_arb = 0x00008b4d;
value gl_object_active_attributes_arb = 0x00008b89;
value gl_object_active_attribute_max_length_arb = 0x00008b8a;
value gl_422_ext = 0x000080cc;
value gl_422_rev_ext = 0x000080cd;
value gl_422_average_ext = 0x000080ce;
value gl_422_rev_average_ext = 0x000080cf;
value gl_abgr_ext = 0x00008000;
value gl_bgr_ext = 0x000080e0;
value gl_bgra_ext = 0x000080e1;
value gl_constant_color_ext = 0x00008001;
value gl_one_minus_constant_color_ext = 0x00008002;
value gl_constant_alpha_ext = 0x00008003;
value gl_one_minus_constant_alpha_ext = 0x00008004;
value gl_blend_color_ext = 0x00008005;
value gl_blend_equation_rgb_ext = 0x00008009;
value gl_blend_equation_alpha_ext = 0x0000883d;
value gl_blend_dst_rgb_ext = 0x000080c8;
value gl_blend_src_rgb_ext = 0x000080c9;
value gl_blend_dst_alpha_ext = 0x000080ca;
value gl_blend_src_alpha_ext = 0x000080cb;
value gl_func_add_ext = 0x00008006;
value gl_min_ext = 0x00008007;
value gl_max_ext = 0x00008008;
value gl_blend_equation_ext = 0x00008009;
value gl_func_subtract_ext = 0x0000800a;
value gl_func_reverse_subtract_ext = 0x0000800b;
value gl_clip_volume_clipping_hint_ext = 0x000080f0;
value gl_cmyk_ext = 0x0000800c;
value gl_cmyka_ext = 0x0000800d;
value gl_pack_cmyk_hint_ext = 0x0000800e;
value gl_unpack_cmyk_hint_ext = 0x0000800f;
value gl_occlusion_test_result_hp = 0x00008166;
value gl_occlusion_test_hp = 0x00008165;
value gl_red_min_clamp_ingr = 0x00008560;
value gl_green_min_clamp_ingr = 0x00008561;
value gl_blue_min_clamp_ingr = 0x00008562;
value gl_alpha_min_clamp_ingr = 0x00008563;
value gl_red_max_clamp_ingr = 0x00008564;
value gl_green_max_clamp_ingr = 0x00008565;
value gl_blue_max_clamp_ingr = 0x00008566;
value gl_alpha_max_clamp_ingr = 0x00008567;
value gl_interlace_read_ingr = 0x00008568;
value gl_palette4_rgb8_oes = 0x00008b90;
value gl_palette4_rgba8_oes = 0x00008b91;
value gl_palette4_r5_g6_b5_oes = 0x00008b92;
value gl_palette4_rgba4_oes = 0x00008b93;
value gl_palette4_rgb5_a1_oes = 0x00008b94;
value gl_palette8_rgb8_oes = 0x00008b95;
value gl_palette8_rgba8_oes = 0x00008b96;
value gl_palette8_r5_g6_b5_oes = 0x00008b97;
value gl_palette8_rgba4_oes = 0x00008b98;
value gl_palette8_rgb5_a1_oes = 0x00008b99;
value gl_implementation_color_read_type_oes = 0x00008b9a;
value gl_implementation_color_read_format_oes = 0x00008b9b;
value gl_interlace_oml = 0x00008980;
value gl_interlace_read_oml = 0x00008981;
value gl_pack_resample_oml = 0x00008984;
value gl_unpack_resample_oml = 0x00008985;
value gl_resample_replicate_oml = 0x00008986;
value gl_resample_zero_fill_oml = 0x00008987;
value gl_resample_average_oml = 0x00008988;
value gl_resample_decimate_oml = 0x00008989;
value gl_format_subsample_24_24_oml = 0x00008982;
value gl_format_subsample_244_244_oml = 0x00008983;
value gl_prefer_doublebuffer_hint_pgi = 0x0001a1f8;
value gl_conserve_memory_hint_pgi = 0x0001a1fd;
value gl_reclaim_memory_hint_pgi = 0x0001a1fe;
value gl_native_graphics_handle_pgi = 0x0001a202;
value gl_native_graphics_begin_hint_pgi = 0x0001a203;
value gl_native_graphics_end_hint_pgi = 0x0001a204;
value gl_always_fast_hint_pgi = 0x0001a20c;
value gl_always_soft_hint_pgi = 0x0001a20d;
value gl_allow_draw_obj_hint_pgi = 0x0001a20e;
value gl_allow_draw_win_hint_pgi = 0x0001a20f;
value gl_allow_draw_frg_hint_pgi = 0x0001a210;
value gl_allow_draw_mem_hint_pgi = 0x0001a211;
value gl_strict_depthfunc_hint_pgi = 0x0001a216;
value gl_strict_lighting_hint_pgi = 0x0001a217;
value gl_strict_scissor_hint_pgi = 0x0001a218;
value gl_full_stipple_hint_pgi = 0x0001a219;
value gl_clip_near_hint_pgi = 0x0001a220;
value gl_clip_far_hint_pgi = 0x0001a221;
value gl_wide_line_hint_pgi = 0x0001a222;
value gl_back_normals_hint_pgi = 0x0001a223;
value gl_vertex23_bit_pgi = 0x00000004;
value gl_vertex4_bit_pgi = 0x00000008;
value gl_color3_bit_pgi = 0x00010000;
value gl_color4_bit_pgi = 0x00020000;
value gl_edgeflag_bit_pgi = 0x00040000;
value gl_index_bit_pgi = 0x00080000;
value gl_mat_ambient_bit_pgi = 0x00100000;
value gl_vertex_data_hint_pgi = 0x0001a22a;
value gl_vertex_consistent_hint_pgi = 0x0001a22b;
value gl_material_side_hint_pgi = 0x0001a22c;
value gl_max_vertex_hint_pgi = 0x0001a22d;
value gl_mat_ambient_and_diffuse_bit_pgi = 0x00200000;
value gl_mat_diffuse_bit_pgi = 0x00400000;
value gl_mat_emission_bit_pgi = 0x00800000;
value gl_mat_color_indexes_bit_pgi = 0x01000000;
value gl_mat_shininess_bit_pgi = 0x02000000;
value gl_mat_specular_bit_pgi = 0x04000000;
value gl_normal_bit_pgi = 0x08000000;
value gl_texcoord1_bit_pgi = 0x10000000;
value gl_texcoord2_bit_pgi = 0x20000000;
value gl_texcoord3_bit_pgi = 0x40000000;
value gl_screen_coordinates_rend = 0x00008490;
value gl_inverted_screen_w_rend = 0x00008491;
value gl_rgb_s3tc = 0x000083a0;
value gl_rgb4_s3tc = 0x000083a1;
value gl_rgba_s3tc = 0x000083a2;
value gl_rgba4_s3tc = 0x000083a3;
value gl_rgba_dxt5_s3tc = 0x000083a4;
value gl_rgba4_dxt5_s3tc = 0x000083a5;
value gl_color_matrix_sgi = 0x000080b1;
value gl_color_matrix_stack_depth_sgi = 0x000080b2;
value gl_max_color_matrix_stack_depth_sgi = 0x000080b3;
value gl_post_color_matrix_red_scale_sgi = 0x000080b4;
value gl_post_color_matrix_green_scale_sgi = 0x000080b5;
value gl_post_color_matrix_blue_scale_sgi = 0x000080b6;
value gl_post_color_matrix_alpha_scale_sgi = 0x000080b7;
value gl_post_color_matrix_red_bias_sgi = 0x000080b8;
value gl_post_color_matrix_green_bias_sgi = 0x000080b9;
value gl_post_color_matrix_blue_bias_sgi = 0x000080ba;
value gl_post_color_matrix_alpha_bias_sgi = 0x000080bb;
value gl_extended_range_sgis = 0x000085a5;
value gl_min_red_sgis = 0x000085a6;
value gl_max_red_sgis = 0x000085a7;
value gl_min_green_sgis = 0x000085a8;
value gl_max_green_sgis = 0x000085a9;
value gl_min_blue_sgis = 0x000085aa;
value gl_max_blue_sgis = 0x000085ab;
value gl_min_alpha_sgis = 0x000085ac;
value gl_max_alpha_sgis = 0x000085ad;
value gl_accum = 0x00000100;
value gl_load = 0x00000101;
value gl_return = 0x00000102;
value gl_mult = 0x00000103;
value gl_add = 0x00000104;
value gl_never = 0x00000200;
value gl_less = 0x00000201;
value gl_equal = 0x00000202;
value gl_lequal = 0x00000203;
value gl_greater = 0x00000204;
value gl_notequal = 0x00000205;
value gl_gequal = 0x00000206;
value gl_always = 0x00000207;
value gl_current_bit = 0x00000001;
value gl_point_bit = 0x00000002;
value gl_line_bit = 0x00000004;
value gl_polygon_bit = 0x00000008;
value gl_polygon_stipple_bit = 0x00000010;
value gl_pixel_mode_bit = 0x00000020;
value gl_lighting_bit = 0x00000040;
value gl_fog_bit = 0x00000080;
value gl_depth_buffer_bit = 0x00000100;
value gl_accum_buffer_bit = 0x00000200;
value gl_stencil_buffer_bit = 0x00000400;
value gl_viewport_bit = 0x00000800;
value gl_transform_bit = 0x00001000;
value gl_enable_bit = 0x00002000;
value gl_color_buffer_bit = 0x00004000;
value gl_hint_bit = 0x00008000;
value gl_eval_bit = 0x00010000;
value gl_list_bit = 0x00020000;
value gl_texture_bit = 0x00040000;
value gl_scissor_bit = 0x00080000;
value gl_all_attrib_bits = 0x000fffff;
value gl_points = 0x00000000;
value gl_lines = 0x00000001;
value gl_line_loop = 0x00000002;
value gl_line_strip = 0x00000003;
value gl_triangles = 0x00000004;
value gl_triangle_strip = 0x00000005;
value gl_triangle_fan = 0x00000006;
value gl_quads = 0x00000007;
value gl_quad_strip = 0x00000008;
value gl_polygon = 0x00000009;
value gl_zero = 0x00000000;
value gl_one = 0x00000001;
value gl_src_color = 0x00000300;
value gl_one_minus_src_color = 0x00000301;
value gl_src_alpha = 0x00000302;
value gl_one_minus_src_alpha = 0x00000303;
value gl_dst_alpha = 0x00000304;
value gl_one_minus_dst_alpha = 0x00000305;
value gl_dst_color = 0x00000306;
value gl_one_minus_dst_color = 0x00000307;
value gl_src_alpha_saturate = 0x00000308;
value gl_true = 0x00000001;
value gl_false = 0x00000000;
value gl_clip_plane0 = 0x00003000;
value gl_clip_plane1 = 0x00003001;
value gl_clip_plane2 = 0x00003002;
value gl_clip_plane3 = 0x00003003;
value gl_clip_plane4 = 0x00003004;
value gl_clip_plane5 = 0x00003005;
value gl_byte = 0x00001400;
value gl_unsigned_byte = 0x00001401;
value gl_short = 0x00001402;
value gl_unsigned_short = 0x00001403;
value gl_int = 0x00001404;
value gl_unsigned_int = 0x00001405;
value gl_float = 0x00001406;
value gl_2_bytes = 0x00001407;
value gl_3_bytes = 0x00001408;
value gl_4_bytes = 0x00001409;
value gl_double = 0x0000140a;
value gl_none = 0x00000000;
value gl_front_left = 0x00000400;
value gl_front_right = 0x00000401;
value gl_back_left = 0x00000402;
value gl_back_right = 0x00000403;
value gl_front = 0x00000404;
value gl_back = 0x00000405;
value gl_left = 0x00000406;
value gl_right = 0x00000407;
value gl_front_and_back = 0x00000408;
value gl_aux0 = 0x00000409;
value gl_aux1 = 0x0000040a;
value gl_aux2 = 0x0000040b;
value gl_aux3 = 0x0000040c;
value gl_no_error = 0x00000000;
value gl_invalid_enum = 0x00000500;
value gl_invalid_value = 0x00000501;
value gl_invalid_operation = 0x00000502;
value gl_stack_overflow = 0x00000503;
value gl_stack_underflow = 0x00000504;
value gl_out_of_memory = 0x00000505;
value gl_2d = 0x00000600;
value gl_3d = 0x00000601;
value gl_3d_color = 0x00000602;
value gl_3d_color_texture = 0x00000603;
value gl_4d_color_texture = 0x00000604;
value gl_pass_through_token = 0x00000700;
value gl_point_token = 0x00000701;
value gl_line_token = 0x00000702;
value gl_polygon_token = 0x00000703;
value gl_bitmap_token = 0x00000704;
value gl_draw_pixel_token = 0x00000705;
value gl_copy_pixel_token = 0x00000706;
value gl_line_reset_token = 0x00000707;
value gl_exp = 0x00000800;
value gl_exp2 = 0x00000801;
value gl_cw = 0x00000900;
value gl_ccw = 0x00000901;
value gl_coeff = 0x00000a00;
value gl_order = 0x00000a01;
value gl_domain = 0x00000a02;
value gl_current_color = 0x00000b00;
value gl_current_index = 0x00000b01;
value gl_current_normal = 0x00000b02;
value gl_current_texture_coords = 0x00000b03;
value gl_current_raster_color = 0x00000b04;
value gl_current_raster_index = 0x00000b05;
value gl_current_raster_texture_coords = 0x00000b06;
value gl_current_raster_position = 0x00000b07;
value gl_current_raster_position_valid = 0x00000b08;
value gl_current_raster_distance = 0x00000b09;
value gl_point_smooth = 0x00000b10;
value gl_point_size = 0x00000b11;
value gl_point_size_range = 0x00000b12;
value gl_point_size_granularity = 0x00000b13;
value gl_line_smooth = 0x00000b20;
value gl_line_width = 0x00000b21;
value gl_line_width_range = 0x00000b22;
value gl_line_width_granularity = 0x00000b23;
value gl_line_stipple = 0x00000b24;
value gl_line_stipple_pattern = 0x00000b25;
value gl_line_stipple_repeat = 0x00000b26;
value gl_list_mode = 0x00000b30;
value gl_max_list_nesting = 0x00000b31;
value gl_list_base = 0x00000b32;
value gl_list_index = 0x00000b33;
value gl_polygon_mode = 0x00000b40;
value gl_polygon_smooth = 0x00000b41;
value gl_polygon_stipple = 0x00000b42;
value gl_edge_flag = 0x00000b43;
value gl_cull_face = 0x00000b44;
value gl_cull_face_mode = 0x00000b45;
value gl_front_face = 0x00000b46;
value gl_lighting = 0x00000b50;
value gl_light_model_local_viewer = 0x00000b51;
value gl_light_model_two_side = 0x00000b52;
value gl_light_model_ambient = 0x00000b53;
value gl_shade_model = 0x00000b54;
value gl_color_material_face = 0x00000b55;
value gl_color_material_parameter = 0x00000b56;
value gl_color_material = 0x00000b57;
value gl_fog = 0x00000b60;
value gl_fog_index = 0x00000b61;
value gl_fog_density = 0x00000b62;
value gl_fog_start = 0x00000b63;
value gl_fog_end = 0x00000b64;
value gl_fog_mode = 0x00000b65;
value gl_fog_color = 0x00000b66;
value gl_depth_range = 0x00000b70;
value gl_depth_test = 0x00000b71;
value gl_depth_writemask = 0x00000b72;
value gl_depth_clear_value = 0x00000b73;
value gl_depth_func = 0x00000b74;
value gl_accum_clear_value = 0x00000b80;
value gl_stencil_test = 0x00000b90;
value gl_stencil_clear_value = 0x00000b91;
value gl_stencil_func = 0x00000b92;
value gl_stencil_value_mask = 0x00000b93;
value gl_stencil_fail = 0x00000b94;
value gl_stencil_pass_depth_fail = 0x00000b95;
value gl_stencil_pass_depth_pass = 0x00000b96;
value gl_stencil_ref = 0x00000b97;
value gl_stencil_writemask = 0x00000b98;
value gl_matrix_mode = 0x00000ba0;
value gl_normalize = 0x00000ba1;
value gl_viewport = 0x00000ba2;
value gl_modelview_stack_depth = 0x00000ba3;
value gl_projection_stack_depth = 0x00000ba4;
value gl_texture_stack_depth = 0x00000ba5;
value gl_modelview_matrix = 0x00000ba6;
value gl_projection_matrix = 0x00000ba7;
value gl_texture_matrix = 0x00000ba8;
value gl_attrib_stack_depth = 0x00000bb0;
value gl_client_attrib_stack_depth = 0x00000bb1;
value gl_alpha_test = 0x00000bc0;
value gl_alpha_test_func = 0x00000bc1;
value gl_alpha_test_ref = 0x00000bc2;
value gl_dither = 0x00000bd0;
value gl_blend_dst = 0x00000be0;
value gl_blend_src = 0x00000be1;
value gl_blend = 0x00000be2;
value gl_logic_op_mode = 0x00000bf0;
value gl_index_logic_op = 0x00000bf1;
value gl_color_logic_op = 0x00000bf2;
value gl_aux_buffers = 0x00000c00;
value gl_draw_buffer = 0x00000c01;
value gl_read_buffer = 0x00000c02;
value gl_scissor_box = 0x00000c10;
value gl_scissor_test = 0x00000c11;
value gl_index_clear_value = 0x00000c20;
value gl_index_writemask = 0x00000c21;
value gl_color_clear_value = 0x00000c22;
value gl_color_writemask = 0x00000c23;
value gl_index_mode = 0x00000c30;
value gl_rgba_mode = 0x00000c31;
value gl_doublebuffer = 0x00000c32;
value gl_stereo = 0x00000c33;
value gl_render_mode = 0x00000c40;
value gl_perspective_correction_hint = 0x00000c50;
value gl_point_smooth_hint = 0x00000c51;
value gl_line_smooth_hint = 0x00000c52;
value gl_polygon_smooth_hint = 0x00000c53;
value gl_fog_hint = 0x00000c54;
value gl_texture_gen_s = 0x00000c60;
value gl_texture_gen_t = 0x00000c61;
value gl_texture_gen_r = 0x00000c62;
value gl_texture_gen_q = 0x00000c63;
value gl_pixel_map_i_to_i = 0x00000c70;
value gl_pixel_map_s_to_s = 0x00000c71;
value gl_pixel_map_i_to_r = 0x00000c72;
value gl_pixel_map_i_to_g = 0x00000c73;
value gl_pixel_map_i_to_b = 0x00000c74;
value gl_pixel_map_i_to_a = 0x00000c75;
value gl_pixel_map_r_to_r = 0x00000c76;
value gl_pixel_map_g_to_g = 0x00000c77;
value gl_pixel_map_b_to_b = 0x00000c78;
value gl_pixel_map_a_to_a = 0x00000c79;
value gl_pixel_map_i_to_i_size = 0x00000cb0;
value gl_pixel_map_s_to_s_size = 0x00000cb1;
value gl_pixel_map_i_to_r_size = 0x00000cb2;
value gl_pixel_map_i_to_g_size = 0x00000cb3;
value gl_pixel_map_i_to_b_size = 0x00000cb4;
value gl_pixel_map_i_to_a_size = 0x00000cb5;
value gl_pixel_map_r_to_r_size = 0x00000cb6;
value gl_pixel_map_g_to_g_size = 0x00000cb7;
value gl_pixel_map_b_to_b_size = 0x00000cb8;
value gl_pixel_map_a_to_a_size = 0x00000cb9;
value gl_unpack_swap_bytes = 0x00000cf0;
value gl_unpack_lsb_first = 0x00000cf1;
value gl_unpack_row_length = 0x00000cf2;
value gl_unpack_skip_rows = 0x00000cf3;
value gl_unpack_skip_pixels = 0x00000cf4;
value gl_unpack_alignment = 0x00000cf5;
value gl_pack_swap_bytes = 0x00000d00;
value gl_pack_lsb_first = 0x00000d01;
value gl_pack_row_length = 0x00000d02;
value gl_pack_skip_rows = 0x00000d03;
value gl_pack_skip_pixels = 0x00000d04;
value gl_pack_alignment = 0x00000d05;
value gl_map_color = 0x00000d10;
value gl_map_stencil = 0x00000d11;
value gl_index_shift = 0x00000d12;
value gl_index_offset = 0x00000d13;
value gl_red_scale = 0x00000d14;
value gl_red_bias = 0x00000d15;
value gl_zoom_x = 0x00000d16;
value gl_zoom_y = 0x00000d17;
value gl_green_scale = 0x00000d18;
value gl_green_bias = 0x00000d19;
value gl_blue_scale = 0x00000d1a;
value gl_blue_bias = 0x00000d1b;
value gl_alpha_scale = 0x00000d1c;
value gl_alpha_bias = 0x00000d1d;
value gl_depth_scale = 0x00000d1e;
value gl_depth_bias = 0x00000d1f;
value gl_max_eval_order = 0x00000d30;
value gl_max_lights = 0x00000d31;
value gl_max_clip_planes = 0x00000d32;
value gl_max_texture_size = 0x00000d33;
value gl_max_pixel_map_table = 0x00000d34;
value gl_max_attrib_stack_depth = 0x00000d35;
value gl_max_modelview_stack_depth = 0x00000d36;
value gl_max_name_stack_depth = 0x00000d37;
value gl_max_projection_stack_depth = 0x00000d38;
value gl_max_texture_stack_depth = 0x00000d39;
value gl_max_viewport_dims = 0x00000d3a;
value gl_max_client_attrib_stack_depth = 0x00000d3b;
value gl_subpixel_bits = 0x00000d50;
value gl_index_bits = 0x00000d51;
value gl_red_bits = 0x00000d52;
value gl_green_bits = 0x00000d53;
value gl_blue_bits = 0x00000d54;
value gl_alpha_bits = 0x00000d55;
value gl_depth_bits = 0x00000d56;
value gl_stencil_bits = 0x00000d57;
value gl_accum_red_bits = 0x00000d58;
value gl_accum_green_bits = 0x00000d59;
value gl_accum_blue_bits = 0x00000d5a;
value gl_accum_alpha_bits = 0x00000d5b;
value gl_name_stack_depth = 0x00000d70;
value gl_auto_normal = 0x00000d80;
value gl_map1_color_4 = 0x00000d90;
value gl_map1_index = 0x00000d91;
value gl_map1_normal = 0x00000d92;
value gl_map1_texture_coord_1 = 0x00000d93;
value gl_map1_texture_coord_2 = 0x00000d94;
value gl_map1_texture_coord_3 = 0x00000d95;
value gl_map1_texture_coord_4 = 0x00000d96;
value gl_map1_vertex_3 = 0x00000d97;
value gl_map1_vertex_4 = 0x00000d98;
value gl_map2_color_4 = 0x00000db0;
value gl_map2_index = 0x00000db1;
value gl_map2_normal = 0x00000db2;
value gl_map2_texture_coord_1 = 0x00000db3;
value gl_map2_texture_coord_2 = 0x00000db4;
value gl_map2_texture_coord_3 = 0x00000db5;
value gl_map2_texture_coord_4 = 0x00000db6;
value gl_map2_vertex_3 = 0x00000db7;
value gl_map2_vertex_4 = 0x00000db8;
value gl_map1_grid_domain = 0x00000dd0;
value gl_map1_grid_segments = 0x00000dd1;
value gl_map2_grid_domain = 0x00000dd2;
value gl_map2_grid_segments = 0x00000dd3;
value gl_texture_1d = 0x00000de0;
value gl_texture_2d = 0x00000de1;
value gl_feedback_buffer_pointer = 0x00000df0;
value gl_feedback_buffer_size = 0x00000df1;
value gl_feedback_buffer_type = 0x00000df2;
value gl_selection_buffer_pointer = 0x00000df3;
value gl_selection_buffer_size = 0x00000df4;
value gl_texture_width = 0x00001000;
value gl_texture_height = 0x00001001;
value gl_texture_internal_format = 0x00001003;
value gl_texture_border_color = 0x00001004;
value gl_texture_border = 0x00001005;
value gl_dont_care = 0x00001100;
value gl_fastest = 0x00001101;
value gl_nicest = 0x00001102;
value gl_light0 = 0x00004000;
value gl_light1 = 0x00004001;
value gl_light2 = 0x00004002;
value gl_light3 = 0x00004003;
value gl_light4 = 0x00004004;
value gl_light5 = 0x00004005;
value gl_light6 = 0x00004006;
value gl_light7 = 0x00004007;
value gl_ambient = 0x00001200;
value gl_diffuse = 0x00001201;
value gl_specular = 0x00001202;
value gl_position = 0x00001203;
value gl_spot_direction = 0x00001204;
value gl_spot_exponent = 0x00001205;
value gl_spot_cutoff = 0x00001206;
value gl_constant_attenuation = 0x00001207;
value gl_linear_attenuation = 0x00001208;
value gl_quadratic_attenuation = 0x00001209;
value gl_compile = 0x00001300;
value gl_compile_and_execute = 0x00001301;
value gl_clear = 0x00001500;
value gl_and = 0x00001501;
value gl_and_reverse = 0x00001502;
value gl_copy = 0x00001503;
value gl_and_inverted = 0x00001504;
value gl_noop = 0x00001505;
value gl_xor = 0x00001506;
value gl_or = 0x00001507;
value gl_nor = 0x00001508;
value gl_equiv = 0x00001509;
value gl_invert = 0x0000150a;
value gl_or_reverse = 0x0000150b;
value gl_copy_inverted = 0x0000150c;
value gl_or_inverted = 0x0000150d;
value gl_nand = 0x0000150e;
value gl_set = 0x0000150f;
value gl_emission = 0x00001600;
value gl_shininess = 0x00001601;
value gl_ambient_and_diffuse = 0x00001602;
value gl_color_indexes = 0x00001603;
value gl_modelview = 0x00001700;
value gl_projection = 0x00001701;
value gl_texture = 0x00001702;
value gl_color = 0x00001800;
value gl_depth = 0x00001801;
value gl_stencil = 0x00001802;
value gl_color_index = 0x00001900;
value gl_stencil_index = 0x00001901;
value gl_depth_component = 0x00001902;
value gl_red = 0x00001903;
value gl_green = 0x00001904;
value gl_blue = 0x00001905;
value gl_alpha = 0x00001906;
value gl_rgb = 0x00001907;
value gl_rgba = 0x00001908;
value gl_luminance = 0x00001909;
value gl_luminance_alpha = 0x0000190a;
value gl_bitmap = 0x00001a00;
value gl_point = 0x00001b00;
value gl_line = 0x00001b01;
value gl_fill = 0x00001b02;
value gl_render = 0x00001c00;
value gl_feedback = 0x00001c01;
value gl_select = 0x00001c02;
value gl_flat = 0x00001d00;
value gl_smooth = 0x00001d01;
value gl_keep = 0x00001e00;
value gl_replace = 0x00001e01;
value gl_incr = 0x00001e02;
value gl_decr = 0x00001e03;
value gl_vendor = 0x00001f00;
value gl_renderer = 0x00001f01;
value gl_version = 0x00001f02;
value gl_extensions = 0x00001f03;
value gl_s = 0x00002000;
value gl_t = 0x00002001;
value gl_r = 0x00002002;
value gl_q = 0x00002003;
value gl_modulate = 0x00002100;
value gl_decal = 0x00002101;
value gl_texture_env_mode = 0x00002200;
value gl_texture_env_color = 0x00002201;
value gl_texture_env = 0x00002300;
value gl_eye_linear = 0x00002400;
value gl_object_linear = 0x00002401;
value gl_sphere_map = 0x00002402;
value gl_texture_gen_mode = 0x00002500;
value gl_object_plane = 0x00002501;
value gl_eye_plane = 0x00002502;
value gl_nearest = 0x00002600;
value gl_linear = 0x00002601;
value gl_nearest_mipmap_nearest = 0x00002700;
value gl_linear_mipmap_nearest = 0x00002701;
value gl_nearest_mipmap_linear = 0x00002702;
value gl_linear_mipmap_linear = 0x00002703;
value gl_texture_mag_filter = 0x00002800;
value gl_texture_min_filter = 0x00002801;
value gl_texture_wrap_s = 0x00002802;
value gl_texture_wrap_t = 0x00002803;
value gl_clamp = 0x00002900;
value gl_repeat = 0x00002901;
value gl_client_pixel_store_bit = 0x00000001;
value gl_client_vertex_array_bit = 0x00000002;
value gl_client_all_attrib_bits = 0x7fffffff;
value gl_polygon_offset_factor = 0x00008038;
value gl_polygon_offset_units = 0x00002a00;
value gl_polygon_offset_point = 0x00002a01;
value gl_polygon_offset_line = 0x00002a02;
value gl_polygon_offset_fill = 0x00008037;
value gl_alpha4 = 0x0000803b;
value gl_alpha8 = 0x0000803c;
value gl_alpha12 = 0x0000803d;
value gl_alpha16 = 0x0000803e;
value gl_luminance4 = 0x0000803f;
value gl_luminance8 = 0x00008040;
value gl_luminance12 = 0x00008041;
value gl_luminance16 = 0x00008042;
value gl_luminance4_alpha4 = 0x00008043;
value gl_luminance6_alpha2 = 0x00008044;
value gl_luminance8_alpha8 = 0x00008045;
value gl_luminance12_alpha4 = 0x00008046;
value gl_luminance12_alpha12 = 0x00008047;
value gl_luminance16_alpha16 = 0x00008048;
value gl_intensity = 0x00008049;
value gl_intensity4 = 0x0000804a;
value gl_intensity8 = 0x0000804b;
value gl_intensity12 = 0x0000804c;
value gl_intensity16 = 0x0000804d;
value gl_r3_g3_b2 = 0x00002a10;
value gl_rgb4 = 0x0000804f;
value gl_rgb5 = 0x00008050;
value gl_rgb8 = 0x00008051;
value gl_rgb10 = 0x00008052;
value gl_rgb12 = 0x00008053;
value gl_rgb16 = 0x00008054;
value gl_rgba2 = 0x00008055;
value gl_rgba4 = 0x00008056;
value gl_rgb5_a1 = 0x00008057;
value gl_rgba8 = 0x00008058;
value gl_rgb10_a2 = 0x00008059;
value gl_rgba12 = 0x0000805a;
value gl_rgba16 = 0x0000805b;
value gl_texture_red_size = 0x0000805c;
value gl_texture_green_size = 0x0000805d;
value gl_texture_blue_size = 0x0000805e;
value gl_texture_alpha_size = 0x0000805f;
value gl_texture_luminance_size = 0x00008060;
value gl_texture_intensity_size = 0x00008061;
value gl_proxy_texture_1d = 0x00008063;
value gl_proxy_texture_2d = 0x00008064;
value gl_texture_priority = 0x00008066;
value gl_texture_resident = 0x00008067;
value gl_texture_binding_1d = 0x00008068;
value gl_texture_binding_2d = 0x00008069;
value gl_vertex_array = 0x00008074;
value gl_normal_array = 0x00008075;
value gl_color_array = 0x00008076;
value gl_index_array = 0x00008077;
value gl_texture_coord_array = 0x00008078;
value gl_edge_flag_array = 0x00008079;
value gl_vertex_array_size = 0x0000807a;
value gl_vertex_array_type = 0x0000807b;
value gl_vertex_array_stride = 0x0000807c;
value gl_normal_array_type = 0x0000807e;
value gl_normal_array_stride = 0x0000807f;
value gl_color_array_size = 0x00008081;
value gl_color_array_type = 0x00008082;
value gl_color_array_stride = 0x00008083;
value gl_index_array_type = 0x00008085;
value gl_index_array_stride = 0x00008086;
value gl_texture_coord_array_size = 0x00008088;
value gl_texture_coord_array_type = 0x00008089;
value gl_texture_coord_array_stride = 0x0000808a;
value gl_edge_flag_array_stride = 0x0000808c;
value gl_vertex_array_pointer = 0x0000808e;
value gl_normal_array_pointer = 0x0000808f;
value gl_color_array_pointer = 0x00008090;
value gl_index_array_pointer = 0x00008091;
value gl_texture_coord_array_pointer = 0x00008092;
value gl_edge_flag_array_pointer = 0x00008093;
value gl_v2f = 0x00002a20;
value gl_v3f = 0x00002a21;
value gl_c4ub_v2f = 0x00002a22;
value gl_c4ub_v3f = 0x00002a23;
value gl_c3f_v3f = 0x00002a24;
value gl_n3f_v3f = 0x00002a25;
value gl_c4f_n3f_v3f = 0x00002a26;
value gl_t2f_v3f = 0x00002a27;
value gl_t4f_v4f = 0x00002a28;
value gl_t2f_c4ub_v3f = 0x00002a29;
value gl_t2f_c3f_v3f = 0x00002a2a;
value gl_t2f_n3f_v3f = 0x00002a2b;
value gl_t2f_c4f_n3f_v3f = 0x00002a2c;
value gl_t4f_c4f_n3f_v4f = 0x00002a2d;
value gl_logic_op = 0x00000bf1;
value gl_texture_components = 0x00001003;
value gl_color_index1_ext = 0x000080e2;
value gl_color_index2_ext = 0x000080e3;
value gl_color_index4_ext = 0x000080e4;
value gl_color_index8_ext = 0x000080e5;
value gl_color_index12_ext = 0x000080e6;
value gl_color_index16_ext = 0x000080e7;
value gl_unsigned_byte_3_3_2 = 0x00008032;
value gl_unsigned_short_4_4_4_4 = 0x00008033;
value gl_unsigned_short_5_5_5_1 = 0x00008034;
value gl_unsigned_int_8_8_8_8 = 0x00008035;
value gl_unsigned_int_10_10_10_2 = 0x00008036;
value gl_rescale_normal = 0x0000803a;
value gl_unsigned_byte_2_3_3_rev = 0x00008362;
value gl_unsigned_short_5_6_5 = 0x00008363;
value gl_unsigned_short_5_6_5_rev = 0x00008364;
value gl_unsigned_short_4_4_4_4_rev = 0x00008365;
value gl_unsigned_short_1_5_5_5_rev = 0x00008366;
value gl_unsigned_int_8_8_8_8_rev = 0x00008367;
value gl_unsigned_int_2_10_10_10_rev = 0x00008368;
value gl_bgr = 0x000080e0;
value gl_bgra = 0x000080e1;
value gl_max_elements_vertices = 0x000080e8;
value gl_max_elements_indices = 0x000080e9;
value gl_clamp_to_edge = 0x0000812f;
value gl_texture_min_lod = 0x0000813a;
value gl_texture_max_lod = 0x0000813b;
value gl_texture_base_level = 0x0000813c;
value gl_texture_max_level = 0x0000813d;
value gl_light_model_color_control = 0x000081f8;
value gl_single_color = 0x000081f9;
value gl_separate_specular_color = 0x000081fa;
value gl_smooth_point_size_range = 0x00000b12;
value gl_smooth_point_size_granularity = 0x00000b13;
value gl_smooth_line_width_range = 0x00000b22;
value gl_smooth_line_width_granularity = 0x00000b23;
value gl_aliased_point_size_range = 0x0000846d;
value gl_aliased_line_width_range = 0x0000846e;
value gl_pack_skip_images = 0x0000806b;
value gl_pack_image_height = 0x0000806c;
value gl_unpack_skip_images = 0x0000806d;
value gl_unpack_image_height = 0x0000806e;
value gl_texture_3d = 0x0000806f;
value gl_proxy_texture_3d = 0x00008070;
value gl_texture_depth = 0x00008071;
value gl_texture_wrap_r = 0x00008072;
value gl_max_3d_texture_size = 0x00008073;
value gl_texture_binding_3d = 0x0000806a;
value gl_texture0 = 0x000084c0;
value gl_texture1 = 0x000084c1;
value gl_texture2 = 0x000084c2;
value gl_texture3 = 0x000084c3;
value gl_texture4 = 0x000084c4;
value gl_texture5 = 0x000084c5;
value gl_texture6 = 0x000084c6;
value gl_texture7 = 0x000084c7;
value gl_texture8 = 0x000084c8;
value gl_texture9 = 0x000084c9;
value gl_texture10 = 0x000084ca;
value gl_texture11 = 0x000084cb;
value gl_texture12 = 0x000084cc;
value gl_texture13 = 0x000084cd;
value gl_texture14 = 0x000084ce;
value gl_texture15 = 0x000084cf;
value gl_texture16 = 0x000084d0;
value gl_texture17 = 0x000084d1;
value gl_texture18 = 0x000084d2;
value gl_texture19 = 0x000084d3;
value gl_texture20 = 0x000084d4;
value gl_texture21 = 0x000084d5;
value gl_texture22 = 0x000084d6;
value gl_texture23 = 0x000084d7;
value gl_texture24 = 0x000084d8;
value gl_texture25 = 0x000084d9;
value gl_texture26 = 0x000084da;
value gl_texture27 = 0x000084db;
value gl_texture28 = 0x000084dc;
value gl_texture29 = 0x000084dd;
value gl_texture30 = 0x000084de;
value gl_texture31 = 0x000084df;
value gl_active_texture = 0x000084e0;
value gl_client_active_texture = 0x000084e1;
value gl_max_texture_units = 0x000084e2;
value gl_normal_map = 0x00008511;
value gl_reflection_map = 0x00008512;
value gl_texture_cube_map = 0x00008513;
value gl_texture_binding_cube_map = 0x00008514;
value gl_texture_cube_map_positive_x = 0x00008515;
value gl_texture_cube_map_negative_x = 0x00008516;
value gl_texture_cube_map_positive_y = 0x00008517;
value gl_texture_cube_map_negative_y = 0x00008518;
value gl_texture_cube_map_positive_z = 0x00008519;
value gl_texture_cube_map_negative_z = 0x0000851a;
value gl_proxy_texture_cube_map = 0x0000851b;
value gl_max_cube_map_texture_size = 0x0000851c;
value gl_compressed_alpha = 0x000084e9;
value gl_compressed_luminance = 0x000084ea;
value gl_compressed_luminance_alpha = 0x000084eb;
value gl_compressed_intensity = 0x000084ec;
value gl_compressed_rgb = 0x000084ed;
value gl_compressed_rgba = 0x000084ee;
value gl_texture_compression_hint = 0x000084ef;
value gl_texture_compressed_image_size = 0x000086a0;
value gl_texture_compressed = 0x000086a1;
value gl_num_compressed_texture_formats = 0x000086a2;
value gl_compressed_texture_formats = 0x000086a3;
value gl_multisample = 0x0000809d;
value gl_sample_alpha_to_coverage = 0x0000809e;
value gl_sample_alpha_to_one = 0x0000809f;
value gl_sample_coverage = 0x000080a0;
value gl_sample_buffers = 0x000080a8;
value gl_samples = 0x000080a9;
value gl_sample_coverage_value = 0x000080aa;
value gl_sample_coverage_invert = 0x000080ab;
value gl_multisample_bit = 0x20000000;
value gl_transpose_modelview_matrix = 0x000084e3;
value gl_transpose_projection_matrix = 0x000084e4;
value gl_transpose_texture_matrix = 0x000084e5;
value gl_transpose_color_matrix = 0x000084e6;
value gl_combine = 0x00008570;
value gl_combine_rgb = 0x00008571;
value gl_combine_alpha = 0x00008572;
value gl_source0_rgb = 0x00008580;
value gl_source1_rgb = 0x00008581;
value gl_source2_rgb = 0x00008582;
value gl_source0_alpha = 0x00008588;
value gl_source1_alpha = 0x00008589;
value gl_source2_alpha = 0x0000858a;
value gl_operand0_rgb = 0x00008590;
value gl_operand1_rgb = 0x00008591;
value gl_operand2_rgb = 0x00008592;
value gl_operand0_alpha = 0x00008598;
value gl_operand1_alpha = 0x00008599;
value gl_operand2_alpha = 0x0000859a;
value gl_rgb_scale = 0x00008573;
value gl_add_signed = 0x00008574;
value gl_interpolate = 0x00008575;
value gl_subtract = 0x000084e7;
value gl_constant = 0x00008576;
value gl_primary_color = 0x00008577;
value gl_previous = 0x00008578;
value gl_dot3_rgb = 0x000086ae;
value gl_dot3_rgba = 0x000086af;
value gl_clamp_to_border = 0x0000812d;
value gl_generate_mipmap = 0x00008191;
value gl_generate_mipmap_hint = 0x00008192;
value gl_depth_component16 = 0x000081a5;
value gl_depth_component24 = 0x000081a6;
value gl_depth_component32 = 0x000081a7;
value gl_texture_depth_size = 0x0000884a;
value gl_depth_texture_mode = 0x0000884b;
value gl_texture_compare_mode = 0x0000884c;
value gl_texture_compare_func = 0x0000884d;
value gl_compare_r_to_texture = 0x0000884e;
value gl_fog_coordinate_source = 0x00008450;
value gl_fog_coordinate = 0x00008451;
value gl_fragment_depth = 0x00008452;
value gl_current_fog_coordinate = 0x00008453;
value gl_fog_coordinate_array_type = 0x00008454;
value gl_fog_coordinate_array_stride = 0x00008455;
value gl_fog_coordinate_array_pointer = 0x00008456;
value gl_fog_coordinate_array = 0x00008457;
value gl_point_size_min = 0x00008126;
value gl_point_size_max = 0x00008127;
value gl_point_fade_threshold_size = 0x00008128;
value gl_point_distance_attenuation = 0x00008129;
value gl_color_sum = 0x00008458;
value gl_current_secondary_color = 0x00008459;
value gl_secondary_color_array_size = 0x0000845a;
value gl_secondary_color_array_type = 0x0000845b;
value gl_secondary_color_array_stride = 0x0000845c;
value gl_secondary_color_array_pointer = 0x0000845d;
value gl_secondary_color_array = 0x0000845e;
value gl_blend_dst_rgb = 0x000080c8;
value gl_blend_src_rgb = 0x000080c9;
value gl_blend_dst_alpha = 0x000080ca;
value gl_blend_src_alpha = 0x000080cb;
value gl_incr_wrap = 0x00008507;
value gl_decr_wrap = 0x00008508;
value gl_texture_filter_control = 0x00008500;
value gl_texture_lod_bias = 0x00008501;
value gl_max_texture_lod_bias = 0x000084fd;
value gl_mirrored_repeat = 0x00008370;
value gl_buffer_size = 0x00008764;
value gl_buffer_usage = 0x00008765;
value gl_query_counter_bits = 0x00008864;
value gl_current_query = 0x00008865;
value gl_query_result = 0x00008866;
value gl_query_result_available = 0x00008867;
value gl_array_buffer = 0x00008892;
value gl_element_array_buffer = 0x00008893;
value gl_array_buffer_binding = 0x00008894;
value gl_element_array_buffer_binding = 0x00008895;
value gl_vertex_array_buffer_binding = 0x00008896;
value gl_normal_array_buffer_binding = 0x00008897;
value gl_color_array_buffer_binding = 0x00008898;
value gl_index_array_buffer_binding = 0x00008899;
value gl_texture_coord_array_buffer_binding = 0x0000889a;
value gl_edge_flag_array_buffer_binding = 0x0000889b;
value gl_secondary_color_array_buffer_binding = 0x0000889c;
value gl_fog_coordinate_array_buffer_binding = 0x0000889d;
value gl_weight_array_buffer_binding = 0x0000889e;
value gl_vertex_attrib_array_buffer_binding = 0x0000889f;
value gl_read_only = 0x000088b8;
value gl_write_only = 0x000088b9;
value gl_read_write = 0x000088ba;
value gl_buffer_access = 0x000088bb;
value gl_buffer_mapped = 0x000088bc;
value gl_buffer_map_pointer = 0x000088bd;
value gl_stream_draw = 0x000088e0;
value gl_stream_read = 0x000088e1;
value gl_stream_copy = 0x000088e2;
value gl_static_draw = 0x000088e4;
value gl_static_read = 0x000088e5;
value gl_static_copy = 0x000088e6;
value gl_dynamic_draw = 0x000088e8;
value gl_dynamic_read = 0x000088e9;
value gl_dynamic_copy = 0x000088ea;
value gl_samples_passed = 0x00008914;
value gl_fog_coord_src = gl_fog_coordinate_source;
value gl_fog_coord = gl_fog_coordinate;
value gl_current_fog_coord = gl_current_fog_coordinate;
value gl_fog_coord_array_type = gl_fog_coordinate_array_type;
value gl_fog_coord_array_stride = gl_fog_coordinate_array_stride;
value gl_fog_coord_array_pointer = gl_fog_coordinate_array_pointer;
value gl_fog_coord_array = gl_fog_coordinate_array;
value gl_fog_coord_array_buffer_binding =
  gl_fog_coordinate_array_buffer_binding;
value gl_src0_rgb = gl_source0_rgb;
value gl_src1_rgb = gl_source1_rgb;
value gl_src2_rgb = gl_source2_rgb;
value gl_src0_alpha = gl_source0_alpha;
value gl_src1_alpha = gl_source1_alpha;
value gl_src2_alpha = gl_source2_alpha;
value gl_blend_equation_rgb = gl_blend_equation;
value gl_vertex_attrib_array_enabled = 0x00008622;
value gl_vertex_attrib_array_size = 0x00008623;
value gl_vertex_attrib_array_stride = 0x00008624;
value gl_vertex_attrib_array_type = 0x00008625;
value gl_current_vertex_attrib = 0x00008626;
value gl_vertex_program_point_size = 0x00008642;
value gl_vertex_program_two_side = 0x00008643;
value gl_vertex_attrib_array_pointer = 0x00008645;
value gl_stencil_back_func = 0x00008800;
value gl_stencil_back_fail = 0x00008801;
value gl_stencil_back_pass_depth_fail = 0x00008802;
value gl_stencil_back_pass_depth_pass = 0x00008803;
value gl_max_draw_buffers = 0x00008824;
value gl_draw_buffer0 = 0x00008825;
value gl_draw_buffer1 = 0x00008826;
value gl_draw_buffer2 = 0x00008827;
value gl_draw_buffer3 = 0x00008828;
value gl_draw_buffer4 = 0x00008829;
value gl_draw_buffer5 = 0x0000882a;
value gl_draw_buffer6 = 0x0000882b;
value gl_draw_buffer7 = 0x0000882c;
value gl_draw_buffer8 = 0x0000882d;
value gl_draw_buffer9 = 0x0000882e;
value gl_draw_buffer10 = 0x0000882f;
value gl_draw_buffer11 = 0x00008830;
value gl_draw_buffer12 = 0x00008831;
value gl_draw_buffer13 = 0x00008832;
value gl_draw_buffer14 = 0x00008833;
value gl_draw_buffer15 = 0x00008834;
value gl_blend_equation_alpha = 0x0000883d;
value gl_point_sprite = 0x00008861;
value gl_coord_replace = 0x00008862;
value gl_max_vertex_attribs = 0x00008869;
value gl_vertex_attrib_array_normalized = 0x0000886a;
value gl_max_texture_coords = 0x00008871;
value gl_max_texture_image_units = 0x00008872;
value gl_fragment_shader = 0x00008b30;
value gl_vertex_shader = 0x00008b31;
value gl_max_fragment_uniform_components = 0x00008b49;
value gl_max_vertex_uniform_components = 0x00008b4a;
value gl_max_varying_floats = 0x00008b4b;
value gl_max_vertex_texture_image_units = 0x00008b4c;
value gl_max_combined_texture_image_units = 0x00008b4d;
value gl_shader_type = 0x00008b4f;
value gl_float_vec2 = 0x00008b50;
value gl_float_vec3 = 0x00008b51;
value gl_float_vec4 = 0x00008b52;
value gl_int_vec2 = 0x00008b53;
value gl_int_vec3 = 0x00008b54;
value gl_int_vec4 = 0x00008b55;
value gl_bool = 0x00008b56;
value gl_bool_vec2 = 0x00008b57;
value gl_bool_vec3 = 0x00008b58;
value gl_bool_vec4 = 0x00008b59;
value gl_float_mat2 = 0x00008b5a;
value gl_float_mat3 = 0x00008b5b;
value gl_float_mat4 = 0x00008b5c;
value gl_sampler_1d = 0x00008b5d;
value gl_sampler_2d = 0x00008b5e;
value gl_sampler_3d = 0x00008b5f;
value gl_sampler_cube = 0x00008b60;
value gl_sampler_1d_shadow = 0x00008b61;
value gl_sampler_2d_shadow = 0x00008b62;
value gl_delete_status = 0x00008b80;
value gl_compile_status = 0x00008b81;
value gl_link_status = 0x00008b82;
value gl_validate_status = 0x00008b83;
value gl_info_log_length = 0x00008b84;
value gl_attached_shaders = 0x00008b85;
value gl_active_uniforms = 0x00008b86;
value gl_active_uniform_max_length = 0x00008b87;
value gl_shader_source_length = 0x00008b88;
value gl_active_attributes = 0x00008b89;
value gl_active_attribute_max_length = 0x00008b8a;
value gl_fragment_shader_derivative_hint = 0x00008b8b;
value gl_shading_language_version = 0x00008b8c;
value gl_current_program = 0x00008b8d;
value gl_point_sprite_coord_origin = 0x00008ca0;
value gl_lower_left = 0x00008ca1;
value gl_upper_left = 0x00008ca2;
value gl_stencil_back_ref = 0x00008ca3;
value gl_stencil_back_value_mask = 0x00008ca4;
value gl_stencil_back_writemask = 0x00008ca5;
value gl_current_raster_secondary_color = 0x0000845f;
value gl_pixel_pack_buffer = 0x000088eb;
value gl_pixel_unpack_buffer = 0x000088ec;
value gl_pixel_pack_buffer_binding = 0x000088ed;
value gl_pixel_unpack_buffer_binding = 0x000088ef;
value gl_srgb = 0x00008c40;
value gl_srgb8 = 0x00008c41;
value gl_srgb_alpha = 0x00008c42;
value gl_srgb8_alpha8 = 0x00008c43;
value gl_sluminance_alpha = 0x00008c44;
value gl_sluminance8_alpha8 = 0x00008c45;
value gl_sluminance = 0x00008c46;
value gl_sluminance8 = 0x00008c47;
value gl_compressed_srgb = 0x00008c48;
value gl_compressed_srgb_alpha = 0x00008c49;
value gl_compressed_sluminance = 0x00008c4a;
value gl_compressed_sluminance_alpha = 0x00008c4b;
external glAccum : int -> float -> unit = "glstub_glAccum" "glstub_glAccum";
external glActiveTexture : int -> unit = "glstub_glActiveTexture"
  "glstub_glActiveTexture";
external glActiveTextureARB : int -> unit = "glstub_glActiveTextureARB"
  "glstub_glActiveTextureARB";
external glAlphaFunc : int -> float -> unit = "glstub_glAlphaFunc"
  "glstub_glAlphaFunc";
external glAreTexturesResident : int -> word_array -> word_array -> bool =
  "glstub_glAreTexturesResident" "glstub_glAreTexturesResident";
value glAreTexturesResident p0 p1 p2 =
  let np1 = to_word_array p1 in
  let np2 = to_word_array (bool_to_int_array p2) in
  let r = glAreTexturesResident p0 np1 np2 in
  let bp2 = Array.create (Bigarray.Array1.dim np2) 0 in
  let _ = copy_word_array np2 bp2 in let _ = copy_to_bool_array bp2 p2 in r;
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
external glBindProgramARB : int -> int -> unit = "glstub_glBindProgramARB"
  "glstub_glBindProgramARB";
external glBindTexture : int -> int -> unit = "glstub_glBindTexture"
  "glstub_glBindTexture";
external glBitmap :
  int -> int -> float -> float -> float -> float -> ubyte_array -> unit =
  "glstub_glBitmap_byte" "glstub_glBitmap";
value glBitmap p0 p1 p2 p3 p4 p5 p6 =
  let np6 = to_ubyte_array p6 in let r = glBitmap p0 p1 p2 p3 p4 p5 np6 in r;
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
external glColor3bv : byte_array -> unit = "glstub_glColor3bv"
  "glstub_glColor3bv";
value glColor3bv p0 =
  let np0 = to_byte_array p0 in let r = glColor3bv np0 in r;
external glColor3d : float -> float -> float -> unit = "glstub_glColor3d"
  "glstub_glColor3d";
external glColor3dv : array float -> unit = "glstub_glColor3dv"
  "glstub_glColor3dv";
external glColor3f : float -> float -> float -> unit = "glstub_glColor3f"
  "glstub_glColor3f";
external glColor3fv : float_array -> unit = "glstub_glColor3fv"
  "glstub_glColor3fv";
value glColor3fv p0 =
  let np0 = to_float_array p0 in let r = glColor3fv np0 in r;
external glColor3i : int -> int -> int -> unit = "glstub_glColor3i"
  "glstub_glColor3i";
external glColor3iv : word_array -> unit = "glstub_glColor3iv"
  "glstub_glColor3iv";
value glColor3iv p0 =
  let np0 = to_word_array p0 in let r = glColor3iv np0 in r;
external glColor3s : int -> int -> int -> unit = "glstub_glColor3s"
  "glstub_glColor3s";
external glColor3sv : short_array -> unit = "glstub_glColor3sv"
  "glstub_glColor3sv";
value glColor3sv p0 =
  let np0 = to_short_array p0 in let r = glColor3sv np0 in r;
external glColor3ub : int -> int -> int -> unit = "glstub_glColor3ub"
  "glstub_glColor3ub";
external glColor3ubv : ubyte_array -> unit = "glstub_glColor3ubv"
  "glstub_glColor3ubv";
value glColor3ubv p0 =
  let np0 = to_ubyte_array p0 in let r = glColor3ubv np0 in r;
external glColor3ui : int -> int -> int -> unit = "glstub_glColor3ui"
  "glstub_glColor3ui";
external glColor3uiv : word_array -> unit = "glstub_glColor3uiv"
  "glstub_glColor3uiv";
value glColor3uiv p0 =
  let np0 = to_word_array p0 in let r = glColor3uiv np0 in r;
external glColor3us : int -> int -> int -> unit = "glstub_glColor3us"
  "glstub_glColor3us";
external glColor3usv : ushort_array -> unit = "glstub_glColor3usv"
  "glstub_glColor3usv";
value glColor3usv p0 =
  let np0 = to_ushort_array p0 in let r = glColor3usv np0 in r;
external glColor4b : int -> int -> int -> int -> unit = "glstub_glColor4b"
  "glstub_glColor4b";
external glColor4bv : byte_array -> unit = "glstub_glColor4bv"
  "glstub_glColor4bv";
value glColor4bv p0 =
  let np0 = to_byte_array p0 in let r = glColor4bv np0 in r;
external glColor4d : float -> float -> float -> float -> unit =
  "glstub_glColor4d" "glstub_glColor4d";
external glColor4dv : array float -> unit = "glstub_glColor4dv"
  "glstub_glColor4dv";
external glColor4f : float -> float -> float -> float -> unit =
  "glstub_glColor4f" "glstub_glColor4f";
external glColor4fv : float_array -> unit = "glstub_glColor4fv"
  "glstub_glColor4fv";
value glColor4fv p0 =
  let np0 = to_float_array p0 in let r = glColor4fv np0 in r;
external glColor4i : int -> int -> int -> int -> unit = "glstub_glColor4i"
  "glstub_glColor4i";
external glColor4iv : word_array -> unit = "glstub_glColor4iv"
  "glstub_glColor4iv";
value glColor4iv p0 =
  let np0 = to_word_array p0 in let r = glColor4iv np0 in r;
external glColor4s : int -> int -> int -> int -> unit = "glstub_glColor4s"
  "glstub_glColor4s";
external glColor4sv : short_array -> unit = "glstub_glColor4sv"
  "glstub_glColor4sv";
value glColor4sv p0 =
  let np0 = to_short_array p0 in let r = glColor4sv np0 in r;
external glColor4ub : int -> int -> int -> int -> unit = "glstub_glColor4ub"
  "glstub_glColor4ub";
external glColor4ubv : ubyte_array -> unit = "glstub_glColor4ubv"
  "glstub_glColor4ubv";
value glColor4ubv p0 =
  let np0 = to_ubyte_array p0 in let r = glColor4ubv np0 in r;
external glColor4ui : int -> int -> int -> int -> unit = "glstub_glColor4ui"
  "glstub_glColor4ui";
external glColor4uiv : word_array -> unit = "glstub_glColor4uiv"
  "glstub_glColor4uiv";
value glColor4uiv p0 =
  let np0 = to_word_array p0 in let r = glColor4uiv np0 in r;
external glColor4us : int -> int -> int -> int -> unit = "glstub_glColor4us"
  "glstub_glColor4us";
external glColor4usv : ushort_array -> unit = "glstub_glColor4usv"
  "glstub_glColor4usv";
value glColor4usv p0 =
  let np0 = to_ushort_array p0 in let r = glColor4usv np0 in r;
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
external glColorTableParameterfv : int -> int -> float_array -> unit =
  "glstub_glColorTableParameterfv" "glstub_glColorTableParameterfv";
value glColorTableParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glColorTableParameterfv p0 p1 np2 in r;
external glColorTableParameteriv : int -> int -> word_array -> unit =
  "glstub_glColorTableParameteriv" "glstub_glColorTableParameteriv";
value glColorTableParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glColorTableParameteriv p0 p1 np2 in r;
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
external glConvolutionParameterfv : int -> int -> float_array -> unit =
  "glstub_glConvolutionParameterfv" "glstub_glConvolutionParameterfv";
value glConvolutionParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glConvolutionParameterfv p0 p1 np2 in r;
external glConvolutionParameteri : int -> int -> int -> unit =
  "glstub_glConvolutionParameteri" "glstub_glConvolutionParameteri";
external glConvolutionParameteriv : int -> int -> word_array -> unit =
  "glstub_glConvolutionParameteriv" "glstub_glConvolutionParameteriv";
value glConvolutionParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glConvolutionParameteriv p0 p1 np2 in r;
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
external glDeleteBuffers : int -> word_array -> unit =
  "glstub_glDeleteBuffers" "glstub_glDeleteBuffers";
value glDeleteBuffers p0 p1 =
  let np1 = to_word_array p1 in let r = glDeleteBuffers p0 np1 in r;
external glDeleteBuffersARB : int -> word_array -> unit =
  "glstub_glDeleteBuffersARB" "glstub_glDeleteBuffersARB";
value glDeleteBuffersARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glDeleteBuffersARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glDeleteLists : int -> int -> unit = "glstub_glDeleteLists"
  "glstub_glDeleteLists";
external glDeleteProgram : int -> unit = "glstub_glDeleteProgram"
  "glstub_glDeleteProgram";
external glDeleteProgramsARB : int -> word_array -> unit =
  "glstub_glDeleteProgramsARB" "glstub_glDeleteProgramsARB";
value glDeleteProgramsARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glDeleteProgramsARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glDeleteQueries : int -> word_array -> unit =
  "glstub_glDeleteQueries" "glstub_glDeleteQueries";
value glDeleteQueries p0 p1 =
  let np1 = to_word_array p1 in let r = glDeleteQueries p0 np1 in r;
external glDeleteQueriesARB : int -> word_array -> unit =
  "glstub_glDeleteQueriesARB" "glstub_glDeleteQueriesARB";
value glDeleteQueriesARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glDeleteQueriesARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glDeleteShader : int -> unit = "glstub_glDeleteShader"
  "glstub_glDeleteShader";
external glDeleteTextures : int -> word_array -> unit =
  "glstub_glDeleteTextures" "glstub_glDeleteTextures";
value glDeleteTextures p0 p1 =
  let np1 = to_word_array p1 in let r = glDeleteTextures p0 np1 in r;
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
external glDrawBuffers : int -> word_array -> unit = "glstub_glDrawBuffers"
  "glstub_glDrawBuffers";
value glDrawBuffers p0 p1 =
  let np1 = to_word_array p1 in let r = glDrawBuffers p0 np1 in r;
external glDrawBuffersARB : int -> word_array -> unit =
  "glstub_glDrawBuffersARB" "glstub_glDrawBuffersARB";
value glDrawBuffersARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glDrawBuffersARB p0 np1 in let _ = copy_word_array np1 p1 in r;
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
external glEdgeFlagv : word_array -> unit = "glstub_glEdgeFlagv"
  "glstub_glEdgeFlagv";
value glEdgeFlagv p0 =
  let np0 = to_word_array (bool_to_int_array p0) in
  let r = glEdgeFlagv np0 in r;
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
external glEvalCoord1fv : float_array -> unit = "glstub_glEvalCoord1fv"
  "glstub_glEvalCoord1fv";
value glEvalCoord1fv p0 =
  let np0 = to_float_array p0 in let r = glEvalCoord1fv np0 in r;
external glEvalCoord2d : float -> float -> unit = "glstub_glEvalCoord2d"
  "glstub_glEvalCoord2d";
external glEvalCoord2dv : array float -> unit = "glstub_glEvalCoord2dv"
  "glstub_glEvalCoord2dv";
external glEvalCoord2f : float -> float -> unit = "glstub_glEvalCoord2f"
  "glstub_glEvalCoord2f";
external glEvalCoord2fv : float_array -> unit = "glstub_glEvalCoord2fv"
  "glstub_glEvalCoord2fv";
value glEvalCoord2fv p0 =
  let np0 = to_float_array p0 in let r = glEvalCoord2fv np0 in r;
external glEvalMesh1 : int -> int -> int -> unit = "glstub_glEvalMesh1"
  "glstub_glEvalMesh1";
external glEvalMesh2 : int -> int -> int -> int -> int -> unit =
  "glstub_glEvalMesh2" "glstub_glEvalMesh2";
external glEvalPoint1 : int -> unit = "glstub_glEvalPoint1"
  "glstub_glEvalPoint1";
external glEvalPoint2 : int -> int -> unit = "glstub_glEvalPoint2"
  "glstub_glEvalPoint2";
external glFeedbackBuffer : int -> int -> float_array -> unit =
  "glstub_glFeedbackBuffer" "glstub_glFeedbackBuffer";
value glFeedbackBuffer p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glFeedbackBuffer p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
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
external glFogCoordfv : float_array -> unit = "glstub_glFogCoordfv"
  "glstub_glFogCoordfv";
value glFogCoordfv p0 =
  let np0 = to_float_array p0 in let r = glFogCoordfv np0 in r;
external glFogf : int -> float -> unit = "glstub_glFogf" "glstub_glFogf";
external glFogfv : int -> float_array -> unit = "glstub_glFogfv"
  "glstub_glFogfv";
value glFogfv p0 p1 =
  let np1 = to_float_array p1 in let r = glFogfv p0 np1 in r;
external glFogi : int -> int -> unit = "glstub_glFogi" "glstub_glFogi";
external glFogiv : int -> word_array -> unit = "glstub_glFogiv"
  "glstub_glFogiv";
value glFogiv p0 p1 =
  let np1 = to_word_array p1 in let r = glFogiv p0 np1 in r;
external glFrontFace : int -> unit = "glstub_glFrontFace"
  "glstub_glFrontFace";
external glFrustum :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glFrustum_byte" "glstub_glFrustum";
external glGenBuffers : int -> word_array -> unit = "glstub_glGenBuffers"
  "glstub_glGenBuffers";
value glGenBuffers p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenBuffers p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenBuffersARB : int -> word_array -> unit =
  "glstub_glGenBuffersARB" "glstub_glGenBuffersARB";
value glGenBuffersARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenBuffersARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenLists : int -> int = "glstub_glGenLists" "glstub_glGenLists";
external glGenProgramsARB : int -> word_array -> unit =
  "glstub_glGenProgramsARB" "glstub_glGenProgramsARB";
value glGenProgramsARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenProgramsARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenQueries : int -> word_array -> unit = "glstub_glGenQueries"
  "glstub_glGenQueries";
value glGenQueries p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenQueries p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenQueriesARB : int -> word_array -> unit =
  "glstub_glGenQueriesARB" "glstub_glGenQueriesARB";
value glGenQueriesARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenQueriesARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenTextures : int -> word_array -> unit = "glstub_glGenTextures"
  "glstub_glGenTextures";
value glGenTextures p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenTextures p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGetActiveAttrib :
  int ->
    int -> int -> word_array -> word_array -> word_array -> string -> unit =
  "glstub_glGetActiveAttrib_byte" "glstub_glGetActiveAttrib";
value glGetActiveAttrib p0 p1 p2 p3 p4 p5 p6 =
  let np3 = to_word_array p3 in
  let np4 = to_word_array p4 in
  let np5 = to_word_array p5 in
  let r = glGetActiveAttrib p0 p1 p2 np3 np4 np5 p6 in
  let _ = copy_word_array np3 p3 in
  let _ = copy_word_array np4 p4 in let _ = copy_word_array np5 p5 in r;
external glGetActiveUniform :
  int ->
    int -> int -> word_array -> word_array -> word_array -> string -> unit =
  "glstub_glGetActiveUniform_byte" "glstub_glGetActiveUniform";
value glGetActiveUniform p0 p1 p2 p3 p4 p5 p6 =
  let np3 = to_word_array p3 in
  let np4 = to_word_array p4 in
  let np5 = to_word_array p5 in
  let r = glGetActiveUniform p0 p1 p2 np3 np4 np5 p6 in
  let _ = copy_word_array np3 p3 in
  let _ = copy_word_array np4 p4 in let _ = copy_word_array np5 p5 in r;
external glGetAttachedShaders :
  int -> int -> word_array -> word_array -> unit =
  "glstub_glGetAttachedShaders" "glstub_glGetAttachedShaders";
value glGetAttachedShaders p0 p1 p2 p3 =
  let np2 = to_word_array p2 in
  let np3 = to_word_array p3 in
  let r = glGetAttachedShaders p0 p1 np2 np3 in
  let _ = copy_word_array np2 p2 in let _ = copy_word_array np3 p3 in r;
external glGetAttribLocation : int -> string -> int =
  "glstub_glGetAttribLocation" "glstub_glGetAttribLocation";
external glGetBooleanv : int -> word_array -> unit = "glstub_glGetBooleanv"
  "glstub_glGetBooleanv";
value glGetBooleanv p0 p1 =
  let np1 = to_word_array (bool_to_int_array p1) in
  let r = glGetBooleanv p0 np1 in
  let bp1 = Array.create (Bigarray.Array1.dim np1) 0 in
  let _ = copy_word_array np1 bp1 in let _ = copy_to_bool_array bp1 p1 in r;
external glGetBufferParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetBufferParameteriv" "glstub_glGetBufferParameteriv";
value glGetBufferParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetBufferParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetBufferParameterivARB : int -> int -> word_array -> unit =
  "glstub_glGetBufferParameterivARB" "glstub_glGetBufferParameterivARB";
value glGetBufferParameterivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetBufferParameterivARB p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
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
external glGetColorTableParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetColorTableParameterfv" "glstub_glGetColorTableParameterfv";
value glGetColorTableParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetColorTableParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetColorTableParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetColorTableParameteriv" "glstub_glGetColorTableParameteriv";
value glGetColorTableParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetColorTableParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetCompressedTexImage : int -> int -> 'a -> unit =
  "glstub_glGetCompressedTexImage" "glstub_glGetCompressedTexImage";
external glGetCompressedTexImageARB : int -> int -> 'a -> unit =
  "glstub_glGetCompressedTexImageARB" "glstub_glGetCompressedTexImageARB";
external glGetConvolutionFilter : int -> int -> int -> 'a -> unit =
  "glstub_glGetConvolutionFilter" "glstub_glGetConvolutionFilter";
external glGetConvolutionParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetConvolutionParameterfv" "glstub_glGetConvolutionParameterfv";
value glGetConvolutionParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetConvolutionParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetConvolutionParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetConvolutionParameteriv" "glstub_glGetConvolutionParameteriv";
value glGetConvolutionParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetConvolutionParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetDoublev : int -> array float -> unit = "glstub_glGetDoublev"
  "glstub_glGetDoublev";
external glGetError : unit -> int = "glstub_glGetError" "glstub_glGetError";
external glGetFloatv : int -> float_array -> unit = "glstub_glGetFloatv"
  "glstub_glGetFloatv";
value glGetFloatv p0 p1 =
  let np1 = to_float_array p1 in
  let r = glGetFloatv p0 np1 in let _ = copy_float_array np1 p1 in r;
external glGetHistogram : int -> bool -> int -> int -> 'a -> unit =
  "glstub_glGetHistogram" "glstub_glGetHistogram";
external glGetHistogramParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetHistogramParameterfv" "glstub_glGetHistogramParameterfv";
value glGetHistogramParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetHistogramParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetHistogramParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetHistogramParameteriv" "glstub_glGetHistogramParameteriv";
value glGetHistogramParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetHistogramParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetIntegerv : int -> word_array -> unit = "glstub_glGetIntegerv"
  "glstub_glGetIntegerv";
value glGetIntegerv p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGetIntegerv p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGetLightfv : int -> int -> float_array -> unit =
  "glstub_glGetLightfv" "glstub_glGetLightfv";
value glGetLightfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetLightfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetLightiv : int -> int -> word_array -> unit =
  "glstub_glGetLightiv" "glstub_glGetLightiv";
value glGetLightiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetLightiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetMapdv : int -> int -> array float -> unit = "glstub_glGetMapdv"
  "glstub_glGetMapdv";
external glGetMapfv : int -> int -> float_array -> unit = "glstub_glGetMapfv"
  "glstub_glGetMapfv";
value glGetMapfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetMapfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetMapiv : int -> int -> word_array -> unit = "glstub_glGetMapiv"
  "glstub_glGetMapiv";
value glGetMapiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetMapiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetMaterialfv : int -> int -> float_array -> unit =
  "glstub_glGetMaterialfv" "glstub_glGetMaterialfv";
value glGetMaterialfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetMaterialfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetMaterialiv : int -> int -> word_array -> unit =
  "glstub_glGetMaterialiv" "glstub_glGetMaterialiv";
value glGetMaterialiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetMaterialiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetMinmax : int -> bool -> int -> int -> 'a -> unit =
  "glstub_glGetMinmax" "glstub_glGetMinmax";
external glGetMinmaxParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetMinmaxParameterfv" "glstub_glGetMinmaxParameterfv";
value glGetMinmaxParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetMinmaxParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetMinmaxParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetMinmaxParameteriv" "glstub_glGetMinmaxParameteriv";
value glGetMinmaxParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetMinmaxParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetPixelMapfv : int -> float_array -> unit =
  "glstub_glGetPixelMapfv" "glstub_glGetPixelMapfv";
value glGetPixelMapfv p0 p1 =
  let np1 = to_float_array p1 in
  let r = glGetPixelMapfv p0 np1 in let _ = copy_float_array np1 p1 in r;
external glGetPixelMapuiv : int -> word_array -> unit =
  "glstub_glGetPixelMapuiv" "glstub_glGetPixelMapuiv";
value glGetPixelMapuiv p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGetPixelMapuiv p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGetPixelMapusv : int -> ushort_array -> unit =
  "glstub_glGetPixelMapusv" "glstub_glGetPixelMapusv";
value glGetPixelMapusv p0 p1 =
  let np1 = to_ushort_array p1 in
  let r = glGetPixelMapusv p0 np1 in let _ = copy_ushort_array np1 p1 in r;
external glGetPointerv : int -> 'a -> unit = "glstub_glGetPointerv"
  "glstub_glGetPointerv";
external glGetPolygonStipple : ubyte_array -> unit =
  "glstub_glGetPolygonStipple" "glstub_glGetPolygonStipple";
value glGetPolygonStipple p0 =
  let np0 = to_ubyte_array p0 in
  let r = glGetPolygonStipple np0 in let _ = copy_ubyte_array np0 p0 in r;
external glGetProgramEnvParameterdvARB : int -> int -> array float -> unit =
  "glstub_glGetProgramEnvParameterdvARB"
  "glstub_glGetProgramEnvParameterdvARB";
external glGetProgramEnvParameterfvARB : int -> int -> float_array -> unit =
  "glstub_glGetProgramEnvParameterfvARB"
  "glstub_glGetProgramEnvParameterfvARB";
value glGetProgramEnvParameterfvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetProgramEnvParameterfvARB p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetProgramInfoLog : int -> int -> word_array -> string -> unit =
  "glstub_glGetProgramInfoLog" "glstub_glGetProgramInfoLog";
value glGetProgramInfoLog p0 p1 p2 p3 =
  let np2 = to_word_array p2 in
  let r = glGetProgramInfoLog p0 p1 np2 p3 in
  let _ = copy_word_array np2 p2 in r;
external glGetProgramLocalParameterdvARB :
  int -> int -> array float -> unit =
  "glstub_glGetProgramLocalParameterdvARB"
  "glstub_glGetProgramLocalParameterdvARB";
external glGetProgramLocalParameterfvARB :
  int -> int -> float_array -> unit =
  "glstub_glGetProgramLocalParameterfvARB"
  "glstub_glGetProgramLocalParameterfvARB";
value glGetProgramLocalParameterfvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetProgramLocalParameterfvARB p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetProgramStringARB : int -> int -> 'a -> unit =
  "glstub_glGetProgramStringARB" "glstub_glGetProgramStringARB";
external glGetProgramiv : int -> int -> word_array -> unit =
  "glstub_glGetProgramiv" "glstub_glGetProgramiv";
value glGetProgramiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetProgramiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetProgramivARB : int -> int -> word_array -> unit =
  "glstub_glGetProgramivARB" "glstub_glGetProgramivARB";
value glGetProgramivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetProgramivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetQueryObjectiv : int -> int -> word_array -> unit =
  "glstub_glGetQueryObjectiv" "glstub_glGetQueryObjectiv";
value glGetQueryObjectiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryObjectiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetQueryObjectivARB : int -> int -> word_array -> unit =
  "glstub_glGetQueryObjectivARB" "glstub_glGetQueryObjectivARB";
value glGetQueryObjectivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryObjectivARB p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetQueryObjectuiv : int -> int -> word_array -> unit =
  "glstub_glGetQueryObjectuiv" "glstub_glGetQueryObjectuiv";
value glGetQueryObjectuiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryObjectuiv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetQueryObjectuivARB : int -> int -> word_array -> unit =
  "glstub_glGetQueryObjectuivARB" "glstub_glGetQueryObjectuivARB";
value glGetQueryObjectuivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryObjectuivARB p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetQueryiv : int -> int -> word_array -> unit =
  "glstub_glGetQueryiv" "glstub_glGetQueryiv";
value glGetQueryiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetQueryivARB : int -> int -> word_array -> unit =
  "glstub_glGetQueryivARB" "glstub_glGetQueryivARB";
value glGetQueryivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetQueryivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetSeparableFilter : int -> int -> int -> 'a -> 'a -> 'a -> unit =
  "glstub_glGetSeparableFilter_byte" "glstub_glGetSeparableFilter";
external glGetShaderInfoLog : int -> int -> word_array -> string -> unit =
  "glstub_glGetShaderInfoLog" "glstub_glGetShaderInfoLog";
value glGetShaderInfoLog p0 p1 p2 p3 =
  let np2 = to_word_array p2 in
  let r = glGetShaderInfoLog p0 p1 np2 p3 in
  let _ = copy_word_array np2 p2 in r;
external glGetShaderSource : int -> int -> word_array -> string -> unit =
  "glstub_glGetShaderSource" "glstub_glGetShaderSource";
value glGetShaderSource p0 p1 p2 p3 =
  let np2 = to_word_array p2 in
  let r = glGetShaderSource p0 p1 np2 p3 in
  let _ = copy_word_array np2 p2 in r;
external glGetShaderiv : int -> int -> word_array -> unit =
  "glstub_glGetShaderiv" "glstub_glGetShaderiv";
value glGetShaderiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetShaderiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetTexEnvfv : int -> int -> float_array -> unit =
  "glstub_glGetTexEnvfv" "glstub_glGetTexEnvfv";
value glGetTexEnvfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetTexEnvfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetTexEnviv : int -> int -> word_array -> unit =
  "glstub_glGetTexEnviv" "glstub_glGetTexEnviv";
value glGetTexEnviv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetTexEnviv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetTexGendv : int -> int -> array float -> unit =
  "glstub_glGetTexGendv" "glstub_glGetTexGendv";
external glGetTexGenfv : int -> int -> float_array -> unit =
  "glstub_glGetTexGenfv" "glstub_glGetTexGenfv";
value glGetTexGenfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetTexGenfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetTexGeniv : int -> int -> word_array -> unit =
  "glstub_glGetTexGeniv" "glstub_glGetTexGeniv";
value glGetTexGeniv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetTexGeniv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetTexImage : int -> int -> int -> int -> 'a -> unit =
  "glstub_glGetTexImage" "glstub_glGetTexImage";
external glGetTexLevelParameterfv :
  int -> int -> int -> float_array -> unit =
  "glstub_glGetTexLevelParameterfv" "glstub_glGetTexLevelParameterfv";
value glGetTexLevelParameterfv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glGetTexLevelParameterfv p0 p1 p2 np3 in
  let _ = copy_float_array np3 p3 in r;
external glGetTexLevelParameteriv : int -> int -> int -> word_array -> unit =
  "glstub_glGetTexLevelParameteriv" "glstub_glGetTexLevelParameteriv";
value glGetTexLevelParameteriv p0 p1 p2 p3 =
  let np3 = to_word_array p3 in
  let r = glGetTexLevelParameteriv p0 p1 p2 np3 in
  let _ = copy_word_array np3 p3 in r;
external glGetTexParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetTexParameterfv" "glstub_glGetTexParameterfv";
value glGetTexParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetTexParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetTexParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetTexParameteriv" "glstub_glGetTexParameteriv";
value glGetTexParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetTexParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetUniformLocation : int -> string -> int =
  "glstub_glGetUniformLocation" "glstub_glGetUniformLocation";
external glGetUniformfv : int -> int -> float_array -> unit =
  "glstub_glGetUniformfv" "glstub_glGetUniformfv";
value glGetUniformfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetUniformfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetUniformiv : int -> int -> word_array -> unit =
  "glstub_glGetUniformiv" "glstub_glGetUniformiv";
value glGetUniformiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetUniformiv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetVertexAttribPointerv : int -> int -> 'a -> unit =
  "glstub_glGetVertexAttribPointerv" "glstub_glGetVertexAttribPointerv";
external glGetVertexAttribPointervARB : int -> int -> 'a -> unit =
  "glstub_glGetVertexAttribPointervARB"
  "glstub_glGetVertexAttribPointervARB";
external glGetVertexAttribdv : int -> int -> array float -> unit =
  "glstub_glGetVertexAttribdv" "glstub_glGetVertexAttribdv";
external glGetVertexAttribdvARB : int -> int -> array float -> unit =
  "glstub_glGetVertexAttribdvARB" "glstub_glGetVertexAttribdvARB";
external glGetVertexAttribfv : int -> int -> float_array -> unit =
  "glstub_glGetVertexAttribfv" "glstub_glGetVertexAttribfv";
value glGetVertexAttribfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetVertexAttribfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetVertexAttribfvARB : int -> int -> float_array -> unit =
  "glstub_glGetVertexAttribfvARB" "glstub_glGetVertexAttribfvARB";
value glGetVertexAttribfvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetVertexAttribfvARB p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetVertexAttribiv : int -> int -> word_array -> unit =
  "glstub_glGetVertexAttribiv" "glstub_glGetVertexAttribiv";
value glGetVertexAttribiv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetVertexAttribiv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetVertexAttribivARB : int -> int -> word_array -> unit =
  "glstub_glGetVertexAttribivARB" "glstub_glGetVertexAttribivARB";
value glGetVertexAttribivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetVertexAttribivARB p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
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
external glIndexfv : float_array -> unit = "glstub_glIndexfv"
  "glstub_glIndexfv";
value glIndexfv p0 =
  let np0 = to_float_array p0 in let r = glIndexfv np0 in r;
external glIndexi : int -> unit = "glstub_glIndexi" "glstub_glIndexi";
external glIndexiv : word_array -> unit = "glstub_glIndexiv"
  "glstub_glIndexiv";
value glIndexiv p0 =
  let np0 = to_word_array p0 in let r = glIndexiv np0 in r;
external glIndexs : int -> unit = "glstub_glIndexs" "glstub_glIndexs";
external glIndexsv : short_array -> unit = "glstub_glIndexsv"
  "glstub_glIndexsv";
value glIndexsv p0 =
  let np0 = to_short_array p0 in let r = glIndexsv np0 in r;
external glIndexub : int -> unit = "glstub_glIndexub" "glstub_glIndexub";
external glIndexubv : ubyte_array -> unit = "glstub_glIndexubv"
  "glstub_glIndexubv";
value glIndexubv p0 =
  let np0 = to_ubyte_array p0 in let r = glIndexubv np0 in r;
external glInitNames : unit -> unit = "glstub_glInitNames"
  "glstub_glInitNames";
external glInterleavedArrays : int -> int -> 'a -> unit =
  "glstub_glInterleavedArrays" "glstub_glInterleavedArrays";
external glIsBuffer : int -> bool = "glstub_glIsBuffer" "glstub_glIsBuffer";
external glIsBufferARB : int -> bool = "glstub_glIsBufferARB"
  "glstub_glIsBufferARB";
external glIsEnabled : int -> bool = "glstub_glIsEnabled"
  "glstub_glIsEnabled";
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
external glLightModelfv : int -> float_array -> unit =
  "glstub_glLightModelfv" "glstub_glLightModelfv";
value glLightModelfv p0 p1 =
  let np1 = to_float_array p1 in let r = glLightModelfv p0 np1 in r;
external glLightModeli : int -> int -> unit = "glstub_glLightModeli"
  "glstub_glLightModeli";
external glLightModeliv : int -> word_array -> unit = "glstub_glLightModeliv"
  "glstub_glLightModeliv";
value glLightModeliv p0 p1 =
  let np1 = to_word_array p1 in let r = glLightModeliv p0 np1 in r;
external glLightf : int -> int -> float -> unit = "glstub_glLightf"
  "glstub_glLightf";
external glLightfv : int -> int -> float_array -> unit = "glstub_glLightfv"
  "glstub_glLightfv";
value glLightfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glLightfv p0 p1 np2 in r;
external glLighti : int -> int -> int -> unit = "glstub_glLighti"
  "glstub_glLighti";
external glLightiv : int -> int -> word_array -> unit = "glstub_glLightiv"
  "glstub_glLightiv";
value glLightiv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glLightiv p0 p1 np2 in r;
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
external glLoadMatrixf : float_array -> unit = "glstub_glLoadMatrixf"
  "glstub_glLoadMatrixf";
value glLoadMatrixf p0 =
  let np0 = to_float_array p0 in let r = glLoadMatrixf np0 in r;
external glLoadName : int -> unit = "glstub_glLoadName" "glstub_glLoadName";
external glLoadTransposeMatrixd : array float -> unit =
  "glstub_glLoadTransposeMatrixd" "glstub_glLoadTransposeMatrixd";
external glLoadTransposeMatrixdARB : array float -> unit =
  "glstub_glLoadTransposeMatrixdARB" "glstub_glLoadTransposeMatrixdARB";
external glLoadTransposeMatrixf : float_array -> unit =
  "glstub_glLoadTransposeMatrixf" "glstub_glLoadTransposeMatrixf";
value glLoadTransposeMatrixf p0 =
  let np0 = to_float_array p0 in let r = glLoadTransposeMatrixf np0 in r;
external glLoadTransposeMatrixfARB : float_array -> unit =
  "glstub_glLoadTransposeMatrixfARB" "glstub_glLoadTransposeMatrixfARB";
value glLoadTransposeMatrixfARB p0 =
  let np0 = to_float_array p0 in
  let r = glLoadTransposeMatrixfARB np0 in
  let _ = copy_float_array np0 p0 in r;
external glLockArraysEXT : int -> int -> unit = "glstub_glLockArraysEXT"
  "glstub_glLockArraysEXT";
external glLogicOp : int -> unit = "glstub_glLogicOp" "glstub_glLogicOp";
external glMap1d :
  int -> float -> float -> int -> int -> array float -> unit =
  "glstub_glMap1d_byte" "glstub_glMap1d";
external glMap1f :
  int -> float -> float -> int -> int -> float_array -> unit =
  "glstub_glMap1f_byte" "glstub_glMap1f";
value glMap1f p0 p1 p2 p3 p4 p5 =
  let np5 = to_float_array p5 in let r = glMap1f p0 p1 p2 p3 p4 np5 in r;
external glMap2d :
  int ->
    float ->
      float ->
        int -> int -> float -> float -> int -> int -> array float -> unit =
  "glstub_glMap2d_byte" "glstub_glMap2d";
external glMap2f :
  int ->
    float ->
      float ->
        int -> int -> float -> float -> int -> int -> float_array -> unit =
  "glstub_glMap2f_byte" "glstub_glMap2f";
value glMap2f p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 =
  let np9 = to_float_array p9 in
  let r = glMap2f p0 p1 p2 p3 p4 p5 p6 p7 p8 np9 in r;
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
external glMaterialfv : int -> int -> float_array -> unit =
  "glstub_glMaterialfv" "glstub_glMaterialfv";
value glMaterialfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glMaterialfv p0 p1 np2 in r;
external glMateriali : int -> int -> int -> unit = "glstub_glMateriali"
  "glstub_glMateriali";
external glMaterialiv : int -> int -> word_array -> unit =
  "glstub_glMaterialiv" "glstub_glMaterialiv";
value glMaterialiv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glMaterialiv p0 p1 np2 in r;
external glMatrixMode : int -> unit = "glstub_glMatrixMode"
  "glstub_glMatrixMode";
external glMinmax : int -> int -> bool -> unit = "glstub_glMinmax"
  "glstub_glMinmax";
external glMultMatrixd : array float -> unit = "glstub_glMultMatrixd"
  "glstub_glMultMatrixd";
external glMultMatrixf : float_array -> unit = "glstub_glMultMatrixf"
  "glstub_glMultMatrixf";
value glMultMatrixf p0 =
  let np0 = to_float_array p0 in let r = glMultMatrixf np0 in r;
external glMultTransposeMatrixd : array float -> unit =
  "glstub_glMultTransposeMatrixd" "glstub_glMultTransposeMatrixd";
external glMultTransposeMatrixdARB : array float -> unit =
  "glstub_glMultTransposeMatrixdARB" "glstub_glMultTransposeMatrixdARB";
external glMultTransposeMatrixf : float_array -> unit =
  "glstub_glMultTransposeMatrixf" "glstub_glMultTransposeMatrixf";
value glMultTransposeMatrixf p0 =
  let np0 = to_float_array p0 in let r = glMultTransposeMatrixf np0 in r;
external glMultTransposeMatrixfARB : float_array -> unit =
  "glstub_glMultTransposeMatrixfARB" "glstub_glMultTransposeMatrixfARB";
value glMultTransposeMatrixfARB p0 =
  let np0 = to_float_array p0 in
  let r = glMultTransposeMatrixfARB np0 in
  let _ = copy_float_array np0 p0 in r;
external glMultiDrawArrays : int -> word_array -> word_array -> int -> unit =
  "glstub_glMultiDrawArrays" "glstub_glMultiDrawArrays";
value glMultiDrawArrays p0 p1 p2 p3 =
  let np1 = to_word_array p1 in
  let np2 = to_word_array p2 in
  let r = glMultiDrawArrays p0 np1 np2 p3 in
  let _ = copy_word_array np1 p1 in let _ = copy_word_array np2 p2 in r;
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
external glMultiTexCoord1fv : int -> float_array -> unit =
  "glstub_glMultiTexCoord1fv" "glstub_glMultiTexCoord1fv";
value glMultiTexCoord1fv p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord1fv p0 np1 in r;
external glMultiTexCoord1fvARB : int -> float_array -> unit =
  "glstub_glMultiTexCoord1fvARB" "glstub_glMultiTexCoord1fvARB";
value glMultiTexCoord1fvARB p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord1fvARB p0 np1 in r;
external glMultiTexCoord1i : int -> int -> unit = "glstub_glMultiTexCoord1i"
  "glstub_glMultiTexCoord1i";
external glMultiTexCoord1iARB : int -> int -> unit =
  "glstub_glMultiTexCoord1iARB" "glstub_glMultiTexCoord1iARB";
external glMultiTexCoord1iv : int -> word_array -> unit =
  "glstub_glMultiTexCoord1iv" "glstub_glMultiTexCoord1iv";
value glMultiTexCoord1iv p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord1iv p0 np1 in r;
external glMultiTexCoord1ivARB : int -> word_array -> unit =
  "glstub_glMultiTexCoord1ivARB" "glstub_glMultiTexCoord1ivARB";
value glMultiTexCoord1ivARB p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord1ivARB p0 np1 in r;
external glMultiTexCoord1s : int -> int -> unit = "glstub_glMultiTexCoord1s"
  "glstub_glMultiTexCoord1s";
external glMultiTexCoord1sARB : int -> int -> unit =
  "glstub_glMultiTexCoord1sARB" "glstub_glMultiTexCoord1sARB";
external glMultiTexCoord1sv : int -> short_array -> unit =
  "glstub_glMultiTexCoord1sv" "glstub_glMultiTexCoord1sv";
value glMultiTexCoord1sv p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord1sv p0 np1 in r;
external glMultiTexCoord1svARB : int -> short_array -> unit =
  "glstub_glMultiTexCoord1svARB" "glstub_glMultiTexCoord1svARB";
value glMultiTexCoord1svARB p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord1svARB p0 np1 in r;
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
external glMultiTexCoord2fv : int -> float_array -> unit =
  "glstub_glMultiTexCoord2fv" "glstub_glMultiTexCoord2fv";
value glMultiTexCoord2fv p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord2fv p0 np1 in r;
external glMultiTexCoord2fvARB : int -> float_array -> unit =
  "glstub_glMultiTexCoord2fvARB" "glstub_glMultiTexCoord2fvARB";
value glMultiTexCoord2fvARB p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord2fvARB p0 np1 in r;
external glMultiTexCoord2i : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2i" "glstub_glMultiTexCoord2i";
external glMultiTexCoord2iARB : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2iARB" "glstub_glMultiTexCoord2iARB";
external glMultiTexCoord2iv : int -> word_array -> unit =
  "glstub_glMultiTexCoord2iv" "glstub_glMultiTexCoord2iv";
value glMultiTexCoord2iv p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord2iv p0 np1 in r;
external glMultiTexCoord2ivARB : int -> word_array -> unit =
  "glstub_glMultiTexCoord2ivARB" "glstub_glMultiTexCoord2ivARB";
value glMultiTexCoord2ivARB p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord2ivARB p0 np1 in r;
external glMultiTexCoord2s : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2s" "glstub_glMultiTexCoord2s";
external glMultiTexCoord2sARB : int -> int -> int -> unit =
  "glstub_glMultiTexCoord2sARB" "glstub_glMultiTexCoord2sARB";
external glMultiTexCoord2sv : int -> short_array -> unit =
  "glstub_glMultiTexCoord2sv" "glstub_glMultiTexCoord2sv";
value glMultiTexCoord2sv p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord2sv p0 np1 in r;
external glMultiTexCoord2svARB : int -> short_array -> unit =
  "glstub_glMultiTexCoord2svARB" "glstub_glMultiTexCoord2svARB";
value glMultiTexCoord2svARB p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord2svARB p0 np1 in r;
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
external glMultiTexCoord3fv : int -> float_array -> unit =
  "glstub_glMultiTexCoord3fv" "glstub_glMultiTexCoord3fv";
value glMultiTexCoord3fv p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord3fv p0 np1 in r;
external glMultiTexCoord3fvARB : int -> float_array -> unit =
  "glstub_glMultiTexCoord3fvARB" "glstub_glMultiTexCoord3fvARB";
value glMultiTexCoord3fvARB p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord3fvARB p0 np1 in r;
external glMultiTexCoord3i : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3i" "glstub_glMultiTexCoord3i";
external glMultiTexCoord3iARB : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3iARB" "glstub_glMultiTexCoord3iARB";
external glMultiTexCoord3iv : int -> word_array -> unit =
  "glstub_glMultiTexCoord3iv" "glstub_glMultiTexCoord3iv";
value glMultiTexCoord3iv p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord3iv p0 np1 in r;
external glMultiTexCoord3ivARB : int -> word_array -> unit =
  "glstub_glMultiTexCoord3ivARB" "glstub_glMultiTexCoord3ivARB";
value glMultiTexCoord3ivARB p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord3ivARB p0 np1 in r;
external glMultiTexCoord3s : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3s" "glstub_glMultiTexCoord3s";
external glMultiTexCoord3sARB : int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord3sARB" "glstub_glMultiTexCoord3sARB";
external glMultiTexCoord3sv : int -> short_array -> unit =
  "glstub_glMultiTexCoord3sv" "glstub_glMultiTexCoord3sv";
value glMultiTexCoord3sv p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord3sv p0 np1 in r;
external glMultiTexCoord3svARB : int -> short_array -> unit =
  "glstub_glMultiTexCoord3svARB" "glstub_glMultiTexCoord3svARB";
value glMultiTexCoord3svARB p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord3svARB p0 np1 in r;
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
external glMultiTexCoord4fv : int -> float_array -> unit =
  "glstub_glMultiTexCoord4fv" "glstub_glMultiTexCoord4fv";
value glMultiTexCoord4fv p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord4fv p0 np1 in r;
external glMultiTexCoord4fvARB : int -> float_array -> unit =
  "glstub_glMultiTexCoord4fvARB" "glstub_glMultiTexCoord4fvARB";
value glMultiTexCoord4fvARB p0 p1 =
  let np1 = to_float_array p1 in let r = glMultiTexCoord4fvARB p0 np1 in r;
external glMultiTexCoord4i : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4i" "glstub_glMultiTexCoord4i";
external glMultiTexCoord4iARB : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4iARB" "glstub_glMultiTexCoord4iARB";
external glMultiTexCoord4iv : int -> word_array -> unit =
  "glstub_glMultiTexCoord4iv" "glstub_glMultiTexCoord4iv";
value glMultiTexCoord4iv p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord4iv p0 np1 in r;
external glMultiTexCoord4ivARB : int -> word_array -> unit =
  "glstub_glMultiTexCoord4ivARB" "glstub_glMultiTexCoord4ivARB";
value glMultiTexCoord4ivARB p0 p1 =
  let np1 = to_word_array p1 in let r = glMultiTexCoord4ivARB p0 np1 in r;
external glMultiTexCoord4s : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4s" "glstub_glMultiTexCoord4s";
external glMultiTexCoord4sARB : int -> int -> int -> int -> int -> unit =
  "glstub_glMultiTexCoord4sARB" "glstub_glMultiTexCoord4sARB";
external glMultiTexCoord4sv : int -> short_array -> unit =
  "glstub_glMultiTexCoord4sv" "glstub_glMultiTexCoord4sv";
value glMultiTexCoord4sv p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord4sv p0 np1 in r;
external glMultiTexCoord4svARB : int -> short_array -> unit =
  "glstub_glMultiTexCoord4svARB" "glstub_glMultiTexCoord4svARB";
value glMultiTexCoord4svARB p0 p1 =
  let np1 = to_short_array p1 in let r = glMultiTexCoord4svARB p0 np1 in r;
external glNewList : int -> int -> unit = "glstub_glNewList"
  "glstub_glNewList";
external glNormal3b : int -> int -> int -> unit = "glstub_glNormal3b"
  "glstub_glNormal3b";
external glNormal3bv : byte_array -> unit = "glstub_glNormal3bv"
  "glstub_glNormal3bv";
value glNormal3bv p0 =
  let np0 = to_byte_array p0 in let r = glNormal3bv np0 in r;
external glNormal3d : float -> float -> float -> unit = "glstub_glNormal3d"
  "glstub_glNormal3d";
external glNormal3dv : array float -> unit = "glstub_glNormal3dv"
  "glstub_glNormal3dv";
external glNormal3f : float -> float -> float -> unit = "glstub_glNormal3f"
  "glstub_glNormal3f";
external glNormal3fv : float_array -> unit = "glstub_glNormal3fv"
  "glstub_glNormal3fv";
value glNormal3fv p0 =
  let np0 = to_float_array p0 in let r = glNormal3fv np0 in r;
external glNormal3i : int -> int -> int -> unit = "glstub_glNormal3i"
  "glstub_glNormal3i";
external glNormal3iv : word_array -> unit = "glstub_glNormal3iv"
  "glstub_glNormal3iv";
value glNormal3iv p0 =
  let np0 = to_word_array p0 in let r = glNormal3iv np0 in r;
external glNormal3s : int -> int -> int -> unit = "glstub_glNormal3s"
  "glstub_glNormal3s";
external glNormal3sv : short_array -> unit = "glstub_glNormal3sv"
  "glstub_glNormal3sv";
value glNormal3sv p0 =
  let np0 = to_short_array p0 in let r = glNormal3sv np0 in r;
external glNormalPointer : int -> int -> 'a -> unit =
  "glstub_glNormalPointer" "glstub_glNormalPointer";
external glOrtho :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glOrtho_byte" "glstub_glOrtho";
external glPassThrough : float -> unit = "glstub_glPassThrough"
  "glstub_glPassThrough";
external glPixelMapfv : int -> int -> float_array -> unit =
  "glstub_glPixelMapfv" "glstub_glPixelMapfv";
value glPixelMapfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glPixelMapfv p0 p1 np2 in r;
external glPixelMapuiv : int -> int -> word_array -> unit =
  "glstub_glPixelMapuiv" "glstub_glPixelMapuiv";
value glPixelMapuiv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glPixelMapuiv p0 p1 np2 in r;
external glPixelMapusv : int -> int -> ushort_array -> unit =
  "glstub_glPixelMapusv" "glstub_glPixelMapusv";
value glPixelMapusv p0 p1 p2 =
  let np2 = to_ushort_array p2 in let r = glPixelMapusv p0 p1 np2 in r;
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
external glPointParameterfv : int -> float_array -> unit =
  "glstub_glPointParameterfv" "glstub_glPointParameterfv";
value glPointParameterfv p0 p1 =
  let np1 = to_float_array p1 in
  let r = glPointParameterfv p0 np1 in let _ = copy_float_array np1 p1 in r;
external glPointParameterfvARB : int -> float_array -> unit =
  "glstub_glPointParameterfvARB" "glstub_glPointParameterfvARB";
value glPointParameterfvARB p0 p1 =
  let np1 = to_float_array p1 in
  let r = glPointParameterfvARB p0 np1 in
  let _ = copy_float_array np1 p1 in r;
external glPointSize : float -> unit = "glstub_glPointSize"
  "glstub_glPointSize";
external glPolygonMode : int -> int -> unit = "glstub_glPolygonMode"
  "glstub_glPolygonMode";
external glPolygonOffset : float -> float -> unit = "glstub_glPolygonOffset"
  "glstub_glPolygonOffset";
external glPolygonStipple : ubyte_array -> unit = "glstub_glPolygonStipple"
  "glstub_glPolygonStipple";
value glPolygonStipple p0 =
  let np0 = to_ubyte_array p0 in let r = glPolygonStipple np0 in r;
external glPopAttrib : unit -> unit = "glstub_glPopAttrib"
  "glstub_glPopAttrib";
external glPopClientAttrib : unit -> unit = "glstub_glPopClientAttrib"
  "glstub_glPopClientAttrib";
external glPopMatrix : unit -> unit = "glstub_glPopMatrix"
  "glstub_glPopMatrix";
external glPopName : unit -> unit = "glstub_glPopName" "glstub_glPopName";
external glPrioritizeTextures : int -> word_array -> float_array -> unit =
  "glstub_glPrioritizeTextures" "glstub_glPrioritizeTextures";
value glPrioritizeTextures p0 p1 p2 =
  let np1 = to_word_array p1 in
  let np2 = to_float_array p2 in let r = glPrioritizeTextures p0 np1 np2 in r;
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
external glProgramEnvParameter4fvARB : int -> int -> float_array -> unit =
  "glstub_glProgramEnvParameter4fvARB" "glstub_glProgramEnvParameter4fvARB";
value glProgramEnvParameter4fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glProgramEnvParameter4fvARB p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
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
external glProgramLocalParameter4fvARB : int -> int -> float_array -> unit =
  "glstub_glProgramLocalParameter4fvARB"
  "glstub_glProgramLocalParameter4fvARB";
value glProgramLocalParameter4fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glProgramLocalParameter4fvARB p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
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
external glRasterPos2fv : float_array -> unit = "glstub_glRasterPos2fv"
  "glstub_glRasterPos2fv";
value glRasterPos2fv p0 =
  let np0 = to_float_array p0 in let r = glRasterPos2fv np0 in r;
external glRasterPos2i : int -> int -> unit = "glstub_glRasterPos2i"
  "glstub_glRasterPos2i";
external glRasterPos2iv : word_array -> unit = "glstub_glRasterPos2iv"
  "glstub_glRasterPos2iv";
value glRasterPos2iv p0 =
  let np0 = to_word_array p0 in let r = glRasterPos2iv np0 in r;
external glRasterPos2s : int -> int -> unit = "glstub_glRasterPos2s"
  "glstub_glRasterPos2s";
external glRasterPos2sv : short_array -> unit = "glstub_glRasterPos2sv"
  "glstub_glRasterPos2sv";
value glRasterPos2sv p0 =
  let np0 = to_short_array p0 in let r = glRasterPos2sv np0 in r;
external glRasterPos3d : float -> float -> float -> unit =
  "glstub_glRasterPos3d" "glstub_glRasterPos3d";
external glRasterPos3dv : array float -> unit = "glstub_glRasterPos3dv"
  "glstub_glRasterPos3dv";
external glRasterPos3f : float -> float -> float -> unit =
  "glstub_glRasterPos3f" "glstub_glRasterPos3f";
external glRasterPos3fv : float_array -> unit = "glstub_glRasterPos3fv"
  "glstub_glRasterPos3fv";
value glRasterPos3fv p0 =
  let np0 = to_float_array p0 in let r = glRasterPos3fv np0 in r;
external glRasterPos3i : int -> int -> int -> unit = "glstub_glRasterPos3i"
  "glstub_glRasterPos3i";
external glRasterPos3iv : word_array -> unit = "glstub_glRasterPos3iv"
  "glstub_glRasterPos3iv";
value glRasterPos3iv p0 =
  let np0 = to_word_array p0 in let r = glRasterPos3iv np0 in r;
external glRasterPos3s : int -> int -> int -> unit = "glstub_glRasterPos3s"
  "glstub_glRasterPos3s";
external glRasterPos3sv : short_array -> unit = "glstub_glRasterPos3sv"
  "glstub_glRasterPos3sv";
value glRasterPos3sv p0 =
  let np0 = to_short_array p0 in let r = glRasterPos3sv np0 in r;
external glRasterPos4d : float -> float -> float -> float -> unit =
  "glstub_glRasterPos4d" "glstub_glRasterPos4d";
external glRasterPos4dv : array float -> unit = "glstub_glRasterPos4dv"
  "glstub_glRasterPos4dv";
external glRasterPos4f : float -> float -> float -> float -> unit =
  "glstub_glRasterPos4f" "glstub_glRasterPos4f";
external glRasterPos4fv : float_array -> unit = "glstub_glRasterPos4fv"
  "glstub_glRasterPos4fv";
value glRasterPos4fv p0 =
  let np0 = to_float_array p0 in let r = glRasterPos4fv np0 in r;
external glRasterPos4i : int -> int -> int -> int -> unit =
  "glstub_glRasterPos4i" "glstub_glRasterPos4i";
external glRasterPos4iv : word_array -> unit = "glstub_glRasterPos4iv"
  "glstub_glRasterPos4iv";
value glRasterPos4iv p0 =
  let np0 = to_word_array p0 in let r = glRasterPos4iv np0 in r;
external glRasterPos4s : int -> int -> int -> int -> unit =
  "glstub_glRasterPos4s" "glstub_glRasterPos4s";
external glRasterPos4sv : short_array -> unit = "glstub_glRasterPos4sv"
  "glstub_glRasterPos4sv";
value glRasterPos4sv p0 =
  let np0 = to_short_array p0 in let r = glRasterPos4sv np0 in r;
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
external glRectfv : float_array -> float_array -> unit = "glstub_glRectfv"
  "glstub_glRectfv";
value glRectfv p0 p1 =
  let np0 = to_float_array p0 in
  let np1 = to_float_array p1 in let r = glRectfv np0 np1 in r;
external glRecti : int -> int -> int -> int -> unit = "glstub_glRecti"
  "glstub_glRecti";
external glRectiv : word_array -> word_array -> unit = "glstub_glRectiv"
  "glstub_glRectiv";
value glRectiv p0 p1 =
  let np0 = to_word_array p0 in
  let np1 = to_word_array p1 in let r = glRectiv np0 np1 in r;
external glRects : int -> int -> int -> int -> unit = "glstub_glRects"
  "glstub_glRects";
external glRectsv : short_array -> short_array -> unit = "glstub_glRectsv"
  "glstub_glRectsv";
value glRectsv p0 p1 =
  let np0 = to_short_array p0 in
  let np1 = to_short_array p1 in let r = glRectsv np0 np1 in r;
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
external glSecondaryColor3bv : byte_array -> unit =
  "glstub_glSecondaryColor3bv" "glstub_glSecondaryColor3bv";
value glSecondaryColor3bv p0 =
  let np0 = to_byte_array p0 in let r = glSecondaryColor3bv np0 in r;
external glSecondaryColor3d : float -> float -> float -> unit =
  "glstub_glSecondaryColor3d" "glstub_glSecondaryColor3d";
external glSecondaryColor3dv : array float -> unit =
  "glstub_glSecondaryColor3dv" "glstub_glSecondaryColor3dv";
external glSecondaryColor3f : float -> float -> float -> unit =
  "glstub_glSecondaryColor3f" "glstub_glSecondaryColor3f";
external glSecondaryColor3fv : float_array -> unit =
  "glstub_glSecondaryColor3fv" "glstub_glSecondaryColor3fv";
value glSecondaryColor3fv p0 =
  let np0 = to_float_array p0 in let r = glSecondaryColor3fv np0 in r;
external glSecondaryColor3i : int -> int -> int -> unit =
  "glstub_glSecondaryColor3i" "glstub_glSecondaryColor3i";
external glSecondaryColor3iv : word_array -> unit =
  "glstub_glSecondaryColor3iv" "glstub_glSecondaryColor3iv";
value glSecondaryColor3iv p0 =
  let np0 = to_word_array p0 in let r = glSecondaryColor3iv np0 in r;
external glSecondaryColor3s : int -> int -> int -> unit =
  "glstub_glSecondaryColor3s" "glstub_glSecondaryColor3s";
external glSecondaryColor3sv : short_array -> unit =
  "glstub_glSecondaryColor3sv" "glstub_glSecondaryColor3sv";
value glSecondaryColor3sv p0 =
  let np0 = to_short_array p0 in let r = glSecondaryColor3sv np0 in r;
external glSecondaryColor3ub : int -> int -> int -> unit =
  "glstub_glSecondaryColor3ub" "glstub_glSecondaryColor3ub";
external glSecondaryColor3ubv : ubyte_array -> unit =
  "glstub_glSecondaryColor3ubv" "glstub_glSecondaryColor3ubv";
value glSecondaryColor3ubv p0 =
  let np0 = to_ubyte_array p0 in let r = glSecondaryColor3ubv np0 in r;
external glSecondaryColor3ui : int -> int -> int -> unit =
  "glstub_glSecondaryColor3ui" "glstub_glSecondaryColor3ui";
external glSecondaryColor3uiv : word_array -> unit =
  "glstub_glSecondaryColor3uiv" "glstub_glSecondaryColor3uiv";
value glSecondaryColor3uiv p0 =
  let np0 = to_word_array p0 in let r = glSecondaryColor3uiv np0 in r;
external glSecondaryColor3us : int -> int -> int -> unit =
  "glstub_glSecondaryColor3us" "glstub_glSecondaryColor3us";
external glSecondaryColor3usv : ushort_array -> unit =
  "glstub_glSecondaryColor3usv" "glstub_glSecondaryColor3usv";
value glSecondaryColor3usv p0 =
  let np0 = to_ushort_array p0 in let r = glSecondaryColor3usv np0 in r;
external glSecondaryColorPointer : int -> int -> int -> 'a -> unit =
  "glstub_glSecondaryColorPointer" "glstub_glSecondaryColorPointer";
external glSelectBuffer : int -> word_array -> unit = "glstub_glSelectBuffer"
  "glstub_glSelectBuffer";
value glSelectBuffer p0 p1 =
  let np1 = to_word_array p1 in
  let r = glSelectBuffer p0 np1 in let _ = copy_word_array np1 p1 in r;
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
external glTexCoord1fv : float_array -> unit = "glstub_glTexCoord1fv"
  "glstub_glTexCoord1fv";
value glTexCoord1fv p0 =
  let np0 = to_float_array p0 in let r = glTexCoord1fv np0 in r;
external glTexCoord1i : int -> unit = "glstub_glTexCoord1i"
  "glstub_glTexCoord1i";
external glTexCoord1iv : word_array -> unit = "glstub_glTexCoord1iv"
  "glstub_glTexCoord1iv";
value glTexCoord1iv p0 =
  let np0 = to_word_array p0 in let r = glTexCoord1iv np0 in r;
external glTexCoord1s : int -> unit = "glstub_glTexCoord1s"
  "glstub_glTexCoord1s";
external glTexCoord1sv : short_array -> unit = "glstub_glTexCoord1sv"
  "glstub_glTexCoord1sv";
value glTexCoord1sv p0 =
  let np0 = to_short_array p0 in let r = glTexCoord1sv np0 in r;
external glTexCoord2d : float -> float -> unit = "glstub_glTexCoord2d"
  "glstub_glTexCoord2d";
external glTexCoord2dv : array float -> unit = "glstub_glTexCoord2dv"
  "glstub_glTexCoord2dv";
external glTexCoord2f : float -> float -> unit = "glstub_glTexCoord2f"
  "glstub_glTexCoord2f";
external glTexCoord2fv : float_array -> unit = "glstub_glTexCoord2fv"
  "glstub_glTexCoord2fv";
value glTexCoord2fv p0 =
  let np0 = to_float_array p0 in let r = glTexCoord2fv np0 in r;
external glTexCoord2i : int -> int -> unit = "glstub_glTexCoord2i"
  "glstub_glTexCoord2i";
external glTexCoord2iv : word_array -> unit = "glstub_glTexCoord2iv"
  "glstub_glTexCoord2iv";
value glTexCoord2iv p0 =
  let np0 = to_word_array p0 in let r = glTexCoord2iv np0 in r;
external glTexCoord2s : int -> int -> unit = "glstub_glTexCoord2s"
  "glstub_glTexCoord2s";
external glTexCoord2sv : short_array -> unit = "glstub_glTexCoord2sv"
  "glstub_glTexCoord2sv";
value glTexCoord2sv p0 =
  let np0 = to_short_array p0 in let r = glTexCoord2sv np0 in r;
external glTexCoord3d : float -> float -> float -> unit =
  "glstub_glTexCoord3d" "glstub_glTexCoord3d";
external glTexCoord3dv : array float -> unit = "glstub_glTexCoord3dv"
  "glstub_glTexCoord3dv";
external glTexCoord3f : float -> float -> float -> unit =
  "glstub_glTexCoord3f" "glstub_glTexCoord3f";
external glTexCoord3fv : float_array -> unit = "glstub_glTexCoord3fv"
  "glstub_glTexCoord3fv";
value glTexCoord3fv p0 =
  let np0 = to_float_array p0 in let r = glTexCoord3fv np0 in r;
external glTexCoord3i : int -> int -> int -> unit = "glstub_glTexCoord3i"
  "glstub_glTexCoord3i";
external glTexCoord3iv : word_array -> unit = "glstub_glTexCoord3iv"
  "glstub_glTexCoord3iv";
value glTexCoord3iv p0 =
  let np0 = to_word_array p0 in let r = glTexCoord3iv np0 in r;
external glTexCoord3s : int -> int -> int -> unit = "glstub_glTexCoord3s"
  "glstub_glTexCoord3s";
external glTexCoord3sv : short_array -> unit = "glstub_glTexCoord3sv"
  "glstub_glTexCoord3sv";
value glTexCoord3sv p0 =
  let np0 = to_short_array p0 in let r = glTexCoord3sv np0 in r;
external glTexCoord4d : float -> float -> float -> float -> unit =
  "glstub_glTexCoord4d" "glstub_glTexCoord4d";
external glTexCoord4dv : array float -> unit = "glstub_glTexCoord4dv"
  "glstub_glTexCoord4dv";
external glTexCoord4f : float -> float -> float -> float -> unit =
  "glstub_glTexCoord4f" "glstub_glTexCoord4f";
external glTexCoord4fv : float_array -> unit = "glstub_glTexCoord4fv"
  "glstub_glTexCoord4fv";
value glTexCoord4fv p0 =
  let np0 = to_float_array p0 in let r = glTexCoord4fv np0 in r;
external glTexCoord4i : int -> int -> int -> int -> unit =
  "glstub_glTexCoord4i" "glstub_glTexCoord4i";
external glTexCoord4iv : word_array -> unit = "glstub_glTexCoord4iv"
  "glstub_glTexCoord4iv";
value glTexCoord4iv p0 =
  let np0 = to_word_array p0 in let r = glTexCoord4iv np0 in r;
external glTexCoord4s : int -> int -> int -> int -> unit =
  "glstub_glTexCoord4s" "glstub_glTexCoord4s";
external glTexCoord4sv : short_array -> unit = "glstub_glTexCoord4sv"
  "glstub_glTexCoord4sv";
value glTexCoord4sv p0 =
  let np0 = to_short_array p0 in let r = glTexCoord4sv np0 in r;
external glTexCoordPointer : int -> int -> int -> 'a -> unit =
  "glstub_glTexCoordPointer" "glstub_glTexCoordPointer";
external glTexEnvf : int -> int -> float -> unit = "glstub_glTexEnvf"
  "glstub_glTexEnvf";
external glTexEnvfv : int -> int -> float_array -> unit = "glstub_glTexEnvfv"
  "glstub_glTexEnvfv";
value glTexEnvfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glTexEnvfv p0 p1 np2 in r;
external glTexEnvi : int -> int -> int -> unit = "glstub_glTexEnvi"
  "glstub_glTexEnvi";
external glTexEnviv : int -> int -> word_array -> unit = "glstub_glTexEnviv"
  "glstub_glTexEnviv";
value glTexEnviv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glTexEnviv p0 p1 np2 in r;
external glTexGend : int -> int -> float -> unit = "glstub_glTexGend"
  "glstub_glTexGend";
external glTexGendv : int -> int -> array float -> unit = "glstub_glTexGendv"
  "glstub_glTexGendv";
external glTexGenf : int -> int -> float -> unit = "glstub_glTexGenf"
  "glstub_glTexGenf";
external glTexGenfv : int -> int -> float_array -> unit = "glstub_glTexGenfv"
  "glstub_glTexGenfv";
value glTexGenfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glTexGenfv p0 p1 np2 in r;
external glTexGeni : int -> int -> int -> unit = "glstub_glTexGeni"
  "glstub_glTexGeni";
external glTexGeniv : int -> int -> word_array -> unit = "glstub_glTexGeniv"
  "glstub_glTexGeniv";
value glTexGeniv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glTexGeniv p0 p1 np2 in r;
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
external glTexParameterfv : int -> int -> float_array -> unit =
  "glstub_glTexParameterfv" "glstub_glTexParameterfv";
value glTexParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glTexParameterfv p0 p1 np2 in r;
external glTexParameteri : int -> int -> int -> unit =
  "glstub_glTexParameteri" "glstub_glTexParameteri";
external glTexParameteriv : int -> int -> word_array -> unit =
  "glstub_glTexParameteriv" "glstub_glTexParameteriv";
value glTexParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glTexParameteriv p0 p1 np2 in r;
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
external glUniform1fv : int -> int -> float_array -> unit =
  "glstub_glUniform1fv" "glstub_glUniform1fv";
value glUniform1fv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glUniform1fv p0 p1 np2 in r;
external glUniform1fvARB : int -> int -> float_array -> unit =
  "glstub_glUniform1fvARB" "glstub_glUniform1fvARB";
value glUniform1fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glUniform1fvARB p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glUniform1i : int -> int -> unit = "glstub_glUniform1i"
  "glstub_glUniform1i";
external glUniform1iARB : int -> int -> unit = "glstub_glUniform1iARB"
  "glstub_glUniform1iARB";
external glUniform1iv : int -> int -> word_array -> unit =
  "glstub_glUniform1iv" "glstub_glUniform1iv";
value glUniform1iv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glUniform1iv p0 p1 np2 in r;
external glUniform1ivARB : int -> int -> word_array -> unit =
  "glstub_glUniform1ivARB" "glstub_glUniform1ivARB";
value glUniform1ivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glUniform1ivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glUniform2f : int -> float -> float -> unit = "glstub_glUniform2f"
  "glstub_glUniform2f";
external glUniform2fARB : int -> float -> float -> unit =
  "glstub_glUniform2fARB" "glstub_glUniform2fARB";
external glUniform2fv : int -> int -> float_array -> unit =
  "glstub_glUniform2fv" "glstub_glUniform2fv";
value glUniform2fv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glUniform2fv p0 p1 np2 in r;
external glUniform2fvARB : int -> int -> float_array -> unit =
  "glstub_glUniform2fvARB" "glstub_glUniform2fvARB";
value glUniform2fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glUniform2fvARB p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glUniform2i : int -> int -> int -> unit = "glstub_glUniform2i"
  "glstub_glUniform2i";
external glUniform2iARB : int -> int -> int -> unit = "glstub_glUniform2iARB"
  "glstub_glUniform2iARB";
external glUniform2iv : int -> int -> word_array -> unit =
  "glstub_glUniform2iv" "glstub_glUniform2iv";
value glUniform2iv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glUniform2iv p0 p1 np2 in r;
external glUniform2ivARB : int -> int -> word_array -> unit =
  "glstub_glUniform2ivARB" "glstub_glUniform2ivARB";
value glUniform2ivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glUniform2ivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glUniform3f : int -> float -> float -> float -> unit =
  "glstub_glUniform3f" "glstub_glUniform3f";
external glUniform3fARB : int -> float -> float -> float -> unit =
  "glstub_glUniform3fARB" "glstub_glUniform3fARB";
external glUniform3fv : int -> int -> float_array -> unit =
  "glstub_glUniform3fv" "glstub_glUniform3fv";
value glUniform3fv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glUniform3fv p0 p1 np2 in r;
external glUniform3fvARB : int -> int -> float_array -> unit =
  "glstub_glUniform3fvARB" "glstub_glUniform3fvARB";
value glUniform3fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glUniform3fvARB p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glUniform3i : int -> int -> int -> int -> unit =
  "glstub_glUniform3i" "glstub_glUniform3i";
external glUniform3iARB : int -> int -> int -> int -> unit =
  "glstub_glUniform3iARB" "glstub_glUniform3iARB";
external glUniform3iv : int -> int -> word_array -> unit =
  "glstub_glUniform3iv" "glstub_glUniform3iv";
value glUniform3iv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glUniform3iv p0 p1 np2 in r;
external glUniform3ivARB : int -> int -> word_array -> unit =
  "glstub_glUniform3ivARB" "glstub_glUniform3ivARB";
value glUniform3ivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glUniform3ivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glUniform4f : int -> float -> float -> float -> float -> unit =
  "glstub_glUniform4f" "glstub_glUniform4f";
external glUniform4fARB : int -> float -> float -> float -> float -> unit =
  "glstub_glUniform4fARB" "glstub_glUniform4fARB";
external glUniform4fv : int -> int -> float_array -> unit =
  "glstub_glUniform4fv" "glstub_glUniform4fv";
value glUniform4fv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glUniform4fv p0 p1 np2 in r;
external glUniform4fvARB : int -> int -> float_array -> unit =
  "glstub_glUniform4fvARB" "glstub_glUniform4fvARB";
value glUniform4fvARB p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glUniform4fvARB p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glUniform4i : int -> int -> int -> int -> int -> unit =
  "glstub_glUniform4i" "glstub_glUniform4i";
external glUniform4iARB : int -> int -> int -> int -> int -> unit =
  "glstub_glUniform4iARB" "glstub_glUniform4iARB";
external glUniform4iv : int -> int -> word_array -> unit =
  "glstub_glUniform4iv" "glstub_glUniform4iv";
value glUniform4iv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glUniform4iv p0 p1 np2 in r;
external glUniform4ivARB : int -> int -> word_array -> unit =
  "glstub_glUniform4ivARB" "glstub_glUniform4ivARB";
value glUniform4ivARB p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glUniform4ivARB p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glUniformMatrix2fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix2fv" "glstub_glUniformMatrix2fv";
value glUniformMatrix2fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in let r = glUniformMatrix2fv p0 p1 p2 np3 in r;
external glUniformMatrix2fvARB : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix2fvARB" "glstub_glUniformMatrix2fvARB";
value glUniformMatrix2fvARB p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix2fvARB p0 p1 p2 np3 in
  let _ = copy_float_array np3 p3 in r;
external glUniformMatrix2x3fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix2x3fv" "glstub_glUniformMatrix2x3fv";
value glUniformMatrix2x3fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix2x3fv p0 p1 p2 np3 in r;
external glUniformMatrix2x4fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix2x4fv" "glstub_glUniformMatrix2x4fv";
value glUniformMatrix2x4fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix2x4fv p0 p1 p2 np3 in r;
external glUniformMatrix3fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix3fv" "glstub_glUniformMatrix3fv";
value glUniformMatrix3fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in let r = glUniformMatrix3fv p0 p1 p2 np3 in r;
external glUniformMatrix3fvARB : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix3fvARB" "glstub_glUniformMatrix3fvARB";
value glUniformMatrix3fvARB p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix3fvARB p0 p1 p2 np3 in
  let _ = copy_float_array np3 p3 in r;
external glUniformMatrix3x2fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix3x2fv" "glstub_glUniformMatrix3x2fv";
value glUniformMatrix3x2fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix3x2fv p0 p1 p2 np3 in r;
external glUniformMatrix3x4fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix3x4fv" "glstub_glUniformMatrix3x4fv";
value glUniformMatrix3x4fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix3x4fv p0 p1 p2 np3 in r;
external glUniformMatrix4fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix4fv" "glstub_glUniformMatrix4fv";
value glUniformMatrix4fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in let r = glUniformMatrix4fv p0 p1 p2 np3 in r;
external glUniformMatrix4fvARB : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix4fvARB" "glstub_glUniformMatrix4fvARB";
value glUniformMatrix4fvARB p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix4fvARB p0 p1 p2 np3 in
  let _ = copy_float_array np3 p3 in r;
external glUniformMatrix4x2fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix4x2fv" "glstub_glUniformMatrix4x2fv";
value glUniformMatrix4x2fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix4x2fv p0 p1 p2 np3 in r;
external glUniformMatrix4x3fv : int -> int -> bool -> float_array -> unit =
  "glstub_glUniformMatrix4x3fv" "glstub_glUniformMatrix4x3fv";
value glUniformMatrix4x3fv p0 p1 p2 p3 =
  let np3 = to_float_array p3 in
  let r = glUniformMatrix4x3fv p0 p1 p2 np3 in r;
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
external glVertex2fv : float_array -> unit = "glstub_glVertex2fv"
  "glstub_glVertex2fv";
value glVertex2fv p0 =
  let np0 = to_float_array p0 in let r = glVertex2fv np0 in r;
external glVertex2i : int -> int -> unit = "glstub_glVertex2i"
  "glstub_glVertex2i";
external glVertex2iv : word_array -> unit = "glstub_glVertex2iv"
  "glstub_glVertex2iv";
value glVertex2iv p0 =
  let np0 = to_word_array p0 in let r = glVertex2iv np0 in r;
external glVertex2s : int -> int -> unit = "glstub_glVertex2s"
  "glstub_glVertex2s";
external glVertex2sv : short_array -> unit = "glstub_glVertex2sv"
  "glstub_glVertex2sv";
value glVertex2sv p0 =
  let np0 = to_short_array p0 in let r = glVertex2sv np0 in r;
external glVertex3d : float -> float -> float -> unit = "glstub_glVertex3d"
  "glstub_glVertex3d";
external glVertex3dv : array float -> unit = "glstub_glVertex3dv"
  "glstub_glVertex3dv";
external glVertex3f : float -> float -> float -> unit = "glstub_glVertex3f"
  "glstub_glVertex3f";
external glVertex3fv : float_array -> unit = "glstub_glVertex3fv"
  "glstub_glVertex3fv";
value glVertex3fv p0 =
  let np0 = to_float_array p0 in let r = glVertex3fv np0 in r;
external glVertex3i : int -> int -> int -> unit = "glstub_glVertex3i"
  "glstub_glVertex3i";
external glVertex3iv : word_array -> unit = "glstub_glVertex3iv"
  "glstub_glVertex3iv";
value glVertex3iv p0 =
  let np0 = to_word_array p0 in let r = glVertex3iv np0 in r;
external glVertex3s : int -> int -> int -> unit = "glstub_glVertex3s"
  "glstub_glVertex3s";
external glVertex3sv : short_array -> unit = "glstub_glVertex3sv"
  "glstub_glVertex3sv";
value glVertex3sv p0 =
  let np0 = to_short_array p0 in let r = glVertex3sv np0 in r;
external glVertex4d : float -> float -> float -> float -> unit =
  "glstub_glVertex4d" "glstub_glVertex4d";
external glVertex4dv : array float -> unit = "glstub_glVertex4dv"
  "glstub_glVertex4dv";
external glVertex4f : float -> float -> float -> float -> unit =
  "glstub_glVertex4f" "glstub_glVertex4f";
external glVertex4fv : float_array -> unit = "glstub_glVertex4fv"
  "glstub_glVertex4fv";
value glVertex4fv p0 =
  let np0 = to_float_array p0 in let r = glVertex4fv np0 in r;
external glVertex4i : int -> int -> int -> int -> unit = "glstub_glVertex4i"
  "glstub_glVertex4i";
external glVertex4iv : word_array -> unit = "glstub_glVertex4iv"
  "glstub_glVertex4iv";
value glVertex4iv p0 =
  let np0 = to_word_array p0 in let r = glVertex4iv np0 in r;
external glVertex4s : int -> int -> int -> int -> unit = "glstub_glVertex4s"
  "glstub_glVertex4s";
external glVertex4sv : short_array -> unit = "glstub_glVertex4sv"
  "glstub_glVertex4sv";
value glVertex4sv p0 =
  let np0 = to_short_array p0 in let r = glVertex4sv np0 in r;
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
external glVertexAttrib1fv : int -> float_array -> unit =
  "glstub_glVertexAttrib1fv" "glstub_glVertexAttrib1fv";
value glVertexAttrib1fv p0 p1 =
  let np1 = to_float_array p1 in let r = glVertexAttrib1fv p0 np1 in r;
external glVertexAttrib1fvARB : int -> float_array -> unit =
  "glstub_glVertexAttrib1fvARB" "glstub_glVertexAttrib1fvARB";
value glVertexAttrib1fvARB p0 p1 =
  let np1 = to_float_array p1 in
  let r = glVertexAttrib1fvARB p0 np1 in let _ = copy_float_array np1 p1 in r;
external glVertexAttrib1s : int -> int -> unit = "glstub_glVertexAttrib1s"
  "glstub_glVertexAttrib1s";
external glVertexAttrib1sARB : int -> int -> unit =
  "glstub_glVertexAttrib1sARB" "glstub_glVertexAttrib1sARB";
external glVertexAttrib1sv : int -> short_array -> unit =
  "glstub_glVertexAttrib1sv" "glstub_glVertexAttrib1sv";
value glVertexAttrib1sv p0 p1 =
  let np1 = to_short_array p1 in let r = glVertexAttrib1sv p0 np1 in r;
external glVertexAttrib1svARB : int -> short_array -> unit =
  "glstub_glVertexAttrib1svARB" "glstub_glVertexAttrib1svARB";
value glVertexAttrib1svARB p0 p1 =
  let np1 = to_short_array p1 in
  let r = glVertexAttrib1svARB p0 np1 in let _ = copy_short_array np1 p1 in r;
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
external glVertexAttrib2fv : int -> float_array -> unit =
  "glstub_glVertexAttrib2fv" "glstub_glVertexAttrib2fv";
value glVertexAttrib2fv p0 p1 =
  let np1 = to_float_array p1 in let r = glVertexAttrib2fv p0 np1 in r;
external glVertexAttrib2fvARB : int -> float_array -> unit =
  "glstub_glVertexAttrib2fvARB" "glstub_glVertexAttrib2fvARB";
value glVertexAttrib2fvARB p0 p1 =
  let np1 = to_float_array p1 in
  let r = glVertexAttrib2fvARB p0 np1 in let _ = copy_float_array np1 p1 in r;
external glVertexAttrib2s : int -> int -> int -> unit =
  "glstub_glVertexAttrib2s" "glstub_glVertexAttrib2s";
external glVertexAttrib2sARB : int -> int -> int -> unit =
  "glstub_glVertexAttrib2sARB" "glstub_glVertexAttrib2sARB";
external glVertexAttrib2sv : int -> short_array -> unit =
  "glstub_glVertexAttrib2sv" "glstub_glVertexAttrib2sv";
value glVertexAttrib2sv p0 p1 =
  let np1 = to_short_array p1 in let r = glVertexAttrib2sv p0 np1 in r;
external glVertexAttrib2svARB : int -> short_array -> unit =
  "glstub_glVertexAttrib2svARB" "glstub_glVertexAttrib2svARB";
value glVertexAttrib2svARB p0 p1 =
  let np1 = to_short_array p1 in
  let r = glVertexAttrib2svARB p0 np1 in let _ = copy_short_array np1 p1 in r;
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
external glVertexAttrib3fv : int -> float_array -> unit =
  "glstub_glVertexAttrib3fv" "glstub_glVertexAttrib3fv";
value glVertexAttrib3fv p0 p1 =
  let np1 = to_float_array p1 in let r = glVertexAttrib3fv p0 np1 in r;
external glVertexAttrib3fvARB : int -> float_array -> unit =
  "glstub_glVertexAttrib3fvARB" "glstub_glVertexAttrib3fvARB";
value glVertexAttrib3fvARB p0 p1 =
  let np1 = to_float_array p1 in
  let r = glVertexAttrib3fvARB p0 np1 in let _ = copy_float_array np1 p1 in r;
external glVertexAttrib3s : int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib3s" "glstub_glVertexAttrib3s";
external glVertexAttrib3sARB : int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib3sARB" "glstub_glVertexAttrib3sARB";
external glVertexAttrib3sv : int -> short_array -> unit =
  "glstub_glVertexAttrib3sv" "glstub_glVertexAttrib3sv";
value glVertexAttrib3sv p0 p1 =
  let np1 = to_short_array p1 in let r = glVertexAttrib3sv p0 np1 in r;
external glVertexAttrib3svARB : int -> short_array -> unit =
  "glstub_glVertexAttrib3svARB" "glstub_glVertexAttrib3svARB";
value glVertexAttrib3svARB p0 p1 =
  let np1 = to_short_array p1 in
  let r = glVertexAttrib3svARB p0 np1 in let _ = copy_short_array np1 p1 in r;
external glVertexAttrib4Nbv : int -> byte_array -> unit =
  "glstub_glVertexAttrib4Nbv" "glstub_glVertexAttrib4Nbv";
value glVertexAttrib4Nbv p0 p1 =
  let np1 = to_byte_array p1 in let r = glVertexAttrib4Nbv p0 np1 in r;
external glVertexAttrib4NbvARB : int -> byte_array -> unit =
  "glstub_glVertexAttrib4NbvARB" "glstub_glVertexAttrib4NbvARB";
value glVertexAttrib4NbvARB p0 p1 =
  let np1 = to_byte_array p1 in
  let r = glVertexAttrib4NbvARB p0 np1 in let _ = copy_byte_array np1 p1 in r;
external glVertexAttrib4Niv : int -> word_array -> unit =
  "glstub_glVertexAttrib4Niv" "glstub_glVertexAttrib4Niv";
value glVertexAttrib4Niv p0 p1 =
  let np1 = to_word_array p1 in let r = glVertexAttrib4Niv p0 np1 in r;
external glVertexAttrib4NivARB : int -> word_array -> unit =
  "glstub_glVertexAttrib4NivARB" "glstub_glVertexAttrib4NivARB";
value glVertexAttrib4NivARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glVertexAttrib4NivARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glVertexAttrib4Nsv : int -> short_array -> unit =
  "glstub_glVertexAttrib4Nsv" "glstub_glVertexAttrib4Nsv";
value glVertexAttrib4Nsv p0 p1 =
  let np1 = to_short_array p1 in let r = glVertexAttrib4Nsv p0 np1 in r;
external glVertexAttrib4NsvARB : int -> short_array -> unit =
  "glstub_glVertexAttrib4NsvARB" "glstub_glVertexAttrib4NsvARB";
value glVertexAttrib4NsvARB p0 p1 =
  let np1 = to_short_array p1 in
  let r = glVertexAttrib4NsvARB p0 np1 in
  let _ = copy_short_array np1 p1 in r;
external glVertexAttrib4Nub : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4Nub" "glstub_glVertexAttrib4Nub";
external glVertexAttrib4NubARB : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4NubARB" "glstub_glVertexAttrib4NubARB";
external glVertexAttrib4Nubv : int -> ubyte_array -> unit =
  "glstub_glVertexAttrib4Nubv" "glstub_glVertexAttrib4Nubv";
value glVertexAttrib4Nubv p0 p1 =
  let np1 = to_ubyte_array p1 in let r = glVertexAttrib4Nubv p0 np1 in r;
external glVertexAttrib4NubvARB : int -> ubyte_array -> unit =
  "glstub_glVertexAttrib4NubvARB" "glstub_glVertexAttrib4NubvARB";
value glVertexAttrib4NubvARB p0 p1 =
  let np1 = to_ubyte_array p1 in
  let r = glVertexAttrib4NubvARB p0 np1 in
  let _ = copy_ubyte_array np1 p1 in r;
external glVertexAttrib4Nuiv : int -> word_array -> unit =
  "glstub_glVertexAttrib4Nuiv" "glstub_glVertexAttrib4Nuiv";
value glVertexAttrib4Nuiv p0 p1 =
  let np1 = to_word_array p1 in let r = glVertexAttrib4Nuiv p0 np1 in r;
external glVertexAttrib4NuivARB : int -> word_array -> unit =
  "glstub_glVertexAttrib4NuivARB" "glstub_glVertexAttrib4NuivARB";
value glVertexAttrib4NuivARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glVertexAttrib4NuivARB p0 np1 in
  let _ = copy_word_array np1 p1 in r;
external glVertexAttrib4Nusv : int -> ushort_array -> unit =
  "glstub_glVertexAttrib4Nusv" "glstub_glVertexAttrib4Nusv";
value glVertexAttrib4Nusv p0 p1 =
  let np1 = to_ushort_array p1 in let r = glVertexAttrib4Nusv p0 np1 in r;
external glVertexAttrib4NusvARB : int -> ushort_array -> unit =
  "glstub_glVertexAttrib4NusvARB" "glstub_glVertexAttrib4NusvARB";
value glVertexAttrib4NusvARB p0 p1 =
  let np1 = to_ushort_array p1 in
  let r = glVertexAttrib4NusvARB p0 np1 in
  let _ = copy_ushort_array np1 p1 in r;
external glVertexAttrib4bv : int -> byte_array -> unit =
  "glstub_glVertexAttrib4bv" "glstub_glVertexAttrib4bv";
value glVertexAttrib4bv p0 p1 =
  let np1 = to_byte_array p1 in let r = glVertexAttrib4bv p0 np1 in r;
external glVertexAttrib4bvARB : int -> byte_array -> unit =
  "glstub_glVertexAttrib4bvARB" "glstub_glVertexAttrib4bvARB";
value glVertexAttrib4bvARB p0 p1 =
  let np1 = to_byte_array p1 in
  let r = glVertexAttrib4bvARB p0 np1 in let _ = copy_byte_array np1 p1 in r;
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
external glVertexAttrib4fv : int -> float_array -> unit =
  "glstub_glVertexAttrib4fv" "glstub_glVertexAttrib4fv";
value glVertexAttrib4fv p0 p1 =
  let np1 = to_float_array p1 in let r = glVertexAttrib4fv p0 np1 in r;
external glVertexAttrib4fvARB : int -> float_array -> unit =
  "glstub_glVertexAttrib4fvARB" "glstub_glVertexAttrib4fvARB";
value glVertexAttrib4fvARB p0 p1 =
  let np1 = to_float_array p1 in
  let r = glVertexAttrib4fvARB p0 np1 in let _ = copy_float_array np1 p1 in r;
external glVertexAttrib4iv : int -> word_array -> unit =
  "glstub_glVertexAttrib4iv" "glstub_glVertexAttrib4iv";
value glVertexAttrib4iv p0 p1 =
  let np1 = to_word_array p1 in let r = glVertexAttrib4iv p0 np1 in r;
external glVertexAttrib4ivARB : int -> word_array -> unit =
  "glstub_glVertexAttrib4ivARB" "glstub_glVertexAttrib4ivARB";
value glVertexAttrib4ivARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glVertexAttrib4ivARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glVertexAttrib4s : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4s" "glstub_glVertexAttrib4s";
external glVertexAttrib4sARB : int -> int -> int -> int -> int -> unit =
  "glstub_glVertexAttrib4sARB" "glstub_glVertexAttrib4sARB";
external glVertexAttrib4sv : int -> short_array -> unit =
  "glstub_glVertexAttrib4sv" "glstub_glVertexAttrib4sv";
value glVertexAttrib4sv p0 p1 =
  let np1 = to_short_array p1 in let r = glVertexAttrib4sv p0 np1 in r;
external glVertexAttrib4svARB : int -> short_array -> unit =
  "glstub_glVertexAttrib4svARB" "glstub_glVertexAttrib4svARB";
value glVertexAttrib4svARB p0 p1 =
  let np1 = to_short_array p1 in
  let r = glVertexAttrib4svARB p0 np1 in let _ = copy_short_array np1 p1 in r;
external glVertexAttrib4ubv : int -> ubyte_array -> unit =
  "glstub_glVertexAttrib4ubv" "glstub_glVertexAttrib4ubv";
value glVertexAttrib4ubv p0 p1 =
  let np1 = to_ubyte_array p1 in let r = glVertexAttrib4ubv p0 np1 in r;
external glVertexAttrib4ubvARB : int -> ubyte_array -> unit =
  "glstub_glVertexAttrib4ubvARB" "glstub_glVertexAttrib4ubvARB";
value glVertexAttrib4ubvARB p0 p1 =
  let np1 = to_ubyte_array p1 in
  let r = glVertexAttrib4ubvARB p0 np1 in
  let _ = copy_ubyte_array np1 p1 in r;
external glVertexAttrib4uiv : int -> word_array -> unit =
  "glstub_glVertexAttrib4uiv" "glstub_glVertexAttrib4uiv";
value glVertexAttrib4uiv p0 p1 =
  let np1 = to_word_array p1 in let r = glVertexAttrib4uiv p0 np1 in r;
external glVertexAttrib4uivARB : int -> word_array -> unit =
  "glstub_glVertexAttrib4uivARB" "glstub_glVertexAttrib4uivARB";
value glVertexAttrib4uivARB p0 p1 =
  let np1 = to_word_array p1 in
  let r = glVertexAttrib4uivARB p0 np1 in let _ = copy_word_array np1 p1 in r;
external glVertexAttrib4usv : int -> ushort_array -> unit =
  "glstub_glVertexAttrib4usv" "glstub_glVertexAttrib4usv";
value glVertexAttrib4usv p0 p1 =
  let np1 = to_ushort_array p1 in let r = glVertexAttrib4usv p0 np1 in r;
external glVertexAttrib4usvARB : int -> ushort_array -> unit =
  "glstub_glVertexAttrib4usvARB" "glstub_glVertexAttrib4usvARB";
value glVertexAttrib4usvARB p0 p1 =
  let np1 = to_ushort_array p1 in
  let r = glVertexAttrib4usvARB p0 np1 in
  let _ = copy_ushort_array np1 p1 in r;
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
external glWindowPos2fv : float_array -> unit = "glstub_glWindowPos2fv"
  "glstub_glWindowPos2fv";
value glWindowPos2fv p0 =
  let np0 = to_float_array p0 in let r = glWindowPos2fv np0 in r;
external glWindowPos2fvARB : float_array -> unit = "glstub_glWindowPos2fvARB"
  "glstub_glWindowPos2fvARB";
value glWindowPos2fvARB p0 =
  let np0 = to_float_array p0 in
  let r = glWindowPos2fvARB np0 in let _ = copy_float_array np0 p0 in r;
external glWindowPos2i : int -> int -> unit = "glstub_glWindowPos2i"
  "glstub_glWindowPos2i";
external glWindowPos2iARB : int -> int -> unit = "glstub_glWindowPos2iARB"
  "glstub_glWindowPos2iARB";
external glWindowPos2iv : word_array -> unit = "glstub_glWindowPos2iv"
  "glstub_glWindowPos2iv";
value glWindowPos2iv p0 =
  let np0 = to_word_array p0 in let r = glWindowPos2iv np0 in r;
external glWindowPos2ivARB : word_array -> unit = "glstub_glWindowPos2ivARB"
  "glstub_glWindowPos2ivARB";
value glWindowPos2ivARB p0 =
  let np0 = to_word_array p0 in
  let r = glWindowPos2ivARB np0 in let _ = copy_word_array np0 p0 in r;
external glWindowPos2s : int -> int -> unit = "glstub_glWindowPos2s"
  "glstub_glWindowPos2s";
external glWindowPos2sARB : int -> int -> unit = "glstub_glWindowPos2sARB"
  "glstub_glWindowPos2sARB";
external glWindowPos2sv : short_array -> unit = "glstub_glWindowPos2sv"
  "glstub_glWindowPos2sv";
value glWindowPos2sv p0 =
  let np0 = to_short_array p0 in let r = glWindowPos2sv np0 in r;
external glWindowPos2svARB : short_array -> unit = "glstub_glWindowPos2svARB"
  "glstub_glWindowPos2svARB";
value glWindowPos2svARB p0 =
  let np0 = to_short_array p0 in
  let r = glWindowPos2svARB np0 in let _ = copy_short_array np0 p0 in r;
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
external glWindowPos3fv : float_array -> unit = "glstub_glWindowPos3fv"
  "glstub_glWindowPos3fv";
value glWindowPos3fv p0 =
  let np0 = to_float_array p0 in let r = glWindowPos3fv np0 in r;
external glWindowPos3fvARB : float_array -> unit = "glstub_glWindowPos3fvARB"
  "glstub_glWindowPos3fvARB";
value glWindowPos3fvARB p0 =
  let np0 = to_float_array p0 in
  let r = glWindowPos3fvARB np0 in let _ = copy_float_array np0 p0 in r;
external glWindowPos3i : int -> int -> int -> unit = "glstub_glWindowPos3i"
  "glstub_glWindowPos3i";
external glWindowPos3iARB : int -> int -> int -> unit =
  "glstub_glWindowPos3iARB" "glstub_glWindowPos3iARB";
external glWindowPos3iv : word_array -> unit = "glstub_glWindowPos3iv"
  "glstub_glWindowPos3iv";
value glWindowPos3iv p0 =
  let np0 = to_word_array p0 in let r = glWindowPos3iv np0 in r;
external glWindowPos3ivARB : word_array -> unit = "glstub_glWindowPos3ivARB"
  "glstub_glWindowPos3ivARB";
value glWindowPos3ivARB p0 =
  let np0 = to_word_array p0 in
  let r = glWindowPos3ivARB np0 in let _ = copy_word_array np0 p0 in r;
external glWindowPos3s : int -> int -> int -> unit = "glstub_glWindowPos3s"
  "glstub_glWindowPos3s";
external glWindowPos3sARB : int -> int -> int -> unit =
  "glstub_glWindowPos3sARB" "glstub_glWindowPos3sARB";
external glWindowPos3sv : short_array -> unit = "glstub_glWindowPos3sv"
  "glstub_glWindowPos3sv";
value glWindowPos3sv p0 =
  let np0 = to_short_array p0 in let r = glWindowPos3sv np0 in r;
external glWindowPos3svARB : short_array -> unit = "glstub_glWindowPos3svARB"
  "glstub_glWindowPos3svARB";
value glWindowPos3svARB p0 =
  let np0 = to_short_array p0 in
  let r = glWindowPos3svARB np0 in let _ = copy_short_array np0 p0 in r;

