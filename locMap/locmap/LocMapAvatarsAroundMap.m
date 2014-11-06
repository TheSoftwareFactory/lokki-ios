//
//  LocMapAvatarsAroundMap.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapAvatarsAroundMap.h"
#import "Users.h"
#import "AvatarAroundMapInfo.h"

//#define AVATARS_AROUND_MAP_DISABLED

@interface LocMapAvatarsAroundMap() <onAvatarClickHandler>
    @property (weak) MKMapView* map;
    @property (strong) NSDictionary* buttons;// key-userID, value-AvatarAroundMapInfo*

    @property  (strong) NSTimer* updateUIDuringRegionChangeTimer;// hack to get region update events during scrolling
@end



@implementation LocMapAvatarsAroundMap

-(id)initForMap:(MKMapView*)map  withDelegate:(id<LocMapAvatarsAroundMapDelegate>)delegate
{
    self = [super init];
    self.delegate = delegate;
#ifdef AVATARS_AROUND_MAP_DISABLED
    return self;
#endif
    self.buttons = [[NSDictionary alloc] init];
    self.map = map;
    
    [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(dashboardUpdated:) name:@"DashboardUpdated" object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(mapPositionUpdated:) name:@"MapRegionDidChange" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(mapPositionUpdateStarted:) name:@"MapRegionWillChange" object:nil];
    
    [self dashboardUpdated:nil];//precreate
    
    return self;
}

- (void) dealloc
{
#ifdef AVATARS_AROUND_MAP_DISABLED
    return;
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dashboardUpdated:(NSNotification *) notification
{
    if (self.updateUIDuringRegionChangeTimer) {
        [self.updateUIDuringRegionChangeTimer invalidate];
        self.updateUIDuringRegionChangeTimer = nil;
        
    }
    [self recreateButtons];
}

-(void)mapPositionUpdateStarted:(NSNotification*)notification
{
    if (!self.updateUIDuringRegionChangeTimer) {
        self.updateUIDuringRegionChangeTimer = [NSTimer timerWithTimeInterval:0.5
                                                        target:self
                                                        selector:@selector(recreateButtons)
                                                        userInfo:nil
                                                        repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.updateUIDuringRegionChangeTimer forMode:NSRunLoopCommonModes];
    }
}


- (void)mapPositionUpdated:(NSNotification *) notification
{
    [self recreateButtons];
}

-(void)onAvatarClick:(id)button
{
    for(NSString* userID in self.buttons) {
        AvatarAroundMapInfo* info = self.buttons[userID];
        if (info.button == button) {
            [self.delegate onAvatarAroundMapClickForUserID:info.userID];
        }
    }
}

- (UIView*)getViewForAvatars
{
    return self.map;
}

// reload avatars on next update
-(void)reloadAvatarForUserID:(NSString*)userID
{
    for (NSString* uID in self.buttons) {
        if ([uID isEqualToString:userID]) {
            AvatarAroundMapInfo* info = self.buttons[uID];
            [info reloadAvatarOnNextUpdate];
        }
    }
}


-(void)recreateButtons
{
#ifdef AVATARS_AROUND_MAP_DISABLED
    return;
#endif
    
    Users* u = [[Users alloc] init];
    NSArray* users = [u getUsersIncludingMyself:YES excludingOnesIDontWantToSee:YES];

    // hide disappeared
    for(NSString* userID in self.buttons) {
        BOOL found = NO;
        AvatarAroundMapInfo* info = self.buttons[userID];
        for(UserData* user in users) {
            if ([user.userID isEqualToString:info.userID]) {
                found = YES;
                break;
            }
        }
        if (!found) {
            [info hideButtonIntoPosition:info.button.center];
        }
        
    }

    NSArray* visibleButtons = [[NSArray alloc] init];

    // add new and update existing
    for(UserData* user in users) {
        if (![self.buttons objectForKey:user.userID])
        {
            NSMutableDictionary* md = [self.buttons mutableCopy];
            md[user.userID] = [[AvatarAroundMapInfo alloc] initButtonForUserID:user.userID withActionTarget:self];
            self.buttons = [md copy];
        }
        
        AvatarAroundMapInfo* info = self.buttons[user.userID];
        [info showForUser:user onMap:self.map avoidOverlappingWithButtons:visibleButtons];
        if (info.buttonShown) {
            visibleButtons = [visibleButtons arrayByAddingObject:info.button];
        }
    }
    
    
    
    
}



@end
