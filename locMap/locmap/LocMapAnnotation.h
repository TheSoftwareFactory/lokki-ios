//
//  LocMapAnnotation.h
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "UserData.h"

@class LocMapAnnotationView;


@interface LocMapAnnotation : NSObject <MKAnnotation> {
    
@private
    CLLocationCoordinate2D _coordinate;
    NSString* _userID;
    NSString* _userEmail;
    NSString* _userName;
    NSData* _userAvatarImageData;
}

@property (nonatomic, assign) LocMapAnnotationView *annotationView;
@property (nonatomic, copy, readonly) NSString* userID;
@property (nonatomic, copy, readonly) NSString* userEmail;
@property (nonatomic, copy) NSString*           userName;
@property (nonatomic, copy) NSDate*             userLastReportTime;
@property (nonatomic, copy) NSData*             userAvatarImageData;
@property                   BOOL                userIsReporting;
    
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) float userCoordinateAccuracy;// accuracy of a coordinate in meters


-(id)initWithUserData:(UserData*)userData;

@end

