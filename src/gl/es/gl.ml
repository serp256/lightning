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
value gl_depth_buffer_bit = 0x00000100;
value gl_stencil_buffer_bit = 0x00000400;
value gl_color_buffer_bit = 0x00004000;
value gl_false = 0x00000000;
value gl_true = 0x00000001;
value gl_points = 0x00000000;
value gl_lines = 0x00000001;
value gl_line_loop = 0x00000002;
value gl_line_strip = 0x00000003;
value gl_triangles = 0x00000004;
value gl_triangle_strip = 0x00000005;
value gl_triangle_fan = 0x00000006;
value gl_never = 0x00000200;
value gl_less = 0x00000201;
value gl_equal = 0x00000202;
value gl_lequal = 0x00000203;
value gl_greater = 0x00000204;
value gl_notequal = 0x00000205;
value gl_gequal = 0x00000206;
value gl_always = 0x00000207;
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
value gl_clip_plane0 = 0x00003000;
value gl_clip_plane1 = 0x00003001;
value gl_clip_plane2 = 0x00003002;
value gl_clip_plane3 = 0x00003003;
value gl_clip_plane4 = 0x00003004;
value gl_clip_plane5 = 0x00003005;
value gl_front = 0x00000404;
value gl_back = 0x00000405;
value gl_front_and_back = 0x00000408;
value gl_fog = 0x00000b60;
value gl_lighting = 0x00000b50;
value gl_texture_2d = 0x00000de1;
value gl_cull_face = 0x00000b44;
value gl_alpha_test = 0x00000bc0;
value gl_blend = 0x00000be2;
value gl_color_logic_op = 0x00000bf2;
value gl_dither = 0x00000bd0;
value gl_stencil_test = 0x00000b90;
value gl_depth_test = 0x00000b71;
value gl_point_smooth = 0x00000b10;
value gl_line_smooth = 0x00000b20;
value gl_scissor_test = 0x00000c11;
value gl_color_material = 0x00000b57;
value gl_normalize = 0x00000ba1;
value gl_rescale_normal = 0x0000803a;
value gl_polygon_offset_fill = 0x00008037;
value gl_vertex_array = 0x00008074;
value gl_normal_array = 0x00008075;
value gl_color_array = 0x00008076;
value gl_texture_coord_array = 0x00008078;
value gl_multisample = 0x0000809d;
value gl_sample_alpha_to_coverage = 0x0000809e;
value gl_sample_alpha_to_one = 0x0000809f;
value gl_sample_coverage = 0x000080a0;
value gl_no_error = 0x00000000;
value gl_invalid_enum = 0x00000500;
value gl_invalid_value = 0x00000501;
value gl_invalid_operation = 0x00000502;
value gl_stack_overflow = 0x00000503;
value gl_stack_underflow = 0x00000504;
value gl_out_of_memory = 0x00000505;
value gl_exp = 0x00000800;
value gl_exp2 = 0x00000801;
value gl_fog_density = 0x00000b62;
value gl_fog_start = 0x00000b63;
value gl_fog_end = 0x00000b64;
value gl_fog_mode = 0x00000b65;
value gl_fog_color = 0x00000b66;
value gl_cw = 0x00000900;
value gl_ccw = 0x00000901;
value gl_current_color = 0x00000b00;
value gl_current_normal = 0x00000b02;
value gl_current_texture_coords = 0x00000b03;
value gl_point_size = 0x00000b11;
value gl_point_size_min = 0x00008126;
value gl_point_size_max = 0x00008127;
value gl_point_fade_threshold_size = 0x00008128;
value gl_point_distance_attenuation = 0x00008129;
value gl_smooth_point_size_range = 0x00000b12;
value gl_line_width = 0x00000b21;
value gl_smooth_line_width_range = 0x00000b22;
value gl_aliased_point_size_range = 0x0000846d;
value gl_aliased_line_width_range = 0x0000846e;
value gl_cull_face_mode = 0x00000b45;
value gl_front_face = 0x00000b46;
value gl_shade_model = 0x00000b54;
value gl_depth_range = 0x00000b70;
value gl_depth_writemask = 0x00000b72;
value gl_depth_clear_value = 0x00000b73;
value gl_depth_func = 0x00000b74;
value gl_stencil_clear_value = 0x00000b91;
value gl_stencil_func = 0x00000b92;
value gl_stencil_value_mask = 0x00000b93;
value gl_stencil_fail = 0x00000b94;
value gl_stencil_pass_depth_fail = 0x00000b95;
value gl_stencil_pass_depth_pass = 0x00000b96;
value gl_stencil_ref = 0x00000b97;
value gl_stencil_writemask = 0x00000b98;
value gl_matrix_mode = 0x00000ba0;
value gl_viewport = 0x00000ba2;
value gl_modelview_stack_depth = 0x00000ba3;
value gl_projection_stack_depth = 0x00000ba4;
value gl_texture_stack_depth = 0x00000ba5;
value gl_modelview_matrix = 0x00000ba6;
value gl_projection_matrix = 0x00000ba7;
value gl_texture_matrix = 0x00000ba8;
value gl_alpha_test_func = 0x00000bc1;
value gl_alpha_test_ref = 0x00000bc2;
value gl_blend_dst = 0x00000be0;
value gl_blend_src = 0x00000be1;
value gl_logic_op_mode = 0x00000bf0;
value gl_scissor_box = 0x00000c10;
value gl_scissor_test = 0x00000c11;
value gl_color_clear_value = 0x00000c22;
value gl_color_writemask = 0x00000c23;
value gl_unpack_alignment = 0x00000cf5;
value gl_pack_alignment = 0x00000d05;
value gl_max_lights = 0x00000d31;
value gl_max_clip_planes = 0x00000d32;
value gl_max_texture_size = 0x00000d33;
value gl_max_modelview_stack_depth = 0x00000d36;
value gl_max_projection_stack_depth = 0x00000d38;
value gl_max_texture_stack_depth = 0x00000d39;
value gl_max_viewport_dims = 0x00000d3a;
value gl_max_texture_units = 0x000084e2;
value gl_subpixel_bits = 0x00000d50;
value gl_red_bits = 0x00000d52;
value gl_green_bits = 0x00000d53;
value gl_blue_bits = 0x00000d54;
value gl_alpha_bits = 0x00000d55;
value gl_depth_bits = 0x00000d56;
value gl_stencil_bits = 0x00000d57;
value gl_polygon_offset_units = 0x00002a00;
value gl_polygon_offset_fill = 0x00008037;
value gl_polygon_offset_factor = 0x00008038;
value gl_texture_binding_2d = 0x00008069;
value gl_vertex_array_size = 0x0000807a;
value gl_vertex_array_type = 0x0000807b;
value gl_vertex_array_stride = 0x0000807c;
value gl_normal_array_type = 0x0000807e;
value gl_normal_array_stride = 0x0000807f;
value gl_color_array_size = 0x00008081;
value gl_color_array_type = 0x00008082;
value gl_color_array_stride = 0x00008083;
value gl_texture_coord_array_size = 0x00008088;
value gl_texture_coord_array_type = 0x00008089;
value gl_texture_coord_array_stride = 0x0000808a;
value gl_vertex_array_pointer = 0x0000808e;
value gl_normal_array_pointer = 0x0000808f;
value gl_color_array_pointer = 0x00008090;
value gl_texture_coord_array_pointer = 0x00008092;
value gl_sample_buffers = 0x000080a8;
value gl_samples = 0x000080a9;
value gl_sample_coverage_value = 0x000080aa;
value gl_sample_coverage_invert = 0x000080ab;
value gl_implementation_color_read_type_oes = 0x00008b9a;
value gl_implementation_color_read_format_oes = 0x00008b9b;
value gl_num_compressed_texture_formats = 0x000086a2;
value gl_compressed_texture_formats = 0x000086a3;
value gl_dont_care = 0x00001100;
value gl_fastest = 0x00001101;
value gl_nicest = 0x00001102;
value gl_perspective_correction_hint = 0x00000c50;
value gl_point_smooth_hint = 0x00000c51;
value gl_line_smooth_hint = 0x00000c52;
value gl_fog_hint = 0x00000c54;
value gl_generate_mipmap_hint = 0x00008192;
value gl_light_model_ambient = 0x00000b53;
value gl_light_model_two_side = 0x00000b52;
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
value gl_byte = 0x00001400;
value gl_unsigned_byte = 0x00001401;
value gl_short = 0x00001402;
value gl_unsigned_short = 0x00001403;
value gl_float = 0x00001406;
value gl_fixed = 0x0000140c;
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
value gl_modelview = 0x00001700;
value gl_projection = 0x00001701;
value gl_texture = 0x00001702;
value gl_alpha = 0x00001906;
value gl_rgb = 0x00001907;
value gl_rgba = 0x00001908;
value gl_luminance = 0x00001909;
value gl_luminance_alpha = 0x0000190a;
value gl_unpack_alignment = 0x00000cf5;
value gl_pack_alignment = 0x00000d05;
value gl_unsigned_short_4_4_4_4 = 0x00008033;
value gl_unsigned_short_5_5_5_1 = 0x00008034;
value gl_unsigned_short_5_6_5 = 0x00008363;
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
value gl_modulate = 0x00002100;
value gl_decal = 0x00002101;
value gl_add = 0x00000104;
value gl_texture_env_mode = 0x00002200;
value gl_texture_env_color = 0x00002201;
value gl_texture_env = 0x00002300;
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
value gl_generate_mipmap = 0x00008191;
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
value gl_repeat = 0x00002901;
value gl_clamp_to_edge = 0x0000812f;
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
value gl_light0 = 0x00004000;
value gl_light1 = 0x00004001;
value gl_light2 = 0x00004002;
value gl_light3 = 0x00004003;
value gl_light4 = 0x00004004;
value gl_light5 = 0x00004005;
value gl_light6 = 0x00004006;
value gl_light7 = 0x00004007;
value gl_array_buffer = 0x00008892;
value gl_element_array_buffer = 0x00008893;
value gl_array_buffer_binding = 0x00008894;
value gl_element_array_buffer_binding = 0x00008895;
value gl_vertex_array_buffer_binding = 0x00008896;
value gl_normal_array_buffer_binding = 0x00008897;
value gl_color_array_buffer_binding = 0x00008898;
value gl_texture_coord_array_buffer_binding = 0x0000889a;
value gl_static_draw = 0x000088e4;
value gl_dynamic_draw = 0x000088e8;
value gl_buffer_size = 0x00008764;
value gl_buffer_usage = 0x00008765;
value gl_subtract = 0x000084e7;
value gl_combine = 0x00008570;
value gl_combine_rgb = 0x00008571;
value gl_combine_alpha = 0x00008572;
value gl_rgb_scale = 0x00008573;
value gl_add_signed = 0x00008574;
value gl_interpolate = 0x00008575;
value gl_constant = 0x00008576;
value gl_primary_color = 0x00008577;
value gl_previous = 0x00008578;
value gl_operand0_rgb = 0x00008590;
value gl_operand1_rgb = 0x00008591;
value gl_operand2_rgb = 0x00008592;
value gl_operand0_alpha = 0x00008598;
value gl_operand1_alpha = 0x00008599;
value gl_operand2_alpha = 0x0000859a;
value gl_alpha_scale = 0x00000d1c;
value gl_src0_rgb = 0x00008580;
value gl_src1_rgb = 0x00008581;
value gl_src2_rgb = 0x00008582;
value gl_src0_alpha = 0x00008588;
value gl_src1_alpha = 0x00008589;
value gl_src2_alpha = 0x0000858a;
value gl_dot3_rgb = 0x000086ae;
value gl_dot3_rgba = 0x000086af;
value gl_texture_crop_rect_oes = 0x00008b9d;
value gl_modelview_matrix_float_as_int_bits_oes = 0x0000898d;
value gl_projection_matrix_float_as_int_bits_oes = 0x0000898e;
value gl_texture_matrix_float_as_int_bits_oes = 0x0000898f;
value gl_max_vertex_units_oes = 0x000086a4;
value gl_max_palette_matrices_oes = 0x00008842;
value gl_matrix_palette_oes = 0x00008840;
value gl_matrix_index_array_oes = 0x00008844;
value gl_weight_array_oes = 0x000086ad;
value gl_current_palette_matrix_oes = 0x00008843;
value gl_matrix_index_array_size_oes = 0x00008846;
value gl_matrix_index_array_type_oes = 0x00008847;
value gl_matrix_index_array_stride_oes = 0x00008848;
value gl_matrix_index_array_pointer_oes = 0x00008849;
value gl_matrix_index_array_buffer_binding_oes = 0x00008b9e;
value gl_weight_array_size_oes = 0x000086ab;
value gl_weight_array_type_oes = 0x000086a9;
value gl_weight_array_stride_oes = 0x000086aa;
value gl_weight_array_pointer_oes = 0x000086ac;
value gl_weight_array_buffer_binding_oes = 0x0000889e;
value gl_point_size_array_oes = 0x00008b9c;
value gl_point_size_array_type_oes = 0x0000898a;
value gl_point_size_array_stride_oes = 0x0000898b;
value gl_point_size_array_pointer_oes = 0x0000898c;
value gl_point_size_array_buffer_binding_oes = 0x00008b9f;
value gl_point_sprite_oes = 0x00008861;
value gl_coord_replace_oes = 0x00008862;
value gl_compressed_rgb_pvrtc_4bppv1_img = 0x00008c00;
value gl_compressed_rgb_pvrtc_2bppv1_img = 0x00008c01;
value gl_compressed_rgba_pvrtc_4bppv1_img = 0x00008c02;
value gl_compressed_rgba_pvrtc_2bppv1_img = 0x00008c03;
external glActiveTexture : int -> unit = "glstub_glActiveTexture"
  "glstub_glActiveTexture" "noalloc";
