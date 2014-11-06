//
//  AvatarAroundMapInfo.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "AvatarAroundMapInfo.h"
#import "FSConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "LocalStorage.h"
#import "LocatingInProgressAnimationAroundAvatar.h"


typedef BOOL (^PointFilter)(CGPoint);
@class LocMapAvatarsAroundMap;

@interface AvatarAroundMapInfo() <LocatingInProgressAnimationAroundAvatarDataSource>
    @property (strong) LocatingInProgressAnimationAroundAvatar* locatingInProgressAnimation;

    @property BOOL buttonHasDefaultImage;

@end

@implementation AvatarAroundMapInfo

-(id)initButtonForUserID:(NSString*)userID withActionTarget:(id<onAvatarClickHandler>)target {
    self = [super init];
    _userID = userID;
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.frame = CGRectMake(0, 0, AVATAR_WIDTH, AVATAR_WIDTH);
    [self.button setImage:[UIImage imageNamed:@"defaultAvatar"] forState:UIControlStateNormal];
    [self.button addTarget:target action:@selector(onAvatarClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.buttonHasDefaultImage = YES;
    
    self.button.hidden = YES;
    UIView* v = [target getViewForAvatars];
    [v addSubview:self.button];
    
    self.locatingInProgressAnimation = [[LocatingInProgressAnimationAroundAvatar alloc] initWithFrame:CGRectMake(0, 0, AVATAR_WIDTH, AVATAR_WIDTH) forView:self.button delegate:self];
        
    return self;
}

-(BOOL)avatarVisible:(CGPoint)pos inRect:(CGRect)rect {
    if (pos.y <= 0 || pos.x + PIN_WIDTH/2 <= 0) {
        return NO;
    }
    if (pos.y - PIN_HEIGHT >= rect.size.height || pos.x - PIN_WIDTH/2 >= rect.size.width) {
        return NO;
    }
    return YES;
}

-(void)reloadAvatarOnNextUpdate {
    self.buttonHasDefaultImage = YES;
}


-(void)showForUser:(UserData*)user onMap:(MKMapView*)map avoidOverlappingWithButtons:(NSArray*)buttons {
    CGPoint p = [map convertCoordinate:user.coord toPointToView:self.button.superview];
    //p.y -= PIN_HEIGHT*3/4;
    CGRect viewRect = self.button.superview.frame;
    viewRect.size.height -= 44;// bottom toolbar
    
    if ([self avatarVisible:p inRect:viewRect]) {
        p.y -= PIN_HEIGHT*3/4;
        [self hideButtonIntoPosition:p];
        return;
    }
    _buttonShown = YES;
    
    CGRect intersectRect = CGRectMake(0, 0, viewRect.size.width, viewRect.size.height);
    CGPoint pos = [AvatarAroundMapInfo findInterceptFromSource:CGPointMake(viewRect.size.width/2, viewRect.size.height/2) andTouch:p withinBounds:intersectRect];

    // make it a bt inside border
    if (pos.x < 1) {
        pos.x = -PIN_WIDTH/8;
        pos.y -= PIN_HEIGHT/2;
    }
    if (pos.x > viewRect.size.width - PIN_WIDTH/2) {
        pos.x = viewRect.size.width - 5*PIN_WIDTH/8;
        pos.y -= PIN_HEIGHT/2;
    }
    if (pos.y < 1) {
        pos.y = -PIN_HEIGHT/8;
    }
    if (pos.y > viewRect.size.height - PIN_HEIGHT/2) {
        pos.y = viewRect.size.height - 3*PIN_HEIGHT/8;
    }
    
    if (user.imgData && self.buttonHasDefaultImage) {
        self.buttonHasDefaultImage = NO;
        [self.button setImage:[UIImage imageWithData:user.imgData] forState:UIControlStateNormal];
    } else if (!user.imgData && self.buttonHasDefaultImage) {
        self.buttonHasDefaultImage = NO;
        [self.button setImage:[[FSConstants instance] getDefaultAvatarForUserWithName:user.userName] forState:UIControlStateNormal];
        
    }
    self.button.imageView.layer.cornerRadius = AVATAR_WIDTH/2;
    self.button.imageView.layer.borderWidth = AVATAR_BORDER_WIDTH;
    self.button.imageView.layer.borderColor = [self getAvatarColorForUser:user];
    self.button.imageView.clipsToBounds = YES;

    BOOL wasHidden =  self.button.hidden;
    self.button.hidden = NO;
    
    pos = [self getForPoint:pos pointNotOverlappingWithButtons:buttons];

    // if was hidden then set position immediately otherwize animate move
    if (wasHidden) {
        self.button.frame = CGRectMake(pos.x, pos.y, AVATAR_WIDTH, AVATAR_WIDTH);
        self.button.alpha = 0;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        // slide when location changes
        if (!wasHidden) {
            self.button.frame = CGRectMake(pos.x, pos.y, AVATAR_WIDTH, AVATAR_WIDTH);
        }
        self.button.alpha = 1;
    }];
    
    [self.locatingInProgressAnimation updateLocatingInProgress];
}

-(BOOL)isPoint:(CGPoint)p overlappingWithButtons:(NSArray*)buttons orOutOfBounds:(CGRect)bounds{
    CGRect pos = CGRectMake(p.x, p.y, AVATAR_WIDTH, AVATAR_WIDTH);

    if (!CGRectContainsRect(bounds, pos) && !CGRectIntersectsRect(bounds, pos)) {
        return YES;
    }

    for(UIButton* b in buttons) {
        CGRect r = b.frame;
        if (CGRectIntersectsRect(pos, r)) {
            return YES;
        }
    }
    return NO;
    
}

-(CGPoint)getOverlappingPointIncrement:(CGPoint)p withBounds:(CGRect)bounds
{
    if (p.y < 0 || p.y > bounds.size.height - AVATAR_WIDTH) {
        return CGPointMake(10, 0);
    }
    return CGPointMake(0, 10);
}

-(CGPoint)getForPoint:(CGPoint)p pointNotOverlappingWithButtons:(NSArray*)buttons
{
    CGRect viewRect = self.button.superview.frame;
    viewRect.size.height -= 44;// bottom toolbar
    viewRect = CGRectMake(0, 0, viewRect.size.width, viewRect.size.height);
    CGPoint pos = p;

    int iteration = 1;
    CGPoint inc = [self getOverlappingPointIncrement:p withBounds:viewRect];
    while([self isPoint:pos overlappingWithButtons:buttons orOutOfBounds:viewRect]) {
        pos.x = p.x + inc.x*iteration;
        pos.y = p.y + inc.y*iteration;
        if (![self isPoint:pos overlappingWithButtons:buttons  orOutOfBounds:viewRect]) {
            return pos;
        }
        pos.x = p.x - inc.x*iteration;
        pos.y = p.y - inc.y*iteration;
        
        if (++iteration > 20) {
            return p;// return original
        }
    }
    
    
    
    return pos;
}

// button flies into newPosition and disappears
-(void)hideButtonIntoPosition:(CGPoint)newPosition {
    _buttonShown = NO;
    if (self.button.hidden) {
        return;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.button.alpha = 0;
        self.button.frame = CGRectMake(newPosition.x, newPosition.y, AVATAR_WIDTH/5, AVATAR_WIDTH/5);
    } completion:^(BOOL finished) {
        if (finished) {
            self.button.hidden = YES;
        }
    }];
    
}

