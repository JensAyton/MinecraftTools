/*
	JAMinecraftKitLionInterfaces.h
	
	Declarations lifted from 10.7 SDK to allow continued building with
	10.6 SDK.
*/

#import <Cocoa/Cocoa.h>


#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070

enum
{
	NSEventPhaseNone		= 0,
	NSEventPhaseBegan		= 0x1 << 0,
	NSEventPhaseStationary	= 0x1 << 1,
	NSEventPhaseChanged		= 0x1 << 2,
	NSEventPhaseEnded		= 0x1 << 3,
	NSEventPhaseCancelled	= 0x1 << 4,
};
typedef NSUInteger NSEventPhase;


@interface NSEvent (OSXLion)

- (BOOL) hasPreciseScrollingDeltas;
- (CGFloat) scrollingDeltaX;
- (CGFloat) scrollingDeltaY;

- (NSEventPhase) phase;
- (NSEventPhase) momentumPhase;

@end

#endif
