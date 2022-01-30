//
//  ASFGNode.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASFGNode : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *fileName;

@end

NS_ASSUME_NONNULL_END
