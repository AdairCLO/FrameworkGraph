//
//  ASFGGraphViewController.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/17.
//

#import "ASFGGraphViewController.h"
#import "ASFGFrameworkViewController.h"
#import "ASFGDisplayFrameworkViewController.h"
#import "ASFGGraphManager.h"
#import "ASFGGraphView.h"
#import "ASFGToast.h"

@interface ASFGGraphViewController ()

@property (nonatomic, strong) ASFGGraphManager *graphManager;
@property (nonatomic, strong) ASFGGraphView *graphView;

@end

@implementation ASFGGraphViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _graphManager = [[ASFGGraphManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Framework Graph";
    
    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(onAddClicked)],
        [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(onClearClicked)],
        [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClicked)],
        [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(onHideClicked)],
    ];
    
    _graphView = [[ASFGGraphView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_graphView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    _graphView.frame = self.view.bounds;
}

- (void)onAddClicked
{
    __weak typeof(self) weakSelf = self;
    ASFGFrameworkViewController *vc = [[ASFGFrameworkViewController alloc] init];
    vc.completeHandler = ^(ASFGFrameworkViewController * _Nonnull controller, NSArray<NSString *> * _Nonnull frameworkOrLibraryPaths) {
        [weakSelf updateGraphData:frameworkOrLibraryPaths];
    };
    UINavigationController *containerVC = [[UINavigationController alloc] initWithRootViewController:vc];
    containerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:containerVC animated:YES completion:nil];
}

- (void)onClearClicked
{
    [self.graphManager clearItems];
    [self.graphView updateGraphData:self.graphManager.graphData];
}

- (void)onSaveClicked
{
    UIImage *image = [self.graphView generateGraphImage];
    if (image == nil)
    {
        [ASFGToast showToast:@"No graph!"];
        return;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *saveToPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"framework_graph.png"];
    [imageData writeToFile:saveToPath atomically:YES];
    NSLog(@"Save graph to: %@", saveToPath);
    
    NSURL *saveToURL = [NSURL fileURLWithPath:saveToPath];
    UIActivityViewController *shareVC = [[UIActivityViewController alloc] initWithActivityItems:@[ saveToURL ] applicationActivities:nil];
    [self presentViewController:shareVC animated:YES completion:nil];
}

- (void)onHideClicked
{
    __weak typeof(self) weakSelf = self;
    ASFGDisplayFrameworkViewController *vc = [[ASFGDisplayFrameworkViewController alloc] initWithFrameworks:[self.graphManager currentAllFrameworks]
                                                                                    currentHiddenFrameworks:[self.graphManager currentHiddenFrameworks]];
    vc.mustDisplayFrameworks = [self.graphManager currentInputFrameworks];
    vc.completeHandler = ^(ASFGDisplayFrameworkViewController * _Nonnull controller, NSSet<NSString *> * _Nonnull hiddenFrameworks) {
        [weakSelf.graphManager updateHiddenFrameworks:hiddenFrameworks];
        [weakSelf.graphView updateGraphData:weakSelf.graphManager.graphData];
    };
    UINavigationController *containerVC = [[UINavigationController alloc] initWithRootViewController:vc];
    containerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:containerVC animated:YES completion:nil];
}

- (void)updateGraphData:(NSArray<NSString *> *)paths
{
    if (paths.count == 0)
    {
        return;
    }
    
    NSLog(@"Try to add graph data: %@", paths);
    
    [_graphManager addItems:paths];
    [_graphView updateGraphData:_graphManager.graphData];
}

@end
