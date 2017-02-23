//
//  FileSystemDoc.h
//  Disk Accountant
//
//  Created by Doom on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "FSItem.h"

@interface FileKindStatistic : NSObject
{
    NSString *_kindName;
    unsigned _fileCount;
    unsigned long long _filesSize;
}

- (id) initWithItem: (FSItem*) item;

- (void) addItemToStatistic: (FSItem* )item;

- (NSString*) description;

- (NSString*) kindName;
- (unsigned) fileCount;		//# of files of this kind
- (unsigned long long) filesSize;	//sum of sizes of files of this kind

@end

@interface FileSystemDoc : NSDocument
{
    FSItem *_rootItem;
    FSItem *_selectedItem;
    NSMutableArray *_zoomStack;
    NSMutableDictionary *_fileKindStatistics;	//Dictionary kind name -> FileKindStatistic
    BOOL _showPackageContents;

    IBOutlet id _loadingTextField;
    IBOutlet id _loadingPanel;
    IBOutlet id _loadingProgressIndicator;
}

- (BOOL) showPackageContents;
- (void) setShowPackageContents: (BOOL) show;
- (BOOL) itemIsNode: (FSItem*) item; //helper methods; returns YES/NO for packages in dependency of the showPackageContents-Flag

- (FSItem*) rootItem;

- (FSItem*) zoomedItem;
- (void) zoomIntoItem: (FSItem*) item;
- (void) zoomOutToItem: (FSItem*) item;
- (void) zoomOutOneStep;

- (FSItem*) selectedItem;			//caller is responsible for posting a "GlobalSelectionChangedNotification"
- (void) setSelectedItem: (FSItem*) item;	//reseiver will post a "ZoomedItemChangedNotification"

- (FileKindStatistic*) kindStatisticForItem: (FSItem*) item;
- (FileKindStatistic*) kindStatisticForKind: (NSString*) kindName;
- (NSDictionary*) kindStatistics;

@end

/* FileSystemDoc Notifications */
extern NSString *GlobalSelectionChangedNotification; //userInfo is nil
extern NSString *ZoomedItemChangedNotification; //userInfo is nil
extern NSString *ShowPackageContentsChangedNotification; //userInfo is nil

