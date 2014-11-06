//
//  Users.m
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "Users.h"
#import "LocalStorage.h"

@interface Users ()


@end

@implementation Users
    
-(BOOL)canShowUserOnMap:(NSString*)userID
{
    return [LocalStorage getShowOnMapForUser:userID];
}

-(BOOL)userIsVisible:(NSDictionary*)userInfo {
    if (!userInfo) {
        return NO;
    }
    NSNumber* n = userInfo[@"visibility"];
    if (!n) {
        return NO;
    }
    NSInteger vis = [n integerValue];
    return (vis == 1);
}

-(NSArray*)addUser:(NSString*)userID withEmail:(NSString*)email fromDashboardData:(NSDictionary*)dashboard toArray:(NSArray*)result
{
    UserData* u;
    BOOL userAlreadyExists = NO;
    for(UserData* ud in result) {
        if ([ud.userID isEqualToString:userID]) {
            u = ud;
            userAlreadyExists = YES;
            break;
        }
    }
    if (!userAlreadyExists) {
        u = [[UserData alloc] init];
    }

    
    u.showOnMap = [self canShowUserOnMap:userID];
    
    u.userID = userID;
    u.userEmail = email;
    u.userName = [LocalStorage getUserNameByEmail:email];
    if (!u.userName) {
        u.userName = email;
    }
    u.imgData = [LocalStorage getAvatarDataByEmail:email];
    u.isReporting = [self userIsVisible:dashboard];
    
    NSNumber* lastReport = [dashboard[@"location"] valueForKey:@"time"];
    NSNumber* lat = [dashboard[@"location"] valueForKey:@"lat"];
    NSNumber* lon = [dashboard[@"location"] valueForKey:@"lon"];
    NSNumber* acc = [dashboard[@"location"] valueForKey:@"acc"];
    if (lat && lon) {
        u.coord = CLLocationCoordinate2DMake([lat floatValue], [lon floatValue]);
    } else {
        u.coord = CLLocationCoordinate2DMake(0, 0);
    }
    if (acc) {
        u.accuracy = [acc floatValue];
    } else {
        u.accuracy = 100;// unknown
    }
    
    u.userLastReportDate = [NSDate dateWithTimeIntervalSince1970:[lastReport doubleValue]/1000];// we are getting miliseconds from server
    
    // no coords - no user
    if (u.coord.latitude == 0 && u.coord.longitude == 0) {
        return result;
    }
    
    if (userAlreadyExists) {
        return result;
    }
    
    return [result arrayByAddingObject:u];
}

    
-(NSArray*)addUserWhoCanSeeMe:(NSString*)userID withEmail:(NSString*)email toArray:(NSArray*)result
{
    UserData* u;
    BOOL userAlreadyExists = NO;
    for(UserData* ud in result) {
        if ([ud.userID isEqualToString:userID]) {
            u = ud;
            userAlreadyExists = YES;
            break;
        }
    }
    if (!userAlreadyExists) {
        u = [[UserData alloc] init];
    }
    
    u.canSeeMe = YES;
    u.userID = userID;
    u.userEmail = email;
    u.userName = [LocalStorage getUserNameByEmail:email];
    if (!u.userName) {
        u.userName = email;
    }
    u.imgData = [LocalStorage getAvatarDataByEmail:email];
    if (!userAlreadyExists) {
        u.userLastReportDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    if (userAlreadyExists) {
        return result;
    }
    return [result arrayByAddingObject:u];
}

    
    
// returns array of UserData objects for all current users
-(NSArray*)getUsersIncludingMyself:(BOOL)includeMyself excludingOnesIDontWantToSee:(BOOL)excludingOnesIDontWantToSee
{
    NSDictionary* dashboard = [LocalStorage getDashboard];
    NSArray* users = [[NSArray alloc] init];
    
    if (includeMyself) {
        //me
        NSString* myUserID = [LocalStorage getLoggedInUserId];
        if (!myUserID) {
            return users;// not logged in yet
        }
        NSString* myEmail = dashboard[@"idmapping"][myUserID];
        if (!myEmail) {
            myEmail = @"Unknown";
        }
    
        users = [self addUser:myUserID withEmail:myEmail fromDashboardData:dashboard toArray:users];
    }

    for(NSString* uid in dashboard[@"icansee"]) {
        NSDictionary* user = dashboard[@"icansee"][uid];
        NSString* email = dashboard[@"idmapping"][uid];
        
        if (!email) {
            email = @"Unknown";
        }
        if (!excludingOnesIDontWantToSee || [self canShowUserOnMap:uid]) {
            users = [self addUser:uid withEmail:email fromDashboardData:user toArray:users];
        }
    }


    
//    NSArray* ret = [[NSArray alloc] initWithObjects:u1, u2, nil];
    return users;
}

-(NSArray*)getUsersIncludingPeopleWhoCanSeeMe:(BOOL)includeMyself
{
    NSArray* users = [self getUsersIncludingMyself:includeMyself excludingOnesIDontWantToSee:NO];
    NSDictionary* dashboard = [LocalStorage getDashboard];
    
    for(NSString* uid in dashboard[@"canseeme"]) {
        NSString* email = dashboard[@"idmapping"][uid];
        
        if (!email) {
            email = @"Unknown";
        }
        users = [self addUserWhoCanSeeMe:uid withEmail:email toArray:users ];
    }
    return users;
        
}

-(BOOL)havePeopleWhoCanSeeMe
{
    NSDictionary* dashboard = [LocalStorage getDashboard];
    
    for(NSString* uid in dashboard[@"canseeme"]) {
        return YES;
    }
    return NO;
}

-(BOOL)isUserReporting:(NSString*)userID {
    NSDictionary* dashboard = [LocalStorage getDashboard];
    
    NSString* myUserID = [LocalStorage getLoggedInUserId];
    if ([myUserID isEqualToString:userID]) {
        return [self userIsVisible:dashboard];
    }
    
    for(NSString* uid in dashboard[@"icansee"]) {
        if ([uid isEqualToString:userID]) {
            NSDictionary* user = dashboard[@"icansee"][uid];
            return [self userIsVisible:user];
        }
       
    }
    
    return NO;
}


-(NSDate*)getUserLastReportDate:(NSString*)userID {
    NSDictionary* dashboard = [LocalStorage getDashboard];
    
    NSString* myUserID = [LocalStorage getLoggedInUserId];
    if ([myUserID isEqualToString:userID]) {
        NSNumber* lastReport = [dashboard[@"location"] valueForKey:@"time"];
        if (!lastReport) {
            return nil;
        }
        return [NSDate dateWithTimeIntervalSince1970:[lastReport doubleValue]/1000];
    }
    
    for(NSString* uid in dashboard[@"icansee"]) {
        if ([uid isEqualToString:userID]) {
            NSDictionary* user = dashboard[@"icansee"][uid];
            if (!user || !user[@"location"]) {
                return nil;
            }
            NSNumber* lastReport = [user[@"location"] valueForKey:@"time"];
            if (!lastReport) {
                return nil;
            }
            return [NSDate dateWithTimeIntervalSince1970:[lastReport doubleValue]/1000];
        }
        
    }
    
    return nil;
    
}



@end

