//
//  MapPlaceCircleOverlay.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/17/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "MapPlaceCircleOverlay.h"

@interface MapPlaceCircleOverlay()
    @property (strong) MapPlaceCircle* mapPlaceCircle;
@end

@implementation MapPlaceCircleOverlay

- (id)initWithMapPlaceCircle:(MapPlaceCircle *)circle {
    self = [super initWithCircle:circle.circle];
    self.mapPlaceCircle = circle;
    
    return self;
}


// draws circle and then on top of it draws place name inside rounded rect white background.
-(void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
    NSString * str = self.mapPlaceCircle.placeName;
    UIGraphicsPushContext(context);
    CGContextSaveGState(context);
    
  
    CGFloat fontSize = 256;
    if (zoomScale > 0.26) {
        fontSize = 128;
    }
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByClipping;
    textStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attr = @{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: font, NSParagraphStyleAttributeName: textStyle};
    
    CGRect circleRect = [self rectForMapRect:[self.overlay boundingMapRect]];
    CGSize size = [str sizeWithAttributes:attr];
    CGPoint center = CGPointMake(circleRect.origin.x + circleRect.size.width /2,circleRect.origin.y + circleRect.size.height /2);
    CGPoint textstart = CGPointMake(center.x - size.width/2, center.y - size.height /2 );
    
    CGRect fullTextRect = CGRectMake(textstart.x - size.width*0.1, textstart.y - size.height*0.1, size.width*1.2, size.height*1.2);
    UIBezierPath* whiteRect = [UIBezierPath bezierPathWithRoundedRect:fullTextRect cornerRadius:fullTextRect.size.height/3.5];
    [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.75] setFill];
    [whiteRect fill];
    
    [str drawAtPoint:textstart withAttributes:attr];
    
    CGContextRestoreGState(context);
    UIGraphicsPopContext();
}

@end
