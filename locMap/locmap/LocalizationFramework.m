//
//  LocalizationFramework.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/27/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "LocalizationFramework.h"

@implementation LocalizationFramework


+(NSString*)localize:(NSString*)ID {
    static NSBundle* enBundle = nil;
    if ( !enBundle ) {
        NSString* bp = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        enBundle = [NSBundle bundleWithPath:bp];
    }
    
    NSString* ret = NSLocalizedString(ID, nil);
    if (!ret || [ret isEqualToString:ID]) {
        ret = [enBundle localizedStringForKey:ID value:ID table:nil];
    }
    
    return ret;
}


@end
