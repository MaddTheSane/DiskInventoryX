//
//  TMVItem.m
//  DiskAccountant
//
//  Created by Tjark Derlien on Tue Sep 30 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#include <math.h>
#include <tgmath.h>
#import "TMVItem.h"
#import "TreeMapView.h"

#define  CUSHION_SCALE_FACTOR	 0.9f

static NSColor* _parentGridColor;
static NSColor* _leafGridColor;
static NSColor* _highlightGridColor;
static NSColor* _nameColor;

static NSMutableDictionary *_gridTextAttributes;
static NSMutableDictionary *_cushionTextAttributes;

//============================ interface TMVItem( Private ) =============================================

@interface TMVItem(Private)

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap parentCushion: (TMVCushionRenderer*) parentCushion cushionHeightFactor: (CGFloat) heightFactor;

- (void) layoutChilds;
- (void) arrangeChildsOnRows: (NSMutableArray*) rows
                childsPerRow: (NSMutableArray*) childsPerRow
                 childWidths: (NSMutableArray*) childWidths
                rowsAreHoriz: (BOOL*) horizontal;
- (double) calculateRow: (NSUInteger) startChildIndex
               rowWidth: (double) rowWidth
            childsUsed : (NSUInteger*) childsUsed
            childWidths: (NSMutableArray*) childWidths;

- (void) createChildRenderers;

@end

//============================ implementation TMVItem =============================================

@implementation TMVItem

+ (void) initialize
{
    if ( _parentGridColor == nil )
        _parentGridColor = [NSColor textColor];
    if ( _leafGridColor == nil )
        _leafGridColor = [NSColor disabledControlTextColor];
    if ( _highlightGridColor == nil )
        _highlightGridColor = [NSColor yellowColor];
    if ( _nameColor == nil )
        _nameColor = [NSColor disabledControlTextColor];
	
    if ( _gridTextAttributes == nil )
        _gridTextAttributes = [[NSMutableDictionary alloc] init];
    if ( _cushionTextAttributes == nil )
        _cushionTextAttributes = [[NSMutableDictionary alloc] init];
}

- (instancetype) initWithDataSource: (id) dataSource delegate: (id) delegate renderedItem: (id) item treeMapView: (id) view
{
	if (self = [super init]) {
		
    _item = item;
    _dataSource = dataSource;
    _delegate = delegate;
    _view = view;
	_rect = NSZeroRect;

    _cushionRenderer = [[TMVCushionRenderer alloc] init];

    if ( ![self isLeaf] )
        [self createChildRenderers];
	}
    return self;
}

- (void) setCushionColor: (NSColor*) color
{
    _cushionRenderer.color = color;
}

- (void) calcLayout: (NSRect) rect
{
    if ( NSEqualRects( _rect, rect ) )
		return;

    NSAssert( NSWidth(_rect) == roundf( NSWidth(_rect) ), @"rect width is not an integral value");
    NSAssert( NSHeight(_rect) == roundf( NSHeight(_rect) ), @"rect height is not an integral value");

    _rect = rect;
    _cushionRenderer.rect = rect;
    
    //if the rect is too small, we do nothing
    if ( NSHeight( _rect) < 1 || NSWidth( _rect ) < 1 )
        return;

    if ( ![self isLeaf] )
        [self layoutChilds];
}

- (void ) drawGrid
{
    if ( [self isLeaf] )
    {
        [_leafGridColor set];

        NSFrameRectWithWidthUsingOperation(_rect, 1, NSCompositeCopy );

/*        if ( NSWidth(_rect) > 60 && NSHeight(_rect) > 20 )
        {
            //            [_gridTextAttributes setObject: [NSFont fontWithName:@"Times" size: 24]
            //                        forKey:NSFontAttributeName];
            [_gridTextAttributes setObject: _leafGridColor forKey:NSForegroundColorAttributeName];
            [[_item displayName] drawInRect: _rect withAttributes: _gridTextAttributes];
        }
        */
    }
    else
    {
        NSEnumerator *childEnum = [_childRenderers objectEnumerator];
        TMVItem *childRenderer;
        while ( ( childRenderer = [childEnum nextObject] ) != nil )
        {
            [childRenderer drawGrid];
        }
    }
}

