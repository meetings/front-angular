//
//  SignInController.m
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 06/10/15.
//
//

#import "SignInController.h"
#import "MMWormhole.h"
#import "SessionManager.h"

@interface SignInController()

@property (nonatomic, strong) MMWormhole *wormhole;
@property (nonatomic, strong) SessionManager *sessionManager;

@end

@implementation SignInController

@synthesize signInDelegate;

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    signInDelegate = context;
    
    self.sessionManager = [[SessionManager alloc] init];

    // Initialize the wormhole
    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.com.swipetomeet.mobile"
                                                         optionalDirectory:nil];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self initWormholeListeners];
    [self.wormhole passMessageObject:@"" identifier:@"applewatchsignin"];
}

- (void)didDeactivate {
    [super didDeactivate];
    [self.wormhole stopListeningForMessageWithIdentifier:@"sessionEvent"];
}

- (void)initWormholeListeners {
    // Listener for sign out events
    [self.wormhole listenForMessageWithIdentifier:@"sessionEvent" listener:^(id message) {
        
        id authObject = [self parseMessage:message];
        if(authObject != nil) {
            NSString *type = [authObject valueForKey:@"type"];
            
            if ([type isEqualToString:@"signin"]) {
                NSString *userId = [authObject objectForKey:@"userId"];
                NSString *token = [authObject objectForKey:@"token"];
                
                [self.sessionManager saveAuthToUserDefaults:userId token:token];

                [self.signInDelegate didSignIn];
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
