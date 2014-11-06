//
//  LocalizationFramework.h
//  Lokki
//
//  Created by Oleg Fedorov on 1/27/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _LOCALIZE(str) [LocalizationFramework localize:str]

@interface LocalizationFramework : NSObject

    // localize to current language and if string with ID does not exist there - fallback to English
    +(NSString*)localize:(NSString*)ID;

@end
