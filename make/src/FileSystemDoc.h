//
//  FileSystemDoc.h
//  Disk Accountant
//
//  Created by Tjark Derlien on Wed Oct 08 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "FSItem.h"
#import "Preferences.h"
#import "LoadingPanelController.h"
#import "FileTypeColors.h"

//! holds information about the count and size of the files of one kind (e.g. MP3 files)
@interface FileKindStatistic : NSObject
{
    NSString *_kindName;
	unsigned long long _size;
	NSMutableSet<FSItem*> *_items;
}

- (instancetype) initWithItem: (FSItem*) item;

- (void) addItem: (FSItem* )item;
- (void) removeItem: (FSItem* )item;

@property (readonly, copy) NSString* kindName;
- (NSString*) description;

@property (readonly) NSUInteger fileCount;		//!< # of files of this kind
@property (readonly) unsigned long long size; //!< sum of sizes of files of this kind
- (void) recalculateSize;

@property (readonly, copy) NSSet<FSItem*>* items;
- (NSEnumerator<FSItem*>*) itemEnumerator;

- (NSComparisonResult) compareSizeDescendingly: (FileKindStatistic*) other;

@end

@interface FileSystemDoc : NSDocument <FSItemDelegate>
{
    FSItem *_rootItem;
    FSItem *_selectedItem;
    NSMutableArray *_zoomStack;
    NSMutableDictionary *_fileKindStatistics;	//!<dictionary: kind name -> FileKindStatistic
	NSMutableDictionary *_viewOptions;
	FileTypeColors *_kindColors;
	
	//these variables are used during the initial directory scan
	LoadingPanelController *_progressController;
	NSMutableArray *_directoryStack;
}

@property BOOL showPhysicalFileSize;
@property BOOL showPackageContents;
@property BOOL showFreeSpace;
@property BOOL showOtherSpace;
@property BOOL ignoreCreatorCode;

- (BOOL) itemIsNode: (FSItem*) item; //!<helper method; returns YES/NO for packages depending on the showPackageContents-Flag

@property (readonly, retain) FSItem *rootItem;

- (BOOL) moveItemToTrash: (FSItem*) item;//!<will post a "FSItemsChangedNotification"
- (void) refreshItem: (FSItem*) item;//!<will post a "FSItemsChangedNotification"

- (FSItem*) zoomedItem;
- (void) zoomIntoItem: (FSItem*) item; //!<will post a "ZoomedItemChangedNotification"
- (void) zoomOutToItem: (FSItem*) item;
- (void) zoomOutOneStep;
- (NSArray*) zoomStack;

- (FSItem*) selectedItem;
- (void) setSelectedItem: (FSItem*) item; //!<will post a "GlobalSelectionChangedNotification"

- (FileKindStatistic*) kindStatisticForItem: (FSItem*) item;
- (FileKindStatistic*) kindStatisticForKind: (NSString*) kindName;
- (NSDictionary*) kindStatistics;

- (FileTypeColors*) fileTypeColors;

- (void) refreshFileKindStatistics;

@end

/* keys for Key Value Observing (KVO) */
extern NSString *DocKeySelectedItem;

/* FileSystemDoc Notifications */
extern NSString *GlobalSelectionChangedNotification; //!<userInfo contains new and old selection
extern NSString *ZoomedItemChangedNotification; //!<userInfo contains new and old zoomed item
extern NSString *FSItemsChangedNotification; //!<some items are modified, deleted or added; userInfo is nil
extern NSString *ViewOptionChangedNotification; //!<the name of the changed option is stored in userInfo for key \c ChangedViewOption (see next line)
extern NSString *ChangedViewOption;
extern NSString *NewItem;
extern NSString *OldItem;
