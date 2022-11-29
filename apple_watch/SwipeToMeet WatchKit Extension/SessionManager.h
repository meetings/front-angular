//
//  SessionService.h
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 01/10/15.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface SessionManager : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

- (void)initAFHTTPRequestOperationManager;

- (void)setAuthHeaders:(NSString*)userId token:(NSString*)token;
- (void)saveAuthToUserDefaults:(NSString*)userId token:(NSString*)token;

- (void)clearAuthHeaders;
- (void)clearAuthUserDefaults;

- (void)fetchUnscheduledMeetings:(NSString*) userId success:(void(^)(id))success failure:(void(^)(NSError*))failure;
- (void)fetchNotification:(NSString*)nid userId:(NSString*)userId success:(void(^)(id))success failure:(void (^)(NSError*))failure;
- (void)fetchMeeting:(NSString*)meetingId success:(void(^)(id))success failure:(void (^)(NSError*))failure;
- (void)fetchNextOption:(NSString*)meetingId schedulingId:(NSString*)schedulingId success:(void(^)(id))success failure:(void (^)(NSError*))failure;
- (void)fetchNextOptions:(NSString*)meetingId schedulingId:(NSString*)schedulingId optionId:(NSString*)optionId params:(NSDictionary*)params success:(void(^)(id))success failure:(void (^)(NSError*))failure;
- (void)answerOption:(NSString*)meetingId schedulingId:(NSString*)schedulingId optionId:(NSString*)optionId params:(NSDictionary*)params success:(void(^)(id))success failure:(void (^)(NSError*))failure;
@end

