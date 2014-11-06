//
//  AppRater.h
//
//  Created by Oleg Fedorov on 25/01/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppRater : NSObject

    +(AppRater*)instance;

    // show app rater only when this trigger is executed. Also this trigger is what we count as number of executions
    -(void)onTrigger;
@end
