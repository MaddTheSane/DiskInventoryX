/*
 *  Preferences.h
 *  Disk Inventory X
 *
 *  Created by Tjark Derlien on 24.11.04.
 *  Copyright 2004 Tjark Derlien. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

//keys for preference values
extern NSString *ShowPackageContents;
extern NSString *ShowFreeSpace;
extern NSString *ShowOtherSpace;
extern NSString *IgnoreCreatorCode;
extern NSString *ShowPhysicalFileSize; //logical size otherwise (like the Finder)
extern NSString *UseSmallFontInKindStatistic;
extern NSString *UseSmallFontInFilesView;
extern NSString *UseSmallFontInSelectionList;
extern NSString *SplitWindowHorizontally;
extern NSString *AnimatedZooming;
extern NSString *EnableLogging;
extern NSString *DontShowDonationMessage;
extern NSString *ShareKindColors;

@interface NSMutableDictionary(DocumentPreferences)

- (instancetype) initWithDefaults;

@property BOOL showPackageContents;
@property BOOL showFreeSpace;
@property BOOL showOtherSpace;
@property BOOL ignoreCreatorCode;
@property BOOL showPhysicalFileSize;

@end
