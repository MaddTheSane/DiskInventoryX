#import "MainWindowController.h"

@implementation MainWindowController

- (id) initWithDocument: (FileSystemDoc*) doc
{
    self = [super init];

    [self setDocument: doc];

    return self;
}

+ (FileSystemDoc*) documentForView: (NSView*) view
{
    FileSystemDoc* doc = nil;

    NSWindow *window = [view window];
    if ( [window isKindOfClass: [NSDrawer class]] )
        window = [window parentWindow];
    
    id delegate = [window delegate];
    NSAssert( delegate != nil, @"expecting to retrieve the document from the window controller, which should be the window's delegate; but the window has no delegte" );

    if ( [delegate respondsToSelector: @selector(document)] )
    {
        doc = [delegate document];
        NSAssert( [doc isKindOfClass: [FileSystemDoc class]], @"document object is not of expected kind 'FileSystemDoc'" );
    }
    else
        NSAssert( NO, @"window's delegate has no method 'document' to retrieve document object" );

    return doc;
}

- (void) awakeFromNib
{
    [_kindsDrawer toggle: self];
}

- (IBAction)toggleFileKindsDrawer:(id)sender
{
    [_kindsDrawer toggle: self];
}

- (IBAction) zoomIn:(id)sender
{
    FSItem *selectedItem = [[self document] selectedItem];

    if ( selectedItem != nil )
    {
        [[self document] zoomIntoItem: selectedItem];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) zoomOut:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *currentZoomedItem = [doc zoomedItem];

    if ( currentZoomedItem != [doc rootItem] )
    {
        [doc zoomOutOneStep];

        [doc setSelectedItem: currentZoomedItem];
        //post notification that the global selection has changed
        [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) showInFinder:(id)sender
{
    FSItem *selectedItem = [[self document] selectedItem];

    if ( selectedItem != nil )
        [[NSWorkspace sharedWorkspace] selectFile: [selectedItem path] inFileViewerRootedAtPath: nil];
}

- (IBAction) showPackageContents:(id)sender
{
    FileSystemDoc *doc = [self document];

    [doc setShowPackageContents: ![doc showPackageContents]];
}

- (IBAction) selectParentItem:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *selectedItem = [doc selectedItem];

    if ( selectedItem != [doc zoomedItem] )
    {
        [doc setSelectedItem: [selectedItem parent]];

        //post notification that the global selection has changed
        [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
    }
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem
{
    FileSystemDoc *doc = [self document];
    
    FSItem *selectedItem = [doc selectedItem];

    if ( [menuItem action] == @selector(zoomIn:) )
    {
        return selectedItem != nil && [selectedItem isFolder];
    }
    else if ( [menuItem action] == @selector(zoomOut:) )
    {
        return [doc rootItem] != [doc zoomedItem];
    }
    else if ( [menuItem action] == @selector(showInFinder:) )
    {
        return selectedItem != nil;
    }
    else if ( [menuItem action] == @selector(showPackageContents:) )
    {
        [menuItem setState: [doc showPackageContents] ? NSOnState : NSOffState];
    }
    else if ( [menuItem action] == @selector(toggleFileKindsDrawer:) )
    {
        [menuItem setState: ([_kindsDrawer state] == NSDrawerOpenState) ? NSOnState : NSOffState];
    }
    else if ( [menuItem action] == @selector(selectParentItem:) )
    {
        return selectedItem != nil && selectedItem != [doc zoomedItem];
    }
    
    return TRUE;
}

@end