external glAlphaFunc : int -> float -> unit = "glstub_glAlphaFunc"
  "glstub_glAlphaFunc" "noalloc";
external glBindBuffer : int -> int -> unit = "glstub_glBindBuffer"
  "glstub_glBindBuffer" "noalloc";
external glBindTexture : int -> int -> unit = "glstub_glBindTexture"
  "glstub_glBindTexture" "noalloc";
external glBlendFunc : int -> int -> unit = "glstub_glBlendFunc"
  "glstub_glBlendFunc" "noalloc";
external glBufferData : int -> int -> 'a -> int -> unit =
  "glstub_glBufferData" "glstub_glBufferData" "noalloc";
external glBufferSubData : int -> int -> int -> 'a -> unit =
  "glstub_glBufferSubData" "glstub_glBufferSubData" "noalloc";
external glClear : int -> unit = "glstub_glClear" "glstub_glClear" "noalloc";
external glClearColor : float -> float -> float -> float -> unit =
  "glstub_glClearColor" "glstub_glClearColor" "noalloc";
external glClearDepthf : float -> unit = "glstub_glClearDepthf"
  "glstub_glClearDepthf" "noalloc";
external glClearStencil : int -> unit = "glstub_glClearStencil"
  "glstub_glClearStencil" "noalloc";
