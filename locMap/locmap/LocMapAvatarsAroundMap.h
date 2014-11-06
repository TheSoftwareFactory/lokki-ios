//
//  LocMapAvatarsAroundMap.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/13/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol LocMapAvatarsAroundMapDelegate
    - (void)onAvatarAroundMapClickForUserID:(NSString*)userID;
@end



// takes care of showing buttons around the map for invisible avatars
@interface LocMapAvatarsAroundMap : NSObject

    @property (strong) id<LocMapAvatarsAroundMapDelegate> delegate;

    // designated initializer
    -(id)initForMap:(MKMapView*)map withDelegate:(id<LocMapAvatarsAroundMapDelegate>)delegate;

    // recreate buttons
    -(void)recreateButtons;

    // reload avatars on next update
    -(void)reloadAvatarForUserID:(NSString*)userID;

@end
