//
//  NTLabelsModel.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTLabelColor;

@interface NTLabelsModel : NSObject
{
	NSMutableDictionary* mDictionary;
	NSMutableDictionary* gradients;
	BOOL mSaveInProgress;
	
	unsigned mBuildID;
}

@property (retain) NSMutableDictionary* gradients;

+ (NTLabelsModel*)model;

- (NSUInteger)count;

- (NSMutableDictionary<NSString*,NTLabelColor*> *)dictionary;

- (NSColor*)color:(int)label;
- (NTGradientDraw*)gradient:(int)label;
- (NSString*)name:(int)label;
- (NSColor*)colorForLabel:(int)label;
- (NSString*)nameForLabel:(int)label;

- (unsigned)buildID;
- (void)restoreDefaults;


@end
