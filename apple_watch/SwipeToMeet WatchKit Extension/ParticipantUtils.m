//
//  ParticipantUtils.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 26/10/15.
//
//

#import "ParticipantUtils.h"

@implementation ParticipantUtils

+ (NSDictionary*)getParticipant:(NSArray*)participants userId:(NSString*)userId {
    NSPredicate *filterCurrentParticipant = [NSPredicate predicateWithFormat:@"user_id == %@", userId ];
    NSDictionary *currentParticipant = [[participants filteredArrayUsingPredicate:filterCurrentParticipant] objectAtIndex:0];
    
    return currentParticipant;
}

+ (NSString*)isManager:(NSDictionary*)participant {
    return [participant valueForKey:@"is_manager"];
}

@end
