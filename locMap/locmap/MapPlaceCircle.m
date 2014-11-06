//
//  MapPlaceCircle.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/17/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "MapPlaceCircle.h"

@implementation MapPlaceCircle

-(id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius name:(NSString*)name placeID:(NSString*)placeID {
    self = [super init];
    _coordinate = coord;
    _radius = radius;
    _placeName = name;
    _placeID = placeID;
    
    _circle = [MKCircle circleWithCenterCoordinate:coord radius:radius];
    _boundingMapRect = _circle.boundingMapRect;
    
    
    return self;
    
}


+ (MapPlaceCircle *)circleWithPlaceID:(NSString*)placeID name:(NSString*)name centerCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius {
    
    MapPlaceCircle* placeCircle = [[MapPlaceCircle alloc] initWithCenterCoordinate:coord radius:radius name:name placeID:placeID];
    return placeCircle;
}

@end
