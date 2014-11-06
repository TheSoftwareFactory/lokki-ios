//
//  Contacts.m
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "Contacts.h"
#import "AddressBook/AddressBook.h"
#import <AddressBookUI/AddressBookUI.h>
#import "LocalStorage.h"
#import "Checks.h"


@interface MyABNewPersonViewControllerDelegate : NSObject <ABNewPersonViewControllerDelegate>
    @property (strong) UINavigationController* presentedViewController;
@end

@implementation MyABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadCachedContactsOnNextAppear" object:self];
    [self.presentedViewController popViewControllerAnimated:YES];
}

@end

static MyABNewPersonViewControllerDelegate* gMyABNewPersonViewControllerDelegate = nil;


@interface Contacts()
    @property ABAddressBookRef addressBook;

    @property (strong) NSArray* cachedContacts;// cache contacts here
@end


@implementation Contacts

-(void)dealloc {
    if (self.addressBook) {
        CFRelease(self.addressBook);
    }
}

-(void)loadContacts {
    [self allMyContacts];
}


- (NSArray *)allMyContacts {
    if (self.cachedContacts) {
        return self.cachedContacts;
    }
    
    CFErrorRef error = nil;
    if (self.addressBook) {
        CFRelease(self.addressBook);
    }
    self.addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    __block BOOL accessGranted = NO;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    //usleep(1000*1000*5);//for testing
    static BOOL messageAboutContactsNotAvailableShown = NO;
    
    if (accessGranted) {
        messageAboutContactsNotAvailableShown = NO;
        self.cachedContacts = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(self.addressBook);
        
        return self.cachedContacts;
    } else {
        if (!messageAboutContactsNotAvailableShown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Contacts showMessageContactsNotAvailable];
            });
            
            messageAboutContactsNotAvailableShown = YES;
        }

        self.cachedContacts = nil;
        return nil;
    }
}

+(void)showMessageContactsNotAvailable {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_LOCALIZE(@"Error")
                                                        message:_LOCALIZE(@"Cannot get access to your Contacts.\nLokki will not work correctly if you don't give it access to your Contacts.")
                                                       delegate:nil
                                              cancelButtonTitle:_LOCALIZE(@"OK")
                                              otherButtonTitles:nil, nil];
    [alertView show];
    
}

-(void)addObjectForRecord:(id)person withName:(NSString*)name email:(NSString*)email toArray:(NSMutableArray*)result alreadyAdded:(NSMutableDictionary*)alreadyAddedEmails
{
    if (email && alreadyAddedEmails[email]) {
        return;
    }
    CFDataRef img = ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)person, kABPersonImageFormatThumbnail);
    NSData* imgData = (__bridge NSData*)img;
    if (img) {
        CFRelease(img);
    }
    NSNumber* rid = [NSNumber numberWithLong:ABRecordGetRecordID((__bridge ABRecordRef)person)];
    if (imgData) {
        if (email) {
            [result addObject:@{@"email":email, @"name":name, @"imgData":imgData, @"recordID":rid}];
        } else {
            [result addObject:@{@"name":name, @"imgData":imgData, @"recordID":rid}];
        }
    } else {
        if (email) {
            [result addObject:@{@"email":email, @"name":name, @"recordID":rid}];
        } else {
            [result addObject:@{@"name":name, @"recordID":rid}];
        }
    }
    
    if (email) {
        alreadyAddedEmails[email] = @"added";
    }
    
}

