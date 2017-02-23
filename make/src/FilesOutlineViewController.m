//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FilesOutlineViewController.h"
#import "FSItem.h"
//#import <CocoaTechFoundation/NSImage-NTExtensions.h>
#import "MainWindowController.h"
#import "Preferences.h"

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
        [self selectRowIndexes: [NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection: NO];

    id delegate = [self delegate];
    
    if ( columnIndex >= 0 && rowIndex >= 0
         && [delegate respondsToSelector:@selector(outlineView:menuForTableColumn:item:)] )
    {
		//get context menu
        NSTableColumn *column = [[self tableColumns] objectAtIndex: columnIndex];
        NSMenu *contextMenu = [delegate outlineView:self menuForTableColumn: column item: [self itemAtRow: rowIndex]];

		//set first responder if we will show a context menu
		//(isn't nessecary for proper function, but makes sense as the user opens the context menu)
		if ( contextMenu != nil
			 && [self acceptsFirstResponder]
			 && [[self window] firstResponder] != self )
		{
			[[self window] makeFirstResponder: self];
		}
		
		return contextMenu;
    }
    else
        return NULL;
}

@end

#pragma mark ------------------- FilesOutlineViewController --------------------------

@interface FilesOutlineViewController(Private)

- (void) onDocumentSelectionChanged;
- (void) reloadPackages: (FSItem*) parent;
- (void) reloadData;
- (void) setOutlineViewFont;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;

@end

@implementation FilesOutlineViewController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
    [center addObserver: self
			   selector: @selector(zoomedItemChanged:)
				   name: ZoomedItemChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(viewOptionChanged:)
				   name: ViewOptionChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(itemsChanged:)
				   name: FSItemsChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(windowWillClose:)
				   name: NSWindowWillCloseNotification
				 object: [_outlineView window]];
	
	//set ImageAndTextCell as the data cell for the first (outline) column
    [[_outlineView outlineTableColumn] setDataCell: [[[ImageAndTextCell alloc] init] autorelease]];
	
	//set FileSizeFormatter for the size column
	FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];
	[[[_outlineView tableColumnWithIdentifier: @"size"] dataCell] setFormatter: sizeFormatter];
        
	//set up KVO
	[[NSUserDefaults standardUserDefaults] addObserver: self
											forKeyPath: UseSmallFontInFilesView
											   options: NSKeyValueChangeSetting
											   context: nil];
	[doc addObserver: self forKeyPath: DocKeySelectedItem options: NSKeyValueChangeSetting context: nil];
	
	//set small font for all for all columns if needed
	[self setOutlineViewFont];
    
    [self reloadData];
}

- (void) dealloc
{
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

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item
{
	FSItem *fsItem = (item == nil) ? [self rootItem] : item;

    return [fsItem childAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    return [[self document] itemIsNode: item];
}

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	FSItem *fsItem = (item == nil) ? [self rootItem] : item;
	
    return [fsItem childCount];
}

- (id) outlineView: (NSOutlineView *) outlineView
objectValueForTableColumn: (NSTableColumn *) tableColumn
            byItem: (id) item
{
    NSString *columnTag = [tableColumn identifier];
    FSItem *fsItem = item;
	
	return [fsItem valueForKey: columnTag];
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
    if ( [[tableColumn identifier] isEqualToString: @"displayName"] )
    {
		//row height for default font is 17 pixels, so subtract 1
        NSImage *icon = [item iconWithSize: ( [outlineView rowHeight] -1 )];
        [cell setImage: icon];
    }
}

- (NSMenu*) outlineView: (NSOutlineView *) outlineView menuForTableColumn: (NSTableColumn*) column item: (id) item
{	
	return _contextMenu;
}

#pragma mark --------NSOutlineView notifications-----------------

- (void) outlineViewSelectionDidChange: (NSNotification*) notification
{
    FSItem *item = [_outlineView selectedItem];

    FileSystemDoc *doc = [self document];

    //if we are notified about the selection change after we've set the selection by ourself
    //(e.g. in 'onDocumentSelectionChanged') we don't want to post any notification
    if ( item != [doc selectedItem] )
        [doc setSelectedItem: item];
}

#pragma mark --------document notifications-----------------

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [self reloadData];
}

- (void) viewOptionChanged: (NSNotification*) notification
{
	NSString *theOption = [[notification userInfo] objectForKey:ChangedViewOption];
	
	if ( [theOption isEqualToString: ShowPackageContents] )
	{
		//save current selection
		id selectedItem = [_outlineView selectedItem];
		[_outlineView deselectAll: self];
		
		[self reloadPackages: nil];
		
		//try to restore selection
		NSInteger row = [_outlineView rowForItem: selectedItem];
		if ( row >= 0 )
			[_outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex:row] byExtendingSelection: NO];
		
		//the view doesn't redraw properly, so invalidate it
		[_outlineView setNeedsDisplay: YES];
	}
	else if ( [theOption isEqualToString: ShowPhysicalFileSize] )
		[self reloadData];
}

- (void) itemsChanged: (NSNotification*) notification
{
    [self reloadData];
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	[[self document] removeObserver: self forKeyPath: DocKeySelectedItem];
	
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: UseSmallFontInFilesView];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

@implementation FilesOutlineViewController(Private)

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	if ( object == [NSUserDefaults standardUserDefaults] )
	{
		if ( [keyPath isEqualToString: UseSmallFontInFilesView] )
			[self setOutlineViewFont];
	}
	else if ( object == [self document] )
	{
		if ( [keyPath isEqualToString: DocKeySelectedItem] )
			[self onDocumentSelectionChanged];
	}
}

- (void) onDocumentSelectionChanged
{
    FSItem *item = [[self document] selectedItem];
	
	if ( item == (FSItem*) [_outlineView selectedItem] )
		return;
	
    if ( item == nil )
        [_outlineView deselectAll: nil];
    else
    {
        NSInteger row = [_outlineView rowForItem: item];
        
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
            [_outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex:row] byExtendingSelection: NO];
            [_outlineView scrollRowToVisible: row];
        }
    }
}

- (void) setOutlineViewFont
{
	float fontSize = 0;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: UseSmallFontInFilesView] )
		fontSize = [NSFont smallSystemFontSize];
	else
		fontSize = [NSFont systemFontSize];
	
	NSFont *font = [NSFont systemFontOfSize: fontSize];
	
	NSEnumerator *columnEnum = [[_outlineView tableColumns] objectEnumerator];
	NSTableColumn *column;
	while ( (column = [columnEnum nextObject]) != nil )
	{
		NSCell *cell = [column dataCell];
		if ( [cell type] == NSTextCellType )
			[cell setFont: font];
	}
	
	[_outlineView setRowHeight: fontSize +4];
}

- (void) reloadData
{
    [_outlineView reloadData];
	[self onDocumentSelectionChanged];
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

@end