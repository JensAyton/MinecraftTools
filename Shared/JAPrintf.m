//
//  JAPrintf.m
//  terrainstats
//
//  Created by Jens Ayton on 2011-11-27.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JAPrintf.h"


void FPrintv(FILE *file, NSString *format, va_list args)
{
	NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
	fputs([string UTF8String], file);
}


void FPrint(FILE *file, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(file, format, args);
	va_end(args);
}


void Print(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(stdout, format, args);
	va_end(args);
}


void EPrint(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(stderr, format, args);
	va_end(args);
}


void Fatal(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(stderr, format, args);
	va_end(args);
	exit(EXIT_FAILURE);
}


NSString *RealPathFromCString(const char *path)
{
	char buffer[PATH_MAX];
	realpath(path, buffer);
	return [NSString stringWithUTF8String:buffer];
}
