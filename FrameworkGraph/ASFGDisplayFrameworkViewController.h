//
//  ASFGDisplayFrameworkViewController.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ASFGDisplayFrameworkViewController;

typedef void(^ASFGDisplayFrameworkViewControllerCompleteHandler)(ASFGDisplayFrameworkViewController *controller, NSSet<NSString *> *hiddenFrameworks);

@interface ASFGDisplayFrameworkViewController : UITableViewController

- (instancetype)initWithFrameworks:(NSDictionary<NSString *, NSArray<NSString *> *> *)frameworks currentHiddenFrameworks:(NSSet<NSString *> *)currentHiddenFrameworks;

@property (nonatomic, strong) NSSet<NSString *> *mustDisplayFrameworks;
@property (nonatomic, copy) ASFGDisplayFrameworkViewControllerCompleteHandler completeHandler;

@end

NS_ASSUME_NONNULL_END
