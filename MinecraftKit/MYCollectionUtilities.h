/*
	MYCollectionUtilities.h
	
	Based on Jens Alfke’s CollectionUtils, modified and simplified for Oolite.
	
	
	Copyright © 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
	With modifications © 2010 Jens Ayton.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	• Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	• Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSE-
	QUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
	SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

#if __cplusplus
extern "C" {
#endif

// Collection creation conveniences:

#define $array(OBJS...)     ({id objs[]={OBJS}; \
                              [NSArray arrayWithObjects: objs count: sizeof(objs)/sizeof(id)];})
#define $marray(OBJS...)    ({id objs[]={OBJS}; \
                              [NSMutableArray arrayWithObjects: objs count: sizeof(objs)/sizeof(id)];})

#define $set(OBJS...)       ({id objs[]={OBJS}; \
                              [NSSet setWithObjects: objs count: sizeof(objs)/sizeof(id)];})
#define $mset(OBJS...)      ({id objs[]={OBJS}; \
                              [NSMutableSet setWithObjects: objs count: sizeof(objs)/sizeof(id)];})

#define $dict(PAIRS...)     ({struct _dictpair pairs[]={PAIRS}; \
                              OOMYDictOf(pairs,sizeof(pairs)/sizeof(struct _dictpair));})
#define $mdict(PAIRS...)    ({struct _dictpair pairs[]={PAIRS}; \
                              OOMYMDictOf(pairs,sizeof(pairs)/sizeof(struct _dictpair));})


// Object conveniences:

BOOL $equal(id obj1, id obj2);      // Like -isEqual: but works even if either/both are nil

	

#define $sprintf(FORMAT, ARGS... )  [NSString stringWithFormat: (FORMAT), ARGS]


#define $true		((NSNumber*)kCFBooleanTrue)
#define $false		((NSNumber*)kCFBooleanFalse)
#define $bool(v)	((v) ? $true : $false)
	
	
#define $int(v)		[NSNumber numberWithInteger:v]
#define $float(v)	[NSNumber numberWithDouble:v]


#define $null		[NSNull null]


// Internals (don't use directly)
struct _dictpair { id key; id value; };
NSDictionary* OOMYDictOf(const struct _dictpair*, size_t count);
NSMutableDictionary* OOMYMDictOf(const struct _dictpair*, size_t count);


	
#if __cplusplus
}
#endif