- (NSArray*)getAllContacts {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSMutableDictionary* alreadyAddedEmails = [[NSMutableDictionary alloc] init];
    
    NSArray *allMyContacts = [self allMyContacts];
    if (allMyContacts) {
        
        for (id person in allMyContacts) {
            NSString *email = nil;
            ABMultiValueRef emails = ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonEmailProperty);
            NSString* name = [self getPersonName:person];
            
            if (emails && ABMultiValueGetCount(emails)) {
                BOOL thisUserAdded = NO;
                for(CFIndex e = 0; e < ABMultiValueGetCount(emails); ++e) {
                    email = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(emails, e);
                    if (email) {
                        email = [email lowercaseString];
                    }
                    
                    if (email && [Checks emailIsValid:email]) {
                        [self addObjectForRecord:person withName:name email:email toArray:result alreadyAdded:alreadyAddedEmails];
                        thisUserAdded = YES;
                    } else {
                        if (!thisUserAdded) {
                            [self addObjectForRecord:person withName:name email:nil toArray:result alreadyAdded:alreadyAddedEmails];
                            thisUserAdded = YES;
                        }
                    }
                }
            } else {
                // no emails
                [self addObjectForRecord:person withName:name email:nil toArray:result alreadyAdded:alreadyAddedEmails];
            }
            if (emails) {
                CFRelease(emails);
            }
        }
    } else {
        return nil;
    }
    

    return result;
}


// returns dictionary with all contacts with emails. Dictionary key is email, dictionary value is another dictionary with name and picture (picture may be missing):
//{name: "Oleg", img:UIImage}
/*
- (NSDictionary*)getAllContactsWithEmails {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    NSArray *allMyContacts = [self allMyContacts];
    if (allMyContacts) {
        
        for (id person in allMyContacts) {
            NSString *email = nil;
            ABMultiValueRef emails = ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonEmailProperty);
            NSString* name = [self getPersonName:person];
            
            if (emails) {
                for(CFIndex e = 0; e < ABMultiValueGetCount(emails); ++e) {
                    email = (__bridge NSString *) ABMultiValueCopyValueAtIndex(emails, e);
                    if (email) {
                        email = [email lowercaseString];
                    }
                
                    if (email && [Checks emailIsValid:email]) {
                        NSData* imgData = (__bridge NSData*)ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)person, kABPersonImageFormatThumbnail);
                        if (imgData) {
                            result[email] = @{@"name":name, @"imgData":imgData};
                        } else {
                            result[email] = @{@"name":name};
                            
                        }
                    }
                }
            }
        }
    } else {
        return nil;
    }
    
    // cache all avatars
    //[LocalStorage setAccountDataFromDict:result];
    
    
    return result;
}
 */
    
-(NSString*)getPersonName:(id)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonFirstNameProperty);
    NSString *secondName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonLastNameProperty);
    NSString *companyName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonOrganizationProperty);
    
    NSString* name = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", (firstName&&secondName)?@" ":@"", secondName?secondName:@""];
    if (companyName) {
        name = [name stringByAppendingString:[NSString stringWithFormat:@" (%@)", companyName]];
    }
    return name;
}

    
-(NSString*)getPersonPhoneNumber:(id)person
{
    ABMultiValueRef phoneNumberMultiValue = ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonPhoneProperty);
    NSUInteger phoneNumberIndex;
    for (phoneNumberIndex = 0; phoneNumberIndex < ABMultiValueGetCount(phoneNumberMultiValue); phoneNumberIndex++) {
        
        NSString *phoneNumber  = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumberMultiValue, phoneNumberIndex);
        if (phoneNumber && phoneNumber.length > 0) {
            return phoneNumber;
        }
    }
    CFRelease(phoneNumberMultiValue);
    return nil;
}

-(id)getPersonEntryForRecordID:(NSNumber*)recordID
{
    NSArray *allMyContacts = [self allMyContacts];
    if (allMyContacts) {
        for (id person in allMyContacts) {
            NSNumber* rid = [NSNumber numberWithLong:ABRecordGetRecordID((__bridge ABRecordRef)person)];
            if ([rid compare:recordID] == NSOrderedSame) {
                return person;
            }
        }
    }
    return nil;
    
}

-(id)getPersonEntryForEmail:(NSString*)_email
{
    NSArray *allMyContacts = [self allMyContacts];
    if (allMyContacts) {
        for (id person in allMyContacts) {
            NSString *email = nil;
            ABMultiValueRef emails = ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonEmailProperty);
            
            if (emails) {
                for(CFIndex e = 0; e < ABMultiValueGetCount(emails); ++e) {
                    email = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(emails, e);
                    
                    if ([email compare:_email options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                        return person;
                    }
                }
                CFRelease(emails);
            }
        }
    }
    return nil;
}


