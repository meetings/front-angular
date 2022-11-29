//
//  WormholeInterface.m
//  SwipeToMeet
//
// Super class for all interface controllers initializes MMWormhole and session manager
//
//  Created by Tuomas Lahti on 02/10/15.
//
//

#import "BaseInterfaceController.h"
#import "MMWormhole.h"
#import "SessionManager.h"

@interface BaseInterfaceController()

@property (nonatomic, strong) MMWormhole *wormhole;
@end

@implementation BaseInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.sessionManager = [[SessionManager alloc] init];
    [self.sessionManager initAFHTTPRequestOperationManager];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.userId = [userDefaults objectForKey:@"userId"];
    self.token = [userDefaults objectForKey:@"token"];
    
    if (self.userId != nil && self.token != nil) {
        [self.sessionManager setAuthHeaders:self.userId token:self.token];
    }

    // Initialize the wormhole
    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.com.swipetomeet.mobile"
                                                        optionalDirectory:nil];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.userId = [userDefaults objectForKey:@"userId"];
    self.token = [userDefaults objectForKey:@"token"];

    [self initWormholeListeners];

    if (self.userId != nil && self.token != nil) {
        [self.sessionManager setAuthHeaders:self.userId token:self.token];
    }

    if (self.userId == nil || self.token == nil) {
        [self presentControllerWithName:@"SignInController" context:self];
    }
}

- (void)didDeactivate {
    [super didDeactivate];
    [self.wormhole stopListeningForMessageWithIdentifier:@"sessionEvent"];
}

- (void)didSignIn {
    [self dismissController];
    [self popToRootController];
}

- (void)initWormholeListeners {
    // Listener for sign in events
    [self.wormhole listenForMessageWithIdentifier:@"sessionEvent" listener:^(id message) {
        
        id authObject = [self parseMessage:message];
        if(authObject != nil) {
            NSString *type = [authObject valueForKey:@"type"];
            
            if ([type isEqualToString:@"signout"]) {
                [self.sessionManager clearAuthHeaders];
                [self.sessionManager clearAuthUserDefaults];
                
                self.userId = nil;
                self.token = nil;
                
                [self presentControllerWithName:@"SignInController" context:self];
            }
        }
    }];
}

- (id)parseMessage:(id)messageObject {
    NSError *error;
    NSDictionary *parsedMessage = [NSJSONSerialization JSONObjectWithData:[messageObject dataUsingEncoding:NSUTF8StringEncoding]
                                                       options:NSJSONReadingMutableContainers
                                                       error:&error];
    return error ? nil : parsedMessage;
}

@end
