//
//  NTDateFormatter.h
//  CocoatechCore
//
//  Created by Steve Gehrman on Thu Feb 27 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTSingletonObject.h"

typedef enum
{
    kShortDate,
    kMediumDate,
    kLongDate,  
    kFullDate,   
} NTDateFormat;

@interface NTDateFormatter : NTSingletonObject
{
    NSDateFormatter* shortFormatter;
    NSDateFormatter* mediumFormatter;
    NSDateFormatter* longFormatter;
    NSDateFormatter* fullFormatter;
    NSDateFormatter* timeFormatter;
	
	NSString* todayString;
	NSString* yesterdayString;
	NSString* tomorrowString;
}

@property (strong) NSDateFormatter* shortFormatter;
@property (strong) NSDateFormatter* mediumFormatter;
@property (strong) NSDateFormatter* longFormatter;
@property (strong) NSDateFormatter* fullFormatter;
@property (strong) NSDateFormatter* timeFormatter;
@property (strong) NSString* todayString;
@property (strong) NSString* yesterdayString;
@property (strong) NSString* tomorrowString;

- (NSString *)dateString:(NSDate*)date format:(NTDateFormat)format relative:(BOOL)relative;

@end

