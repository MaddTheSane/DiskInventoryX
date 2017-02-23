#import "FilesOutlineViewController.h"
#import "FSItem.h"
#import "NSImage-ScaleExtension.h"
#import "MainWindowController.h"

#pragma mark ----------------NSOutlineView context menu extension---------------------

@interface NSObject(NSOutlineViewDelegateContextMenu)
- (NSMenu*) outlineView: (NSOutlineView *) outlineView menuForTableColumn: (NSTableColumn*) column item: (id) item;
@end

@interface NSOutlineView(ContextMenuExtension)
- (id) selectedItem;
@end

@implementation NSOutlineView(ContextMenuExtension)
// return the selected item
- (id) selectedItem
{
    int row = [self selectedRow];
    return row >= 0 ? [self itemAtRow: row] : nil;
}

// ask the delegate which menu to show
-(NSMenu*) menuForEvent:(NSEvent*)evt
{
    NSPoint point = [self convertPoint: [evt locationInWindow] fromView: nil];
    
    int columnIndex = [self columnAtPoint:point];
    int rowIndex = [self rowAtPoint:point];

    if ( rowIndex >= 0 && [self numberOfSelectedRows] <= 1)
        [self selectRow: rowIndex byExtendingSelection: NO];

    id delegate = [self delegate];
    
    if ( columnIndex >= 0 && rowIndex >= 0
         && [delegate respondsToSelector:@selector(outlineView:menuForTableColumn:item:)] )
    {
        NSTableColumn *column = [[self tableColumns] objectAtIndex: columnIndex];
        return [delegate outlineView:self menuForTableColumn: column item: [self itemAtRow: rowIndex]];
    }
    else
        return NULL;
}

@end

#pragma mark ------------------- FilesOutlineViewController --------------------------

@interface FilesOutlineViewController(Private)

- (NSImage*) iconForItem: (FSItem*) item withSize: (int) size;
- (void) reloadPackages: (FSItem*) parent;
- (void) reloadData;

@end

@implementation FilesOutlineViewController

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
	
    _cell = [[ImageAndTextCell alloc] init];

    _fileIcons = [[NSMutableDictionary alloc] init];
    
    [[_outlineView outlineTableColumn] setDataCell: _cell];
        
    [self reloadData];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_cell release];

    [_fileIcons release];
    
    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil && _outlineView != nil )
        _document = [MainWindowController documentForView: _outlineView];

    return _document;
}

- (FSItem*) rootItem
{
    return [[self document] zoomedItem];
}

#pragma mark --------NSOutlineView datasource-----------------

- (NSMenu*) outlineView: (NSOutlineView *) outlineView menuForTableColumn: (NSTableColumn*) column item: (id) item
{
     return _contextMenu;
}

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item
{
    if ( item == nil )
        item = [self rootItem];

    return [item childAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    return [[self document] itemIsNode: item];
}

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
    if ( item == nil )
        item = [self rootItem];

    return [item childCount];
}

- (id) outlineView: (NSOutlineView *) outlineView
objectValueForTableColumn: (NSTableColumn *) tableColumn
            byItem: (id) item
{
    NSString *columnTag = [tableColumn identifier];
    FSItem *fsItem = item;

    if ( [columnTag isEqualToString: @"name"] )
    {
        return [fsItem displayName];
    }
    else if ( [columnTag isEqualToString: @"size"] )
    {
        return [fsItem displaySize];
    }
    else if ( [columnTag isEqualToString: @"kindName"] )
    {
        return [fsItem kindName];
    }
    else
    {
        NSAssert( NO, @"value for unknown column requested" );
        return @"";
    }
}

- (BOOL) outlineView: (NSOutlineView *) outlineView
          writeItems: (NSArray*) items
        toPasteboard: (NSPasteboard*) pboard
{
    return NO;
}

#pragma mark --------NSOutlineView delegate-----------------

- (void) outlineView: (NSOutlineView *) outlineView
     willDisplayCell: (id) cell
      forTableColumn: (NSTableColumn *) tableColumn
                item: (id) item
{
    if ( [[tableColumn identifier] isEqualToString: @"name"] )
    {
        NSImage *icon = [self iconForItem: item withSize: 16];
        [cell setImage: icon];
    }
}

