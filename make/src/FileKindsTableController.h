/* FileKindsTableController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"

@interface FileKindsTableController : NSObject
{
    IBOutlet NSTableView *_tableView;
    IBOutlet FileSystemDoc *_document;
    IBOutlet NSWindowController *_windowController;

    NSImageCell *_cushionImageCell;
    NSMutableArray *_cushionImages;
    NSMutableArray *_kinds;
}

- (FileSystemDoc*) document;

@end
