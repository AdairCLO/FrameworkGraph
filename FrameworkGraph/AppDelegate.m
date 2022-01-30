//
//  AppDelegate.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/17.
//

#import "AppDelegate.h"
#import "ASFGGraphViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIViewController *vc = [[ASFGGraphViewController alloc] init];
    UIViewController *rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    _window = [[UIWindow alloc] initWithFrame:screenRect];
    _window.rootViewController = rootViewController;
    [_window makeKeyAndVisible];
    
    NSLog(@"Install Dir: %@", [NSBundle mainBundle].bundlePath);
    NSLog(@"Home Dir: %@", NSHomeDirectory());
    
    return YES;
}

@end
