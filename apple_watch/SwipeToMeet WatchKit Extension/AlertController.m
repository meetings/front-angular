//
//  AlertController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 06/10/15.
//
//

#import "AlertController.h"
#import "AFNetworking.h"

@interface AlertController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *messageLabel;

@end

@implementation AlertController

- (void)awakeWithContext:(id)context {
    NSError *error = context;
    [self handleError:error];
}

- (void)handleError:(NSError*) error {
    NSString *title = @"Sorry";
    NSString *message = @"";
    
    long errorCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];

    switch (errorCode) {
        case 0:
            title = @"No internet connect";
            message = @"Please check your connection and try again.";
            break;
            
        case 401:
            message = @"Please sign in with your iPhone application";
            break;
            
        case 403:
            message = @"It seems that you do not have permission to access the content of this meeting.";
            break;
            
        case 404:
            message = @"There was a server problem. This may also be a connectivity issue.";
            break;
            
        default:
            title = @"Unknown error";
            message = @"Sorry, we made a mistake";
            break;
    }
    
    [self setLabels:title message:message];
}

- (IBAction)didTapButton {
    [self dismissController];
}

- (void)setLabels:(NSString*) title message:(NSString*)message {
    [self.titleLabel setText:title];
    [self.messageLabel setText:message];
}

@end
