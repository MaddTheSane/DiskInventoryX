#import "TreeMapView.h"

NSString *TreeMapViewItemTouchedNotification = @"TreeMapViewItemTouched";
NSString *TreeMapViewSelectionDidChangedNotification = @"TreeMapViewSelectionDidChangeed";
NSString *TreeMapViewSelectionIsChangingNotification = @"TreeMapViewSelectionIsChanging";
NSString *TMVTouchedItem = @"TreeMapViewTouchedItem"; //key for touched item in userInfo of a TreeMapViewItemTouchedNotification


//================ interface TreeMapView(Private) ======================================================

@interface TreeMapView(Private)

- (void) drawInCache;
- (void) allocContentCache;
- (void) deallocContentCache;
- (TMVItemRenderer*) findChildRendererByPathToItem: (NSMutableArray*) path underParent: (TMVItemRenderer*) parentRenderer;

@end

//================ implementation TreeMapView ======================================================

@implementation TreeMapView

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
	
    if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)])
        [super awakeFromNib];

    //we have no overlapping views
    //[[self window] useOptimizedDrawing: YES];

    [self setPostsFrameChangedNotifications: YES];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	//we want to know if we were resized
    [nc addObserver: self
		   selector: @selector(viewFrameDidChangeNotification:)
			   name: NSViewFrameDidChangeNotification
			 object: self];
	
	//these 2 notifications are sent by our window when it gains or looses focus
    [nc addObserver: self
		   selector: @selector(windowDidResignKey:)
			   name: NSWindowDidResignKeyNotification
			 object: [self window]];	
    [nc addObserver: self
		   selector: @selector(windowDidBecomeKey:)
			   name: NSWindowDidBecomeKeyNotification
			 object: [self window]];
	
    return self;
}

- (void) awakeFromNib
{
    [[self window] setAcceptsMouseMovedEvents: YES];
    
    _rootItemRenderer = [[TMVItemRenderer alloc] initWithDataSource: dataSource delegate: delegate renderedItem: nil tableMapView: self];
}

- (void) dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    //remove ourself as observer for the NSViewFrameDidChangeNotification
    [nc removeObserver: self];

    //remove our delegate for all our notifications
    if ( delegate != nil )
        [nc removeObserver: delegate name:nil object:self];

    [_rootItemRenderer release];
    [self deallocContentCache]; 

    [super dealloc];
}

- (id) delegate
{
    return delegate;
}

- (void) setDelegate: (id) new_delegate
{
    NSParameterAssert( new_delegate != nil );
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    if ( delegate != nil )
        [nc removeObserver: delegate name:nil object:self];

    delegate = new_delegate;

    // register our delegate as observer for all our notifications
#define REGISTER_DELEGATE( method, notification ) \
    if ([delegate respondsToSelector:@selector(method:)]) \
        [nc addObserver: delegate selector: @selector(method:) \
               name: notification object:self]

    REGISTER_DELEGATE( treeMapViewSelectionDidChange,	TreeMapViewSelectionDidChangedNotification );
    REGISTER_DELEGATE( treeMapViewSelectionIsChanging,	TreeMapViewSelectionIsChangingNotification );
    REGISTER_DELEGATE( treeMapViewItemTouched,		TreeMapViewItemTouchedNotification );

#undef REGISTER_DELEGATE
}

- (void) setDataSource: (id) new_dataSource
{
    dataSource = new_dataSource;

    //check that the data source implements all the required methods of category NSObject(TableMapViewDataSource)
#define RAISE_EXCEPTION( method ) \
        [NSException raise:NSInternalInconsistencyException \
                    format:@"data source doesn't respond to '%@'", method]

    if ( ![ dataSource respondsToSelector:@selector(treeMapView: child: ofItem:) ] )
        RAISE_EXCEPTION( @"(id) treeMapView: (TreeMapView*) view child: (unsigned) index ofItem: (id) item" );
        
    if ( ![ dataSource respondsToSelector:@selector(treeMapView: isNode:) ] )
        RAISE_EXCEPTION( @"(BOOL) treeMapView: (TreeMapView*) view isNode: (id) item" );
    
    if ( ![ dataSource respondsToSelector:@selector(treeMapView: numberOfChildrenOfItem:) ] )
        RAISE_EXCEPTION( @"(unsigned) treeMapView: (TreeMapView*) view numberOfChildrenOfItem: (id) item" );
    
    if ( ![ dataSource respondsToSelector:@selector(treeMapView: weightByItem:) ] )
        RAISE_EXCEPTION( @"(unsigned long long) treeMapView: (TreeMapView*) view weightByItem: (id) item" );
        
#undef RAISE_EXCEPTION
}

