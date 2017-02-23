//
//  CFArray-NTExtensions.m
//  CocoatechCore
//
//  Created by Steve Gehrman on 11/10/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "CFArray-NTExtensions.h"

const void * NTNSObjectRetain(CFAllocatorRef allocator, const void *value)
{
    return (CFTypeRef)CFBridgingRetain((__bridge id _Nullable)((void*)value));
}

void NTNSObjectRelease(CFAllocatorRef allocator, const void *value)
{
    CFBridgingRelease(value);
}

CFStringRef NTNSObjectCopyDescription(const void *value)
{
    return CFBridgingRetain([(__bridge id)value description]);
}

Boolean NTNSObjectIsEqual(const void *value1, const void *value2)
{
    return [(__bridge id)value1 isEqual: (__bridge id)value2];
}

CFStringRef NTPointerCopyDescription(const void *ptr)
{
    return (CFStringRef)CFBridgingRetain([[NSString alloc] initWithFormat: @"<0x%p>", ptr]);
}

CFStringRef NTIntegerCopyDescription(const void *ptr)
{
    NSInteger i = (NSInteger)ptr;
    assert(sizeof(ptr) >= sizeof(i));
    return (CFStringRef)CFBridgingRetain([[NSString alloc] initWithFormat: @"%ld", (long)i]);
}

const CFArrayCallBacks NTNonOwnedPointerArrayCallbacks = {
0,     // version;
NULL,  // retain;
NULL,  // release;
NTPointerCopyDescription, // copyDescription
NULL,  // equal
};

const CFArrayCallBacks NTNSObjectArrayCallbacks = {
0,     // version;
NTNSObjectRetain,
NTNSObjectRelease,
NTNSObjectCopyDescription,
NTNSObjectIsEqual,
};

const CFArrayCallBacks NTIntegerArrayCallbacks = {
0,     // version;
NULL,  // retain;
NULL,  // release;
NTIntegerCopyDescription, // copyDescription
NULL,  // equal
};


NSMutableArray *NTCreateNonOwnedPointerArray(void)
{
    return (NSMutableArray *)CFBridgingRelease(CFArrayCreateMutable(kCFAllocatorDefault, 0, &NTNonOwnedPointerArrayCallbacks));
}

NSMutableArray *NTCreateIntegerArray(void)
{
    return (NSMutableArray *)CFBridgingRelease(CFArrayCreateMutable(kCFAllocatorDefault, 0, &NTIntegerArrayCallbacks));
}