external glClientActiveTexture : int -> unit = "glstub_glClientActiveTexture"
  "glstub_glClientActiveTexture" "noalloc";
external glClipPlanef : int -> float_array -> unit = "glstub_glClipPlanef"
  "glstub_glClipPlanef" "noalloc";
value glClipPlanef p0 p1 =
  let np1 = to_float_array p1 in let r = glClipPlanef p0 np1 in r;
external glColor4f : float -> float -> float -> float -> unit =
  "glstub_glColor4f" "glstub_glColor4f" "noalloc";
external glColor4ub : int -> int -> int -> int -> unit = "glstub_glColor4ub"
  "glstub_glColor4ub" "noalloc";
external glColorMask : bool -> bool -> bool -> bool -> unit =
  "glstub_glColorMask" "glstub_glColorMask" "noalloc";
external glColorPointer : int -> int -> int -> 'a -> unit =
  "glstub_glColorPointer" "glstub_glColorPointer" "noalloc";
external glCompressedTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexImage2D_byte" "glstub_glCompressedTexImage2D"
  "noalloc";
external glCompressedTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glCompressedTexSubImage2D_byte" "glstub_glCompressedTexSubImage2D"
  "noalloc";
external glCopyTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexImage2D_byte" "glstub_glCopyTexImage2D" "noalloc";
external glCopyTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> unit =
  "glstub_glCopyTexSubImage2D_byte" "glstub_glCopyTexSubImage2D" "noalloc";
