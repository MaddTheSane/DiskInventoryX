//
//  NSBitmapImageRep-Extensions.h
//  TreeMapView
//
//  Created by Tjark Derlien on 20.10.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBitmapImageRep (CreationExtensions)

//creates a Bitmap with 24 bit color depth and no alpha component							 
- (nullable instancetype) initRGBBitmapWithWidth: (int) width height: (int) height;

//creates an autoreleased NSImage with the samme dimensions as the NSBitmapImageRep
//and adds the NSBitmapImageRep as the only image represensation;
//set flipped coordinates if "view" is flipped
- (NSImage*) suitableImageForView: (NSView*) view;
@end

NS_ASSUME_NONNULL_END
