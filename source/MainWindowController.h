/* MainWindowController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"

@interface MainWindowController : NSWindowController
{
    IBOutlet NSDrawer *_kindsDrawer;
}

- (id) initWithDocument: (FileSystemDoc*) doc;

+ (FileSystemDoc*) documentForView: (NSView*) view;

- (IBAction)toggleFileKindsDrawer:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) showInFinder:(id)sender;
- (IBAction) showPackageContents:(id)sender;
- (IBAction) selectParentItem:(id)sender;

@end
