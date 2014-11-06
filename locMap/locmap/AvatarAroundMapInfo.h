//
//  AvatarAroundMapInfo.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Users.h"

@protocol onAvatarClickHandler <NSObject>
    - (void)onAvatarClick:(id)button;
    - (UIView*)getViewForAvatars;
@end


@interface AvatarAroundMapInfo : NSObject
    @property (strong, readonly) UIButton* button;
    @property (strong, readonly) NSString* userID;

    @property (readonly) BOOL buttonShown;//YES if button is shown or showing. NO if it is hidden or hiding

    //designated initializer
    -(id)initButtonForUserID:(NSString*)userID withActionTarget:(id<onAvatarClickHandler>)target;

    -(void)showForUser:(UserData*)user onMap:(MKMapView*)map avoidOverlappingWithButtons:(NSArray*)buttons;//buttons is array of UIButton*

    -(void)hideButtonIntoPosition:(CGPoint)newPosition;

    -(void)reloadAvatarOnNextUpdate;

@end