- (void) drawHighlightFrame
{
    //if the rect is too small, we do nothing
    if ( NSHeight( _rect) < 1 || NSWidth( _rect ) < 1 )
        return;
    
    [_highlightGridColor set];
	
	float oldLineWidth = [NSBezierPath defaultLineWidth];
	[NSBezierPath setDefaultLineWidth: 2];
	
    [NSBezierPath strokeRect: _rect];
	
	[NSBezierPath setDefaultLineWidth: oldLineWidth];
}

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap
{
    [self drawCushionInBitmap: bitmap parentCushion: nil cushionHeightFactor: 0.5f];
}

- (BOOL) isLeaf
{
    return ![_dataSource treeMapView: _view isNode: _item];
}

- (id) item
{
    return _item;
}

- (unsigned long long) weight
{
    return [_dataSource treeMapView: _view weightByItem: _item];
}

- (NSRect) rect
{
    return _rect;
}

- (NSEnumerator *) childEnumerator
{
    NSAssert( _childRenderers != nil, @"method 'childEnumerator' can only be invoked for nodes, not for leafs");

    return [_childRenderers objectEnumerator];
}

- (TMVItem*) childAtIndex: (NSUInteger) index
{
    return _childRenderers[index];
}

- (NSUInteger) childCount
{
    return _childRenderers.count;
}

- (TMVItem *) hitTest: (NSPoint) aPoint
{
    if ( !NSPointInRect( aPoint, _rect ) )
        return nil;
    
    if ([self isLeaf]) {
        return self;
    } else {
        NSEnumerator *childEnum = [_childRenderers objectEnumerator];
        for (TMVItem *childRenderer in _childRenderers ) {
            TMVItem *hittedChildRenderer = [childRenderer hitTest: aPoint];            
            if ( hittedChildRenderer != nil )
                return hittedChildRenderer;
        }
        return nil;
    }
}

@end

//============================ implementation TMVItem( Private ) =============================================

@implementation TMVItem( Private )

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap parentCushion: (TMVCushionRenderer*) parentCushion cushionHeightFactor: (CGFloat) heightFactor
{
    //if the rect is too small, we do nothing
    if ( NSHeight( _rect) < 1 || NSWidth( _rect ) < 1 )
        return;

    if ( parentCushion != NULL )
    {
        [_cushionRenderer setSurface: [parentCushion surface]];
        [_cushionRenderer addRidgeByHeightFactor: heightFactor];
    }

    if ( [self isLeaf] )
    {
        if ( _delegate != nil && [_delegate respondsToSelector: @selector(treeMapView: willDisplayItem: withRenderer:)] )
            [_delegate treeMapView: _view willDisplayItem: _item withRenderer: self];

		[_cushionRenderer renderCushionInBitmap: bitmap];
		//[_cushionRenderer renderCushionInBitmapPPC603: bitmap];

        /*        if ( NSWidth(_rect) > 60 && NSHeight(_rect) > 20 )
        {
            float r, g, b, a;
            [_cushionColor getRed: &r green: &g blue: &b alpha: &a];

            r /= 2;
            g /= 2;
            b /= 2;

            NSColor *color = [NSColor colorWithCalibratedRed: r green: g blue: b alpha: a];

            //            [_cushionTextAttributes setObject: [NSFont fontWithName:@"Times" size: 24]
            //                        forKey:NSFontAttributeName];
            [_cushionTextAttributes setObject: color forKey:NSForegroundColorAttributeName];
            [[_item displayName] drawInRect: _rect withAttributes: _cushionTextAttributes];
        }
        */
    }
    else
    {
		for (id childRender in _childRenderers) {
			[childRender drawCushionInBitmap: bitmap parentCushion: _cushionRenderer cushionHeightFactor: (heightFactor * CUSHION_SCALE_FACTOR)];
		}
    }
}

