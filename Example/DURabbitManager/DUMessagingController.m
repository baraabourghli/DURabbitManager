//
//  DUMessagingControllerViewController.m
//  DURabbitManager
//
//  Created by Arif Fikri Abas on 9/15/16.
//  Copyright © 2016 iamariffikri@hotmail.com. All rights reserved.
//

#import "DUMessagingController.h"
#import "DURabbitManager.h"

@interface DUMessagingController ()
@property (strong, nonatomic) IBOutlet UITextField *messageTextField;
@end

@implementation DUMessagingController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)sendMessage:(id)sender {
}

- (IBAction)endSession:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[DURabbitManager sharedManager] stop];
    }];
}


@end
