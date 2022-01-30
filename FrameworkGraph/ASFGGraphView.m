//
//  ASFGGraphView.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGGraphView.h"
#import "ASFGGraphData.h"
#import "ASFGGraphContentView.h"

#if TARGET_IPHONE_SIMULATOR

const CGFloat kImageMaxDimension = -1;

#else

const CGFloat kImageMaxDimension = 2048;

#endif

@interface ASFGGraphView ()

@property (nonatomic, strong) ASFGGraphContentView *contentView;

@end

@implementation ASFGGraphView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.alwaysBounceVertical = YES;
        self.alwaysBounceHorizontal = YES;
        
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = [UIColor systemBackgroundColor];
        }
        else
        {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        _contentView = [[ASFGGraphContentView alloc] init];
        [self addSubview:_contentView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize realContentSize = [self realContentAreaSize];
    
    _contentView.frame = CGRectMake(_contentView.frame.size.width >= realContentSize.width ? 0 : (realContentSize.width - _contentView.frame.size.width) / 2,
                                    _contentView.frame.size.height >= realContentSize.height ? 0 : (realContentSize.height - _contentView.frame.size.height) / 2,
                                    _contentView.frame.size.width,
                                    _contentView.frame.size.height);
}

- (CGSize)realContentAreaSize
{
    return CGSizeMake(self.frame.size.width - self.adjustedContentInset.left - self.adjustedContentInset.right, self.frame.size.height - self.adjustedContentInset.top - self.adjustedContentInset.bottom);
}

- (void)updateGraphData:(ASFGGraphData *)graphData
{
    _contentView.graphData = graphData;
    
    self.contentSize = _contentView.bounds.size;
    
    // center the content
    self.contentOffset = CGPointMake(self.contentSize.width > self.bounds.size.width ? (self.contentSize.width - self.bounds.size.width) / 2 : -self.adjustedContentInset.left,
                                     self.contentSize.height > self.bounds.size.height ? (self.contentSize.height - self.bounds.size.height) / 2 : -self.adjustedContentInset.top);
    
    [self setNeedsLayout];
}

- (UIImage *)generateGraphImage
{
    CGFloat scaleFactor = 2;
    CGFloat imgWidth = _contentView.bounds.size.width * scaleFactor;
    CGFloat imgHeight = _contentView.bounds.size.height * scaleFactor;
    if (imgWidth == 0 || imgHeight == 0)
    {
        return nil;
    }
    
    CGFloat scale = 1;
    if (kImageMaxDimension > 0)
    {
        if (imgWidth > imgHeight)
        {
            if (imgWidth > kImageMaxDimension)
            {
                scale = kImageMaxDimension / imgWidth;
                imgHeight = floor(kImageMaxDimension * imgHeight / imgWidth);
                imgWidth = kImageMaxDimension;
            }
        }
        else
        {
            if (imgHeight > kImageMaxDimension)
            {
                scale = kImageMaxDimension / imgHeight;
                imgWidth = floor(kImageMaxDimension * imgWidth / imgHeight);
                imgHeight = kImageMaxDimension;
            }
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(_contentView.bounds.size, YES, scaleFactor * scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_contentView.layer renderInContext:context];
//    [_contentView drawViewHierarchyInRect:_contentView.bounds afterScreenUpdates:NO]; // not work for super big content...
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
