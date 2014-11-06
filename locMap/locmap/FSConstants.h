//
//  FSConstants.h
//  Lokki
//
//  Created by Oleg Fedorov on 11/27/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AVATAR_WIDTH 50
#define PIN_WIDTH 62
#define PIN_HEIGHT 95
#define AVATAR_BORDER_WIDTH 3
#define HALO_SIZE 60

#define CALLOUT_BORDER_WIDTH 10
#define CALLOUT_WIDTH 268
#define CALLOUT_HEIGHT 112
#define CALLOUT_TRIANGLE_SIZE 16


@interface FSConstants : NSObject

+(FSConstants*)instance;
-(void)clearCache;

@property (strong, nonatomic) UIColor* orange;
@property (strong, nonatomic) UIColor* blue;
@property (strong, nonatomic) UIColor* green;

-(void)applyGradientToView:(UIView*)view;

-(UIImage*)getDefaultAvatarForUserWithName:(NSString*)userName;

@end

