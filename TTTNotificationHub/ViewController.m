//
//  ViewController.m
//  TTTNotificationHub
//
//  Created by an_ttt on 16/5/15.
//  Copyright © 2016年 an_ttt. All rights reserved.
//

#import "ViewController.h"
#import "TTTNotificationHub.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (nonatomic, strong) TTTNotificationHub *notificationHub;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)reduce:(UIButton *)sender
{
    
    [self.notificationHub setCountAndCheckZero:self.notificationHub.count - 1];

}

- (IBAction)increase:(UIButton *)sender
{
    [self.notificationHub setCountAndCheckZero:self.notificationHub.count + 1];
}

- (TTTNotificationHub *)notificationHub
{
    if (!_notificationHub) {
  
        _notificationHub = [[TTTNotificationHub alloc] initWithView:self.myLabel scale:0.7 offset:CGPointMake(-20, 20) maxInstance:50.0];
        
        __weak typeof(self) weak_self = self;
        _notificationHub.destoryBlock = ^() {
            /*UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"oops, has been destory!" message:@"oops, has been destory!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:okAction];
            [weak_self presentViewController:alertController animated:YES completion:nil];*/
        };
    }
    
    return _notificationHub;
}


@end
