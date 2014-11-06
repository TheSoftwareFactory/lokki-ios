//
//  LocatingInProgressAnimationAroundAvatar.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocatingInProgressAnimationAroundAvatar.h"
#import "LocalStorage.h"

@interface LocatingInProgressAnimationAroundAvatar()
    @property (strong)  UIImageView* locatingAnimation;
    @property (nonatomic) BOOL locatingInProgress;
    @property (strong) NSDate* whenStartedLocatingAnimation;//remember when started animating to give it at least 2 seconds
    @property float currentRotationAngle;
@end

@implementation LocatingInProgressAnimationAroundAvatar

-(id)initWithFrame:(CGRect)frame forView:(UIView*)parent delegate:(id<LocatingInProgressAnimationAroundAvatarDataSource>)delegate {
    self = [super init];
    
    self.whenStartedLocatingAnimation = [NSDate dateWithTimeIntervalSinceNow:0];
    self.currentRotationAngle = 0;
    self.locatingInProgress = NO;
    
    self.delegate = delegate;
    self.locatingAnimation = [[UIImageView alloc] initWithFrame:frame];
    self.locatingAnimation.image = [UIImage imageNamed:@"halo"];
    [parent addSubview:self.locatingAnimation];
    [self updateLocatingInProgress];
    return self;
}



-(void)updateLocatingInProgress
{
    NSDate* lastRequest = [LocalStorage getLastLocationUpdateRequestTime];
    if (!lastRequest) {
        return;
    }
    
    // don't touch it for 2 seconds after animation start
    if (self.locatingInProgress && [self.whenStartedLocatingAnimation timeIntervalSinceNow] > -2) {
        return;
    }
    
    if ([lastRequest timeIntervalSinceNow] < -60) {
        self.locatingInProgress = NO;
        return;// more than a minute since request, stop showing locating animation
    }
    
    BOOL visible = [self.delegate isUserReportingForLocatingInProgressAnimationAroundAvatar:self];
    if (!visible) {
        self.locatingInProgress = NO;
        return;//user is not reporting - dont show animation
    }
    
    // animating for a minute if location is older than a minute
    NSTimeInterval t = [[self.delegate getUserLastReportDateForLocatingInProgressAnimationAroundAvatar:self] timeIntervalSinceDate:lastRequest];
    if (t >= 0 || t > -5*60) {
        self.locatingInProgress = NO;// location was received after request or 5 minutes before so good enough
        return;
    }
    
    self.locatingInProgress = YES;
}



-(void)setLocatingInProgress:(BOOL)inProgress
{
    if (!_locatingInProgress && inProgress) {
        self.whenStartedLocatingAnimation = [NSDate dateWithTimeIntervalSinceNow:0];
        _locatingInProgress = inProgress;
        [self startLocatingAnimation];
    } else {
        _locatingInProgress = inProgress;
    }
    self.locatingAnimation.hidden = !_locatingInProgress;
}

-(void)startLocatingAnimation
{
    if (!self.locatingInProgress) {
        return;
    }
    
    self.currentRotationAngle += 3.14;
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
        self.locatingAnimation.transform = CGAffineTransformMakeRotation(self.currentRotationAngle);
    } completion:^(BOOL finished) {
        if (finished) {
            [self updateLocatingInProgress];
            if (self.locatingInProgress) {
                [self startLocatingAnimation];// continue animations
            }
        } else {
            self.locatingInProgress = NO;
        }
    }];
}


@end
