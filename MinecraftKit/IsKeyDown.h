/*
	IsKeyDown.h
	Map Viewer for Redline
	$Id: IsKeyDown.h 146 2007-01-16 20:23:13Z jayton $
	
	Test whether a given key is currently being pressed. Note that this test
	for _keys_, not _characters_.
	
	Copyright © 2007 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#include <Carbon/Carbon.h>

#ifdef __cplusplus
extern "C" {
#endif

Boolean IsKeySetInKeyMap(uint8_t inVirtualKeyCode, const KeyMap inKeyMap) __attribute__((const));

Boolean IsKeyDown(uint8_t inVirtualKeyCode);

#ifdef __cplusplus
};
#endif
