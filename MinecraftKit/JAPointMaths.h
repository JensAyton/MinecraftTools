#import <Foundation/Foundation.h>


// Utilities for working with NSPoints as 2D vectors.
static inline NSPoint PtAdd(NSPoint a, NSPoint b)
{
	return (NSPoint){ a.x + b.x, a.y + b.y };
}

static inline NSPoint PtSub(NSPoint a, NSPoint b)
{
	return (NSPoint){ a.x - b.x, a.y - b.y };
}

static inline NSPoint PtScale(NSPoint p, CGFloat scale)
{
	return (NSPoint){ p.x * scale, p.y * scale };
}

static inline CGFloat PtDot(NSPoint a, NSPoint b)
{
	return a.x * b.x + a.y * b.y;
}

static inline CGFloat PtCross(NSPoint a, NSPoint b)
{
	return a.x * b.y - b.x * a.y;
}

static inline NSPoint PtRotCW(NSPoint p)
{
	// Rotate 90 degrees clockwise.
	return (NSPoint){ p.y, -p.x };
}

static inline NSPoint PtRotACW(NSPoint p)
{
	// Rotate 90 degrees anticlockwise.
	return (NSPoint){ -p.y, p.x };
}

static inline NSPoint PtNormalize(NSPoint p)
{
	return PtScale(p, 1.0 / sqrt(PtDot(p, p)));
}
