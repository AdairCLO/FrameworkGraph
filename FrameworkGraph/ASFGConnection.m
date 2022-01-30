//
//  ASFGConnection.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGConnection.h"

@implementation ASFGConnection

- (instancetype)initWithTargetNode:(ASFGNode *)targetNode connectionType:(ASFGConnectionType)connectionType
{
    self = [super init];
    if (self)
    {
        _targetNode = targetNode;
        _connectionType = connectionType;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ASFGConnection(%p): %@ - %zd", self, _targetNode, _connectionType];
}

@end
