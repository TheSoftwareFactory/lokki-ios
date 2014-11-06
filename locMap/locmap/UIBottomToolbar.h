//
//  UIBottomToolbar
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapKit/MapKit.h"

enum UIBottomToolbarSelectedItem {
    kUIBottomToolbarSelectedItemMap = 0,
    kUIBottomToolbarSelectedItemPlaces = 1
};

// will be sent when selectedItem changes
#define NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED @"NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED"

@interface UIBottomToolbar : UIToolbar

    -(void)initOnce;

    -(void)createButtonsForMapView:(MKMapView*)mapView currentState:(enum UIBottomToolbarSelectedItem)state;

    -(enum UIBottomToolbarSelectedItem)selectedItem;
    -(void)setSelectedItem:(enum UIBottomToolbarSelectedItem)item;

@end