external glCullFace : int -> unit = "glstub_glCullFace" "glstub_glCullFace"
  "noalloc";
external glCurrentPaletteMatrixOES : int -> unit =
  "glstub_glCurrentPaletteMatrixOES" "glstub_glCurrentPaletteMatrixOES"
  "noalloc";
external glDeleteBuffers : int -> word_array -> unit =
  "glstub_glDeleteBuffers" "glstub_glDeleteBuffers" "noalloc";
value glDeleteBuffers p0 p1 =
  let np1 = to_word_array p1 in let r = glDeleteBuffers p0 np1 in r;
external glDeleteTextures : int -> word_array -> unit =
  "glstub_glDeleteTextures" "glstub_glDeleteTextures" "noalloc";
value glDeleteTextures p0 p1 =
  let np1 = to_word_array p1 in let r = glDeleteTextures p0 np1 in r;
external glDepthFunc : int -> unit = "glstub_glDepthFunc"
  "glstub_glDepthFunc" "noalloc";
external glDepthMask : bool -> unit = "glstub_glDepthMask"
  "glstub_glDepthMask" "noalloc";
external glDepthRangef : float -> float -> unit = "glstub_glDepthRangef"
  "glstub_glDepthRangef" "noalloc";
external glDisable : int -> unit = "glstub_glDisable" "glstub_glDisable"
  "noalloc";