#pragma mark --------NSOutlineView notifications-----------------

- (void) outlineViewSelectionDidChange: (NSNotification*) notification
{
    FSItem *item = [_outlineView selectedItem];

    FileSystemDoc *doc = [self document];

    //if we are notified about the selection change after we've set the selection by ourself
    //(e.g. in 'globalSelectionChanged:') we don't want to post any notification
    if ( item != [doc selectedItem] )
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
        [_outlineView deselectAll: nil];
    else
    {
        int row = [_outlineView rowForItem: item];
        
        //if the item can't be found in the view, then the user hasn't expanded the parents yet
        if ( row < 0 )
        {
            //first, get path from the root item to the item to be selected
            NSMutableArray *path = [NSMutableArray array];
            
            item = [item parent];
            while ( item != nil )
            {
                [path insertObject: item atIndex: 0];
                
                if ( item == [self rootItem] )
                    item = nil;
                else
                    item = [item parent];
            }
            
            //second, expand all parents
            int i = 0;
            for ( i = 1; i < [path count]; i++ )
            {
                row = [_outlineView rowForItem: item];
                if ( row <= 0 )
                {
                    //the item is not exandable, so stop here
                    //(e.g. item is a pckage, but package contents aren't shown)
                    if ( ![[self document] itemIsNode: [path objectAtIndex: i]] )
                        break;
                        
                    [_outlineView expandItem: [path objectAtIndex: i]];
                }
            }
            
            //now the item may be found in the outline view, if the expandation wasn't stopped
            row = [_outlineView rowForItem: [[self document] selectedItem]];
        }
        
        if ( row < 0 )
            [_outlineView deselectAll: nil];
        else
        {
            [_outlineView selectRow: row byExtendingSelection: NO];
            [_outlineView scrollRowToVisible: row];
        }
    }
}

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [self reloadData];
}

- (void) showPackageContentsChanged: (NSNotification*) notification
{
	//save current selection
	id selectedItem = [_outlineView selectedItem];
	[_outlineView deselectAll: self];
	
    [self reloadPackages: nil];
	
	//try to restore selection
	int row = [_outlineView rowForItem: selectedItem];
	if ( row >= 0 )
		[_outlineView selectRow: row byExtendingSelection: NO];
	
	//the view doesn't redraw properly, so invalidate it
	[_outlineView setNeedsDisplay: YES];
}

- (void) itemsChanged: (NSNotification*) notification
{
    [self reloadData];
}

@end

@implementation FilesOutlineViewController(Private)

- (void) reloadData
{
    [_outlineView reloadData];
}

- (void) reloadPackages: (FSItem*) parent
{
	FileSystemDoc *doc = [self document];
	
    if ( parent == nil )
	{
        parent = [self rootItem];
	}

    unsigned i;
    for ( i = 0; i < [parent childCount]; i++ )
    {
        FSItem *child = [parent childAtIndex: i];

        //if the item is shown in the outline view, reload all package items
        if ( [child isFolder] && [_outlineView rowForItem: child] >= 0 )
        {
			//collapse item if it is no longer expandable
			if ( ![doc itemIsNode: child] && [_outlineView isItemExpanded: child] )
				[_outlineView collapseItem: child collapseChildren: TRUE];
			
            if ( [child isPackage] )
                [_outlineView reloadItem: child];

			//recurse through childs
			if ( [[self document] itemIsNode: child] )
				[self reloadPackages: child];
        }
    }
}

- (NSImage*) iconForItem: (FSItem*) item withSize: (int) size
{
    id key = [item hashObject];
    NSImage *icon = [_fileIcons objectForKey: key];

    if ( icon == nil )
    {
        icon = [[NSWorkspace sharedWorkspace] iconForFile: [item path]];
        if ( icon == nil )
            icon = (NSImage*) [NSNull null];
        else
            icon = [icon sizeIcon: size];

        [_fileIcons setObject: icon forKey: key];
    }

    return ( icon == (NSImage*) [NSNull null] ) ? nil : icon;
}

@end