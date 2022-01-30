//
//  ASFGFrameworkViewController.h
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ASFGFrameworkViewController;

typedef void(^ASFGFrameworkViewControllerCompleteHandler)(ASFGFrameworkViewController *controller, NSArray<NSString *> *frameworkOrLibraryPaths);

@interface ASFGFrameworkViewController : UITableViewController

@property (nonatomic, copy) ASFGFrameworkViewControllerCompleteHandler completeHandler;

@end

NS_ASSUME_NONNULL_END
