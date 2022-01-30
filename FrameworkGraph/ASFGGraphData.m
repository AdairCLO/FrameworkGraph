//
//  ASFGGraphData.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGGraphData.h"

@interface ASFGGraphData ()

@property (nonatomic, strong) NSArray<ASFGNode *> *inputNodes;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<ASFGConnection *> *> *graph;
@property (nonatomic, strong) NSArray<NSArray<ASFGNode *> *> *levelGraph;
@property (nonatomic, assign) NSUInteger maxNodeCountOfLevelInLevelGraph;

@end

@implementation ASFGGraphData

- (instancetype)initWithInputNodes:(NSArray<ASFGNode *> *)inputNodes graph:(NSDictionary<NSString *, NSArray<ASFGConnection *> *> *)graph levelGraph:(NSArray<NSArray<ASFGNode *> *> *)levelGraph
{
    self = [super init];
    if (self)
    {
        _inputNodes = inputNodes;
        _graph = graph;
        _levelGraph = levelGraph;
        
        [_levelGraph enumerateObjectsUsingBlock:^(NSArray<ASFGNode *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _maxNodeCountOfLevelInLevelGraph = MAX(_maxNodeCountOfLevelInLevelGraph, obj.count);
        }];
    }
    return self;
}

- (ASFGConnection *)connectionFrom:(ASFGNode *)sourceNode to:(ASFGNode *)targetNode;
{
    NSArray<ASFGConnection *> *connections = _graph[sourceNode.filePath];
    if (connections.count == 0)
    {
        return nil;
    }
    
    __block ASFGConnection *resultConnection = nil;
    [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull connection, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([connection.targetNode.filePath isEqualToString:targetNode.filePath])
        {
            resultConnection = connection;
            *stop = YES;
        }
    }];
    return resultConnection;
}

@end
