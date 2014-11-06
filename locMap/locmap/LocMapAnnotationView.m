//
//  LocMapAnnotationView.m
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapAnnotationView.h"
#import "LocMapAnnotation.h"
#import <QuartzCore/QuartzCore.h>
#import "FSConstants.h"
#import "LocMapAnnotationViewCallout.h"
#import "LocalStorage.h"
#import "LocatingInProgressAnimationAroundAvatar.h"


@interface LocMapAnnotationView () <LocatingInProgressAnimationAroundAvatarDataSource>

    @property BOOL _showCustomCallout;
    @property (strong) LocMapAnnotationViewCallout* calloutView;
    @property (strong) UIImageView* pinImage;


    @property (strong) LocatingInProgressAnimationAroundAvatar* locatingInProgressAnimation;

@end


@implementation LocMapAnnotationView


- (id)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if (self) {
        LocMapAnnotation* ann = annotation;
        ann.annotationView = self;
        
        // Compensate frame a bit so everything's aligned
        [self setCenterOffset:CGPointMake(0, -PIN_HEIGHT/2)];
        //[self setCalloutOffset:CGPointMake(3, 0)];

        self.pinImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PIN_WIDTH, PIN_HEIGHT)];//-3 to go deeper into avatar
        [self addSubview:self.pinImage];
        
        avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 7, AVATAR_WIDTH, AVATAR_WIDTH)];
        [self addSubview:avatarView];
        
        self.locatingInProgressAnimation = [[LocatingInProgressAnimationAroundAvatar alloc] initWithFrame:CGRectMake(1, 2, HALO_SIZE, HALO_SIZE) forView:self delegate:self];
        
        self.frame = CGRectMake(-PIN_WIDTH/2, -PIN_HEIGHT, PIN_WIDTH, PIN_HEIGHT);

        [self updateAnnotationInfo];
        
    }
    return self;
}

-(void)setHorizontalDisplacement:(float)dx {
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self setCenterOffset:CGPointMake(dx, -PIN_HEIGHT/2)];
    } completion:^(BOOL finished) {
        
    }];
    
}

-(float)getHorizontalDisplacement {
    return self.centerOffset.x;
}



-(NSDate*)getUserLastReportDateForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation {
    LocMapAnnotation* ann = (LocMapAnnotation*)[super annotation];
    return ann.userLastReportTime;
}

-(BOOL)isUserReportingForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation {
    LocMapAnnotation* ann = (LocMapAnnotation*)[super annotation];
    return ann.userIsReporting;
}


-(void)updatePinImage
{
    self.pinImage.image = [UIImage imageNamed:[self avatarImageName:[super annotation]]];
}

-(NSString*)avatarImageName:(LocMapAnnotation*)ann {
    // location too inaccurate?
    if (ann.userCoordinateAccuracy > 100) {
        return @"orangePin";
    }
    
    // location too old?
    NSTimeInterval diff = [ann.userLastReportTime timeIntervalSinceNow];
    if (diff <= 0) {
        diff = -diff;
        if (diff > 60*60) {
            return @"orangePin";
        }
    }
    
    
    if ([ann.userID isEqualToString:[LocalStorage getLoggedInUserId]]) {
        return @"greenPin";
    } else {
        return @"bluePin";
    }
}

// half of width gives pure round
-(void)setRoundedAvatar:(UIImageView *)avatar toDiameter:(float)cornerRadius
{
    avatar.layer.cornerRadius = cornerRadius;
    avatar.clipsToBounds = YES;
    
}

- (void)setAnnotation:(id)annotation {
    [super setAnnotation:annotation];
    [self updateAnnotationInfo];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if(selected)
    {
        self.calloutView = [[LocMapAnnotationViewCallout alloc] initWithAnnotation:[super annotation]];
        [self setShowCustomCallout:YES animated:YES];
    }
    else
    {
        [self setShowCustomCallout:NO animated:YES];
    }
}
    
-(void)updateAnnotationInfo
{
    [self.locatingInProgressAnimation updateLocatingInProgress];
    [self updatePinImage];
    LocMapAnnotation *ann = (LocMapAnnotation *)super.annotation;
    if (ann.userAvatarImageData) {
        avatarImg = [UIImage imageWithData:ann.userAvatarImageData];
    } else {
        avatarImg = [[FSConstants instance] getDefaultAvatarForUserWithName:ann.userName];
    }
    [avatarView setImage:avatarImg];
    [self setRoundedAvatar:avatarView toDiameter:AVATAR_WIDTH/2];
    
    if (self.calloutView) {
        [self.calloutView updateInfo];
    }
}
    
/*
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self._showCustomCallout && CGRectContainsPoint(self.calloutView.frame, point)) {
        return self.calloutView;
        
    } else {
        return nil;
    }
}*/

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    UIView* hitView = [super hitTest:point withEvent:event];
    if (hitView != nil)
    {
        [self.superview bringSubviewToFront:self];
    }
    return hitView;
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect rect = self.bounds;
    BOOL isInside = CGRectContainsPoint(rect, point);
    if(!isInside)
    {
        if (self._showCustomCallout && CGRectContainsPoint(self.calloutView.frame, point)) {
            isInside = YES;
        }
    }
    return isInside;
}

-(void)onCustomCalloutFinishedShowing
{
    //self.frame = CGRectUnion(self.frame, self.calloutView.frame);
}

-(void)onCustomCalloutFinishedDisappearing
{
    [self.calloutView removeFromSuperview];
    //self.frame = CGRectMake(-AVATAR_WIDTH/2, -AVATAR_WIDTH - PIN_HEIGHT/2, AVATAR_WIDTH, AVATAR_WIDTH + PIN_HEIGHT/2);
}


- (void)setShowCustomCallout:(BOOL)showCustomCallout
{
    [self setShowCustomCallout:showCustomCallout animated:NO];
}

-(BOOL)calloutVisible {
    return self._showCustomCallout;
}


- (void)setShowCustomCallout:(BOOL)showCustomCallout animated:(BOOL)animated
{
    if (self._showCustomCallout == showCustomCallout) return;
    
    self._showCustomCallout = showCustomCallout;
    
    void (^animationBlock)(void) = nil;
    void (^completionBlock)(BOOL finished) = nil;
    
    CGAffineTransform hiddenTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.01, 0.01), CGAffineTransformMakeTranslation(0, CALLOUT_HEIGHT/2));
    CGAffineTransform secondTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.2, 1.2), CGAffineTransformMakeTranslation(0, -10));//-10 help triangle not to cover avatar with scale 1.2
    
    if (self._showCustomCallout) {
        self.calloutView.alpha = 0.0f;
        self.calloutView.transform = hiddenTransform;
        
        animationBlock = ^{
            self.calloutView.alpha = 1.0f;
            self.calloutView.transform = secondTransform;
            [self addSubview:self.calloutView];
        };
        completionBlock = ^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.2f animations:^{
                    self.calloutView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL f) {
                    [self onCustomCalloutFinishedShowing];
                }];
            } else {
                [self onCustomCalloutFinishedShowing];
            }
        };
        
    } else {
        animationBlock = ^{
            self.calloutView.alpha = 0.0f;
            self.calloutView.transform = hiddenTransform;
        };
        completionBlock = ^(BOOL finished) {
            [self onCustomCalloutFinishedDisappearing];
        };
    }
    
    if (animated) {
        [UIView animateWithDuration:0.5f animations:animationBlock completion:completionBlock];
        
    } else {
        animationBlock();
        completionBlock(YES);
    }
}


@end