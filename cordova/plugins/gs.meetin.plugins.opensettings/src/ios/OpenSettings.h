//
//  Created by Tuomas Lahti
//

#import <Cordova/CDV.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OpenSettings : CDVPlugin

- (void)settings:(CDVInvokedUrlCommand*)command;

@end