- (void) layoutChilds
{
    NSMutableArray *rows = [[NSMutableArray alloc] init];   //doubles, fraction of total height for each row
    NSMutableArray *childsPerRow = [[NSMutableArray alloc] init]; //ints, number of childs per row
    NSMutableArray *childWidths = [[NSMutableArray alloc] initWithCapacity: _childRenderers.count]; //doubles, fraction of total width for each child

    BOOL horizontalRows;

    [self arrangeChildsOnRows: rows
                 childsPerRow: childsPerRow
                  childWidths: childWidths
                 rowsAreHoriz: &horizontalRows];

    const NSInteger parentWidth = (NSInteger) /*roundf*/( horizontalRows ? NSWidth(_rect) : NSHeight(_rect) );
    const NSInteger parentHeight = (NSInteger) /*roundf*/( horizontalRows ? NSHeight(_rect) : NSWidth(_rect) );

    const NSInteger parentBottom = (NSInteger) /*roundf*/( horizontalRows ? NSMaxY(_rect) : NSMaxX(_rect) );
    const NSInteger parentRight = (NSInteger) /*roundf*/( horizontalRows ? NSMaxX(_rect) : NSMaxY(_rect) );
    const NSInteger parentLeft = (NSInteger) /*roundf*/( horizontalRows ? NSMinX(_rect) : NSMinY(_rect) );

    NSUInteger childIndex = 0;
    NSUInteger row = 0;

    NSInteger top = horizontalRows ? NSMinY(_rect) : NSMinX(_rect);

    for ( row = 0; row < rows.count; row++ )
    {
        NSUInteger column = 0;
        NSInteger bottom = top + round( [rows[row] doubleValue] * parentHeight );
        //if this is the last row, make sure it's bottom is the same as our bottom (get rid of rounding errors)
        if ( bottom > parentBottom || row == rows.count - 1 )
            bottom = parentBottom;

        NSInteger left = parentLeft;

        for ( column = 0; column < [childsPerRow[row] unsignedIntValue]; column++, childIndex++)
        {
            int right = left + roundf( [childWidths[childIndex] doubleValue] * parentWidth );
            //if this is last child in the current row, make sure it's rect ends with our rect
            if ( right > parentRight || column == [childsPerRow[row] unsignedIntValue] - 1)
                right = parentRight;

            NSRect rcChild;
            if (horizontalRows)
            {
                rcChild.origin.x = left;
                rcChild.origin.y = top;
                rcChild.size.width  = right - left;
                rcChild.size.height = bottom - top;
            }
            else
            {
                rcChild.origin.x = top;
                rcChild.origin.y = left;
                rcChild.size.width  = bottom - top;
                rcChild.size.height = right - left;
            }

            TMVItem *childRenderer= _childRenderers[childIndex];

            [childRenderer calcLayout: rcChild];

            left = right;
        }

        top = bottom;
    }
}

- (void) arrangeChildsOnRows: (NSMutableArray*) rows
                childsPerRow: (NSMutableArray*) childsPerRow
                 childWidths: (NSMutableArray*) childWidths
                rowsAreHoriz: (BOOL*) horizontal
{
    NSUInteger childCount = _childRenderers.count;
    NSUInteger i;
	NSNumber *num = nil;
	
    if ( [self weight] == 0 )
    {
		num = @1;
        [rows addObject: num];
		
		num = @(childCount);
        [childsPerRow addObject: num];

        id standardWidth = @(1.0/childCount);
        for ( i = 0; i < childCount; i++ )
            [childWidths addObject: standardWidth];

        *horizontal = TRUE;
    }
    else
    {
        *horizontal = _rect.size.width >= _rect.size.height;

        double width = 1;
        if ( *horizontal )
        {
            if ( _rect.size.height > 0 )
                width = (double) _rect.size.width / _rect.size.height;
        }
        else
        {
            if ( _rect.size.width > 0 )
                width = (double) _rect.size.height / _rect.size.width;
        }

        for ( i = 0; i < childCount; )
        {
            NSUInteger childsUsed = 0;
            double rowHeight = [self calculateRow: i
                                         rowWidth: width
                                       childsUsed: &childsUsed
                                      childWidths: childWidths];

			num = @(rowHeight);
            [rows addObject: num];
			
			num = @(childsUsed);
            [childsPerRow addObject: num];

            i += childsUsed;
        }
    }
}

