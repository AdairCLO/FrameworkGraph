//
//  ASFGFrameworkManager.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASFGFrameworkManager : NSObject

- (NSUInteger)dirPathCount;
- (NSString *)dirPathWithDirIndex:(NSUInteger)dirIndex;

- (NSUInteger)frameworkOrLibraryCountWithDirIndex:(NSUInteger)dirIndex;

- (NSString *)frameworkOrLibraryNameWithDirIndex:(NSUInteger)dirIndex fileIndex:(NSUInteger)fileIndex;
- (NSString *)frameworkOrLibraryPathWithDirIndex:(NSUInteger)dirIndex fileIndex:(NSUInteger)fileIndex;

@end

NS_ASSUME_NONNULL_END
