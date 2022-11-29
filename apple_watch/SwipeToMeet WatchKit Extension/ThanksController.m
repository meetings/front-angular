//
//  ThanksController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 07/10/15.
//
//

#import "ThanksController.h"

@interface ThanksController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *messageLabel;

@property (assign, nonatomic) BOOL isManager;

@end

@implementation ThanksController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.isManager = [[context valueForKey:@"isManager"]  isEqual: @"1"];
    [self setLabels:[[context valueForKey:@"thanksMsg"] integerValue]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    [super didDeactivate];
}

- (IBAction)didTapButton {
    [self popToRootController];
}

- (void)setLabels:(long) thankMsg {
    NSString *title = @"";
    NSString *message = @"";
    
    // ThankMsg codes match the cordova app's codes.
    // Time found (2) is handled in another controller.
    // Scheduling failed (4) shouldn't be possible because it can be reached only from old notifications.
    switch (thankMsg) {
        case 1:
            title = @"That's great!";
            message = @"We’ll let you know if more input is needed or when the time is found.";
            break;
            
        case 3:
            title = @"Bummer!";
            if (self.isManager) {
                message = @"No time could be found. Open SwipeToMeet with your iPhone for solutions.";
            } else {
                message = @"We’re out of suggestions and no time could be found. We’ll notify the organiser.";
            }
            break;
            
        case 5:
            title = @"Time already set";
            message = @"Organiser has picked the time manually. Scheduling is no longer active.";
            break;
    }
    
    [self.titleLabel setText:title];
    [self.messageLabel setText:message];
}

@end
