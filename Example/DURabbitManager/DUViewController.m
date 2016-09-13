//
//  DUViewController.m
//  DURabbitManager
//
//  Created by iamariffikri@hotmail.com on 09/09/2016.
//  Copyright (c) 2016 iamariffikri@hotmail.com. All rights reserved.
//

#import "DUViewController.h"
#import "DURabbitManager.h"

@interface DUViewController ()
@property (strong, nonatomic) IBOutlet UITextField *hostServerField;
@property (strong, nonatomic) IBOutlet UITextField *portServerField;

@end

@implementation DUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.hostServerField.autocorrectionType = UITextAutocorrectionTypeNo;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)connectRabbit:(id)sender {
    [self.view endEditing:YES];

    [[DURabbitManager sharedManager] setServer:self.hostServerField.text stagingServer:nil port:[self.portServerField.text integerValue]];

    [[DURabbitManager sharedManager] startWithExchange:@"MY" routingKey:@"" success:^(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage) {
        NSLog(@"JSON-Message :%@", jsonMessage);
    } failed:^{
        NSLog(@"Failed");
    }];

}

- (IBAction)downloadApp:(UIButton *)appButton {
    NSString *appURL = [NSString stringWithFormat:@"https://itunes.apple.com/my/app/%@", appButton.tag ? @"duriana/id720005600" : @"88motors/id1083395016"];


    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
}


@end
