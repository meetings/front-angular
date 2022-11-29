//
//  ParticipantUtils.h
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 26/10/15.
//
//

#import <Foundation/Foundation.h>

@interface ParticipantUtils : NSObject

+ (NSDictionary*)getParticipant:(NSArray*)participants userId:(NSString*)userId;

+ (NSString*)isManager:(NSDictionary*)participant;

@end
