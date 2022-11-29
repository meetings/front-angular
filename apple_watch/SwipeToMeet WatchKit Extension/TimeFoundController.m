//
//  TimeFoundController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 06/10/15.
//
//

#import "TimeFoundController.h"

@interface TimeFoundController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *timeLabel;

@property (strong, nonatomic) NSString *meetingId;

@end

@implementation TimeFoundController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.meetingId = [context objectForKey:@"id"];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if (self.userId != nil && self.token != nil) {
        [self fetchMeeting:self.meetingId];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)didTapButton {
    [self popToRootController];
}

- (void)fetchMeeting:(NSString*)meetingId {
    [self.sessionManager fetchMeeting:meetingId success:^(id result) {
        
        [self setLabels:result];
        
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)setLabels:(id)meeting {
    NSDate *beginDate = [NSDate dateWithTimeIntervalSince1970:[[meeting valueForKey:@"begin_epoch"] longValue]];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[[meeting valueForKey:@"end_epoch"] longValue]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MMM d"];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *beginDateFormatted = [dateFormatter stringFromDate:beginDate];
    NSString *beginTimeFormatted = [timeFormatter stringFromDate:beginDate];
    NSString *endTimeFormatted = [timeFormatter stringFromDate:endDate];
    
    [self.dateLabel setText:beginDateFormatted];
    [self.timeLabel setText:[NSString stringWithFormat:@"%@ - %@", beginTimeFormatted, endTimeFormatted]];
    
    [self.dateLabel setHidden:NO];
    [self.timeLabel setHidden:NO];
}

@end
