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
type byte_array = (int, Bigarray.int8_signed_elt, Bigarray.c_layout) Bigarray.Array1.t
type ubyte_array = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
type short_array = (int, Bigarray.int16_signed_elt, Bigarray.c_layout) Bigarray.Array1.t
type ushort_array = (int, Bigarray.int16_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
type word_array = (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t
type dword_array = (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t
type int_array = (int, Bigarray.int_elt, Bigarray.c_layout) Bigarray.Array1.t
type float_array = (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t
type double_array = (float, Bigarray.float64_elt, Bigarray.c_layout) Bigarray.Array1.t

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
type byte_matrix = (int, Bigarray.int8_signed_elt, Bigarray.c_layout) Bigarray.Array2.t
type ubyte_matrix = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array2.t
type short_matrix = (int, Bigarray.int16_signed_elt, Bigarray.c_layout) Bigarray.Array2.t
type ushort_matrix = (int, Bigarray.int16_unsigned_elt, Bigarray.c_layout) Bigarray.Array2.t
type word_matrix = (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array2.t
type dword_matrix = (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array2.t
type int_matrix = (int, Bigarray.int_elt, Bigarray.c_layout) Bigarray.Array2.t
type float_matrix = (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array2.t
type double_matrix = (float, Bigarray.float64_elt, Bigarray.c_layout) Bigarray.Array2.t

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
let make_byte_array len = Bigarray.Array1.create Bigarray.int8_signed Bigarray.c_layout len
let make_ubyte_array len = Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout len
let make_short_array len = Bigarray.Array1.create Bigarray.int16_signed Bigarray.c_layout len
let make_ushort_array len = Bigarray.Array1.create Bigarray.int16_unsigned Bigarray.c_layout len
let make_word_array len = Bigarray.Array1.create Bigarray.int32 Bigarray.c_layout len
let make_dword_array len = Bigarray.Array1.create Bigarray.int64 Bigarray.c_layout len
let make_int_array len = Bigarray.Array1.create Bigarray.int Bigarray.c_layout len
let make_float_array len = Bigarray.Array1.create Bigarray.float32 Bigarray.c_layout len
let make_double_array len = Bigarray.Array1.create Bigarray.float64 Bigarray.c_layout len

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
let make_byte_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int8_signed Bigarray.c_layout  dim1 dim2
let make_ubyte_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int8_unsigned Bigarray.c_layout  dim1 dim2
let make_short_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int16_signed Bigarray.c_layout  dim1 dim2
let make_ushort_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int16_unsigned Bigarray.c_layout  dim1 dim2
let make_word_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int32 Bigarray.c_layout  dim1 dim2
let make_dword_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int64 Bigarray.c_layout  dim1 dim2
let make_int_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.int Bigarray.c_layout  dim1 dim2
let make_float_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.float32 Bigarray.c_layout  dim1 dim2
let make_double_matrix dim1 dim2 = Bigarray.Array2.create Bigarray.float64 Bigarray.c_layout  dim1 dim2

(** Conversions between native Ocaml arrays and bigarrays for
	- int arrays to byte_arrays
	- int arrays to ubyte_arrays
	- int arrays to short_arrays
	- int arrays to ushort_arrays
	- int arrays to int_arrays
	- float arrays to float_arrays
	- float arrays to double_arrays
*)
let to_byte_array a = Bigarray.Array1.of_array Bigarray.int8_signed Bigarray.c_layout a
let to_ubyte_array a = Bigarray.Array1.of_array Bigarray.int8_unsigned Bigarray.c_layout a
let to_short_array a = Bigarray.Array1.of_array Bigarray.int16_signed Bigarray.c_layout a
let to_ushort_array a = Bigarray.Array1.of_array Bigarray.int16_unsigned Bigarray.c_layout a
let to_word_array a = 
	let r = make_word_array (Array.length a) in
	let _ = Array.iteri (fun i a -> r.{i} <- Int32.of_int a ) a in r
let to_dword_array a = 
	let r = make_dword_array (Array.length a) in
	let _ = Array.iteri (fun i a -> r.{i} <- Int64.of_int a ) a in r
let to_int_array a = 
	let r = make_int_array (Array.length a) in
	let _ = Array.iteri (fun i a -> r.{i} <- a ) a in r
let to_float_array a = 
	let r = make_float_array (Array.length a) in
	let _ = Array.iteri (fun i a -> r.{i} <- a ) a in r
let to_double_array a = 
	let r = make_double_array (Array.length a) in
	let _ = Array.iteri (fun i a -> r.{i} <- a ) a in r

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
let copy_byte_array src dst =
	Array.iteri (fun i c -> dst.(i) <- src.{i} ) dst
let copy_ubyte_array = copy_byte_array
let copy_short_array = copy_byte_array
let copy_ushort_array = copy_byte_array
let copy_word_array src dst =
	Array.iteri (fun i c -> dst.(i) <- Int32.to_int src.{i} ) dst
let copy_dword_array src dst =
	Array.iteri (fun i c -> dst.(i) <- Int64.to_int src.{i} ) dst
let copy_float_array src dst = copy_byte_array	
let copy_double_array src dst = copy_byte_array	

(** Convert a byte_array or ubyte_array to a string *)
let to_string a =
	let l = Bigarray.Array1.dim a in
	let s = String.create l in
	for i = 0 to (l - 1) do
		s.[i] <- a.{i}
	done;
	s

(** Convert between booleans and ints *)
let int_of_bool b = if b then 1 else 0
let bool_of_int i = not (i = 0)
let bool_to_int_array b = Array.map int_of_bool b
let int_to_bool_array i = Array.map bool_of_int i
let copy_to_bool_array src dst = 
	Array.mapi (fun i c -> dst.(i) <-  bool_of_int src.(i)) dst



