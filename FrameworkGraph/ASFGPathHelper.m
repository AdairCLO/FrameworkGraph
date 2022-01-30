//
//  ASFGPathHelper.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/24.
//

#import "ASFGPathHelper.h"

#if TARGET_IPHONE_SIMULATOR

// TODO: how to get this 'dir prefix' at run time??
static NSString * const kDirPrefix = @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot";

#else

static NSString * const kDirPrefix = @"";

#endif

@implementation ASFGPathHelper

#if TARGET_IPHONE_SIMULATOR

+ (void)initialize
{
    if (self == [ASFGPathHelper class])
    {
        // check the kDirPrefix
        NSString *UIKitPath = [self realAccessPathWithPath:@"/System/Library/Frameworks/UIKit.framework/UIKit"];
        BOOL isDir = NO;
        BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:UIKitPath isDirectory:&isDir];
        assert(existed && !isDir);
    }
}

#endif

+ (NSString *)realAccessPathWithPath:(NSString *)path
{
    if (kDirPrefix.length == 0)
    {
        return path;
    }
    
    return [kDirPrefix stringByAppendingPathComponent:path];
}

@end
