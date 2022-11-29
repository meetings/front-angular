//
//  TimelineRow.h
//  SwipeToMeet
//
//  Created by Tuomas Lahti on 01/10/15.
//
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface TimelineRow : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *meetingTitleLabel;

@end
