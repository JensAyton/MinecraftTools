/*
	JAMinecraftSchematic+RedstoneHelpers.m
	
	Copyright © 2010 Jens Ayton
	
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

#import "JAMinecraftSchematic+RedstoneHelpers.h"


@implementation JAMinecraftSchematic (RedstoneHelpers)

- (BOOL) cellIsBlockWithSideTorchAt:(JACellLocation)location
{
	if (!MCCellIsFullySolid([self cellAt:location]))  return NO;
	
	if (MCCellIsRedstoneTorch([self cellAt:JACellNorth(location)]))  return YES;
	if (MCCellIsRedstoneTorch([self cellAt:JACellSouth(location)]))  return YES;
	if (MCCellIsRedstoneTorch([self cellAt:JACellEast(location)]))  return YES;
	if (MCCellIsRedstoneTorch([self cellAt:JACellWest(location)]))  return YES;
	
	return NO;
}


- (BOOL) cellIsBlockWithTopTorchAt:(JACellLocation)location
{
	if (!MCCellIsFullySolid([self cellAt:location]))  return NO;
	
	if (MCCellIsRedstoneTorch([self cellAt:JACellAbove(location)]))  return YES;
	
	return NO;
}

@end
