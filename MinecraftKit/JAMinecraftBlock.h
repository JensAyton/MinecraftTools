/*
	JAMinecraftBlock.h
	
	A single Minecraft block, with a tile entity attached if appropriate.
	
	To avoid overhead when dealing with many blocks, it is better to work
	with MCCell structs and track tile entities separately, but for low-volume
	work an object representation can be more convenient.
	
	
	Copyright © 2011–2012 Jens Ayton
	
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


#import "JAMinecraftTypes.h"

@interface JAMinecraftBlock: NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, readonly) uint8_t blockID;
@property (nonatomic, readonly) uint8_t blockData;
@property (nonatomic, copy, readonly) NSDictionary *tileEntity;

- (BOOL) isEqualToBlock:(JAMinecraftBlock *)other;

@property (nonatomic, readonly) NSString *shortBlockDescription;
@property (nonatomic, readonly) NSString *longBlockDescription;

@end


@interface JAMinecraftBlock (Creation)

+ (id) blockWithID:(uint8_t)blockID data:(uint8_t)blockData tileEntity:(NSDictionary *)tileEntity;
+ (id) blockWithCell:(MCCell)cell tileEntity:(NSDictionary *)tileEntity;

+ (JAMinecraftBlock *) airBlock;
+ (JAMinecraftBlock *) holeBlock;
+ (JAMinecraftBlock *) stoneBlock;

@end


@interface JAMinecraftBlock (Conveniences)

@property (nonatomic, readonly) MCCell cell;

@end


@interface JAMutableMincraftBlock: JAMinecraftBlock

@property (nonatomic, readwrite) uint8_t blockID;
@property (nonatomic, readwrite) uint8_t blockData;
@property (nonatomic, copy, readwrite) NSDictionary *tileEntity;

@end
