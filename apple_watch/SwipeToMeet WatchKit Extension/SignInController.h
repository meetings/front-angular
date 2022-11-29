//
//  SignInController.h
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 06/10/15.
//
//

#import <WatchKit/WatchKit.h>


@protocol SignInDelegate <NSObject>

- (void)didSignIn;

@end

@interface SignInController : WKInterfaceController

@property (nonatomic, assign) id<SignInDelegate> signInDelegate;

@end
