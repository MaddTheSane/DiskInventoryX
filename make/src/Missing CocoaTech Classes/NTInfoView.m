//
//  NTInfoView.m
//  Disk Inventory X
//
//  Created by C.W. Betts on 6/21/16.
//
//

#import "NTInfoView.h"

@implementation NTInfoView
@synthesize desc = _desc;

- (id)initWithFrame:(NSRect)arg1 longFormat:(BOOL)arg2
{
	if (self = [super initWithFrame:arg1]) {
		_longFormat = arg2;
	}
	return self;
}

- (id)initWithFrame:(NSRect)arg1
{
	return [self initWithFrame:arg1 longFormat:NO];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
