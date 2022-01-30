//
//  ASFGDisplayFrameworkViewController.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/27.
//

#import "ASFGDisplayFrameworkViewController.h"

static NSString * const kCellIdentifier = @"cell";
const CGFloat kHeaderHeight = 30;

@interface ASFGDisplayFrameworkViewController ()

@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSString *> *> *data;
@property (nonatomic, strong) NSMutableSet<NSString *> *hiddenFrameworks;
@property (nonatomic, strong) NSMutableSet<NSString *> *allDisplayDirs;
@property (nonatomic, strong) NSArray<NSString *> *dirs;

@end

@implementation ASFGDisplayFrameworkViewController

- (instancetype)initWithFrameworks:(NSDictionary<NSString *, NSArray<NSString *> *> *)frameworks currentHiddenFrameworks:(NSSet<NSString *> *)currentHiddenFrameworks
{
    self = [super init];
    {
        _data = frameworks;
        _hiddenFrameworks = [currentHiddenFrameworks mutableCopy];
        if (_hiddenFrameworks == nil)
        {
            _hiddenFrameworks =  [[NSMutableSet alloc] init];
        }
        _allDisplayDirs = [[NSMutableSet alloc] init];
        [frameworks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull dir, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            __block BOOL allDisplayDir = YES;
            [frameworks[dir] enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([_hiddenFrameworks containsObject:filePath])
                {
                    allDisplayDir = NO;
                    *stop = YES;
                }
            }];
            if (allDisplayDir)
            {
                [_allDisplayDirs addObject:dir];
            }
        }];
        
        NSMutableArray<NSString *> *dirs = [frameworks.allKeys mutableCopy];
        [dirs sortUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        _dirs = dirs;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Show/Hide Frameworks";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onDoneBarButtonItemClicked)];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.allowsMultipleSelection = YES;
}

- (void)onDoneBarButtonItemClicked
{
    if (_completeHandler != nil)
    {
        _completeHandler(self, _hiddenFrameworks);
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

- (void)toggleDir:(UIButton *)btn
{
    BOOL display = NO;
    NSUInteger section = btn.tag;
    NSString *dir = _dirs[section];
    if ([_allDisplayDirs containsObject:dir])
    {
        display = NO;
        [_allDisplayDirs removeObject:dir];
    }
    else
    {
        display = YES;
        [_allDisplayDirs addObject:dir];
    }
    
    [_data[dir] enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        if (display)
        {
            [_hiddenFrameworks removeObject:filePath];
        }
        else if (![_mustDisplayFrameworks containsObject:filePath])
        {
            [_hiddenFrameworks addObject:filePath];
        }
    }];
    
    [self.tableView reloadData];
}

- (void)toggleDisplayFramework:(NSIndexPath *)indexPath
{
    NSString *dir = _dirs[indexPath.section];
    NSString *framework = _data[dir][indexPath.row];
    if ([_mustDisplayFrameworks containsObject:framework])
    {
        return;
    }
    
    if ([_hiddenFrameworks containsObject:framework])
    {
        [_hiddenFrameworks removeObject:framework];
        
        __block BOOL allDisplay = YES;
        [_data[dir] enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([_hiddenFrameworks containsObject:filePath])
            {
                allDisplay = NO;
                *stop = YES;
            }
        }];
        if (allDisplay)
        {
            [_allDisplayDirs addObject:dir];
        }
    }
    else
    {
        [_hiddenFrameworks addObject:framework];
        
        if ([_allDisplayDirs containsObject:dir])
        {
            [_allDisplayDirs removeObject:dir];
        }
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = [_hiddenFrameworks containsObject:framework] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderHeight;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    if (@available(iOS 13.0, *)) {
        headerView.backgroundColor = [UIColor systemGray5Color];
    }
    else
    {
        headerView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1];
    }
    
    UIButton *toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [toggleButton setTitle:@"Toggle" forState:UIControlStateNormal];
    [toggleButton sizeToFit];
    toggleButton.frame = CGRectMake(tableView.bounds.size.width - toggleButton.bounds.size.width - 16,
                                    (kHeaderHeight - toggleButton.bounds.size.height) / 2,
                                    toggleButton.bounds.size.width,
                                    toggleButton.bounds.size.height);
    toggleButton.tag = section;
    [toggleButton addTarget:self action:@selector(toggleDir:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:toggleButton];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.text = _dirs[section];
    [titleLabel sizeToFit];
    titleLabel.frame = CGRectMake(16,
                                  (kHeaderHeight - titleLabel.bounds.size.height) / 2,
                                  MIN(titleLabel.bounds.size.width, CGRectGetMinX(toggleButton.frame) - 16 - 6),
                                  titleLabel.bounds.size.height);
    [headerView addSubview:titleLabel];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleDisplayFramework:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleDisplayFramework:indexPath];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _dirs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[_dirs[section]].count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _dirs[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    NSString *dir = _dirs[indexPath.section];
    NSString *framework = _data[dir][indexPath.row];
    NSString *title = [framework substringFromIndex:(dir.length + 1)];
    cell.textLabel.text = title;
    cell.accessoryType = [_hiddenFrameworks containsObject:framework] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIColor *color = [_mustDisplayFrameworks containsObject:framework] ? [UIColor grayColor] : [UIColor systemBlueColor];
    cell.textLabel.textColor = color;
    cell.tintColor = color;
    return cell;
}

@end
