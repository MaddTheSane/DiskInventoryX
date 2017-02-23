#import "FileKindsTableController.h"
#import "FileTypeColors.h"
#import "TMVCushionRenderer.h"
#import "MainWindowController.h"

//============ interface FileSystemDoc(Private) ==========================================================

@interface FileKindsTableController(Private)

- (void) createKindArray;
- (void) globalSelectionChanged: (NSNotification*) notification;

@end

//============ implementation FileKindsTableController ==========================================================

@implementation FileKindsTableController

- (void) awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(globalSelectionChanged:)
                                                 name: GlobalSelectionChangedNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(zoomedItemChanged:)
                                                 name: ZoomedItemChangedNotification
                                               object: [self document]];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showPackageContentsChanged:)
                                                 name: ShowPackageContentsChangedNotification
                                               object: [self document]];

    [self createKindArray];

    _cushionImageCell = [[NSImageCell alloc] init];
    
    [[_tableView tableColumnWithIdentifier: @"color"] setDataCell: _cushionImageCell];
    
    //NSMutableArray *_cushionImages;

    [_tableView reloadData];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_kinds release];
    [_cushionImages release];
    [_cushionImageCell release];

    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil )
        _document = [_windowController document];

    return _document;
}

//NSTableView delegate
- (void) tableView: (NSTableView*) tableView willDisplayCell: (id) cell forTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
}

//NSTableView data source
- (int) numberOfRowsInTableView: (NSTableView*) view
{
    return (int) [_kinds count];
}

- (id) tableView:  (NSTableView*) tableView objectValueForTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
    FileKindStatistic *kindStatistics = [_kinds objectAtIndex: row];
    NSString *columnTag = [tableColumn identifier];
        
    if ( [columnTag isEqualToString: @"kindName"] )
    {
        return [kindStatistics kindName];
    }
    else if ( [columnTag isEqualToString: @"fileCount"] )
    {
        return [NSNumber numberWithUnsignedInt: [kindStatistics fileCount]];
    }
    else if ( [columnTag isEqualToString: @"size"] )
    {
        NSString* units[] = {@"bytes", @"kB", @"MB", @"GB", @"TB"};
        double dsize = [kindStatistics filesSize];
        unsigned i = 0;
        while ( dsize >= 1024 && i < 5 )
        {
            i++;
            dsize /= 1024;
        }

        if ( i <= 1 )
            return [NSString stringWithFormat: @"%u %@", (unsigned) round(dsize), units[i] ];
        else
            return [NSString stringWithFormat: @"%.1f %@", (float) dsize, units[i]];
    }
    else if ( [columnTag isEqualToString: @"color"] )
    {	//color
        NSSize cellSize = NSMakeSize( [tableColumn width], [tableView rowHeight] );

        NSBitmapImageRep* bitmap = [[ NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL    // Let the class allocate it
                                                                            pixelsWide: cellSize.width
                                                                            pixelsHigh: cellSize.height
                                                                         bitsPerSample: 8       // Each component is 8 bits (one byte)
                                                                       samplesPerPixel: 3       // Number of components (R, G, B, no alpha)
                                                                              hasAlpha: NO
                                                                              isPlanar: NO
                                                                        colorSpaceName: NSDeviceRGBColorSpace
                                                                           bytesPerRow: 0       // 0 means: Let the class figure it out
                                                                          bitsPerPixel: 0];       // 0 means: Let the class figure it out

        NSImage *image = [[NSImage alloc] initWithSize: cellSize];
        // ...place our NSBitmapImageRep in the NSImag ...
        [image addRepresentation: bitmap];
        [bitmap release];

        [image setFlipped: [tableView isFlipped]];

        TMVCushionRenderer *cushionRenderer = [[TMVCushionRenderer alloc] initWithRect: NSMakeRect(0, 0, cellSize.width, cellSize.height)];

        [cushionRenderer setColor: [[FileTypeColors instance] colorForKind: [kindStatistics kindName]]];
        [cushionRenderer addRidgeByHeightFactor: 0.5];
        [cushionRenderer renderCushionInBitmap: bitmap];

        [cushionRenderer release];

        return [image autorelease];
    }
    else
    {
        NSAssert( NO, @"value for unknown column requested" );
        return @"";
    }
}

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
    //int row = [_tableView selectedRow];
}

@end

//============ implementation FileSystemDoc(Private) ==========================================================

@implementation FileKindsTableController(Private)

int CompareFileStatistics( id fs1, id fs2, void *context )
{
    if ( [fs1 filesSize] == [fs2 filesSize] )
        return NSOrderedSame;
    else
        return [fs1 filesSize] > [fs2 filesSize] ? NSOrderedAscending : NSOrderedDescending ;
}

- (void) createKindArray
{
    FileSystemDoc *document = [self document];

    [_kinds release];
    _kinds = [[NSMutableArray alloc] initWithCapacity: [[document kindStatistics] count]];

    NSEnumerator *kindEnum = [[document kindStatistics] objectEnumerator];

    FileKindStatistic *statistic;
    while ( ( statistic = [kindEnum nextObject] ) != nil )
    {
        [_kinds addObject: statistic];
    }

    [_kinds sortUsingFunction: &CompareFileStatistics context: NULL];
}

- (void) globalSelectionChanged: (NSNotification*) notification
{
    FSItem *item = [[self document] selectedItem];

    if ( item != nil )
    {
        NSString *itemKind = [item kindName];

        unsigned i;
        for ( i = 0; i < [_kinds count]; i++ )
        {
            if ( [itemKind isEqualToString: [[_kinds objectAtIndex: i] kindName]] )
            {
                [_tableView selectRow: i byExtendingSelection: NO];
                [_tableView scrollRowToVisible: i];
                return;
            }
        }
    }

    //unknown kind (maybe a folder)
    [_tableView deselectAll: self];
}

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [self createKindArray];
    
    [_tableView reloadData];
}

- (void) showPackageContentsChanged: (NSNotification*) notification
{
    [self createKindArray];
    
    [_tableView reloadData];
}

@end

