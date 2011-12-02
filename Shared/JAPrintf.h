/*
	Printf()-like functions for NSStrings, and other utilities for command-
	line tool.
*/

#import <Foundation/Foundation.h>

/*
	FPrintv()
	Equivalent to vfprinf(), but takes an NSString and supports %@.
*/
void FPrintv(FILE *file, NSString *format, va_list args) NS_FORMAT_FUNCTION(2, 0);

/*
	FPrint()
	Equivalent to fprinf(), but takes an NSString and supports %@.
*/
void FPrint(FILE *file, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);

/*
	Print()
	Equivalent to printf(), but takes an NSString and supports %@.
*/
void Print(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/*
	EPrint()
	Equivalent to fprintf(stderr, ...), but takes an NSString and supports %@.
*/
void EPrint(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/*
	Fatal()
	EPrint() followed by exit(EXIT_FAILURE).
*/
void Fatal(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2) __attribute__((noreturn));


/*
	Given a C string with a possibly abbreviated path, return an absolute path.
*/
NSString *RealPathFromCString(const char *path);
