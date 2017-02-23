//
//  NTNameAndID.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 6/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTNameAndID : NSObject
{
    NSNumber* mIdentifierNumber;
    NSString *mName;
}

+ (instancetype)nameAndID:(NSString*)name identifier:(NSInteger)identifier;

@property (readonly) NSInteger identifier;
- (NSNumber*)identifierNumber;
- (NSString*)name;

@end

@interface NTNameAndID (Utilities)

+ (NSArray<NSString*>*)names:(NSArray<NTNameAndID*>*)nameIDArray;
+ (NSArray<NSNumber*>*)identifiers:(NSArray<NTNameAndID*>*)nameIDArray;

@end