- (void) drawRect: (NSRect) rect
{
	//first, draw the focus rect, if we are first responder
	if ( [[self window] isKeyWindow]
		 && [[self window] firstResponder] == self )
	{
		[NSGraphicsContext saveGraphicsState];
		
		NSSetFocusRingStyle( NSFocusRingOnly );
		
		[[NSColor keyboardFocusIndicatorColor] set];		
		NSFrameRectWithWidth( [self visibleRect], 1 ); 
		
		[NSGraphicsContext restoreGraphicsState];
	}
	
	//If the window is being resized, we don't draw the tree map (too slow).
	//same for the case that we don't have anything to draw
    if ( [self inLiveResize] || [_rootItemRenderer childCount] == 0 )
    {
        //NSDrawWindowBackground( rect );
        NSEraseRect( rect );
        return;
    }
    
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
    //if our size has changed, re-layout items and re-establish tracking rects
    NSRect viewBounds = [self bounds];
    BOOL relayout = !NSEqualRects( viewBounds, [_rootItemRenderer rect] );
    if ( relayout )
    {
        [_rootItemRenderer calcLayout: viewBounds];
 
        [self deallocContentCache];
    }

    [self drawInCache];

    NSSize imageSize = NSMakeSize( NSWidth(viewBounds), NSHeight(viewBounds) );

    NSImage *image = [[NSImage alloc] initWithSize: imageSize];

    [image addRepresentation: _cachedContent];
    [image setFlipped: [self isFlipped]];

    [image drawAtPoint: NSMakePoint( 0, 0 )
              fromRect: viewBounds
             operation: NSCompositeCopy
              fraction: 1];

    [image release];
    
    if ( _selectedRenderer != nil )
    {
        [_selectedRenderer drawHighlightFrame];
    }
	
}
	
- (void) mouseDown: (NSEvent*) theEvent
{
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint: point fromView: nil];
    point.y--;

    //find the hitted item
    TMVItemRenderer* renderer = [_rootItemRenderer hitTest: point];

    if ( renderer != _selectedRenderer )
    {
        _selectedRenderer = renderer;
        
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName: TreeMapViewSelectionDidChangedNotification object: self userInfo: nil];

        [self setNeedsDisplay: YES];
    }
}

- (void) mouseMoved: (NSEvent *)theEvent
{
    [super mouseMoved: theEvent];
    
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint: point fromView: nil];
    point.y--;

    //first test if the mouse is still in the same item
    if ( _touchedRenderer != nil && [_touchedRenderer hitTest: point] != nil )
        return;

    //the mouse is moved to a new item, so look for the new one
     TMVItemRenderer* renderer = [_rootItemRenderer hitTest: point];

    if ( renderer == _touchedRenderer )
    {
        NSAssert( renderer == nil, @"why this?" );
        return;
    }

    _touchedRenderer = renderer;

    id touchedItem = (_touchedRenderer == nil) ? nil : [_touchedRenderer item];

    //set tooltip
    NSString *toolTip = nil;
    if ( touchedItem != nil && [delegate respondsToSelector: @selector(treeMapView: getToolTipByItem:)] )
        toolTip = [delegate treeMapView: self getToolTipByItem: touchedItem];

    [self setToolTip: toolTip];

    //post notification about the touched item
    NSDictionary *userInfo = (touchedItem == nil) ?
        [NSDictionary dictionary] : [NSDictionary dictionaryWithObject: touchedItem forKey: TMVTouchedItem];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: TreeMapViewItemTouchedNotification object: self userInfo: userInfo];
}

- (NSMenu*) menuForEvent: (NSEvent*) event
{
    if ( [delegate respondsToSelector: @selector(treeMapView: willShowMenuForEvent:)] )
        [delegate treeMapView: self willShowMenuForEvent: event];

    return [super menuForEvent: event];
}


- (TMVCellId) cellIdByPoint: (NSPoint) point inViewCoords: (BOOL) viewCoords;
{
    if ( !viewCoords)
        point = [self convertPoint: point fromView: nil];

    return [_rootItemRenderer hitTest: point];
}

- (id) selectedItem
{
    return _selectedRenderer == nil ? nil : [_selectedRenderer item];
}

- (id) itemByCellId: (TMVCellId) cellId
{
    NSParameterAssert( cellId != nil );

    return [cellId item];
}

- (void) selectItemByCellId: (TMVCellId) cellId
{
    if ( cellId != _selectedRenderer )
    {
        _selectedRenderer = cellId;

        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName: TreeMapViewSelectionDidChangedNotification object: self userInfo: nil];

        [self setNeedsDisplay: YES];
    }
}

- (void) selectItemByPathToItem: (NSArray*) path
{
    //path must at least contain one item (the root item)
    NSParameterAssert( [path count] > 0 );
    
    TMVItemRenderer *rendererToSelect = nil;
    
    if ( [path count] == 1 )
    {
        rendererToSelect = _rootItemRenderer;
    }
    else
    {
        NSMutableArray *mutablePath = [path mutableCopy];
        [mutablePath removeObjectAtIndex: 0];
        
        rendererToSelect = [self findChildRendererByPathToItem: mutablePath underParent: nil];
    }

    [self selectItemByCellId: rendererToSelect];
}

