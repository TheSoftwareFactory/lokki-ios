//
//  ServerApi+messages.h
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "ServerApi.h"

@interface ServerApi (messages)

    // change "i'm visible" global flag on server
    -(void)changeVisibility:(BOOL)visible;
    
    // report new location to the server
    -(void)reportLocationToServer:(CLLocation*)newLocation;

    // signup to the server
    -(void)signupWithEmail:(NSString*)email andDeviceId:(NSString*)deviceId;

    // query latest version of dashboard from server for logged in user
    -(void)getDashboardFromServer;

    // allow user with emails to see me
    -(void)allowContactToSeeMe:(NSArray*)emails;//array of NSString*

    // disallow user to see me
    -(void)disallowContactToSeeMe:(NSString*)userID;
    
    // register APN token on server
    -(void)registerAPNToken:(NSString*)token;
    
    // requests location updates from all users I can see
    -(void)requestLocationUpdates;



    // create new place with
    -(void)createPlaceWithName:(NSString*)name image:(NSString*)img lat:(double)lat lon:(double)lon radius:(double)radius;

    // edit place details
    -(void)updatePlaceWithID:(NSString*)placeID newName:(NSString*)name newImage:(NSString*)img newLat:(double)lat newLon:(double)lon newRadius:(double)radius;

    // delete place
    -(void)deletePlaceWithID:(NSString*)placeID;

    // returns all places info for a user
    -(void)getPlaces;

@end