external glDisableClientState : int -> unit = "glstub_glDisableClientState"
  "glstub_glDisableClientState" "noalloc";
external glDrawArrays : int -> int -> int -> unit = "glstub_glDrawArrays"
  "glstub_glDrawArrays" "noalloc";
external glDrawElements : int -> int -> int -> 'a -> unit =
  "glstub_glDrawElements" "glstub_glDrawElements" "noalloc";
external glDrawTexfOES : float -> float -> float -> float -> float -> unit =
  "glstub_glDrawTexfOES" "glstub_glDrawTexfOES" "noalloc";
external glDrawTexfvOES : float_array -> unit = "glstub_glDrawTexfvOES"
  "glstub_glDrawTexfvOES" "noalloc";
value glDrawTexfvOES p0 =
  let np0 = to_float_array p0 in let r = glDrawTexfvOES np0 in r;
external glDrawTexiOES : int -> int -> int -> int -> int -> unit =
  "glstub_glDrawTexiOES" "glstub_glDrawTexiOES" "noalloc";
external glDrawTexivOES : word_array -> unit = "glstub_glDrawTexivOES"
  "glstub_glDrawTexivOES" "noalloc";
value glDrawTexivOES p0 =
  let np0 = to_word_array p0 in let r = glDrawTexivOES np0 in r;
external glDrawTexsOES : int -> int -> int -> int -> int -> unit =
  "glstub_glDrawTexsOES" "glstub_glDrawTexsOES" "noalloc";
external glDrawTexsvOES : short_array -> unit = "glstub_glDrawTexsvOES"
  "glstub_glDrawTexsvOES" "noalloc";
value glDrawTexsvOES p0 =
  let np0 = to_short_array p0 in let r = glDrawTexsvOES np0 in r;
external glEnable : int -> unit = "glstub_glEnable" "glstub_glEnable"
  "noalloc";
external glEnableClientState : int -> unit = "glstub_glEnableClientState"
  "glstub_glEnableClientState" "noalloc";
external glFinish : unit -> unit = "glstub_glFinish" "glstub_glFinish"
  "noalloc";
external glFlush : unit -> unit = "glstub_glFlush" "glstub_glFlush"
  "noalloc";
external glFogf : int -> float -> unit = "glstub_glFogf" "glstub_glFogf"
  "noalloc";
external glFogfv : int -> float_array -> unit = "glstub_glFogfv"
  "glstub_glFogfv" "noalloc";
value glFogfv p0 p1 =
  let np1 = to_float_array p1 in let r = glFogfv p0 np1 in r;
