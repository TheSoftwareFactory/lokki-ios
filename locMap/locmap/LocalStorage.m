//
//  LocalStorage.m
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocalStorage.h"

#define SAVED_DATA_KEY @"SAVEDDATA"

static NSMutableDictionary* gCachedData = nil;

@implementation LocalStorage

+(void)clearCache {
    if (gCachedData) {
        gCachedData = nil;
    }
}

+(void)setValue:(id)value forKey:(NSString *)key
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (!gCachedData) {
        [self getValueForKey:key];
    }
    
    if (value != nil) {
        [gCachedData setValue:value forKey:key];
    } else {
        [gCachedData removeObjectForKey:key];
    }
    
    [userDefaults setObject:gCachedData forKey:SAVED_DATA_KEY];
    [userDefaults synchronize];
}


+(id)getValueForKey:(NSString *)key
{
    if (!gCachedData) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        gCachedData = [[userDefaults dictionaryForKey:SAVED_DATA_KEY] mutableCopy];
        if (!gCachedData) {
            gCachedData = [[NSMutableDictionary alloc] init];
        }
    }
    return gCachedData[key];
}

+(void)deleteStoredDataForKey:(NSString *)key {
    [LocalStorage setValue:nil forKey:key];
}


+(int)getMapType
{
    NSNumber* number = [LocalStorage getValueForKey:@"MapType"];
    if (number)
    {
        return [number intValue];
    }
    else
    {
        return 2;//MKMapTypeHybrid
    }
}

+(void)setMapType:(int)type
{
    NSNumber* number = [NSNumber numberWithInt:type];
    return [LocalStorage setValue:number forKey:@"MapType"];
    
}


+(BOOL)isReportingEnabled
{
    return ![[LocalStorage getValueForKey:@"ReportingEnabled"]  isEqual:@"NO"];
}

+(void)setReportingEnabled:(BOOL)enabled
{
    [LocalStorage setValue:(enabled?@"YES":@"NO") forKey:@"ReportingEnabled"];
}

+(BOOL)privacyPolicyAccepted
{
    return [[LocalStorage getValueForKey:@"PrivacyPolicyAccepted"]  isEqual:@"YES"];
}

+(void)acceptPrivacyPolicy
{
    [LocalStorage setValue:@"YES" forKey:@"PrivacyPolicyAccepted"];
}

    
+(void)setShowOnMap:(BOOL)showOnMap forUser:(NSString*)userID
{
    NSString* name = [NSString stringWithFormat:@"ShowUserOnMap_%@", userID];
    [LocalStorage setValue:(showOnMap?@"YES":@"NO") forKey:name];
}

+(BOOL)getShowOnMapForUser:(NSString*)userID
{
    NSString* name = [NSString stringWithFormat:@"ShowUserOnMap_%@", userID];
    return ![[LocalStorage getValueForKey:name] isEqual:@"NO"];// missing means YES
}



+(NSString*)getLoggedInUserId
{
    return [LocalStorage getValueForKey:@"LoggedInUserId"];
   
}

+(NSString*)getAuthToken
{
    return [LocalStorage getValueForKey:@"AuthToken"];
}

+(void)setLoggedInUserId:(NSString*)userId withAuthToken:(NSString*)authToken
{
    [LocalStorage setValue:userId forKey:@"LoggedInUserId"];
    [LocalStorage setValue:authToken forKey:@"AuthToken"];
}

+(void)clearLoggedInUser {
    [LocalStorage setValue:nil forKey:@"LoggedInUserId"];
    [LocalStorage setValue:nil forKey:@"AuthToken"];
}


+(NSDictionary*)getDashboard
{
    return [LocalStorage getValueForKey:@"Dashboard"];
}


+(void)setDashboard:(NSDictionary*)dashboard
{
    [LocalStorage setValue:dashboard forKey:@"Dashboard"];
}


+(NSDictionary*)getPlaces {
    return [LocalStorage getValueForKey:@"Places"];
}


