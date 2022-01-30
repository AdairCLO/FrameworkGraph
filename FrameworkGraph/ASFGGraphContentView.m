//
//  ASFGGraphContentView.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGGraphContentView.h"
#import "ASFGGraphData.h"
#import "ASFGNodeView.h"
#import "ASFGColor.h"

#define ENABLE_DRAW_ARROW

static const CGFloat kGraphMargin = 20;
static const CGFloat kNodeHorizontalMargin = 60;
static const CGFloat kNodeVerticalMargin = 100;
static const CGFloat kNodeWidth = 120;
static const CGFloat kNodeHeight = 80;

static const CGFloat kConnectionLineWidth = 1;
static const CGFloat kConnetionDashLineLen = 6;

#ifdef ENABLE_DRAW_ARROW
static const CGFloat kConnectionArrowLen = 10;
static const CGFloat kConnectionArrowAngle = M_PI / 6;
#endif

@interface ASFGGraphContentView ()

@property (nonatomic, strong) NSMutableArray<ASFGNodeView *> *nodeViews;
@property (nonatomic, strong) NSDictionary<NSString *, ASFGNodeView *> *nodeViewDict;

@end

@implementation ASFGGraphContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [ASFGColor graphBackgroundColor];
        
        _nodeViews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self updateConnections];
}

- (void)setGraphData:(ASFGGraphData *)graphData
{
    _graphData = graphData;
    
    [self updateContent];
}

- (void)updateContent
{
    // width
    CGFloat width = 0;
    if (_graphData.maxNodeCountOfLevelInLevelGraph > 0)
    {
        width = kGraphMargin
                + _graphData.maxNodeCountOfLevelInLevelGraph * kNodeWidth
                + (_graphData.maxNodeCountOfLevelInLevelGraph - 1) * kNodeHorizontalMargin
                + kGraphMargin;
    }
    // height
    CGFloat height = 0;
    if (_graphData.levelGraph.count > 0)
    {
        height = kGraphMargin
                 + _graphData.levelGraph.count * kNodeHeight
                 + (_graphData.levelGraph.count - 1) * kNodeVerticalMargin
                 + kGraphMargin;
    }
    
    NSMutableDictionary<NSString *, ASFGNodeView *> *nodeViewDict = [[NSMutableDictionary alloc] init];
    _nodeViewDict = nodeViewDict;
    
    __block NSInteger nodeIndex = 0;
    [_graphData.levelGraph enumerateObjectsUsingBlock:^(NSArray<ASFGNode *> * _Nonnull level, NSUInteger levelIndex, BOOL * _Nonnull stop) {
        NSInteger nodeCountInLevel = level.count;
        CGFloat levelWidth = kNodeWidth * nodeCountInLevel + kNodeHorizontalMargin * (nodeCountInLevel - 1);
        CGFloat marginLeft = (width - levelWidth) / 2;
        
        [level enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            ASFGNodeView *nodeView = nil;
            if (nodeIndex < _nodeViews.count)
            {
                nodeView = [_nodeViews objectAtIndex:nodeIndex];
            }
            if (nodeView == nil)
            {
                nodeView = [[ASFGNodeView alloc] init];
                [_nodeViews addObject:nodeView];
                [self addSubview:nodeView];
            }
            
            nodeView.nodeData = node;
            nodeView.frame = CGRectMake(marginLeft + ((kNodeWidth + kNodeHorizontalMargin) * idx), //kGraphMargin
                                        kGraphMargin + (kNodeHeight + kNodeVerticalMargin) * levelIndex,
                                        kNodeWidth,
                                        kNodeHeight);
            
            nodeViewDict[node.filePath] = nodeView;
            
            nodeIndex += 1;
        }];
    }];
    
    // remove no use node view
    NSInteger currentNodeViewCount = _nodeViews.count;
    for (NSInteger i = nodeIndex; i < currentNodeViewCount; i++)
    {
        ASFGNodeView *nodeView = [_nodeViews objectAtIndex:nodeIndex];
        [_nodeViews removeObjectAtIndex:nodeIndex];
        [nodeView removeFromSuperview];
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height);
    [self setNeedsDisplay];
}

- (void)updateConnections
{    
    [_graphData.inputNodes enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        ASFGNodeView *nodeView = _nodeViewDict[node.filePath];
        NSArray<ASFGConnection *> *connections = _graphData.graph[node.filePath];
        [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull connection, NSUInteger idx, BOOL * _Nonnull stop) {
            [self drawConnection:connection sourceNodeView:nodeView];
        }];
    }];
}