external glFrontFace : int -> unit = "glstub_glFrontFace"
  "glstub_glFrontFace" "noalloc";
external glFrustumf :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glFrustumf_byte" "glstub_glFrustumf" "noalloc";
external glGenBuffers : int -> word_array -> unit = "glstub_glGenBuffers"
  "glstub_glGenBuffers" "noalloc";
value glGenBuffers p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenBuffers p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGenTextures : int -> word_array -> unit = "glstub_glGenTextures"
  "glstub_glGenTextures" "noalloc";
value glGenTextures p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGenTextures p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGetBooleanv : int -> word_array -> unit = "glstub_glGetBooleanv"
  "glstub_glGetBooleanv" "noalloc";
value glGetBooleanv p0 p1 =
  let np1 = to_word_array (bool_to_int_array p1) in
  let r = glGetBooleanv p0 np1 in
  let bp1 = Array.create (Bigarray.Array1.dim np1) 0 in
  let _ = copy_word_array np1 bp1 in let _ = copy_to_bool_array bp1 p1 in r;
external glGetBufferParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetBufferParameteriv" "glstub_glGetBufferParameteriv" "noalloc";
value glGetBufferParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetBufferParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glGetClipPlanef : int -> float_array -> unit =
  "glstub_glGetClipPlanef" "glstub_glGetClipPlanef" "noalloc";
value glGetClipPlanef p0 p1 =
  let np1 = to_float_array p1 in
  let r = glGetClipPlanef p0 np1 in let _ = copy_float_array np1 p1 in r;
external glGetError : unit -> int = "glstub_glGetError" "glstub_glGetError";
external glGetFloatv : int -> float_array -> unit = "glstub_glGetFloatv"
  "glstub_glGetFloatv" "noalloc";
value glGetFloatv p0 p1 =
  let np1 = to_float_array p1 in
  let r = glGetFloatv p0 np1 in let _ = copy_float_array np1 p1 in r;
external glGetIntegerv : int -> word_array -> unit = "glstub_glGetIntegerv"
  "glstub_glGetIntegerv" "noalloc";
value glGetIntegerv p0 p1 =
  let np1 = to_word_array p1 in
  let r = glGetIntegerv p0 np1 in let _ = copy_word_array np1 p1 in r;
external glGetLightfv : int -> int -> float_array -> unit =
  "glstub_glGetLightfv" "glstub_glGetLightfv" "noalloc";
value glGetLightfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetLightfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetMaterialfv : int -> int -> float_array -> unit =
  "glstub_glGetMaterialfv" "glstub_glGetMaterialfv" "noalloc";
value glGetMaterialfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetMaterialfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetTexEnvfv : int -> int -> float_array -> unit =
  "glstub_glGetTexEnvfv" "glstub_glGetTexEnvfv" "noalloc";
value glGetTexEnvfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetTexEnvfv p0 p1 np2 in let _ = copy_float_array np2 p2 in r;
external glGetTexEnviv : int -> int -> word_array -> unit =
  "glstub_glGetTexEnviv" "glstub_glGetTexEnviv" "noalloc";
value glGetTexEnviv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetTexEnviv p0 p1 np2 in let _ = copy_word_array np2 p2 in r;
external glGetTexParameterfv : int -> int -> float_array -> unit =
  "glstub_glGetTexParameterfv" "glstub_glGetTexParameterfv" "noalloc";
value glGetTexParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in
  let r = glGetTexParameterfv p0 p1 np2 in
  let _ = copy_float_array np2 p2 in r;
external glGetTexParameteriv : int -> int -> word_array -> unit =
  "glstub_glGetTexParameteriv" "glstub_glGetTexParameteriv" "noalloc";
value glGetTexParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in
  let r = glGetTexParameteriv p0 p1 np2 in
  let _ = copy_word_array np2 p2 in r;
external glHint : int -> int -> unit = "glstub_glHint" "glstub_glHint"
  "noalloc";
external glIsBuffer : int -> bool = "glstub_glIsBuffer" "glstub_glIsBuffer";
external glIsEnabled : int -> bool = "glstub_glIsEnabled"
  "glstub_glIsEnabled";
