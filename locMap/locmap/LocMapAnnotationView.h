//
//  LocMapAnnotationView.h
//  locmap
//
//  Created by Oleg Fedorov on 11/19/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface LocMapAnnotationView : MKAnnotationView {
    UIImage *avatarImg;
    UIImageView *avatarView;
}


-(void)updateAnnotationInfo;
- (void)setShowCustomCallout:(BOOL)showCustomCallout animated:(BOOL)animated;
-(BOOL)calloutVisible;

// to avoid overlapping annotations we do change X position for some of annotations using this method
-(void)setHorizontalDisplacement:(float)dx;
-(float)getHorizontalDisplacement;

@end