- (double) calculateRow: (NSUInteger) startChildIndex
               rowWidth: (double) rowWidth
            childsUsed : (NSUInteger*) childsUsed
            childWidths: (NSMutableArray*) childWidths
{
    static const double minProportion = 0.4;
    const double mySize= [self weight];
    NSUInteger i;
    double sizeUsed= 0;
    double rowHeight= 0;
    NSUInteger childCount = _childRenderers.count;

    *childsUsed = 0;

    for  ( i = startChildIndex; i < childCount; i++ )
    {
        double  childSize = [_childRenderers[i] weight];
        if ( childSize == 0)
        {
            NSAssert( i > startChildIndex, @"first child must not have size of 0" );
            break;
        }

        sizeUsed += childSize;
        double virtualRowHeight = sizeUsed / mySize;
        NSAssert( virtualRowHeight > 0 && virtualRowHeight <= 1, @"incorrect calculated parent size ( sum(childs) > parent )" );

        // Rectangle(mySize)    = width * 1.0
        // Rectangle(childSize) = childWidth * virtualRowHeight
        // Rectangle(childSize) = childSize / mySize * width

        double childWidth= childSize / mySize * rowWidth / virtualRowHeight;

        if (childWidth / virtualRowHeight < minProportion)
        {
            NSAssert(i > startChildIndex, @"" ); // because width >= 1 and _minProportion < 1.
                                                 // For the first child we have:
                                                 // childWidth / rowHeight
                                                 // = childSize / mySize * width / rowHeight / rowHeight
                                                 // = childSize * width / sizeUsed / sizeUsed * mySize
                                                 // > childSize * mySize / sizeUsed / sizeUsed
                                                 // > childSize * childSize / childSize / childSize
                                                 // = 1 > _minProportion.
            break;
        }
        rowHeight = virtualRowHeight;
    }
    NSAssert(i > startChildIndex, @"row calculation aborted" );

    // Now i-1 is the last child used
    // and rowHeight is the height of the row.

    // We add the rest of the zero-sized childs
    while ( i < childCount && [_childRenderers[i] weight] == 0 )
        i++;

    *childsUsed = i - startChildIndex;

	// Rectangle(1.0 * 1.0) = mySize
	double rowSize = mySize * rowHeight;
	
    // Now as we know the rowHeight, we compute the widths of our children.
    for ( i = 0; i < *childsUsed; i++ )
    {
		double childSize = [_childRenderers[startChildIndex + i] weight];
        double cw = childSize / rowSize;
        //NSAssert(cw >= 0);

		NSNumber *num = @(cw);
        [childWidths addObject: num];
    }

    return rowHeight;
}

- (void) createChildRenderers
{
    NSUInteger childCount = [_dataSource treeMapView: _view numberOfChildrenOfItem: _item];

    _childRenderers = [[NSMutableArray alloc] initWithCapacity: childCount];

    for ( NSUInteger i = 0; i < childCount; i++ )
    {
        id childItem = [_dataSource treeMapView: _view child: i ofItem: _item];
        NSAssert( childItem != nil, @"data source returned nil as child item" );

        TMVItem *childRenderer = [[TMVItem alloc]
            initWithDataSource: _dataSource delegate: _delegate renderedItem: childItem treeMapView: _view];

        [_childRenderers addObject: childRenderer];

    }
}

@end
