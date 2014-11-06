//
//  LocMapFormatters.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/2/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapFormatters.h"

@implementation LocMapFormatters
    
    
+(NSString*)dateDescription:(NSDate*)date
    {
        NSString* t = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        NSTimeInterval diff = [date timeIntervalSinceNow];
        if (diff > 0) {
            return t;//in future
        }
        diff = -diff;
        
        NSString* interval;
        if (diff < 2*60) {
            interval = _LOCALIZE(@"TimeFormatJustNow");
        } else if (diff < 120*60) {
            interval = [NSString stringWithFormat:_LOCALIZE(@"TimeFormatMinutesAgo"), (int)(diff/60)];
        } else {
            interval = [NSString stringWithFormat:_LOCALIZE(@"TimeFormatHoursAgo"), (int)(diff/60/60)];
        }
        
        if (interval) {
            return [NSString stringWithFormat:@"%@ (%@)", t, interval];
        }
        return t;
    }
    


@end
