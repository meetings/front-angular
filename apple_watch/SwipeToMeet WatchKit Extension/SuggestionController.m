//
//  SuggestionController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 02/10/15.
//
//

#import "SuggestionController.h"
#import "AppConfig.h"

@interface SuggestionController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *suggestionDateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *suggestionTimeLabel;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *optionGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *animationGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *acceptedGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *declinedGroup;

@property (strong, nonatomic) PTPusher *pusher;
@property (strong, nonatomic) NSString *pusherChannel;

@property (strong, nonatomic) NSDictionary *meeting;
@property (strong, nonatomic) NSDictionary *currentOption;
@property (strong, nonatomic) NSDictionary *nextOptions;

@property (assign, nonatomic) BOOL popToRoot;

@end

@implementation SuggestionController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    [self.optionGroup setHidden:NO];
    [self.animationGroup setHidden:YES];
    
    self.meeting = [context objectForKey:@"meeting"];
    
    NSDictionary *options = [context objectForKey:@"options"];
    self.currentOption = [options objectForKey:@"option"];
    self.nextOptions = @{
        @"yes_option": [options objectForKey:@"yes_option"],
        @"no_option": [options objectForKey:@"no_option"]
    };
    
    [self setLabels:self.currentOption];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if (self.popToRoot) {
        [self popToRootController];
    }

    [self initPusher];
    
    [self.optionGroup setHidden:NO];
    [self.animationGroup setHidden:YES];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
    PTPusherChannel *channel = [self.pusher channelNamed:self.pusherChannel];
    [channel unsubscribe];
    
    [self.pusher disconnect];
}

- (IBAction)didTapYesButton {
    [self answerOption:@"yes"];
}

- (IBAction)didTapNoButton {
    [self answerOption:@"no"];
}

- (void)initPusher {
    self.pusher = [PTPusher pusherWithKey:PUSHER_API_KEY delegate:self];
    self.pusher.authorizationURL = [NSURL URLWithString:PUSHER_AUTH_URL];
    [self.pusher connect];
    
    self.pusherChannel = [NSString stringWithFormat:@"private-meetings_user_%@", self.userId];
    PTPusherChannel *channel = [self.pusher subscribeToChannelNamed:self.pusherChannel];
    
    [channel bindToEventNamed:@"scheduling_time_found" handleWithBlock:^(PTPusherEvent *channelEvent) {        
        NSString *receivedSchedulingId = [channelEvent.data objectForKey:@"scheduling_id"];
        NSString *currentSchedulingId = [self.meeting  objectForKey:@"current_scheduling_id"];
        
        if ([receivedSchedulingId isEqualToString:currentSchedulingId]) {
            self.popToRoot = YES;

            [self pushControllerWithName:@"TimeFoundController" context:self.meeting];
        }
    }];
}

- (void)pusher:(PTPusher *)pusher willAuthorizeChannel:(PTPusherChannel *)channel withRequest:(NSMutableURLRequest *)request {
    [request setValue:self.userId forHTTPHeaderField:@"user_id"];
    [request setValue:self.token forHTTPHeaderField:@"dic"];
}

- (void) answerOption:(NSString*)answer {
    [self.optionGroup setHidden:YES];
    [self.animationGroup setHidden:NO];

    if ([answer isEqualToString:@"yes"]) {
        [self.acceptedGroup setHidden:NO];
        [self.declinedGroup setHidden:YES];
    } else {
        [self.acceptedGroup setHidden:YES];
        [self.declinedGroup setHidden:NO];
    }

    id scheduling = [self.meeting objectForKey:@"current_scheduling"];
    
    NSString *meetingId = [self.meeting valueForKey:@"id"];
    NSString *schedulingId = [scheduling valueForKey:@"id"];
    NSString *currentOptionId = [self.currentOption valueForKey:@"id"];
    
    NSString *selectedOption = [answer isEqualToString:@"yes"] ? @"yes_option" : @"no_option";
    NSString *nextOptionId = [[self.nextOptions valueForKey:selectedOption] valueForKey:@"id"];
    
    [self.sessionManager answerOption:meetingId
                         schedulingId:schedulingId
                         optionId:currentOptionId
                         params:@{@"answer": answer}
                         success:^(id result) {
        
        if ([[[self.nextOptions valueForKey:selectedOption] valueForKey:@"no_suggestions_left"] integerValue] == 1) {
            self.popToRoot = YES;

            NSDictionary *currentParticipant = [ParticipantUtils getParticipant:[self.meeting objectForKey:@"participants"] userId:self.userId];
            [self pushControllerWithName:@"ThanksController" context:@{@"thanksMsg": @3, @"isManager": [ParticipantUtils isManager:currentParticipant]}];
            
        } else {
            [self fetchNextOptions:meetingId
                  schedulingId:schedulingId
                  optionId:nextOptionId
                  params:@{
                      @"parent_option_id": currentOptionId,
                      @"parent_option_answer": answer
                  }];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)fetchNextOptions:(NSString*) meetingId
                         schedulingId:(NSString*)schedulingId
                         optionId:(NSString *)optionId
                         params:(NSDictionary *)params {

    [self.sessionManager fetchNextOptions:meetingId
                         schedulingId:schedulingId
                         optionId:optionId
                         params:params
                         success:^(id result) {
                             
                             if ([[[result valueForKey:@"option"] valueForKey:@"optional"] integerValue] == 1){
                                 self.popToRoot = YES;

                                 [self pushControllerWithName:@"ThanksController" context:@{@"thanksMsg": @1}];
                             }

                             [self.optionGroup setHidden:NO];
                             [self.animationGroup setHidden:YES];

                             self.currentOption = [result objectForKey:@"option"];
                             self.nextOptions = @{
                                                  @"yes_option": [result objectForKey:@"yes_option"],
                                                  @"no_option": [result objectForKey:@"no_option"]
                                                  };

                             [self setLabels:self.currentOption];


    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)setLabels:(id)option {
    NSDate *beginDate = [NSDate dateWithTimeIntervalSince1970:[[option valueForKey:@"begin_epoch"] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[[option valueForKey:@"end_epoch"] longValue]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MMM d"];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *beginDateFormatted = [dateFormatter stringFromDate:beginDate];
    NSString *beginTimeFormatted = [timeFormatter stringFromDate:beginDate];
    NSString *endTimeFormatted = [timeFormatter stringFromDate:endDate];
    
    [self.suggestionDateLabel setText:beginDateFormatted];
    [self.suggestionTimeLabel setText:[NSString stringWithFormat:@"%@ - %@", beginTimeFormatted, endTimeFormatted]];
}


@end
