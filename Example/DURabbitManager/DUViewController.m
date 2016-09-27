//
//  DUViewController.m
//  DURabbitManager
//
//  Created by iamariffikri@hotmail.com on 09/09/2016.
//  Copyright (c) 2016 iamariffikri@hotmail.com. All rights reserved.
//

#import "DUViewController.h"
#import "DUMessagingController.h"
#import "DURabbitManager.h"

@interface DUViewController ()
@property (weak, nonatomic) IBOutlet UITextField *hostServerField;
@property (weak, nonatomic) IBOutlet UITextField *portServerField;
@property (strong, nonatomic) DUMessagingController *messagingController;
@end

@implementation DUViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hostServerField.autocorrectionType = UITextAutocorrectionTypeNo;
}

- (IBAction)connectRabbit:(id)sender {
    [self.view endEditing:YES];

    [[DURabbitManager sharedManager] setServer:self.hostServerField.text
                                 stagingServer:nil
                                          port:[self.portServerField.text integerValue]
                                      username:@"guest"
                                      password:@"guest"];

    [[DURabbitManager sharedManager] startConsumingWithExchange:@"MY" routingKey:@"123" success:^(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage) {
        NSLog(@"Rabbit: Message recieved %@", jsonMessage);

        if([[jsonMessage valueForKey:@"status"] intValue] == 200) {
            [self performSegueWithIdentifier:@"startMessagingSegue" sender:self];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.messagingController.consoleTextView.text = [NSString stringWithFormat:@"%@\n%@", self.messagingController.consoleTextView.text, jsonMessage];
            [self scrollTextViewToBottom:self.messagingController.consoleTextView];
        });
    } failed:^{
        NSLog(@"Rabbit: Connection Failed");
    }];
}

- (IBAction)downloadApp:(UIButton *)appButton {
    NSString *appURL = [NSString stringWithFormat:@"https://itunes.apple.com/my/app/%@", appButton.tag ? @"duriana/id720005600" : @"88motors/id1083395016"];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"startMessagingSegue"]) {
        self.messagingController = segue.destinationViewController;
    }
}

-(void)scrollTextViewToBottom:(UITextView *)textView {
    if(textView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}


@end
