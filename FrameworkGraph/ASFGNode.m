//
//  ASFGNode.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGNode.h"

@interface ASFGNode ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;

@end

@implementation ASFGNode

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    if (self)
    {
        _filePath = [filePath copy];
        _fileName = [_filePath lastPathComponent];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ASFGNode(%p): %@", self, _filePath];
}

@end
