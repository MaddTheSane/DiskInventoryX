//
//  FSItem.h
//  DiskAccountant
//
//  Created by Doom on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern unsigned g_fileCount;
extern unsigned g_folderCount;


@interface FSItem : NSObject {
    unsigned long long _size;
    NSString *_name;
    NSString *_kindName;
    NSString *_folderName;
    NSString *_displayName;
    FSItem *_parent;

    BOOL _isPackage;
    BOOL _isFolder;

    FSRef _fsRef;

    unsigned _hash;
    id _hashObject;

    NSMutableArray *_childs;
}

- (id) initWithName: (NSString *) name parent: (FSItem*) parent;
- (id) initWithPath: (NSString *) path;

- (void) loadChilds;

- (NSString *) description;

- (BOOL) isFolder;
- (BOOL) isPackage;

- (BOOL) isRoot;
- (FSItem*) parent;
- (FSItem*) root;

- (NSEnumerator *) childEnumerator;
- (FSItem*) childAtIndex: (unsigned) index;
- (unsigned) childCount;

- (unsigned long long) size;

- (NSString *) displaySize;

- (NSString *) name;
- (NSString *) path;
- (NSString *) folderName;

- (NSString *) displayName;
- (NSString *) displayFolderName;
- (NSString *) kindName;

- (unsigned) hash;
- (id) hashObject; //to put into NSDictionary

- (const FSRefPtr) fsRef;
@end

//FSItem notifications
//'object' is always the root item

//when a folder is listed
extern NSString* FSItemFolderEntered;
extern NSString* FSItemEnteredFolder; //key in userInfo for the FSItem representing the entered folder
