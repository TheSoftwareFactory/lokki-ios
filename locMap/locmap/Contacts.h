//
//  Contacts.h
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contacts : NSObject

    // load and cache contacts so all next functions will be fast
    -(void)loadContacts;

    // returns dictionary with all contacts with emails. Dictionary key is email, dictionary value is another dictionary with name and picture (picture may be missing):
    //{name: "Oleg", imgURL:"some.png"}
    //- (NSDictionary*)getAllContactsWithEmails;

    // returns array with all contacts with or without emails. Array data is NSDictionary with email (may be missing if email not defined), name and picture (picture may be missing):
    //{email: "b@b.bb", name: "Oleg", imgURL:"some.png", recordID:123}
    // recordID is to be used with
    - (NSArray*)getAllContacts;

    // the same as getAllContactsWithEmails but for single email
    -(NSDictionary*)getContactDataToCacheForEmail:(NSString*)email;

    // returns YES if contact with defined email exists
    -(BOOL)contactWithEmailExists:(NSString*)email;


    // returns name of a first contact with defined email
    -(NSString*)getContactNameForEmail:(NSString*)email;
    
    // returns phone number of a first contact with defined email
    -(NSString*)getPhoneNumberForEmail:(NSString*)email;

    // show contact page of a first contact with defined email
    -(BOOL)showPersonContactPageForEmail:(NSString*)email fromViewController:(UIViewController*)controller;

    // show contact page of a first contact with defined record ID
    -(BOOL)showPersonContactPageForRecordID:(NSNumber*)recordID fromViewController:(UIViewController*)controller;

    -(BOOL)createPersonContactForEmail:(NSString*)email fromViewController:(UIViewController*)controller;

@end
