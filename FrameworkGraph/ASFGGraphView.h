//
//  ASFGGraphView.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import <UIKit/UIKit.h>

@class ASFGGraphData;

NS_ASSUME_NONNULL_BEGIN

@interface ASFGGraphView : UIScrollView

- (void)updateGraphData:(ASFGGraphData *)graphData;
- (UIImage *)generateGraphImage;

@end

NS_ASSUME_NONNULL_END
