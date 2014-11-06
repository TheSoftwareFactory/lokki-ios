//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"


@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;
@synthesize locationIsEditable;
@synthesize locationCoordinates;
@synthesize locationRadius;
@synthesize callbackId;

- (void)showLocation:(CDVInvokedUrlCommand *)command {
    self.callbackId = [NSString stringWithString:command.callbackId];
    
	NSDictionary *options = [command.arguments objectAtIndex:0];
    if (!self.childView) {
        [self createView];
    } else {
        [self showMap];
    }
    
    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
    BOOL editable = NO;
    if ([options objectForKey:@"editable"]) {
        editable = [[options objectForKey:@"editable"] boolValue];
    }
    CLLocationDistance diameter = 500;
    if ([options objectForKey:@"radius"]) {
        diameter = [[options objectForKey:@"radius"] floatValue];
    } else if ([options objectForKey:@"acc"]) {
        diameter = [[options objectForKey:@"acc"] floatValue];
    }
    
    self.locationIsEditable = editable;
    self.locationCoordinates = centerCoord;
    self.locationRadius = diameter;
    
    NSString *title = @"!";
    if ([options objectForKey:@"name"]) {
        title = [options valueForKey:@"name"];
    }
    
    [self addPin:centerCoord withDiameter:diameter withTitle:title canBeMoved:editable];
}

-(void)addPin:(CLLocationCoordinate2D)centerCoord withDiameter:(CLLocationDistance)diameter withTitle:(NSString *)title canBeMoved:(BOOL)editable
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    [self.childView setFrame:screenBounds];
    [self.mapView setFrame:screenBounds];
    
    CLLocationDistance viewDiameter = 500;
    if (diameter*2 > viewDiameter) {
        viewDiameter = diameter*2 + 100;
    }
    
    MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord, viewDiameter, viewDiameter)];
    [self.mapView setRegion:region animated:YES];
    
    CGRect frame = CGRectMake(screenBounds.size.width - 29.0, 0,  29.0, 29.0);
    
    [ self.imageButton setImage:[UIImage imageNamed:@"map-close-button.png"] forState:UIControlStateNormal];
    [ self.imageButton setFrame:frame];
    [ self.imageButton addTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
    
    CLLocationCoordinate2D pinCoord = centerCoord;
    
    NSInteger index=1;
    
    CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title diameter:diameter editable:editable];

    [self.mapView addOverlay:[MKCircle circleWithCenterCoordinate:pinCoord radius:diameter]];
    
    [self.mapView addAnnotation:annotation];
    [self.mapView selectAnnotation:annotation animated:YES];
    [annotation release];
    
}


- (void) closeButton:(id)button
{
    if (self.mapView) {
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView removeOverlays:self.mapView.overlays];
    }
    
	[ self hideMap];
    
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    [results setValue:[NSNumber numberWithDouble:self.locationCoordinates.latitude] forKey:@"lat"];
    [results setValue:[NSNumber numberWithDouble:self.locationCoordinates.longitude] forKey:@"lon"];
    [results setValue:[NSNumber numberWithDouble:self.locationRadius] forKey:@"radius"];
    
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
	[self writeJavascript:[pluginResult toSuccessCallbackString:self.callbackId]];
}

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    if (![annotation isKindOfClass:[CDVAnnotation class]]) {
        NSLog(@"Unknown annotation class!");
        return nil;
    }
    
    CDVAnnotation* cdvAnnotation = (CDVAnnotation*)annotation;
    
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"lokkiPin"];
    if (pin == nil) {
        #if __has_feature(objc_arc)
            pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"lokkiPin"];
        #else
            pin = [[[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"lokkiPin"] autorelease];
        #endif
    } else {
        pin.annotation = annotation;
    }
    pin.draggable = cdvAnnotation.editable;
    pin.canShowCallout = YES;
    
    return pin;
}

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    if([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay];
        circleView.fillColor = [UIColor colorWithRed:0.1 green:0.1 blue:1.0 alpha:0.3];
        return [circleView autorelease];
    }
    return nil;
}

-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
	self.childView = [[UIView alloc] init];
    self.mapView = [[MKMapView alloc] init];
    [self.mapView sizeToFit];
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
	self.mapView.showsUserLocation = YES;
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[self.childView addSubview:self.mapView];
	[self.childView addSubview:self.imageButton];

	[ [ [ self viewController ] view ] addSubview:self.childView];  
}

- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated 
{ 

}

- (void)showMap
{
	if (!self.mapView) 
	{
		[self createView];
	}
	self.childView.hidden = NO;
	self.mapView.showsUserLocation = YES;
}


- (void)hideMap
{
    if (!self.mapView || self.childView.hidden==YES) 
	{
		return;
	}
	// disable location services, if we no longer need it.
	self.mapView.showsUserLocation = NO;
	self.childView.hidden = YES;
}


- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)annotationView
didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    
    if (newState == MKAnnotationViewDragStateEnding)
    {
        if (![annotationView.annotation isKindOfClass:[CDVAnnotation class]]) {
            NSLog(@"Unknown annotation class moved!");
            return;
        }

        CDVAnnotation* cdvAnnotation = (CDVAnnotation*)annotationView.annotation;
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        self.locationCoordinates = droppedAt;
        NSLog(@"Pin dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
        
        // find and delete old overlay and add new one
        // TODO: make overlays of own type to keep reference to annotation there to easily find and remove only needed overlays
        [self.mapView removeOverlays:self.mapView.overlays];
        [self.mapView addOverlay:[MKCircle circleWithCenterCoordinate:droppedAt radius:cdvAnnotation.diameter]];
        
    }
}


- (void)dealloc
{
    if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
        self.imageButton = nil;
	}
	if(childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
    [super dealloc];
}

@end
