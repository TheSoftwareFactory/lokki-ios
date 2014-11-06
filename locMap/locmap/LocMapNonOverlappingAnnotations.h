//
//  LocMapNonOverlappingAnnotations.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/16/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LocMapNonOverlappingAnnotations : NSObject

    // designated initializer
    -(id)initForMap:(MKMapView*)map;

    // scan all annotations and make sure they dont overlap.
    // this class also has animation from time to time to increase non overlapping displacement
    -(void)makeSureAnnotationsAreNotOverlapping;

    // when we select one of overlapping annotation - increase displacement to show all avatars in bunch and allow to select them
    -(void)increaseOverlapDisplacementOnAnnotationSelected;
    -(void)decreaseOverlapDisplacementOnAnnotationDeselected;

    -(void)makeCorrectZOrderForViews:(NSArray*)views;// array of MKAnnotationView

@end

