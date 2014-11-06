//
//  LocatingInProgressAnimationAroundAvatar.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LocatingInProgressAnimationAroundAvatar;

@protocol LocatingInProgressAnimationAroundAvatarDataSource <NSObject>

    // should return date of last report from user avatar is attached to. or nil if not reported yet
    -(NSDate*)getUserLastReportDateForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation;

    -(BOOL)isUserReportingForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation;
@end



@interface LocatingInProgressAnimationAroundAvatar : NSObject
    @property (weak) id<LocatingInProgressAnimationAroundAvatarDataSource> delegate;

    //designated initializer
    -(id)initWithFrame:(CGRect)frame forView:(UIView*)parent delegate:(id<LocatingInProgressAnimationAroundAvatarDataSource>)delegate;

    // if something changes - call this to trigger animation start if needed
    -(void)updateLocatingInProgress;
@end
