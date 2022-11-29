//
//  Created by Tuomas Lahti
//

#import "OpenSettings.h"
#import <Cordova/CDV.h>

@implementation OpenSettings


-(void) settings:(CDVInvokedUrlCommand*)command {

    CDVPluginResult* pluginResult = nil;

    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
    // TODO check if is iOS8 otherwise error
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pluginInitialize {
}


@end
