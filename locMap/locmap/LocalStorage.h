//
//  LocalStorage.h
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalStorage : NSObject

+(void)clearCache;// clear memory

+(void)setValue:(id)value forKey:(NSString *)key;
+(id)getValueForKey:(NSString *)key;
+(void)deleteStoredDataForKey:(NSString *)key;

+(int)getMapType;
+(void)setMapType:(int)type;

+(BOOL)isReportingEnabled;
+(void)setReportingEnabled:(BOOL)enabled;

+(BOOL)privacyPolicyAccepted;
+(void)acceptPrivacyPolicy;

+(NSString*)getLoggedInUserId;
+(NSString*)getAuthToken;
+(void)setLoggedInUserId:(NSString*)userId withAuthToken:(NSString*)authToken;
+(void)clearLoggedInUser;



+(NSDictionary*)getDashboard;
+(void)setDashboard:(NSDictionary*)dashboard;

+(NSDictionary*)getPlaces;
+(void)setPlaces:(NSDictionary*)places;


+(NSString*)getEmailByUserID:(NSString*)userID;

+(NSData*)getAvatarDataByEmail:(NSString*)email;// returns avatar data cached by setAccountDataFromDict for the same email. returns nil if not cached
+(NSData*)getAvatarDataByUserID:(NSString*)userID;
+(NSString*)getUserNameByEmail:(NSString*)email;// returns cached user name. if cached email not found - returns nil
+(NSString*)getUserNameByUserID:(NSString*)userID;

+(void)setAccountDataFromDict:(NSDictionary*)dict;//cache dict returned by Contacts

+(NSArray*)getPeopleICanSee;// returns array of String* - all id's of people who allowed me to see them (cached from dashboard)
+(NSArray*)getPeopleIDontWantToSee;// returns array of String* - all id's of people whom user does not want to see allowed me to see them (cached from settings)
+(NSArray*)getPeopleIAllowedToSeeMe;// returns array of String* - all id's of people whom I allowed to see me (cached from dashboard)

+(void)setPeopleICanSee:(NSArray*)people;// array of String* - all id's of people who allowed me to see them (cached from dashboard)
+(void)setPeopleIDontWantToSee:(NSArray*)people;// array of String* - all id's of people whom user does not want to see allowed me to see them (cached from settings)
+(void)setPeopleIAllowedToSeeMe:(NSArray*)people;//  array of String* - all id's of people whom I allowed to see me (cached from dashboard)

    
+(void)setShowOnMap:(BOOL)showOnMap forUser:(NSString*)userID;
+(BOOL)getShowOnMapForUser:(NSString*)userID;

+(void)saveLastLocationUpdateRequestTime:(NSDate*)date;
+(NSDate*)getLastLocationUpdateRequestTime;



@end
