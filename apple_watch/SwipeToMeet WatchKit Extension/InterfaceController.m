//
//  InterfaceController.m
//  SwipeToMeet WatchKit Extension
//
//  Created by Tuomas Lahti on 30/09/15.
//
//

#import "InterfaceController.h"
#import "TimelineRow.h"
#import "SessionManager.h"

@interface InterfaceController()

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *timelineTable;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *emptyTimelineGroup;

@property (nonatomic, strong) NSArray *currentSchedulings;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    if (self.userId != nil && self.token != nil) {
        [self fetchUnscheduledMeetings:self.userId];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification {    
    NSString *nid = [remoteNotification valueForKey:@"nid"];

    if (nid != nil) {
        [self fetchAndOpenNotification:nid userId:self.userId];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    id selectedMeeting = [self.currentSchedulings objectAtIndex:rowIndex];
    
    [self pushControllerWithName:@"LandingPageController" context:selectedMeeting];
}

- (void)fetchUnscheduledMeetings:(NSString*) userId {
    [self.sessionManager fetchUnscheduledMeetings:userId success:^(id result) {
        NSPredicate *filterCurrentSchedulings = [NSPredicate predicateWithFormat:@"current_scheduling_id != 0" ];
        self.currentSchedulings = [result filteredArrayUsingPredicate:filterCurrentSchedulings];

        // clear the table
        [self.timelineTable setNumberOfRows:0 withRowType:@"TimelineRow"];
        
        if ([self.currentSchedulings count] == 0) {
            [self.emptyTimelineGroup setHidden:NO];
            
        } else {
            [self.emptyTimelineGroup setHidden:YES];
            for(NSInteger i = 0; i < [self.currentSchedulings count]; i++) {
                
                NSDictionary *meeting = [self.currentSchedulings objectAtIndex:i];
                NSDictionary *participant = [ParticipantUtils getParticipant:[meeting objectForKey:@"participants"] userId:self.userId];
                long hasAnswered = [[participant valueForKey:@"has_answered_current_scheduling"] integerValue];
                
                if ( hasAnswered == 1) {
                    [self.timelineTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:i] withRowType:@"TimelineRow"];
                } else {
                    [self.timelineTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:i] withRowType:@"TimelineRowHighlight"];
                }
                
                TimelineRow *row = [self.timelineTable rowControllerAtIndex:i];
                
                NSString *title = [meeting valueForKey:@"title_value"];

                if ([title length] != 0) {
                    [row.meetingTitleLabel setText:title];
                }
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);

        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

- (void)fetchAndOpenNotification:(NSString*)nid userId:(NSString*)userId{
    [self.sessionManager fetchNotification:nid userId:userId success:^(id result) {
        id meeting = [[result objectForKey:@"data"] objectForKey:@"meeting"];
        [self pushControllerWithName:@"LandingPageController" context:meeting];

    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
        
        [self presentControllerWithName:@"AlertController" context:error];
    }];
}

@end



