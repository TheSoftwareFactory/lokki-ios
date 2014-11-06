//
//  FSConstants.m
//  Lokki
//
//  Created by Oleg Fedorov on 11/27/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "FSConstants.h"

@interface FSConstants()
    @property (strong) NSMutableDictionary* cachedAvatarsForName;// key - user name, value - UIImage
@end


@implementation FSConstants

-(id)init
{
    self = [super init];
    self.cachedAvatarsForName = [[NSMutableDictionary alloc] init];
    return self;
}

+(FSConstants*)instance
{
    static FSConstants* stInstance = nil;
    
    if (!stInstance) {
        stInstance = [[FSConstants alloc] init];
    }
    return stInstance;
}

-(void)clearCache
{
    self.cachedAvatarsForName = [[NSMutableDictionary alloc] init];
}


-(UIColor*)orange
{
    if (!_orange) {
        _orange = [UIColor colorWithRed:255.0/255.0 green:148.0/255 blue:0 alpha:1.0];
    }
    return _orange;
}

-(UIColor*)blue
{
    if (!_blue) {
        _blue = [UIColor colorWithRed:16.0/255.0 green:115.0/255.0 blue:188.0/255.0 alpha:1.0];
    }
    return _blue;
}


-(UIColor*)green
{
    if (!_green) {
        _green = [UIColor colorWithRed:76.0/255.0 green:216.0/255.0 blue:99.0/255.0 alpha:1.0];
    }
    return _green;
}

-(void)applyGradientToView:(UIView*)view
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    UIColor* c1 = [UIColor colorWithRed:0x50/255.0 green:0x74/255.0 blue:0xbc/255.0 alpha:1];//5074bc
    UIColor* c2 = [UIColor colorWithRed:0x01/255.0 green:0x9c/255.0 blue:0xde/255.0 alpha:1];
    UIColor* c3 = [UIColor colorWithRed:0x00/255.0 green:0xa6/255.0 blue:0x9b/255.0 alpha:1];//00a69b
    gradient.colors = [NSArray arrayWithObjects:(id)[c1 CGColor], (id)[c2 CGColor], (id)[c2 CGColor], (id)[c3 CGColor], nil];
    gradient.endPoint = CGPointMake(1, 1);
    gradient.locations  = @[[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1]];
    [view.layer insertSublayer:gradient atIndex:0];
}


-(UIImage*)getDefaultAvatarForUserWithName:(NSString*)userName
{
    if ([self.cachedAvatarsForName objectForKey:userName]) {
        return [self.cachedAvatarsForName objectForKey:userName];
    }
    
    if (!userName || userName.length < 1) {
        return [UIImage imageNamed:@"defaultAvatar"];
    }
    NSMutableString * firstCharacters = [NSMutableString string];
    NSArray * words = [userName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n,.:@!?+-()&%€#\"';_<>"]];
    for (NSString * word in words) {
        if ([word length] > 0) {
            NSString * firstLetter = [word substringToIndex:1];
            [firstCharacters appendString:[firstLetter uppercaseString]];
            if (firstCharacters.length > 1) {
                break;
            }
        }
    }
    NSString* initials = [firstCharacters copy];
    
    UIImage* image = [UIImage imageNamed:@"defaultAvatar"];
    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    CGRect rect = CGRectMake(0, 20, image.size.width, image.size.height);

    [[UIColor whiteColor] set];
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:48];
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByClipping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attr = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: font, NSParagraphStyleAttributeName: textStyle};
    [initials drawInRect:CGRectIntegral(rect) withAttributes:attr];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!newImage) {
        newImage = [UIImage imageNamed:@"defaultAvatar"];
    }
    
    self.cachedAvatarsForName[userName] = newImage;
    return newImage;
}

@end
