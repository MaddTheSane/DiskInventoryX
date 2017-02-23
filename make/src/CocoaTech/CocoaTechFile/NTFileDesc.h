//
//  NTFileDesc.h
//  CocoatechFile
//
//  Created by sgehrman on Sun Jul 15 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTVolume, NTFileDescData, NTMetadata, NSDate, NTIcon, NTFSRefObject, NTVolumeMgrState, NTFileDesc, NTFileTypeIdentifier;

@interface NTFileDesc : NSObject <NSCoding>
{    	
	NTFileDescData* cache;
	NTFSRefObject* FSRefObject;
    NTVolumeMgrState *volumeMgrState;

	BOOL mv_valid;
	BOOL mv_isComputer;
}

@property (retain, nonatomic) NTFileDescData* cache;
@property (retain, nonatomic) NTFSRefObject* FSRefObject;
@property (retain, nonatomic) NTVolumeMgrState *volumeMgrState;

- (id)initWithPath:(NSString *)path;
- (id)initWithFSRefObject:(NTFSRefObject*)refObject;

    // returns the resolved NTFileDesc if it's an alias
- (NTFileDesc*)descResolveIfAlias;
- (NTFileDesc*)descResolveIfAlias:(BOOL)resolveIfServerAlias;
- (NTFileDesc*)aliasDesc; // if we were resolved from an alias, this is the original alias file
- (NTFileDesc*)newDesc NS_RETURNS_NOT_RETAINED;  // creates a new copy of the desc (resets mod dates, displayname etc)

- (NTIcon*)icon;

@property (readonly, getter=isValid) BOOL valid;
@property (readonly) BOOL stillExists;
@property (readonly, getter=isComputer) BOOL computer;
- (BOOL)isValid;
- (BOOL)stillExists;
- (BOOL)isComputer;

	// is the directory or file open
@property (readonly, getter=isOpen) BOOL open;

@property (readonly) NSPoint finderPosition;
- (NSString*)versionString;
- (NSString*)bundleVersionString;
- (NSString*)bundleIdentifier;
- (NSString*)infoString;
- (NSString*)itemInfo;
- (NSString*)uniformTypeID;

- (NSString *)path;
- (NSString*)displayPath; // path, or Computer for @"", or boot volumes name for "/"
- (NSArray<NTFSRefObject*>*)FSRefPath:(BOOL)includeSelf; // an array of FSRefObjects
- (NTMetadata*)metadata;

    // an array of FileDescs - strips out /Volume automatically
- (NSArray<NTFileDesc*>*)pathComponents:(BOOL)resolveAliases;

- (NSURL*)URL;
@property (readonly) const char *fileSystemPath NS_RETURNS_INNER_POINTER;
@property (readonly) const char *UTF8Path NS_RETURNS_INNER_POINTER;

- (FSRef*)FSRefPtr;

- (UInt32)nodeID;
@property (readonly, copy) NSString *name;
@property (readonly, copy) NSString *displayName;
@property (readonly, copy) NSString *extension;
@property (readonly, copy) NSString *executablePath;
- (NTFileDesc *)application;

- (NSString*)dictionaryKey;
- (NSString*)strictDictionaryKey; // like dictionaryKey, but adds the parentDirID so you can know if the item moved for example

- (NSString*)bundleSignature;

- (NTFileDesc *)parentDesc;
- (UInt32)parentDirID;
- (BOOL)parentIsVolume;
- (NSString *)parentPath:(BOOL)forDisplay;

- (NTVolume*)volume;
@property (readonly) FSVolumeRefNum volumeRefNum;

- (NSString *)kindString;
- (NSString *)architecture;
- (NTFileTypeIdentifier*)typeIdentifier;

@property (readonly) UInt64 size; // returns total size for files
@property (readonly) UInt64 physicalSize; // returns total physical size for files

@property (readonly) UInt64 rsrcForkSize;
@property (readonly) UInt64 dataForkSize;
@property (readonly) UInt64 rsrcForkPhysicalSize;
@property (readonly) UInt64 dataForkPhysicalSize;

