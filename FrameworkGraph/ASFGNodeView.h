//
//  ASFGNodeView.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/21.
//

#import <UIKit/UIKit.h>

@class ASFGNode;

NS_ASSUME_NONNULL_BEGIN

@interface ASFGNodeView : UIView

@property (nonatomic, strong) ASFGNode *nodeData;

@end

NS_ASSUME_NONNULL_END
