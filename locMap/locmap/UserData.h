//
//  UserData.h
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapKit/MapKit.h"

@interface UserData : NSObject

@property (strong, nonatomic)   NSString* userID;
@property (strong, nonatomic)   NSString* userEmail;
@property (strong, nonatomic)   NSString* userName;
@property (strong, nonatomic)   NSData* imgData;
@property (strong, nonatomic)   NSDate* userLastReportDate;
@property                       BOOL isReporting;//NO if user is hiding
    

@property (nonatomic) CLLocationCoordinate2D coord;//where this user is
@property (nonatomic) float accuracy;//accuracy of user's current location
    
@property (nonatomic) BOOL showOnMap;// show this user on map or not
@property (nonatomic) BOOL canSeeMe;// can this user see me or not


@end


