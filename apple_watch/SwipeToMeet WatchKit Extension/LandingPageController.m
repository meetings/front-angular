//
//  LandingPageController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 01/10/15.
//
//

#import "LandingPageController.h"

@interface LandingPageController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *locationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *answerButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *disabledLabelGroup;

@property (strong, nonatomic) NSMutableDictionary *suggestionModel;
@property (assign, nonatomic) BOOL popToRoot;

@end

@implementation LandingPageController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.suggestionModel = [NSMutableDictionary dictionary];
    
    [self.suggestionModel setObject:context forKey:@"meeting"];
    [self setLabels:[self.suggestionModel objectForKey:@"meeting"]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if (self.popToRoot) {
        [self popToRootController];
    }
    
    if (self.userId != nil && self.token != nil) {
        [self fetchMeeting:[[self.suggestionModel objectForKey:@"meeting"] valueForKey:@"id"]];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)didTapAnswerButton {
    [self pushControllerWithName:@"SuggestionController" context:self.suggestionModel];
}

- (void)fetchMeeting:(NSString*)meetingId {
    [self.sessionManager fetchMeeting:meetingId success:^(id result) {
        
        [self.suggestionModel setObject:result forKey:@"meeting"];
        [self setLabels:[self.suggestionModel objectForKey:@"meeting"]];
        
        id scheduling = [result objectForKey:@"current_scheduling"];
        
        if (scheduling == nil) {
            scheduling = [result objectForKey:@"previous_scheduling"];
        }
        
        long schedulingCompleted = [[scheduling valueForKey:@"completed_epoch"] longValue];
        long schedulingCanceled  = [[scheduling valueForKey:@"cancelled_epoch"] longValue];
        long schedulingFailed    = [[scheduling valueForKey:@"failed_epoch"] longValue];
        
        if(schedulingCompleted != 0) {
            self.popToRoot = YES;
            [self pushControllerWithName:@"TimeFoundController" context:result];
        }

        if(schedulingCanceled != 0) {
            self.popToRoot = YES;
            [self pushControllerWithName:@"ThanksController" context:@{@"thanksMsg": @5}];
        }

        if(schedulingFailed != 0) {
            self.popToRoot = YES;

            NSDictionary *currentParticipant = [ParticipantUtils getParticipant:[[self.suggestionModel objectForKey:@"meeting"] objectForKey:@"participants"] userId:self.userId];
            [self pushControllerWithName:@"ThanksController" context:@{@"thanksMsg": @3, @"isManager": [ParticipantUtils isManager:currentParticipant]}];
        }

        if(schedulingCompleted == 0 && schedulingCanceled == 0 && schedulingFailed == 0) {
            [self fetchNextOption:meetingId schedulingId:[scheduling valueForKey:@"id"]];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)fetchNextOption:(NSString*) meetingId schedulingId:(NSString*)schedulingId {
    [self.sessionManager fetchNextOption:meetingId schedulingId:schedulingId success:^(id result) {
        
        [self.suggestionModel setObject:result forKey:@"options"];
        
        if ([[[result valueForKey:@"option"] valueForKey:@"no_suggestions_left"] integerValue] == 1) {
            self.popToRoot = YES;

            NSDictionary *currentParticipant = [ParticipantUtils getParticipant:[[self.suggestionModel objectForKey:@"meeting"] objectForKey:@"participants"] userId:self.userId];
            [self pushControllerWithName:@"ThanksController" context:@{@"thanksMsg": @3, @"isManager": [ParticipantUtils isManager:currentParticipant]}];

        } else {
            [self.disabledLabelGroup setHidden:YES];
            [self.answerButton setHidden:NO];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)setLabels:(id)meeting {
    NSString *title = [meeting valueForKey:@"title_value"];

    if ([title length] != 0) {
        [self.titleLabel setText:title];
    }
    
    NSString *location = [meeting valueForKey:@"location_value"];
    
    if ([location length] != 0) {
        [self.locationLabel setText:location];
    }
}

@end
