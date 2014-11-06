//
//  MapPlaceCircleOverlay.h
//  Lokki
//
//  Created by Oleg Fedorov on 1/17/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "MapPlaceCircle.h"

@interface MapPlaceCircleOverlay : MKCircleRenderer

    - (id)initWithMapPlaceCircle:(MapPlaceCircle *)circle;



@end
