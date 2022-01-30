//
//  ASFGToast.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/26.
//

#import "ASFGToast.h"
#import <UIKit/UIKit.h>

@implementation ASFGToast

+(void)showToast:(NSString *)msg
{
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [vc addAction:cancelAction];
    
    [[UIApplication sharedApplication].windows.firstObject.rootViewController presentViewController:vc animated:NO completion:nil];
}

@end
