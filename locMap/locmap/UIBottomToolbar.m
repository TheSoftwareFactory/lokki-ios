//
//  UIBottomToolbar
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "UIBottomToolbar.h"
#import "LocalStorage.h"

#define DOT_RADIUS 3
#define DOT_Y 8

@interface UIBottomToolbar()
    @property (nonatomic) enum UIBottomToolbarSelectedItem selectedState;
    @property (weak) MKMapView* mapView;

    @property CGPoint dotPosition;

@end


@implementation UIBottomToolbar

-(void)initOnce {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object: nil];
}


-(void)orientationDidChange:(NSNotification*)notif {
    [self createButtonsForMapView:self.mapView currentState:self.selectedState];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    //dot
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGRect circleRect = CGRectMake(self.dotPosition.x - DOT_RADIUS, self.dotPosition.y - DOT_RADIUS, DOT_RADIUS*2, DOT_RADIUS*2);
    CGContextAddEllipseInRect(ctx, circleRect);
    CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1] CGColor]));
    CGContextFillPath(ctx);
}

-(void)setSelectedState:(enum UIBottomToolbarSelectedItem)selectedState {
    _selectedState = selectedState;
    [LocalStorage setValue:[NSNumber numberWithInt:(int)selectedState] forKey:@"UIBottomToolbarActivateState"];
}

-(enum UIBottomToolbarSelectedItem)selectedItem {
    return self.selectedState;
}

-(void)setSelectedItem:(enum UIBottomToolbarSelectedItem)item {
    if (self.selectedState == item) {
        return;
    }
    
    self.selectedState = item;
    [self createButtonsForMapView:self.mapView currentState:self.selectedState];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED object:self];
}


-(void)createButtonsForMapView:(MKMapView*)mapView currentState:(enum UIBottomToolbarSelectedItem)state {
    self.mapView = mapView;
    self.selectedState = state;
    
    UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *fixedSpaceBetweenButtons = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpaceBetweenButtons.width = 40;
    
    
    UIBarButtonItem *mapTab = [[UIBarButtonItem alloc] initWithTitle:_LOCALIZE(@"MAP") style:UIBarButtonItemStylePlain target:self action:@selector(onMapTabSelected)];
    UIBarButtonItem *placesTab = [[UIBarButtonItem alloc] initWithTitle:_LOCALIZE(@"PLACES") style:UIBarButtonItemStylePlain target:self action:@selector(onPlacesTabSelected)];
    
    [self setItems:@[flex1, mapTab, fixedSpaceBetweenButtons, placesTab, flex2]];
    
    UIColor* selectedColor = [UIColor grayColor];
    UIColor* notSelectedColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.3];
    UIColor* color0 = (self.selectedState == kUIBottomToolbarSelectedItemMap) ? selectedColor : notSelectedColor;
    UIColor* color1 = (self.selectedState == kUIBottomToolbarSelectedItemPlaces) ? selectedColor : notSelectedColor;
    
    int idx = 0;
    for (UIView *subview in self.subviews) {
        if ([subview respondsToSelector:@selector(setTintColor:)]) {
            if (idx == 0) {
                if (self.selectedState == kUIBottomToolbarSelectedItemMap) {
                    self.dotPosition = CGPointMake(subview.frame.origin.x + subview.frame.size.width/2, DOT_Y);
                }
                [subview performSelector:@selector(setTintColor:) withObject:color0];
            }
            if (idx == 1) {
                if (self.selectedState == kUIBottomToolbarSelectedItemPlaces) {
                    self.dotPosition = CGPointMake(subview.frame.origin.x + subview.frame.size.width/2, DOT_Y);
                }
                [subview performSelector:@selector(setTintColor:) withObject:color1];
            }
        }
        ++idx;
    }
    
}

-(void)onMapTabSelected {
    NSLog(@"onMapTabSelected");
    self.selectedState = kUIBottomToolbarSelectedItemMap;
    [self createButtonsForMapView:self.mapView currentState:self.selectedState];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED object:self];
}

-(void)onPlacesTabSelected {
    NSLog(@"onPlacesTabSelected");
    self.selectedState = kUIBottomToolbarSelectedItemPlaces;
    [self createButtonsForMapView:self.mapView currentState:self.selectedState];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED object:self];
}


-(UIView*)viewForLocateMeButton {
    if ([self.items count] > 0) {
        for(UIBarButtonItem* bar in self.items) {
            if ([bar isKindOfClass:[MKUserTrackingBarButtonItem class]]) {
                UIView *view = [bar valueForKey:@"view"];
                return  view;
            }
        }
        return nil;
    }
    return nil;
    
}

- (CGRect)frameForLocateMeButton
{
    if ([self.items count] > 0) {
        for(UIBarButtonItem* bar in self.items) {
            if ([bar isKindOfClass:[MKUserTrackingBarButtonItem class]]) {
                UIView *view = [bar valueForKey:@"view"];
                return  view ? view.frame : CGRectZero;
            }
        }
        return CGRectZero;
    }
    return CGRectZero;
}

/*
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    if (CGRectContainsPoint([self frameForLocateMeButton], point)) {
        return [self viewForLocateMeButton];
    }
    return nil;
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    if (CGRectContainsPoint([self frameForLocateMeButton], point)) {
        return YES;
    }
    
    return NO;
}
*/

@end