- (void) reloadData
{
    [self deallocContentCache];

    [_rootItemRenderer release];

    _selectedRenderer = nil;
    _touchedRenderer = nil;

    _rootItemRenderer = [[TMVItemRenderer alloc] initWithDataSource: dataSource delegate: delegate renderedItem: nil tableMapView: self];

    [self addToolTipRect: [self bounds] owner: self userData: nil];
    
    [self setNeedsDisplay: YES];
}

- (NSString *) view: (NSView *) view stringForToolTip: (NSToolTipTag) tag point: (NSPoint) point userData: (void *) userData
{
    if ( delegate != nil && [delegate respondsToSelector: @selector(treeMapView: getToolTipByItem:)] )
    {
        TMVItemRenderer *childRenderer = [self cellIdByPoint: point inViewCoords: YES];

        return [delegate treeMapView: self getToolTipByItem: [childRenderer item]];
    }
    else
        return @"";
}

- (void) viewDidEndLiveResize
{
    [_rootItemRenderer calcLayout: [self bounds]];
    
    //[self addToolTipRect: [self bounds] owner: self userData: nil];
    
    [self setNeedsDisplay: YES];
}

- (void) viewWillStartLiveResize
{
    [self deallocContentCache];
    
    [self removeAllToolTips];
}

- (void) viewFrameDidChangeNotification: (NSNotification*) notification
{
    [self deallocContentCache];
}

- (BOOL) isFlipped
{
    return YES;
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

//we're about to get the input focus, so invalidate the area of the focus rect
- (BOOL) becomeFirstResponder
{
	if ( ![super resignFirstResponder] )
		return NO;
	
	[self setKeyboardFocusRingNeedsDisplayInRect: [self visibleRect]];
	
	return YES;
}

//we're about to loose the input focus, so invalidate the area of the focus rect
- (BOOL) resignFirstResponder
{
	if ( ![super resignFirstResponder] )
		return NO;
	
	[self setKeyboardFocusRingNeedsDisplayInRect: [self visibleRect]];
	
	return YES;
}

//our window is no longer key, so invalidate the area of our focus rect
- (void) windowDidResignKey: (NSNotification *)aNotification
{
	if ( [[self window] firstResponder] == self )
		[self setKeyboardFocusRingNeedsDisplayInRect: [self visibleRect]];
}

//our window has become key, so invalidate the area of our focus rect
- (void) windowDidBecomeKey: (NSNotification *) aNotification
{
	if ( [[self window] firstResponder] == self )
		[self setKeyboardFocusRingNeedsDisplayInRect: [self visibleRect]];
}

- (BOOL) canBecomeKeyView
{
	return YES;
}

- (BOOL) isOpaque
{
    return YES;
}

@end

//================ implementation TreeMapView(Private) ======================================================

@implementation TreeMapView(Private)

- (void) drawInCache
{
    if ( _cachedContent != nil )
        return;

    [self allocContentCache];

    [_rootItemRenderer drawCushionInBitmap: _cachedContent];
}

- (void) allocContentCache
{
    [_cachedContent release];

    NSRect viewBounds = [self bounds];

    _cachedContent = [[ NSBitmapImageRep alloc]
                initWithBitmapDataPlanes:       NULL    // Let the class allocate it
                              pixelsWide:       NSWidth( viewBounds )
                              pixelsHigh:       NSHeight( viewBounds )
                           bitsPerSample:       8       // Each component is 8 bits (one byte)
                         samplesPerPixel:       3       // Number of components (R, G, B, no alpha)
                                hasAlpha:       NO
                                isPlanar:       NO
                          colorSpaceName:       NSDeviceRGBColorSpace
                             bytesPerRow:       0       // 0 means: Let the class figure it out
                            bitsPerPixel:       0];     // 0 means: Let the class figure it out
    
}

- (void) deallocContentCache
{
    if ( _cachedContent != nil )
    {
        [_cachedContent release];
        _cachedContent = nil;
    }
}

- (TMVItemRenderer*) findChildRendererByPathToItem: (NSMutableArray*) path underParent: (TMVItemRenderer*) parentRenderer
{
    NSAssert( [path count] >= 1, @"path is empty" );

    if ( parentRenderer == nil )
        parentRenderer = _rootItemRenderer;

    unsigned i;
    for ( i = 0; i < [parentRenderer childCount]; i++ )
    {
        TMVItemRenderer *childRenderer = [parentRenderer childAtIndex: i];
        if ( [childRenderer item] == [path objectAtIndex: 0] )
        {
            if ( [path count] > 1 )
            {
                NSAssert( ![childRenderer isLeaf], @"childRenderer is not a leaf although the path goes deeper" );
                [path removeObjectAtIndex: 0];
                return [self findChildRendererByPathToItem: path underParent: childRenderer];
            }
            else
                return childRenderer;
        }
    }

    //the child renderer of 'parentRenderer' displaying the frist item in 'path' not found
    return nil;
}

@end
