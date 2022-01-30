//
//  ASFGFrameworkManager.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/23.
//

#import "ASFGFrameworkManager.h"
#import "ASFGPathHelper.h"

@interface ASFGFrameworkManager ()

@property (nonatomic, strong) NSArray<NSString *> *dirPaths;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *frameworkOrLibraryPaths;

@end

@implementation ASFGFrameworkManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dirPaths = [[self class] dirConfig];
        
        NSMutableArray<NSString *> *dirData = [[NSMutableArray alloc] init];
        [_dirPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *realPath = [ASFGPathHelper realAccessPathWithPath:path];
            BOOL isDir = NO;
            BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:realPath isDirectory:&isDir];
            if (existed && isDir)
            {
                [dirData addObject:realPath];
            }
        }];
        
        NSMutableArray<NSArray<NSString *> *> *itemData = [[NSMutableArray alloc] init];
        [dirData enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            if (contents == nil)
            {
                contents = @[];
            }
            
            NSMutableArray<NSString *> *sortedContent = [contents mutableCopy];
            
            // filter
            NSMutableIndexSet *filterIndexSet = [[NSMutableIndexSet alloc] init];
            [sortedContent enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj hasSuffix:@".framework"] && ![obj hasSuffix:@"dylib"])
                {
                    [filterIndexSet addIndex:idx];
                }
            }];
            [sortedContent removeObjectsAtIndexes:filterIndexSet];
            
            [sortedContent sortUsingComparator:^NSComparisonResult(NSString * _Nonnull content1, NSString * _Nonnull content2) {
                return [content1 compare:content2];
            }];
            
            [itemData addObject:sortedContent];
        }];
        
        _frameworkOrLibraryPaths = itemData;
    }
    return self;
}

- (NSUInteger)dirPathCount
{
    return _dirPaths.count;
}

- (NSString *)dirPathWithDirIndex:(NSUInteger)dirIndex
{
    if (dirIndex >= _dirPaths.count)
    {
        return nil;
    }
    
    return _dirPaths[dirIndex];
}

- (NSUInteger)frameworkOrLibraryCountWithDirIndex:(NSUInteger)dirIndex
{
    return [self frameworkOrLibraryWithDirIndex:dirIndex].count;
}

- (NSArray<NSString *> *)frameworkOrLibraryWithDirIndex:(NSUInteger)dirIndex
{
    if (dirIndex >= _dirPaths.count)
    {
        return nil;
    }
    
    return _frameworkOrLibraryPaths[dirIndex];
}

- (NSString *)frameworkOrLibraryNameWithDirIndex:(NSUInteger)dirIndex fileIndex:(NSUInteger)fileIndex
{
    NSArray<NSString *> *files = [self frameworkOrLibraryWithDirIndex:dirIndex];
    if (fileIndex >= files.count)
    {
        return nil;
    }
    
    return files[fileIndex];
}

- (NSString *)frameworkOrLibraryPathWithDirIndex:(NSUInteger)dirIndex fileIndex:(NSUInteger)fileIndex
{
    NSString *dir = [self dirPathWithDirIndex:dirIndex];
    if (dir == nil)
    {
        return nil;
    }
    
    NSString *file = [self frameworkOrLibraryNameWithDirIndex:dirIndex fileIndex:fileIndex];
    if (file == nil)
    {
        return nil;
    }
    
    return [dir stringByAppendingPathComponent:file];
}

+ (NSArray<NSString *> *)dirConfig
{
#if TARGET_IPHONE_SIMULATOR
    return @[
        @"/System/Library/Frameworks",
        @"/System/Library/PrivateFrameworks",
        @"/usr/lib",
        //@"/usr/lib/system/introspection",
    ];
#else
    return @[
//        @"/System/Library/Frameworks",
//        @"/System/Library/PrivateFrameworks",
        @"/usr/lib",
//        @"/usr/lib/system/introspection",
//        @"/Developer/usr/lib",
//        @"/Developer/Library/PrivateFrameworks",
    ];
#endif
}

@end
