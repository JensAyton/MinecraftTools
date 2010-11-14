/*
	IsKeyDown.m
	Map Viewer for Redline
	$Id: IsKeyDown.c 130 2007-01-10 13:42:23Z jayton $
	
	Copyright © 2007 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the “Software”), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "IsKeyDown.h"


Boolean IsKeySetInKeyMap(uint8_t inVirtualKeyCode, const KeyMap inKeyMap)
{
	if (127 < inVirtualKeyCode) return false;
	
	// Key map is a bit field. Check the inVirtualKeyCodeth bit of it.
	uint8_t byteIdx = (inVirtualKeyCode) >> 3;		// All but low three bits
	uint8_t shift = (inVirtualKeyCode) & 7;			// Low three bits.
	uint8_t mask = 1 << shift;
	uint8_t byte = ((uint8_t *)inKeyMap)[byteIdx];
	
	return 0 != (byte & mask);
}


Boolean IsKeyDown(uint8_t inVirtualKeyCode)
{
	KeyMap keys;
	GetKeys(keys);
	return IsKeySetInKeyMap(inVirtualKeyCode, keys);
}
