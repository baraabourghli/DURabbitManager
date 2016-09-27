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
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@end

@implementation DUMessagingController

- (IBAction)sendMessage:(id)sender {
    [[DURabbitManager sharedManager] sendMesage:@"Hi Back" immedite:YES];
}

- (IBAction)endSession:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[DURabbitManager sharedManager] stopConsuming];
    }];
}

@end
