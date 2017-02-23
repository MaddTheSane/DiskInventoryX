//
//  NTNameAndID.m
//  CocoatechCore
//
//  Created by Steve Gehrman on 6/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTNameAndID.h"

// =================================================================

@interface NTNameAndID (hidden)
- (void)setIdentifierNumber:(NSNumber *)theIdentifier;
- (void)setName:(NSString *)theName;
@end

@implementation NTNameAndID

+ (NTNameAndID*)nameAndID:(NSString*)name identifier:(NSInteger)identifier;
{
    NTNameAndID* result = [[NTNameAndID alloc] init];
	
    [result setIdentifierNumber:[NSNumber numberWithInteger:identifier]];
    [result setName:name];
	
    return result;
}

- (void)dealloc;
{
    [self setName:nil];
	[self setIdentifierNumber:nil];
	
}

//---------------------------------------------------------- 
//  ident 
//---------------------------------------------------------- 
- (NSInteger)identifier;
{
    return [[self identifierNumber] integerValue];
}

//---------------------------------------------------------- 
//  identifierNumber 
//---------------------------------------------------------- 
- (NSNumber *)identifierNumber
{
    return mIdentifierNumber; 
}

- (void)setIdentifierNumber:(NSNumber *)theIdentifierNumber
{
    if (mIdentifierNumber != theIdentifierNumber) {
        mIdentifierNumber = theIdentifierNumber;
    }
}

//---------------------------------------------------------- 
//  name 
//---------------------------------------------------------- 
- (NSString *)name
{
    return mName; 
}

- (void)setName:(NSString *)theName
{
    if (mName != theName) {
        mName = [theName copy];
    }
}

- (BOOL)isEqual:(NTNameAndID*)right;
{
	if (![right isKindOfClass:[NTNameAndID class]]) {
		return NO;
	}
	return ([self identifier] == [right identifier] &&
			[[self name] isEqualToString:[right name]]);
}

- (NSComparisonResult)compare:(NTNameAndID *)right;
{
    return [[self name] compare:[right name]]; 
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@ (%@)", [self name], [[self identifierNumber] description]];
}

@end

@implementation NTNameAndID (Utilities)

+ (NSArray*)names:(NSArray*)nameIDArray;
{
	NSMutableArray *result = [NSMutableArray array];
	NTNameAndID *nameID;
	
	for (nameID in nameIDArray)
	{
		if ([nameID name])
			[result addObject:[nameID name]];
	}
	
	return result;
}

+ (NSArray*)identifiers:(NSArray*)nameIDArray;
{
	NSMutableArray *result = [NSMutableArray array];
	NTNameAndID *nameID;
	
	for (nameID in nameIDArray)
		[result addObject:@([nameID identifier])];
	
	return result;
}

@end

