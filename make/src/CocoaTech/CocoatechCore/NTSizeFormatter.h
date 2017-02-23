//
//  NTSizeFormatter.h
//  CocoatechCore
//
//  Created by Steve Gehrman on Thu Feb 27 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTSingletonObject.h"

typedef NS_ENUM(NSInteger, NTSizeUnit)
{
	kByteUnit,
	kKiloBytesUnit,
	kMegaBytesUnit,
	kGigaBytesUnit
};

@interface NTSizeFormatter : NTSingletonObject
{
    NSNumberFormatter* numFormatter;
	
	NSString* byteUnit;
	NSString* kiloUnit;
	NSString* megaUnit;
	NSString* gigaUnit;
}

- (NSString *)fileSize:(UInt64)numBytes
			allowBytes:(BOOL)allowBytes DEPRECATED_ATTRIBUTE; // allowBytes == NO means 512 bytes will be .5 KB

- (NSString *)fileSize:(UInt64)numBytes DEPRECATED_ATTRIBUTE; // allowBytes is YES by default

- (NSString *)fileSize:(UInt64)numBytes
			   outUnit:(NTSizeUnit*)outUnit 
			allowBytes:(BOOL)allowBytes DEPRECATED_ATTRIBUTE; // allowBytes == NO means 512 bytes will be .5 KB

- (NSString *)stringForUnit:(NTSizeUnit)unit DEPRECATED_ATTRIBUTE;

- (NSString*)fileSizeInBytes:(UInt64)numBytes DEPRECATED_ATTRIBUTE;

- (NSString*)numberString:(UInt64)number;
- (NSString*)sizeString:(NSSize)size;
@end

