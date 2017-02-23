#import "TreeMapViewController.h"
#import "TreeMapView.h"
#import "FileTypeColors.h"
#import "MainWindowController.h"

@implementation TreeMapViewController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(globalSelectionChanged:)
                                                 name: GlobalSelectionChangedNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(zoomedItemChanged:)
                                                 name: ZoomedItemChangedNotification
                                               object: doc];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showPackageContentsChanged:)
                                                 name: ShowPackageContentsChangedNotification
                                               object: doc];
	
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(itemsChanged:)
                                                 name: FSItemsChanged
                                               object: doc];

    [_fileNameTextField setStringValue: @""];
    [_fileSizeTextField setStringValue: @""];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil && _treeMapView != nil )
        _document = [MainWindowController documentForView: _treeMapView];

    return _document;
}

- (FSItem*) rootItem
{
    return [[self document] zoomedItem];
}

// TableMapViewDataSource
- (id) treeMapView: (TreeMapView*) view child: (unsigned) index ofItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [fsItem childAtIndex: index];
}

- (BOOL) treeMapView: (TreeMapView*) view isNode: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [[self document] itemIsNode: fsItem];
}

- (unsigned) treeMapView: (TreeMapView*) view numberOfChildrenOfItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [fsItem childCount];
}

- (unsigned long long) treeMapView: (TreeMapView*) view weightByItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [fsItem size];
}

// TableMapViewDelegate
- (NSString*) treeMapView: (TreeMapView*) view getToolTipByItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [fsItem displayName];
}

- (void) treeMapView: (TreeMapView*) view willDisplayItem: (id) item withRenderer: (TMVItemRenderer*) renderer
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    if ( ![self treeMapView: view isNode: fsItem] )
    {
        NSColor *color = [[FileTypeColors instance] colorForItem: fsItem];

        [renderer setCushionColor: color];
    }

}

- (void) treeMapView: (TreeMapView*) view willShowMenuForEvent: (NSEvent*) event
{
    if ( [event type] == NSRightMouseDown )
    {
        //right mouse click -> context menu
        //select the item hit by the click,
        //so the user gets feedback for which item the menu is shown 
        NSPoint point = [event locationInWindow];

        TMVCellId cell = [_treeMapView cellIdByPoint: point inViewCoords: NO];
        NSAssert1( cell != nil, @"No item at %@", NSStringFromPoint(point) );

        FileSystemDoc *document = [self document];

        [document setSelectedItem: [_treeMapView itemByCellId: cell]];

        //post notification that the global selection has changed
        //we send our document as 'object' as we want to be callbacked by the notification so that
        //the selection in the TreeMap is changed (see globalSelectionChanged:)
        [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: document userInfo: nil];
    }
}

//TableMapViewNotifications
- (void)treeMapViewItemTouched: (NSNotification*) notification
{
    FSItem *fsItem = [[notification userInfo] objectForKey: TMVTouchedItem];

    if ( fsItem == nil )
    {
        [_fileNameTextField setStringValue: @""];
        [_fileSizeTextField setStringValue: @""];
    }
    else
    {
        NSString *displayName = [fsItem displayName];
        displayName = [displayName stringByAppendingFormat: @" (%@)", [fsItem displayFolderName]];
        
        [_fileNameTextField setStringValue: displayName];

        [_fileSizeTextField setStringValue: [NSString stringWithFormat: @"%@, %@", [fsItem kindName], [fsItem displaySize]]];
    }
}

- (void) treeMapViewSelectionDidChange: (NSNotification*) notification
{
    FSItem *item = [_treeMapView selectedItem];

    FileSystemDoc *doc = [self document];

    //if we are notified about the selection change after we've set the selection by ourself
    //(e.g. in 'globalSelectionChanged:') we don't want to post any notification
    if ( [doc selectedItem] != item )
    {
        [doc setSelectedItem: item];

        //post notification that the global selection has changed
        [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
    }
}

#pragma mark --------document notifications-----------------

- (void) globalSelectionChanged: (NSNotification*) notification
{
    if ( [notification object] == self )
        return;

    FSItem *item = [[self document] selectedItem];

    if ( item == nil )
    {
        [_treeMapView selectItemByCellId: nil];
    }
    else
    {
        //put path from root item to selected item in an array
        NSMutableArray *pathToSelectedItem = [NSMutableArray array];
        [pathToSelectedItem insertObject: item atIndex: 0];

        do
        {
            item = [item parent];
            if ( item != nil )
                [pathToSelectedItem insertObject: item atIndex: 0];
        }
        while ( item != nil && item != [self rootItem]);

        [_treeMapView selectItemByPathToItem: pathToSelectedItem];
    }
}

- (void) itemsChanged: (NSNotification*) notification
{
    [_treeMapView reloadData];
}

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [_treeMapView reloadData];
}

- (void) showPackageContentsChanged: (NSNotification*) notification
{
    [_treeMapView reloadData];

    //restore selection
    [self globalSelectionChanged: [NSNotification notificationWithName: GlobalSelectionChangedNotification
                                                                object: nil]];
}

@end
