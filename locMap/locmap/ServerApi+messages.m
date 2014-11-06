//
//  ServerApi+messages.m
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "ServerApi+messages.h"
#import "LocalStorage.h"

@implementation ServerApi (messages)


-(void)reportLocationToServer:(CLLocation*)newLocation
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationPostLocation withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/location", [self getServerURL], [self getUserId]];
    NSString *data = [NSString stringWithFormat:@"{\"location\":{\"lat\":%f, \"lon\":%f, \"acc\":%f}}", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy];
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationPostLocation];
}

-(void)changeVisibility:(BOOL)visible
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationChangeVisibility withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/visibility", [self getServerURL], [self getUserId]];
    NSString* data = [NSString stringWithFormat:@"{\"visibility\":%@}", (visible) ? @"true" : @"false"];
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationChangeVisibility];
}


// signup to the server
-(void)signupWithEmail:(NSString*)email andDeviceId:(NSString*)deviceId
{
    if ([self loggedIn]) {
        NSLog(@"!!! Very strange - second signup detected");
    }
    
    NSString* langCode = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];//@"en-GB";//language: 'fi-FI'
    
    NSString* URL = [NSString stringWithFormat:@"%@/signup", [self getServerURL]];
    NSString* data = [NSString stringWithFormat:@"{\"email\":\"%@\", \"device_id\":\"%@\", \"language\" : \"%@\"}", email, deviceId, langCode];
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationSignup];
}

// query latest version of dashboard from server for logged in user
-(void)getDashboardFromServer
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationDashboard withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
   
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/dashboard", [self getServerURL], [self getUserId]];
    
    [self sendData:nil toURL:URL forOperationType:ServerOperationDashboard];
    
}

// disallow user to see me
-(void)disallowContactToSeeMe:(NSString*)userID
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationDisallow withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/allow/%@", [self getServerURL], [self getUserId], userID];
    
    [self sendData:nil toURL:URL forOperationType:ServerOperationDisallow];
}


// allow user with email to see me
-(void)allowContactToSeeMe:(NSArray*)emails
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationAllow withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/allow", [self getServerURL], [self getUserId]];
    NSString *data = @"{\"emails\":[";
    int count = 0;
    for(NSString* em in emails) {
        if (count) {
            data = [NSString stringWithFormat:@"%@, \"%@\"", data, em];
        } else {
            data = [NSString stringWithFormat:@"%@\"%@\"", data, em];
        }
        ++count;
    }
    
    data = [NSString stringWithFormat:@"%@]}", data];
    
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationAllow];
    
}


// register APN token on server
-(void)registerAPNToken:(NSString*)token
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationRegisterAPN withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/apnToken", [self getServerURL], [self getUserId]];
    
    NSString* data = [NSString stringWithFormat:@"{\"apnToken\":\"%@\"}", token];
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:requestData toURL:URL forOperationType:ServerOperationRegisterAPN];
}

-(void)requestLocationUpdates
{
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationRequestLocationUpdates withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    [LocalStorage saveLastLocationUpdateRequestTime:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/update/locations", [self getServerURL], [self getUserId]];
    
    [self sendData:nil toURL:URL forOperationType:ServerOperationRequestLocationUpdates];
}



// create new place with
-(void)createPlaceWithName:(NSString*)name image:(NSString*)img lat:(double)lat lon:(double)lon radius:(double)radius {

    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationAddPlace withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/place", [self getServerURL], [self getUserId]];
    
    NSString* data = [NSString stringWithFormat:@"{\"name\":\"%@\", \"lat\":%f, \"lon\":%f, \"rad\":%f, \"img\":\"%@\"}", name, lat, lon, radius, img];
    
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationAddPlace];
    
    
}

// edit place details
-(void)updatePlaceWithID:(NSString*)placeID newName:(NSString*)name newImage:(NSString*)img newLat:(double)lat newLon:(double)lon newRadius:(double)radius {
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationEditPlace withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/place/%@", [self getServerURL], [self getUserId], placeID];
    
    NSString* data = [NSString stringWithFormat:@"{\"name\":\"%@\", \"lat\":%f, \"lon\":%f, \"rad\":%f, \"img\":\"%@\"}", name, lat, lon, radius, img];
    
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:requestData toURL:URL forOperationType:ServerOperationEditPlace];
}


// delete place
-(void)deletePlaceWithID:(NSString*)placeID {
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationDeletePlace withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/place/%@", [self getServerURL], [self getUserId], placeID];
    
    [self sendData:nil toURL:URL forOperationType:ServerOperationDeletePlace];
    
}


// returns all places info for a user
-(void)getPlaces {
    if (![self loggedIn]) {
        [self.delegate serverApi:self finishedOperation:ServerOperationGetPlaces withResult:NO withResponse:@{@"error": @"User not logged in?"}];
        return;
    }
    
    NSString* URL = [NSString stringWithFormat:@"%@/user/%@/places", [self getServerURL], [self getUserId]];
    
    [self sendData:nil toURL:URL forOperationType:ServerOperationGetPlaces];
}


@end
