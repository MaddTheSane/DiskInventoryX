//
//  TMVItem.h
//  DiskAccountant
//
//  Created by Tjark Derlien on Tue Sep 30 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMVCushionRenderer.h"

//! holds display information about one cell in the treemap
@interface TMVItem : NSObject
{
    id _dataSource;
    id _delegate;
    id _item;
    id _view;
    
    NSRect _rect;
    NSMutableArray *_childRenderers;
    TMVCushionRenderer *_cushionRenderer;
}

- (instancetype) init UNAVAILABLE_ATTRIBUTE;
- (instancetype) initWithDataSource: (id) dataSource delegate: (id) delegate renderedItem: (id) item treeMapView: (id) view NS_DESIGNATED_INITIALIZER;

- (void) setCushionColor: (NSColor*) color; 

- (void) calcLayout: (NSRect) rect;

- (void) drawGrid;
- (void) drawHighlightFrame;

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap;

@property (getter=isLeaf, readonly) BOOL leaf;
@property (readonly, strong) id item;
@property (readonly) unsigned long long weight;

@property (readonly, strong) NSEnumerator *childEnumerator;
- (TMVItem*) childAtIndex: (NSUInteger) index;
@property (readonly) NSUInteger childCount;

@property (readonly) NSRect rect;
- (TMVItem *) hitTest: (NSPoint) aPoint;

@end
