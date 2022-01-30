//
//  ASFGFrameworkViewController.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/17.
//

#import "ASFGFrameworkViewController.h"
#import "ASFGFrameworkManager.h"

static NSString * const kCellIdentifier = @"cell";

@interface ASFGFrameworkViewController ()

@property (nonatomic, strong) ASFGFrameworkManager *frameworkManager;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *selectedIndexPathSet;

@end

@implementation ASFGFrameworkViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _frameworkManager = [[ASFGFrameworkManager alloc] init];
        _selectedIndexPathSet = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Frameworks";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneBarButtonItemClicked)];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.allowsMultipleSelection = YES;
}

- (void)onDoneBarButtonItemClicked
{
    NSMutableArray<NSString *> *selectedPaths = [[NSMutableArray alloc] init];
    [_selectedIndexPathSet enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *path = [self.frameworkManager frameworkOrLibraryPathWithDirIndex:obj.section fileIndex:obj.row];
        [selectedPaths addObject:path];
    }];
    if (_completeHandler != nil)
    {
        _completeHandler(self, selectedPaths);
    }
    
    if (self.presentingViewController != nil)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_selectedIndexPathSet addObject:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_selectedIndexPathSet removeObject:indexPath];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_frameworkManager dirPathCount];
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_frameworkManager dirPathWithDirIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_frameworkManager frameworkOrLibraryCountWithDirIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    NSString *name = [_frameworkManager frameworkOrLibraryNameWithDirIndex:indexPath.section fileIndex:indexPath.row];
    cell.textLabel.text = name;
    return cell;
}

@end
