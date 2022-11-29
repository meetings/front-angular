//
//  WormholeInterface.h
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 02/10/15.
//
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "SessionManager.h"
#import "SignInController.h"

@interface BaseInterfaceController : WKInterfaceController <SignInDelegate>

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *token;

@property (nonatomic, strong) SessionManager *sessionManager;

@end
