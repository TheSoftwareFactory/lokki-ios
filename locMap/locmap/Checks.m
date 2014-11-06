//
//  Checks.m
//  locmap
//
//  Created by Oleg Fedorov on 11/26/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "Checks.h"

@implementation Checks


+(BOOL)emailIsValid:(NSString*)email
{
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    
    BOOL strictFilter = YES;
    NSString *emailRegex = strictFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}



@end

