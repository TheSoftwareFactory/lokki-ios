//
//  LocMapAnnotation.m
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapAnnotation.h"

@implementation LocMapAnnotation

@synthesize userID = _userID;
@synthesize userEmail = _userEmail;
@synthesize userName = _userName;
@synthesize userAvatarImageData = _userAvatarImageData;
@synthesize	coordinate = _coordinate;
@synthesize annotationView = _annotationView;
@synthesize userCoordinateAccuracy = _userCoordinateAccuracy;


-(id)initWithUserData:(UserData*)userData
{
    if ((self = [super init])) {
        _userID = userData.userID;
        self.coordinate = userData.coord;
        _userName = userData.userName;
        _userEmail = userData.userEmail;
        self.userIsReporting = userData.isReporting;
        self.userLastReportTime = userData.userLastReportDate;
        self.userCoordinateAccuracy = userData.accuracy;
        
        if (userData.imgData) {
            _userAvatarImageData = userData.imgData;
        }
    }
    return self;
}



- (NSString *)title {
    return _userName;
}

/*
-(void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    [self willChangeValueForKey:@"coordinate"];
    _coordinate = coordinate;
    [self didChangeValueForKey:@"coordinate"];
}
*/

@end
