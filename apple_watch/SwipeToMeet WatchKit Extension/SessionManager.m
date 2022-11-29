//
//  SessionService.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 01/10/15.
//
//

#import "SessionManager.h"
#import "AFNetworking.h"
#import "AppConfig.h"

@implementation SessionManager

- (void)initAFHTTPRequestOperationManager {
    NSURL *baseURL = [NSURL URLWithString:API_BASE_URL];
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.requestSerializer.timeoutInterval = 20;
    self.manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    [self.manager.requestSerializer setValue:@"1" forHTTPHeaderField:@"x-expect-http-errors-for-rest"];
    [self.manager.requestSerializer setValue:@"1" forHTTPHeaderField:@"x-expect-int-epochs"];
}

- (void)setAuthHeaders:(NSString*)userId token:(NSString*)token {
    [self.manager.requestSerializer setValue:userId forHTTPHeaderField:@"user_id"];
    [self.manager.requestSerializer setValue:token forHTTPHeaderField:@"dic"];
}

- (void)saveAuthToUserDefaults:(NSString*)userId token:(NSString*)token {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:userId forKey:@"userId"];
    [userDefaults setObject:token forKey:@"token"];
    
    [userDefaults synchronize];
}

- (void)clearAuthHeaders {
    [self.manager.requestSerializer setValue:nil forHTTPHeaderField:@"user_id"];
    [self.manager.requestSerializer setValue:nil forHTTPHeaderField:@"dic"];
}

- (void)clearAuthUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:nil forKey:@"userId"];
    [userDefaults setObject:nil forKey:@"token"];
    
    [userDefaults synchronize];
}

- (void)fetchUnscheduledMeetings:(NSString*) userId success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"users/%@/unscheduled_meetings", userId];
    
    [self.manager GET:queryUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchNotification:(NSString*)nid userId:(NSString*)userId success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"users/%@/notifications/%@", userId, nid];
    
    [self.manager GET:queryUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchMeeting:(NSString*)meetingId success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"meetings/%@/", meetingId];
    
    [self.manager GET:queryUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchNextOption:(NSString*)meetingId schedulingId:(NSString*)schedulingId success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"meetings/%@/schedulings/%@/provide_next_option", meetingId, schedulingId];
    
    [self.manager POST:queryUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchNextOptions:(NSString*)meetingId schedulingId:(NSString*)schedulingId optionId:(NSString*)optionId params:(NSDictionary*)params success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"meetings/%@/schedulings/%@/options/%@/provide_next_options", meetingId, schedulingId, optionId];
    
    [self.manager POST:queryUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)answerOption:(NSString*)meetingId schedulingId:(NSString*)schedulingId optionId:(NSString*)optionId params:(NSDictionary*)params success:(void(^)(id))success failure:(void (^)(NSError*))failure {
    NSString *queryUrl = [NSString stringWithFormat:@"meetings/%@/schedulings/%@/options/%@/answers", meetingId, schedulingId, optionId];
    
    [self.manager POST:queryUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

@end
