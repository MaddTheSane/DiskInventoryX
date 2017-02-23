//
//  TMVItemRenderer.h
//  DiskAccountant
//
//  Created by Doom on Tue Sep 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMVCushionRenderer.h"

@interface TMVItemRenderer : NSObject
{
    id _dataSource;
    id _delegate;
    id _item;
    id _view;
    
    NSRect _rect;
    NSMutableArray *_childRenderers;
    TMVCushionRenderer *_cushionRenderer;
}

- (id) initWithDataSource: (id) dataSource delegate: (id) delegate renderedItem: (id) item tableMapView: (id) view;

- (void) setCushionColor: (NSColor*) color; 

- (void) calcLayout: (NSRect) rect;

- (void) drawGrid;
- (void) drawHighlightFrame;

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap;

- (BOOL) isLeaf;
- (id) item;
- (unsigned long long) weight;

- (NSEnumerator *) childEnumerator;
- (TMVItemRenderer*) childAtIndex: (unsigned) index;
- (unsigned) childCount;

- (NSRect) rect;
- (TMVItemRenderer *) hitTest: (NSPoint) aPoint;

@end
