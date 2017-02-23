/* TreeMapView */

#import <Cocoa/Cocoa.h>
#import "TMVItemRenderer.h"

typedef TMVItemRenderer* TMVCellId;

@interface TreeMapView : NSView
{
    TMVItemRenderer *_rootItemRenderer;
    IBOutlet id delegate;
    IBOutlet id dataSource;
    TMVItemRenderer *_selectedRenderer;
    TMVItemRenderer *_touchedRenderer;
    NSBitmapImageRep *_cachedContent;
}

- (void) reloadData;

- (TMVCellId) cellIdByPoint: (NSPoint) point inViewCoords: (BOOL) viewCoords;
- (id) itemByCellId: (TMVCellId) cellId;

- (id) selectedItem;
- (void) selectItemByPathToItem: (NSArray*) path;
- (void) selectItemByCellId: (TMVCellId) cellId; 

@end

// Data Source Note: Specifying nil as the item will refer to the "root" item.
// (there must be one (and only one!) root item)
@interface NSObject(TableMapViewDataSource)
// required
- (id) treeMapView: (TreeMapView*) view child: (unsigned) index ofItem: (id) item;
- (BOOL) treeMapView: (TreeMapView*) view isNode: (id) item;
- (unsigned) treeMapView: (TreeMapView*) view numberOfChildrenOfItem: (id) item;
- (unsigned long long) treeMapView: (TreeMapView*) view weightByItem: (id) item;
@end

/* optional delegate methods */
@interface NSObject(TableMapViewDelegate)
- (NSString*) treeMapView: (TreeMapView*) view getToolTipByItem: (id) item;
- (void) treeMapView: (TreeMapView*) view willDisplayItem: (id) item withRenderer: (TMVItemRenderer*) renderer;
- (BOOL) treeMapView: (TreeMapView*) view shouldSelectItem: (id) item;
- (void) treeMapView: (TreeMapView*) view willShowMenuForEvent: (NSEvent*) event;
@end

/* Notifications */
extern NSString *TreeMapViewItemTouchedNotification;
extern NSString *TreeMapViewSelectionDidChangedNotification;
extern NSString *TreeMapViewSelectionIsChangingNotification;
extern NSString *TMVTouchedItem;	//key for touched item in userInfo of a TreeMapViewItemTouchedNotification

// the corresponding (id) item is set as user data for NSNotification
@interface NSObject(TableMapViewNotifications)
- (void)treeMapViewSelectionDidChange: (NSNotification*) notification;
- (void)treeMapViewSelectionIsChanging: (NSNotification*) notification;
- (void)treeMapViewItemTouched: (NSNotification*) notification;
@end

