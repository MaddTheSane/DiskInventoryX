/* FileKindsTableController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "FileSizeFormatter.h"

@interface FileKindsTableController : NSObject
{
    IBOutlet NSTableView *_tableView;
    IBOutlet FileSystemDoc *_document;
    IBOutlet NSWindowController *_windowController;

    NSMutableArray *_cushionImages;
    NSMutableArray *_kinds;
}

- (FileSystemDoc*) document;

@end