+(void)setPlaces:(NSDictionary*)places {
    [LocalStorage setValue:places forKey:@"Places"];
}

+(NSString*)getEmailByUserID:(NSString*)userID
{
    NSDictionary* dashboard = [LocalStorage getDashboard];
    if (dashboard) {
        NSString* email = dashboard[@"idmapping"][userID];
        return email;
    }
    return nil;
}


+(NSData*)getAvatarDataByEmail:(NSString*)email
{
    NSDictionary* d = [LocalStorage getValueForKey:@"CachedAvatarsByEmail"];
    return [d objectForKey:email];
}

+(NSData*)getAvatarDataByUserID:(NSString*)userID
{
    NSString* email = [LocalStorage getEmailByUserID:userID];
    if (!email) {
        return nil;
    }
    return [LocalStorage getAvatarDataByEmail:email];
}
    
    
+(NSString*)getUserNameByEmail:(NSString*)email
{
    NSDictionary* d = [LocalStorage getValueForKey:@"CachedNamesByEmail"];
    if ([d objectForKey:email]) {
        return [d objectForKey:email];
    }
    return nil;
}
    
+(NSString*)getUserNameByUserID:(NSString*)userID
{
    NSString* email = [LocalStorage getEmailByUserID:userID];
    if (!email) {
        return nil;
    }
    return [LocalStorage getUserNameByEmail:email];
}


+(void)setAccountDataFromDict:(NSDictionary*)dict
{
    NSDictionary* dAvatars = [LocalStorage getValueForKey:@"CachedAvatarsByEmail"];
    if (!dAvatars) {
        dAvatars = [[NSDictionary alloc] init];
    }
    NSMutableDictionary* mdAvatars = [dAvatars mutableCopy];

    NSDictionary* dUserNames = [LocalStorage getValueForKey:@"CachedNamesByEmail"];
    if (!dUserNames) {
        dUserNames = [[NSDictionary alloc] init];
    }
    NSMutableDictionary* mdUserNames = [dUserNames mutableCopy];

    for(NSString* email in dict) {
        if (dict[email][@"imgData"]) {
            mdAvatars[email] = dict[email][@"imgData"];
        }
        if (dict[email][@"name"]) {
            mdUserNames[email] = dict[email][@"name"];
        }
    }

    [LocalStorage setValue:mdAvatars forKey:@"CachedAvatarsByEmail"];
    [LocalStorage setValue:mdUserNames forKey:@"CachedNamesByEmail"];
}
    


+(NSArray*)getPeopleICanSee
{
    NSArray* arr = [LocalStorage getValueForKey:@"PeopleICanSee"];
    if (!arr) {
        return @[];
    }
    return arr;
}


+(NSArray*)getPeopleIDontWantToSee
{
    NSArray* arr = [LocalStorage getValueForKey:@"PeopleIDontWantToSee"];
    if (!arr) {
        return @[];
    }
    return arr;
}


+(NSArray*)getPeopleIAllowedToSeeMe
{
    NSArray* arr = [LocalStorage getValueForKey:@"PeopleIAllowedToSeeMe"];
    if (!arr) {
        return @[];
    }
    return arr;
}



+(void)setPeopleICanSee:(NSArray*)people
{
    [LocalStorage setValue:people forKey:@"PeopleICanSee"];
}

+(void)setPeopleIDontWantToSee:(NSArray*)people
{
    [LocalStorage setValue:people forKey:@"PeopleIDontWantToSee"];
}


+(void)setPeopleIAllowedToSeeMe:(NSArray*)people
{
    [LocalStorage setValue:people forKey:@"PeopleIAllowedToSeeMe"];
}


+(void)saveLastLocationUpdateRequestTime:(NSDate*)date
{
    [LocalStorage setValue:date forKey:@"LastLocationUpdateRequestTime"];
}

+(NSDate*)getLastLocationUpdateRequestTime
{
    return [LocalStorage getValueForKey:@"LastLocationUpdateRequestTime"];
}


@end