external glIsTexture : int -> bool = "glstub_glIsTexture"
  "glstub_glIsTexture";
external glLightModelf : int -> float -> unit = "glstub_glLightModelf"
  "glstub_glLightModelf" "noalloc";
external glLightModelfv : int -> float_array -> unit =
  "glstub_glLightModelfv" "glstub_glLightModelfv" "noalloc";
value glLightModelfv p0 p1 =
  let np1 = to_float_array p1 in let r = glLightModelfv p0 np1 in r;
external glLightf : int -> int -> float -> unit = "glstub_glLightf"
  "glstub_glLightf" "noalloc";
external glLightfv : int -> int -> float_array -> unit = "glstub_glLightfv"
  "glstub_glLightfv" "noalloc";
value glLightfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glLightfv p0 p1 np2 in r;
external glLineWidth : float -> unit = "glstub_glLineWidth"
  "glstub_glLineWidth" "noalloc";
external glLoadIdentity : unit -> unit = "glstub_glLoadIdentity"
  "glstub_glLoadIdentity" "noalloc";
external glLoadMatrixf : float_array -> unit = "glstub_glLoadMatrixf"
  "glstub_glLoadMatrixf" "noalloc";
value glLoadMatrixf p0 =
  let np0 = to_float_array p0 in let r = glLoadMatrixf np0 in r;
external glLoadPaletteFromModelViewMatrixOES : unit -> unit =
  "glstub_glLoadPaletteFromModelViewMatrixOES"
  "glstub_glLoadPaletteFromModelViewMatrixOES" "noalloc";
external glLogicOp : int -> unit = "glstub_glLogicOp" "glstub_glLogicOp"
  "noalloc";
external glMaterialf : int -> int -> float -> unit = "glstub_glMaterialf"
  "glstub_glMaterialf" "noalloc";
external glMaterialfv : int -> int -> float_array -> unit =
  "glstub_glMaterialfv" "glstub_glMaterialfv" "noalloc";
value glMaterialfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glMaterialfv p0 p1 np2 in r;
external glMatrixIndexPointerOES : int -> int -> int -> 'a -> unit =
  "glstub_glMatrixIndexPointerOES" "glstub_glMatrixIndexPointerOES"
  "noalloc";
external glMatrixMode : int -> unit = "glstub_glMatrixMode"
  "glstub_glMatrixMode" "noalloc";
external glMultMatrixf : float_array -> unit = "glstub_glMultMatrixf"
  "glstub_glMultMatrixf" "noalloc";
value glMultMatrixf p0 =
  let np0 = to_float_array p0 in let r = glMultMatrixf np0 in r;
external glMultiTexCoord4f :
  int -> float -> float -> float -> float -> unit =
  "glstub_glMultiTexCoord4f" "glstub_glMultiTexCoord4f" "noalloc";
external glNormal3f : float -> float -> float -> unit = "glstub_glNormal3f"
  "glstub_glNormal3f" "noalloc";
external glNormalPointer : int -> int -> 'a -> unit =
  "glstub_glNormalPointer" "glstub_glNormalPointer" "noalloc";
external glOrthof :
  float -> float -> float -> float -> float -> float -> unit =
  "glstub_glOrthof_byte" "glstub_glOrthof" "noalloc";
external glPixelStorei : int -> int -> unit = "glstub_glPixelStorei"
  "glstub_glPixelStorei" "noalloc";
external glPointParameterf : int -> float -> unit =
  "glstub_glPointParameterf" "glstub_glPointParameterf" "noalloc";
external glPointParameterfv : int -> float_array -> unit =
  "glstub_glPointParameterfv" "glstub_glPointParameterfv" "noalloc";
value glPointParameterfv p0 p1 =
  let np1 = to_float_array p1 in let r = glPointParameterfv p0 np1 in r;
external glPointSize : float -> unit = "glstub_glPointSize"
  "glstub_glPointSize" "noalloc";
external glPointSizePointerOES : int -> int -> 'a -> unit =
  "glstub_glPointSizePointerOES" "glstub_glPointSizePointerOES" "noalloc";
