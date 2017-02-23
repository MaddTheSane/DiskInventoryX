//
//  FileSizeTransformer.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 25.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileSizeTransformer : NSValueTransformer
{
	NSByteCountFormatter *_sizeFormatter;
}

+ (id) transformer;

@end
