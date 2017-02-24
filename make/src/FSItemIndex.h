//
//  FSItemIndex.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 01.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"

typedef NS_OPTIONS(unsigned short, FSItemIndexType) {
	FSItemIndexName = 1,
	FSItemIndexKind = 2,
	FSItemIndexPath = 4,
	FSItemIndexAll = 0xffff
};

//! this class let search FSItems by their display names, kinds and path
//! (I implemented this with SearchKit, but it is so damn slow that I replaced it with
//! a stupid simple but still faster implementation)
@interface FSItemIndex : NSObject
{
	NSMutableDictionary *_displayNameIndex;
	NSMutableDictionary *_displayFolderIndex;
	NSDictionary *_kindStatistics;
	
/*	NSMutableDictionary *_indexedItems;
	
	SKIndexRef _kindNameIndex;
	SKIndexRef _displayNameIndex;
	SKSearchGroupRef _searchGroupAll;
	*/
}

- (id) initWithKindStatistics: (NSDictionary*) kindStatistics;

- (void) addItem: (FSItem*) item;
- (void) addItemsFromArray: (NSArray<FSItem*>*) items;

- (NSArray*) searchItems: (NSString*) searchString inIndex: (FSItemIndexType) indexesToSearch;

@end
