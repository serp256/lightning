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

