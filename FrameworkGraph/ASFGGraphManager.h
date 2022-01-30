//
//  ASFGGraphManager.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import <Foundation/Foundation.h>

@class ASFGGraphData;

NS_ASSUME_NONNULL_BEGIN

@interface ASFGGraphManager : NSObject

@property (nonatomic, strong, readonly) ASFGGraphData *graphData;

- (void)addItems:(NSArray<NSString *> *)itemPaths;
- (void)clearItems;

- (void)updateHiddenFrameworks:(NSSet<NSString *> *)frameworks;
- (NSSet<NSString *> *)currentHiddenFrameworks;
- (NSSet<NSString *> *)currentInputFrameworks;
- (NSDictionary<NSString *, NSArray<NSString *> *> *)currentAllFrameworks;

@end

NS_ASSUME_NONNULL_END
