//
//  FSItem.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>

extern unsigned g_fileCount;
extern unsigned g_folderCount;

@interface NSString (ComparisonAdditions)
- (NSComparisonResult) compareAsFilesystemName: (NSString*) other;
@end

@protocol FSItemDelegate;

typedef enum
{
	FileFolderItem, //regular file or folder
	OtherSpaceItem, //represents "other" space (that means the space occupied by the rest of the files on the volume)
	FreeSpaceItem	//free space on volume
} FSItemType;

@interface FSItem : NSObject {
	NTFileDesc *_fileDesc;
    __unsafe_unretained FSItem *_parent;	//only valid for non-root items
	NSMutableDictionary *_icons; //holds icons in various sizes (see iconWithSize:)
	FSItemType _type;
    NSNumber *_size;
    //NSUInteger _hash;
    NSMutableArray *_childs;
	id _delegate;
}

- (id) initWithPath: (NSString *) path;

- (id) initAsOtherSpaceItemForParent: (FSItem*) parent;
- (id) initAsFreeSpaceItemForParent: (FSItem*) parent;

@property (assign) id<FSItemDelegate> delegate;

@property (readonly) FSItemType type;
- (BOOL) isSpecialItem;

- (NTFileDesc *) fileDesc;
- (void) setFileDesc: (NTFileDesc*) desc;

- (void) loadChildren; //optimized version by Dave Payne

- (NSString *) description;

- (BOOL) isFolder; //returns NO for an alias pointing to a directory (in contrast to NTFileDesc.isDirectory)
- (BOOL) isPackage;
- (BOOL) isAlias;

- (BOOL) exists;

- (BOOL) isRoot;
- (FSItem*) parent;
- (FSItem*) root;

- (NSImage*) iconWithSize: (unsigned) iconSize;

- (NSEnumerator *) childEnumerator;
- (FSItem*) childAtIndex: (NSUInteger) index;
- (NSUInteger) childCount;

- (void) removeChild: (FSItem*) child updateParent: (BOOL) updateParent; //child will be released!
- (void) insertChild: (FSItem*) newChild updateParent: (BOOL) updateParent;
- (void) replaceChild: (FSItem*) oldChild withItem: (FSItem*) newChild updateParent: (BOOL) updateParent;

- (void) recalculateSize: (BOOL) usePhysicalSize updateParent: (BOOL) updateParent;
	//just recalculates size (no file system access)
- (void) recalculateSize: (BOOL) usePhysicalSize;

- (void) setKindString; //will ask delegate whether to ignore creator codes
- (void) setKindStringIgnoringCreatorCode: (BOOL) ignoreCreatorCode includeChilds: (BOOL) includeChilds;

@property (readonly, retain) NSNumber *size;
@property (readonly) unsigned long long sizeValue;

- (NSString *) name;
- (NSString *) path;
- (NSString *) folderName;

- (NSString *) displayName;
- (NSString *) displayFolderName; //folder name relative to root item, not "/"
- (NSString *) displayPath; //path relative to root item, not "/"
- (NSString *) kindName;

- (NSComparisonResult) compareSize: (FSItem*) other;
- (NSComparisonResult) compareDisplayName: (FSItem*) other;

//- (NSUInteger) hash;
@end

/* optional delegate methods */
@protocol FSItemDelegate<NSObject>
- (BOOL) fsItemEnteringFolder: (FSItem*) item; //!< delegate may return \c NO to stop loading in "loadChilds"
- (BOOL) fsItemExittingFolder: (FSItem*) item;
- (BOOL) fsItemShouldIgnoreCreatorCode: (FSItem*) item; //!< default is \c NO (if not implemented by delegate)
//! set kind string in "loadChilds?";
//! default is \c NO (if not implemented by delegate)
- (BOOL) fsItemShouldLookIntoPackages: (FSItem*) item;
- (BOOL) fsItemShouldUsePhysicalFileSize: (FSItem*) item;
@end

//Exception raised by FSItem
//! delegate canceled the loading (see above)
extern NSString* FSItemLoadingCanceledException;
//! error while enumerating files/folders (e.g. volume has been ejected (unmounted)) 
extern NSString* FSItemLoadingFailedException;
