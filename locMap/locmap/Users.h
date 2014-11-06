//
//  Users.h
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserData.h"

@interface Users : NSObject

// returns array of UserData objects for all current users
-(NSArray*)getUsersIncludingMyself:(BOOL)includeMyself excludingOnesIDontWantToSee:(BOOL)excludingOnesIDontWantToSee;

-(NSArray*)getUsersIncludingPeopleWhoCanSeeMe:(BOOL)includeMyself;

-(BOOL)havePeopleWhoCanSeeMe;

-(NSDate*)getUserLastReportDate:(NSString*)userID;
-(BOOL)isUserReporting:(NSString*)userID;

@end

