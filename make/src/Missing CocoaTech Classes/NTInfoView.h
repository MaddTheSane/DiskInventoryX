//
//  NTInfoView.h
//  Disk Inventory X
//
//  Created by C.W. Betts on 6/21/16.
//
//

#import <Cocoa/Cocoa.h>
#import <CocoatechFile/NTFileDesc.h>

@class NTTitledInfoView;
@class NTThreadWorkerController;

@interface NTInfoView : NSView
{
	NTTitledInfoView *_titledInfoView;
	NTFileDesc *_desc;
	BOOL _longFormat;
	NSString *_calculatedFolderSize;
	NSString *_calculatedFolderNumItems;
	NTThreadWorkerController *_calcSizeThread;
}

- (id)initWithFrame:(NSRect)arg1 longFormat:(BOOL)arg2;
- (id)initWithFrame:(NSRect)arg1;
@property (retain) NTFileDesc *desc;

@end