-(NSDictionary*)getContactDataToCacheForEmail:(NSString*)email
{
    NSDictionary* result;
    id person = [self getPersonEntryForEmail:email];
    if (person) {
        NSData* imgData = (__bridge_transfer NSData*)ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)person, kABPersonImageFormatThumbnail);
        NSString* name = [self getPersonName:person];
        if (imgData) {
            result = @{email : @{@"name":name, @"imgData":imgData}};
        } else {
            result = @{email : @{@"name":name}};
        }
    }
    return result;
}



// returns name of a first contact with defined email
-(NSString*)getContactNameForEmail:(NSString*)email
{
    id person = [self getPersonEntryForEmail:email];
    if (person) {
        return [self getPersonName:person];
    }
    return nil;
}

// returns YES if contact with defined email exists
-(BOOL)contactWithEmailExists:(NSString*)email {
    id person = [self getPersonEntryForEmail:email];
    return person != nil;
}


-(NSString*)getPhoneNumberForEmail:(NSString*)_email {
    id person = [self getPersonEntryForEmail:_email];
    if (person) {
        return [self getPersonPhoneNumber:person];
    }
    return nil;
}

// show contact page of a first contact with defined record ID
-(BOOL)showPersonContactPageForRecordID:(NSNumber*)recordID fromViewController:(UIViewController*)controller {
    id person = [self getPersonEntryForRecordID:recordID];
    if (person) {
        [self showPersonContactPage:person fromViewController:controller];
        return YES;
    }
    return NO;
    
}


-(BOOL)showPersonContactPageForEmail:(NSString*)email fromViewController:(UIViewController*)controller
{
    id person = [self getPersonEntryForEmail:email];
    if (person) {
        [self showPersonContactPage:person fromViewController:controller];
        return YES;
    }
    return NO;
}

-(void)showPersonContactPage:(id)person fromViewController:(UIViewController*)controller {
    ABPersonViewController *picker = [[ABPersonViewController alloc] init];
    picker.allowsActions = YES;
    //picker.personViewDelegate = self;
    picker.displayedPerson = (__bridge ABRecordRef)person;
    // Allow users to edit the person’s information
    picker.allowsEditing = YES;
    picker.editing = YES;
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController*)controller pushViewController:picker animated:YES];
    } else {
        [controller.navigationController pushViewController:picker animated:YES];
    }
    
    // always assume something has changed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadCachedContactsOnNextAppear" object:self];
}


-(BOOL)createPersonContactForEmail:(NSString*)email fromViewController:(UIViewController*)controller
{
    ABRecordRef newPerson = ABPersonCreate();
    if (!newPerson) {
        return NO;
    }
    ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABPersonEmailProperty);
    if (!ABMultiValueAddValueAndLabel(emailMultiValue,(__bridge  CFTypeRef)email, kABWorkLabel, nil)) {
        return NO;
    }
    if (!ABRecordSetValue(newPerson, kABPersonEmailProperty, emailMultiValue, nil)) {
        return NO;
    }
    if (!gMyABNewPersonViewControllerDelegate) {
        gMyABNewPersonViewControllerDelegate = [[MyABNewPersonViewControllerDelegate alloc] init];
    }
    ABNewPersonViewController* abNewPersonPicker = [[ABNewPersonViewController alloc] init];
    [abNewPersonPicker setDisplayedPerson:newPerson];
    abNewPersonPicker.newPersonViewDelegate = gMyABNewPersonViewControllerDelegate;
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        gMyABNewPersonViewControllerDelegate.presentedViewController = (UINavigationController*)controller;
        [(UINavigationController*)controller pushViewController:abNewPersonPicker animated:YES];
    } else {
        gMyABNewPersonViewControllerDelegate.presentedViewController = controller.navigationController;
        [controller.navigationController pushViewController:abNewPersonPicker animated:YES];
    }
    return YES;
    
}
    
-(BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return YES;
}



@end
