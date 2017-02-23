//
//  NTUsersAndGroups.h
//  CocoatechCore
//
//  Created by sgehrman on Tue Jul 31 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTSingletonObject.h"

@class NTNameAndID;

@interface NTUsersAndGroups : NTSingletonObject
{
    BOOL mIsRoot;
    NSString* mUserName;
    uid_t mUserID;
    gid_t mGroupID;
    NSArray<NTNameAndID*>* mUserGroups;
    NSArray<NTNameAndID*>* mUsers;
    NSArray<NTNameAndID*>* mGroups;
}

@property (readonly) BOOL isRoot;
@property (readonly, copy) NSString *userName;

@property (readonly) uid_t userID;
@property (readonly) gid_t groupID;
- (NSArray<NTNameAndID*> *)userGroups;
- (NSArray<NTNameAndID*> *)users;
- (NSArray<NTNameAndID*> *)groups;

- (NTNameAndID*)userWithID:(uid_t)userID;
- (NTNameAndID*)groupWithID:(gid_t)groupID;

- (BOOL)userIsMemberOfGroup:(gid_t)groupID;

- (NSString*)groupName:(uid_t)groupID;
- (NSString*)userName:(gid_t)userID;

- (gid_t)groupID:(NSString*)groupName;
- (uid_t)userID:(NSString*)userName;

// menuItem tag has the group and user IDs
- (NSMenu*)userMenu:(NSString*)filterPrefix;
- (NSMenu*)groupMenu:(NSString*)filterPrefix;

// append to existing menu
- (void)userMenu:(NSMenu*)menu target:(id)target action:(SEL)action filterPrefix:(NSString*)filterPrefix;
- (void)groupMenu:(NSMenu*)menu target:(id)target action:(SEL)action filterPrefix:(NSString*)filterPrefix;

@end
