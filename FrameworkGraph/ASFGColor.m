//
//  ASFGColor.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/27.
//

#import "ASFGColor.h"

@implementation ASFGColor

+ (UIColor *)graphBackgroundColor
{
    return [UIColor colorWithRed:239/255.0 green:238/255.0 blue:197/255.0 alpha:1];
}

+ (UIColor *)graphNodeBackgroundColor
{
    return [UIColor colorWithRed:221/255.0 green:229/255.0 blue:242/255.0 alpha:1];
}

+ (UIColor *)graphNodeBorderColor
{
    return [UIColor colorWithRed:85/255.0 green:142/255.0 blue:243/255.0 alpha:1];
}

+ (UIColor *)graphNodeTextColor
{
    return [UIColor blackColor];
}

+ (UIColor *)graphDependencyColor
{
    return [UIColor blackColor];
}

+ (UIColor *)graphRexportDependencyColor;
{
    return [UIColor colorWithRed:99/255.0 green:150/255.0 blue:216/255.0 alpha:1];
}

+ (UIColor *)graphCircularDependencyColor
{
    return [UIColor redColor];
}

@end