external glPolygonOffset : float -> float -> unit = "glstub_glPolygonOffset"
  "glstub_glPolygonOffset" "noalloc";
external glPopMatrix : unit -> unit = "glstub_glPopMatrix"
  "glstub_glPopMatrix" "noalloc";
external glPushMatrix : unit -> unit = "glstub_glPushMatrix"
  "glstub_glPushMatrix" "noalloc";
external glReadPixels :
  int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glReadPixels_byte" "glstub_glReadPixels" "noalloc";
external glRotatef : float -> float -> float -> float -> unit =
  "glstub_glRotatef" "glstub_glRotatef" "noalloc";
external glSampleCoverage : float -> bool -> unit = "glstub_glSampleCoverage"
  "glstub_glSampleCoverage" "noalloc";
external glScalef : float -> float -> float -> unit = "glstub_glScalef"
  "glstub_glScalef" "noalloc";
external glScissor : int -> int -> int -> int -> unit = "glstub_glScissor"
  "glstub_glScissor" "noalloc";
external glShadeModel : int -> unit = "glstub_glShadeModel"
  "glstub_glShadeModel" "noalloc";
external glStencilFunc : int -> int -> int -> unit = "glstub_glStencilFunc"
  "glstub_glStencilFunc" "noalloc";
external glStencilMask : int -> unit = "glstub_glStencilMask"
  "glstub_glStencilMask" "noalloc";
external glStencilOp : int -> int -> int -> unit = "glstub_glStencilOp"
  "glstub_glStencilOp" "noalloc";
external glTexCoordPointer : int -> int -> int -> 'a -> unit =
  "glstub_glTexCoordPointer" "glstub_glTexCoordPointer" "noalloc";
external glTexEnvf : int -> int -> float -> unit = "glstub_glTexEnvf"
  "glstub_glTexEnvf" "noalloc";
external glTexEnvfv : int -> int -> float_array -> unit = "glstub_glTexEnvfv"
  "glstub_glTexEnvfv" "noalloc";
value glTexEnvfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glTexEnvfv p0 p1 np2 in r;
external glTexEnvi : int -> int -> int -> unit = "glstub_glTexEnvi"
  "glstub_glTexEnvi" "noalloc";
external glTexEnviv : int -> int -> word_array -> unit = "glstub_glTexEnviv"
  "glstub_glTexEnviv" "noalloc";
value glTexEnviv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glTexEnviv p0 p1 np2 in r;
external glTexImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexImage2D_byte" "glstub_glTexImage2D" "noalloc";
external glTexParameterf : int -> int -> float -> unit =
  "glstub_glTexParameterf" "glstub_glTexParameterf" "noalloc";
external glTexParameterfv : int -> int -> float_array -> unit =
  "glstub_glTexParameterfv" "glstub_glTexParameterfv" "noalloc";
value glTexParameterfv p0 p1 p2 =
  let np2 = to_float_array p2 in let r = glTexParameterfv p0 p1 np2 in r;
external glTexParameteri : int -> int -> int -> unit =
  "glstub_glTexParameteri" "glstub_glTexParameteri" "noalloc";
external glTexParameteriv : int -> int -> word_array -> unit =
  "glstub_glTexParameteriv" "glstub_glTexParameteriv" "noalloc";
value glTexParameteriv p0 p1 p2 =
  let np2 = to_word_array p2 in let r = glTexParameteriv p0 p1 np2 in r;
external glTexSubImage2D :
  int -> int -> int -> int -> int -> int -> int -> int -> 'a -> unit =
  "glstub_glTexSubImage2D_byte" "glstub_glTexSubImage2D" "noalloc";
external glTranslatef : float -> float -> float -> unit =
  "glstub_glTranslatef" "glstub_glTranslatef" "noalloc";
external glVertexPointer : int -> int -> int -> 'a -> unit =
  "glstub_glVertexPointer" "glstub_glVertexPointer" "noalloc";
external glViewport : int -> int -> int -> int -> unit = "glstub_glViewport"
  "glstub_glViewport" "noalloc";
external glWeightPointerOES : int -> int -> int -> 'a -> unit =
  "glstub_glWeightPointerOES" "glstub_glWeightPointerOES" "noalloc";

