//
//  UITransparentToolbar.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "UITransparentToolbar.h"
#import "MapKit/MapKit.h"

@implementation UITransparentToolbar

- (void)drawRect:(CGRect)rect {
    // do nothing in here
}

- (void) applyTranslucentBackground
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.translucent = YES;
}

- (id) init
{
    self = [super init];
    [self applyTranslucentBackground];
    return self;
}

// Override initWithFrame.
- (id) initWithFrame:(CGRect) frame
{
    self = [super initWithFrame:frame];
    [self applyTranslucentBackground];
    return self;
}


-(void)createButtonsForMapView:(MKMapView*)mapView {
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:mapView];
    [self setItems:@[flex, trackingButton]];
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


@end
