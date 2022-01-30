//
//  ASFGNodeView.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/21.
//

#import "ASFGNodeView.h"
#import "ASFGNode.h"
#import "ASFGColor.h"

const CGFloat kNodeCornerRadius = 6;
const CGFloat kNodeBorderWidth = 2;
const CGFloat kContentMargin = 6;

@interface ASFGNodeView ()

@property (nonatomic, strong) UILabel *nameLabel;
//@property (nonatomic, strong) UILabel *descLabel;

@end

@implementation ASFGNodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [ASFGColor graphNodeBackgroundColor];
        self.layer.cornerRadius = kNodeCornerRadius;
        self.layer.borderWidth = kNodeBorderWidth;
        self.layer.borderColor = [ASFGColor graphNodeBorderColor].CGColor;
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(kContentMargin, kContentMargin, self.bounds.size.width - kContentMargin - kContentMargin, self.bounds.size.height - kContentMargin - kContentMargin)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        _nameLabel.textColor = [ASFGColor graphNodeTextColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 0;
//        _nameLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_nameLabel];
        
//        _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
//        [self addSubview:_descLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _nameLabel.frame = CGRectMake(kContentMargin, kContentMargin, self.bounds.size.width - kContentMargin - kContentMargin, self.bounds.size.height - kContentMargin - kContentMargin);
}

- (void)setNodeData:(ASFGNode *)nodeData
{
    _nodeData = nodeData;
    
    _nameLabel.text = _nodeData.fileName;
}

@end
