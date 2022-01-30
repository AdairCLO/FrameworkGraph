//
//  ASFGColor.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASFGColor : NSObject

+ (UIColor *)graphBackgroundColor;
+ (UIColor *)graphNodeBackgroundColor;
+ (UIColor *)graphNodeBorderColor;
+ (UIColor *)graphNodeTextColor;
+ (UIColor *)graphDependencyColor;
+ (UIColor *)graphRexportDependencyColor;
+ (UIColor *)graphCircularDependencyColor;

@end

NS_ASSUME_NONNULL_END
