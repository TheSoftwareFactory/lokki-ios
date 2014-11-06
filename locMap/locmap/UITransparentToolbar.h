//
//  UITransparentToolbar.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface UITransparentToolbar : UIToolbar
    -(void)createButtonsForMapView:(MKMapView*)mapView;

@end
