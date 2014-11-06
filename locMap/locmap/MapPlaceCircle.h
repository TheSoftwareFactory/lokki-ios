//
//  MapPlaceCircle.h
//  Lokki
//
//  Created by Oleg Fedorov on 1/17/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MapPlaceCircle : NSObject <MKOverlay>
    + (MapPlaceCircle *)circleWithPlaceID:(NSString*)placeID name:(NSString*)name centerCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius;

    @property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
    @property (nonatomic, readonly) MKMapRect boundingMapRect;

    @property (nonatomic, readonly) CLLocationDistance radius;
    @property (strong, readonly) NSString* placeID;
    @property (strong, readonly) NSString* placeName;

    @property (strong, readonly) MKCircle* circle;
@end
