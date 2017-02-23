/* FilesOutlineViewController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "ImageAndTextCell.h"

@interface FilesOutlineViewController : NSObject
{
    IBOutlet FileSystemDoc *_document;
    IBOutlet NSOutlineView *_outlineView;
    IBOutlet NSMenu *_contextMenu;
    ImageAndTextCell *_cell;
    NSMutableDictionary *_fileIcons;
}

- (FileSystemDoc*) document;

- (FSItem*) rootItem;

@end
