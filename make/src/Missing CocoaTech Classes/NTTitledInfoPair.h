//
//  NTTitledInfoPair.h
//  Disk Inventory X
//
//  Created by C.W. Betts on 6/21/16.
//
//

#import <Foundation/Foundation.h>

@interface NTTitledInfoPair : NSObject
{
	NSString *_title;
	NSString *_info;
	SEL _action;
	id _target;
}

+ (instancetype)infoPair:(id)arg1 info:(id)arg2;
+ (instancetype)infoPair:(id)arg1 info:(id)arg2 action:(SEL)arg3 target:(id)arg4;
- (instancetype)initWithTitle:(id)arg1 info:(id)arg2 action:(SEL)arg3 target:(id)arg4;
- (NSString*)title;
- (NSString*)info;
- (SEL)action;
- (id)target;

@end