@property (readonly) UInt32 valence;  // only valid for folders, 0 if file or invalid

- (BOOL)isOnBootVolume;

- (BOOL)isFile;
- (BOOL)isDirectory;
- (BOOL)isInvisible;
- (BOOL)isLocked;
- (BOOL)hasCustomIcon;
- (BOOL)isStationery;
- (BOOL)isBundleBitSet;
- (BOOL)isAliasBitSet;
- (BOOL)isPackage;
- (BOOL)isApplication;
- (BOOL)isExtensionHidden;
- (BOOL)isReadable;
- (BOOL)isWritable;
- (BOOL)isExecutable;
- (BOOL)isDeletable;
- (BOOL)isRenamable;

	//! read only even if we had admin privleges
@property (readonly, getter=isReadOnly) BOOL readOnly;

- (BOOL)isMovable;
//! returns YES if isCarbonAlias or isPathFinderAlias or isUnixSymbolicLink
@property (readonly, getter=isAlias) BOOL alias;
@property (readonly, getter=isCarbonAlias) BOOL carbonAlias;
@property (readonly, getter=isPathFinderAlias) BOOL pathFinderAlias;
@property (readonly, getter=isSymbolicLink) BOOL symbolicLink;
@property (readonly, getter=isBrokenAlias) BOOL brokenAlias;
@property (readonly, getter=isServerAlias) BOOL serverAlias;
@property (readonly, getter=isStickyBitSet) BOOL stickyBitSet;
@property (readonly, getter=isPipe) BOOL pipe;
@property (readonly, getter=isVolume) BOOL volume;
@property (readonly, getter=isNameLocked) BOOL nameLocked;

- (BOOL)catalogInfo:(FSCatalogInfo*)outCatalogInfo bitmap:(FSCatalogInfoBitmap)bitmap;

// if your on UFS, you get a ._ path which is in appledouble format, so not good for getting the resource fork data
- (NSString*)pathToResourceFork;

- (BOOL)hasBeenModified;
- (BOOL)hasBeenRenamed;
- (NSString*)nameWhenCreated;

- (NSDate*)modificationDate;
- (NSDate*)attributeModificationDate;
- (NSDate*)creationDate;
- (NSDate*)accessDate;
- (NSDate*)lastUsedDate;

- (UInt32)posixPermissions;
@property (readonly, getter=isExecutableBitSet) BOOL executableBitSet;
- (UInt32)posixFileMode;
- (NSString*)permissionString;

- (UInt32)ownerID;
- (NSString *)ownerName;
- (UInt32)groupID;
- (NSString *)groupName;

@property (readonly) OSType type;
@property (readonly) OSType creator;
- (int)label;
- (NSString*)comments;

- (const FileInfo*)fileInfo;

- (BOOL)applicationCanOpenFile:(NTFileDesc*)file;

- (BOOL)isParentOfDesc:(NTFileDesc*)desc;  //!< used to determine if NTFileDesc is contained by this directory
- (BOOL)isParentOfFSRef:(FSRef*)fsRefPtr;  //!< used to determine if FSRef is contained by this directory
- (BOOL)isParentOfRefPath:(NSArray*)fsRefPath;  //!< used to determine if FSRef is contained by this directory

    // debugging tools
- (NSString*)description;
- (NSString*)longDescription;

@end

@interface NTFileDesc (NTVolume)

- (BOOL)isVolumeReadOnly;
- (BOOL)isBootVolume;
- (BOOL)isExternal;
- (BOOL)isNetwork;
- (BOOL)isLocalFileSystem;
- (BOOL)isSlowVolume;  // DVD, CD, Network
- (BOOL)isEjectable;
- (NTFileDesc *)mountPoint;
@end

@interface NTFileDesc (Setters)

// the name to display to the user for a rename command
- (NSString*)displayNameForRename;

// changes contents to new FSRef after rename (if FSRef changes which it does in some cases on rename)
- (NSString*)rename:(NSString*)newName err:(OSStatus*)outErr;

@end

// ================================================================================================================

// type and creator of a Path Finder document
#define kPathFinderAliasExtension @"path"

