//
//  ASFGGraphData.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import <Foundation/Foundation.h>
#import "ASFGNode.h"
#import "ASFGConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASFGGraphData : NSObject

- (instancetype)initWithInputNodes:(NSArray<ASFGNode *> *)inputNodes graph:(NSDictionary<NSString *, NSArray<ASFGConnection *> *> *)graph levelGraph:(NSArray<NSArray <ASFGNode *> *> *)levelGraph;

@property (nonatomic, strong, readonly) NSArray<ASFGNode *> *inputNodes;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSArray<ASFGConnection *> *> *graph;
@property (nonatomic, strong, readonly) NSArray<NSArray<ASFGNode *> *> *levelGraph;
@property (nonatomic, assign, readonly) NSUInteger maxNodeCountOfLevelInLevelGraph;

- (ASFGConnection *)connectionFrom:(ASFGNode *)sourceNode to:(ASFGNode *)targetNode;

@end

NS_ASSUME_NONNULL_END