- (void)drawConnection:(ASFGConnection *)connection sourceNodeView:(ASFGNodeView *)sourceNodeView
{
    ASFGNodeView *targetNodeView = _nodeViewDict[connection.targetNode.filePath];
    
    CGPoint sourcePoint = CGPointZero;
    CGPoint targetPoint = CGPointZero;
    assert(sourceNodeView.frame.origin.y != targetNodeView.frame.origin.y);
    if (sourceNodeView.frame.origin.y < targetNodeView.frame.origin.y)
    {
        sourcePoint = CGPointMake(sourceNodeView.frame.origin.x + sourceNodeView.frame.size.width / 2,
                                  CGRectGetMaxY(sourceNodeView.frame));
        
        targetPoint = CGPointMake(targetNodeView.frame.origin.x + targetNodeView.frame.size.width / 2,
                                  CGRectGetMinY(targetNodeView.frame));

    }
    else
    {
        sourcePoint = CGPointMake(sourceNodeView.frame.origin.x + sourceNodeView.frame.size.width / 2,
                                  CGRectGetMinY(sourceNodeView.frame));
    
        targetPoint = CGPointMake(targetNodeView.frame.origin.x + targetNodeView.frame.size.width / 2,
                                  CGRectGetMaxY(targetNodeView.frame));
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = kConnectionLineWidth;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    
    // line color
    ASFGConnection *reverseConnection = [_graphData connectionFrom:connection.targetNode to:sourceNodeView.nodeData];
    if (reverseConnection != nil)
    {
        // circular dependecy...
        assert(connection.connectionType == ASFGConnectionTypeStrong && reverseConnection.connectionType == ASFGConnectionTypeStrong);
        [[ASFGColor graphCircularDependencyColor] set];
    }
    else if (connection.connectionType == ASFGConnectionTypeReexport)
    {
        // reexport
        [[ASFGColor graphRexportDependencyColor] set];
    }
    else
    {
        // strong/weak
        [[ASFGColor graphDependencyColor] set];
    }
    
    // line style
    if (connection.connectionType == ASFGConnectionTypeWeak)
    {
        CGFloat lengths[2] = { kConnetionDashLineLen, kConnetionDashLineLen };
        [path setLineDash:lengths count:2 phase:0];
    }
    
    // draw line
    [path moveToPoint:sourcePoint];
    [path addLineToPoint:targetPoint];
    
    [path stroke];
    
#ifdef ENABLE_DRAW_ARROW
    // draw arrow
    [path removeAllPoints];
    [path setLineDash:nil count:0 phase:0];
    
    // two coordinate:
    // coord 1: UIView coordinate: origin is the left-top point, y axis is toard down, x axis is toward right
    // coord 2: "arrow coordinate": origin is the targetPoint; y axis is the connection and toward 'down', x axis is toward 'right'
    
    CGFloat arrowCoordX = sin(kConnectionArrowAngle) * kConnectionArrowLen;
    CGFloat arrowCoordY = cos(kConnectionArrowAngle) * kConnectionArrowLen;
    CGFloat theAngle = asin((targetPoint.y - sourcePoint.y) / sqrt(pow(targetPoint.y - sourcePoint.y, 2) + pow(targetPoint.x - sourcePoint.x, 2)));
    assert(!isnan(theAngle));
    CGFloat coordTransformAngle = (targetPoint.x < sourcePoint.x) ? (M_PI_2 - theAngle) : (theAngle - M_PI_2);
    // rotate first, then translate
    CGAffineTransform arrowCoordTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(coordTransformAngle), CGAffineTransformMakeTranslation(targetPoint.x, targetPoint.y));
    CGPoint arrowLeftPoint = CGPointApplyAffineTransform(CGPointMake(-arrowCoordX, -arrowCoordY), arrowCoordTransform);
    CGPoint arrowRightPoint = CGPointApplyAffineTransform(CGPointMake(arrowCoordX, -arrowCoordY), arrowCoordTransform);
    
    [path moveToPoint:targetPoint];
    [path addLineToPoint:arrowLeftPoint];
    [path moveToPoint:targetPoint];
    [path addLineToPoint:arrowRightPoint];
    
    [path stroke];
#endif
}

@end
