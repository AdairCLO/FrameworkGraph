//
//  ASFGConnection.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import <Foundation/Foundation.h>
#import "ASFGNode.h"

typedef NS_ENUM(NSUInteger, ASFGConnectionType) {
    ASFGConnectionTypeStrong,
    ASFGConnectionTypeWeak,
    ASFGConnectionTypeReexport,
};

NS_ASSUME_NONNULL_BEGIN

@interface ASFGConnection : NSObject

- (instancetype)initWithTargetNode:(ASFGNode *)targetNode connectionType:(ASFGConnectionType)connectionType;

@property (nonatomic, strong) ASFGNode *targetNode;
@property (nonatomic, assign) ASFGConnectionType connectionType;

@end

NS_ASSUME_NONNULL_END
