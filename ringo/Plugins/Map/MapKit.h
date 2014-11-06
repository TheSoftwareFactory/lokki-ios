//
//  UIControls.h
//  Cordova
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import <Cordova/CDVPlugin.h>


@interface MapKitView : CDVPlugin <MKMapViewDelegate> 
{
}

@property (nonatomic, copy) NSString *buttonCallback;
@property (nonatomic, retain) UIView* childView;
@property (nonatomic, retain) MKMapView* mapView;
@property (nonatomic, retain) UIButton*  imageButton;
@property (nonatomic) BOOL locationIsEditable;// if we have editable location or not
@property (nonatomic) CLLocationCoordinate2D locationCoordinates;// if we have movale pin - here will be it's final coords
@property (nonatomic) double locationRadius;// if we have movale pin - here will be it's final radius/diameter
@property (nonatomic, strong) NSString* callbackId;//what to call to return results to JS


- (void)showLocation:(CDVInvokedUrlCommand *)command;



@end