-(CGColorRef)getAvatarColorForUser:(UserData*)user {
    if (user.accuracy > 100 || [user.userLastReportDate timeIntervalSinceNow] < -60*60) {
        return [[[FSConstants instance] orange] CGColor];
    }
    
    if ([[LocalStorage getLoggedInUserId] isEqualToString:user.userID]) {
        return [[[FSConstants instance] green] CGColor];
    }
    return [[[FSConstants instance] blue] CGColor];
}

-(NSDate*)getUserLastReportDateForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation {
    Users* users = [[Users alloc] init];
    
    NSDate* d = [users getUserLastReportDate:self.userID];
    if (d) {
        return d;
    }
    return [NSDate dateWithTimeIntervalSince1970:0];
}

-(BOOL)isUserReportingForLocatingInProgressAnimationAroundAvatar:(LocatingInProgressAnimationAroundAvatar*)animation {
    Users* users = [[Users alloc] init];
    return [users isUserReporting:self.userID];
}



+ (CGPoint)findInterceptFromSource:(CGPoint)source andTouch:(CGPoint)touch withinBounds:(CGRect)bounds
{
    CGFloat boundsLeftX = bounds.origin.x;
    CGFloat boundsRightX = bounds.size.width;
    CGFloat boundsBottomY = bounds.origin.y;
    CGFloat boundsTopY = bounds.size.height;
    
    if (source.x == touch.x && source.y == touch.y) {
        return CGPointMake(-99999.0, -99999.0);
    } else if (source.x == touch.x) {
        return CGPointMake(source.x, (source.y > touch.y)?boundsTopY:boundsBottomY);
    } else if (source.y == touch.y) {
        return CGPointMake((source.x > touch.x)?boundsLeftX:boundsRightX, source.y);
    } else {
        CGFloat slope = (touch.y - source.y) / (touch.x - source.x);
        CGFloat b = source.y - (slope * source.x);
        CGFloat y = slope * boundsLeftX + b;
        CGPoint p1 = CGPointMake(boundsLeftX, y);
        if ([self point:p1 hasRightDirectionForTouch:touch andSource:source andInBounds:bounds]) {
            return p1;
        }
        
        y = slope * boundsRightX + b;
        p1 = CGPointMake(boundsRightX, y);
        if ([self point:p1 hasRightDirectionForTouch:touch andSource:source andInBounds:bounds]) {
            return p1;
        }
        
        CGFloat x = (boundsBottomY - b) / slope;
        p1 = CGPointMake(x, boundsBottomY);
        if ([self point:p1 hasRightDirectionForTouch:touch andSource:source andInBounds:bounds]) {
            return p1;
        }
        
        x = (boundsTopY - b) / slope;
        p1 = CGPointMake(x, boundsTopY);
//        if ([self point:p1 hasRightDirectionForTouch:touch andSource:source andInBounds:bounds]) {
            return p1;
  //      }
    }
}

+(BOOL)point:(CGPoint)point hasRightDirectionForTouch:(CGPoint)touch andSource:(CGPoint)source andInBounds:(CGRect)bounds {
    if (point.x < bounds.origin.x || point.x > (bounds.size.width) || point.y < bounds.origin.y || point.y > bounds.size.height) {
        return NO;
    }
    
    CGFloat xDelta = touch.x - source.x;
    if (xDelta >= 0.0) {
        if (point.x < source.x) {
            return NO;
        }
    } else {
        if (point.x >= source.x) {
            return NO;
        }
    }
    
    CGFloat yDelta = touch.y - source.y;
    if (yDelta >= 0.0) {
        if (point.y < source.y) {
            return NO;
        }
    } else {
        if (point.y >= source.y) {
            return NO;
        }
    }
    return YES;
}


@end


