//
//  AddContactsViewController.m
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "AddContactsViewController.h"
#import "Contacts.h"
#import "ServerApi+messages.h"
#import "LocalStorage.h"
#import "Tutorial.h"
#include "FSConstants.h"


@interface AddContactsViewController () <ServerApiDelegate, UISearchBarDelegate, UIAlertViewDelegate>
    @property (strong, nonatomic) IBOutlet UITableView *contacts;
    @property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
    @property (weak, nonatomic) IBOutlet UILabel *headerLabel;

//    @property (strong, nonatomic) NSDictionary* contactsInfo;
    @property (strong, nonatomic) NSArray* sortedContacts;//array of NSDictionary* {name, email, imgData}

    @property (strong, nonatomic) NSMutableArray* selectedEmails;// of NSString*. contains selected emails

    @property (atomic, strong) ServerApi* serverApi;

    @property (atomic) int numberOfRequestsInProgress;

    @property (strong) NSArray* emailsSentToServer;

    @property (strong) NSString* contactsFilter;// if not nil then use it to filter contacts

    @property (strong) NSString* noEmail;// no Email string


    @property (strong, atomic) NSArray* cachedContacts;// array returned by [Contacts getAllContacts]

@end

@implementation AddContactsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.serverApi = [[ServerApi alloc] initWithDelegate:self];
    self.selectedEmails = [[NSMutableArray alloc] init];
    self.searchBar.delegate = self;
    
    [self localize];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)localize {
    self.searchBar.placeholder = _LOCALIZE(@"Filter contacts");
    self.headerLabel.text = _LOCALIZE(@"Select people you allow to see your location");
    [[self navigationItem] setTitle:_LOCALIZE(@"Select contacts")];
    self.noEmail = _LOCALIZE(@"No email");
}

-(void)viewWillAppear:(BOOL)animated {
    self.cachedContacts = nil;
    [self loadDataAsync];
}

-(void)loadDataAsync
{
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:indicator];
    indicator.center = self.view.center;
    [indicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        Contacts *contacts = [[Contacts alloc] init];
        if (!self.cachedContacts) {
            self.cachedContacts = [contacts getAllContacts];
        }
        
        //sort
        NSArray *sortedKeys = [self.cachedContacts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1[@"name"] caseInsensitiveCompare:obj2[@"name"]];
        }];
        NSMutableArray* s = [[NSMutableArray alloc] init];
        for(NSDictionary* dict in sortedKeys) {
            NSString* email = dict[@"email"];
            NSString* name = dict[@"name"];
            
            if (![self userAlreadyAdded:email] && [self userCanBeAddedWithCurrentFilter:name email:email]) {
                [s addObject:dict];
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sortedContacts = [s copy];
            [self.contacts reloadData];
            [self updateNavigationBar];

            [indicator stopAnimating];
            [indicator removeFromSuperview];
        });
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)userCanBeAddedWithCurrentFilter:(NSString*)name email:(NSString*)email
{
    if (self.contactsFilter == nil || [self.contactsFilter length] == 0) {
        return YES;
    }
    
    NSRange nameRange = [name rangeOfString:self.contactsFilter options:NSCaseInsensitiveSearch];
    
    NSRange emailRange = {NSNotFound, NSNotFound};
    if (email) {
        emailRange = [email rangeOfString:self.contactsFilter options:NSCaseInsensitiveSearch];
    }
    if (nameRange.location != NSNotFound || emailRange.location != NSNotFound)
    {
        return YES;
    }
    return NO;
}

-(BOOL)userAlreadyAdded:(NSString*)email
{
    if (!email) {
        return NO;// add everyone without email
    }
    
    NSString* loggedIn = [LocalStorage getEmailByUserID:[LocalStorage getLoggedInUserId]];
    if ([loggedIn isEqualToString:email]) {
        return YES;
    }
    
    NSDictionary* dashboard = [LocalStorage getDashboard];
    if (dashboard && dashboard[@"canseeme"]) {
        for(NSString* allowedUserId in dashboard[@"canseeme"]) {
            NSString* allowedUserEmail = dashboard[@"idmapping"][allowedUserId];
            if ([allowedUserEmail isEqualToString:email]) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.sortedContacts count]*2;// add separator as every second item
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _LOCALIZE(@"Select people you allow to see your location", nil);
}
*/
// half of width gives pure round
-(void)setRoundedAvatar:(UIImageView *)avatarView cornerRadius:(float)cornerRadius
{
    avatarView.layer.cornerRadius = cornerRadius;
    avatarView.clipsToBounds = YES;
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    if (indexPath.row%2 == 1)
        return 40;
    return 16;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"ContactCell";
    if (indexPath.row%2 == 0) {
        CellIdentifier = @"ContactCellSeparator";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (cell && indexPath.row%2 == 1) {
        NSDictionary* contactInfo = self.sortedContacts[indexPath.row/2];
        NSString* email = contactInfo[@"email"];
        bool selected = (email) ? [self.selectedEmails containsObject:email] : NO;
            
        cell.accessoryType = (selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        cell.textLabel.text = contactInfo[@"name"];
        cell.detailTextLabel.text = (email ? email : self.noEmail);
        
        NSNumber* rid = contactInfo[@"recordID"];
        cell.tag = [rid integerValue];
        if (contactInfo[@"imgData"]) {
            [cell.imageView setImage:[UIImage imageWithData:contactInfo[@"imgData"]]];
        } else {
            [cell.imageView setImage:[[FSConstants instance] getDefaultAvatarForUserWithName:cell.textLabel.text]];
        }

            
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self setRoundedAvatar:cell.imageView cornerRadius:20];
    }
    if (cell && indexPath.row%2 == 0) {
    }
    
    return cell;
}

-(void)cacheContactInfo:(NSDictionary*)contactInfo {
    NSString* email = contactInfo[@"email"];
    NSString* name = contactInfo[@"name"];
    NSData* data = contactInfo[@"imgData"];
    
    NSDictionary* dict = nil;
    if (data) {
        dict = @{email : @{@"name" : name, @"imgData" : data}};
    } else {
        dict = @{email : @{@"name" : name}};
    }
    
    [LocalStorage setAccountDataFromDict:dict];
    
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row%2 == 0) {
        return nil;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString* email = cell.detailTextLabel.text;
    if ([email isEqualToString:self.noEmail]) {
        [self proposeToSetEmailForUserAtCell:cell];
        return nil;
    }
    
    bool selected = [self.selectedEmails containsObject:email];
    if (selected) {
        
        [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [self.selectedEmails removeObject:email];
        
    } else {
        NSDictionary* contactInfo = self.sortedContacts[indexPath.row/2];
        [self cacheContactInfo:contactInfo];
        
        [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedEmails addObject:email];
        
    }
    
    [self updateNavigationBar];
    return nil;
}

-(void)proposeToSetEmailForUserAtCell:(UITableViewCell *)cell
{
    NSString* text = _LOCALIZE(@"This contact does not have email defined. Do you want to add email address to this contact to be able to use it in Lokki?");
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                          message:text
                                                         delegate:self
                                                cancelButtonTitle:_LOCALIZE(@"Not now")
                                                otherButtonTitles:_LOCALIZE(@"Add email"), nil];
    alertView.tag = cell.tag;// tag will contain address book ID
    [alertView show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        Contacts* contacts = [[Contacts alloc] init];
        NSNumber* idx = [NSNumber numberWithLong:alertView.tag];
        if (![contacts showPersonContactPageForRecordID:idx fromViewController:self]) {
            UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                            message:_LOCALIZE(@"FailedToCreateContact")
                                                            delegate:nil
                                                            cancelButtonTitle:_LOCALIZE(@"OK")
                                                            otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

-(void)updateNavigationBar
{
    if (self.numberOfRequestsInProgress) {
        [[self navigationItem] setTitle:_LOCALIZE(@"Sending contacts")];
        [[self navigationItem] setRightBarButtonItems:@[]];
    } else if ([self.selectedEmails count] == 0) {
        [[self navigationItem] setTitle:_LOCALIZE(@"Select contacts")];
        [[self navigationItem] setRightBarButtonItems:@[]];
    } else {
        [[self navigationItem] setTitle:[NSString stringWithFormat:_LOCALIZE(@"Selected: %@"), @([self.selectedEmails count])]];
        UIBarButtonItem *buttonAdd = [[UIBarButtonItem alloc] initWithTitle:_LOCALIZE(@"Invite") style:UIBarButtonItemStylePlain target:self action:@selector(onAddContacts:)];
        [[self navigationItem] setRightBarButtonItems:@[buttonAdd]];
    }
    
}


- (IBAction)onAddContacts:(UIBarButtonItem *)sender
{
    if (self.numberOfRequestsInProgress) {
        NSLog(@"Do not send allow requests twice!");
        return;
    }
    
    if (![self sendSelectedContactsToServer]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self updateNavigationBar];
}



-(BOOL)sendSelectedContactsToServer
{
    self.numberOfRequestsInProgress = 1;
    NSArray* emails = self.selectedEmails;
    NSLog(@"Inviting: %@", emails);
    self.emailsSentToServer = emails;
    [self.serverApi allowContactToSeeMe:emails];
    
    
    return ([emails count] > 0);
}


- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
#ifdef DEBUG
    NSLog(@"Operation %d finished with status: %d and response %@", (int)type, (int)success, response);
#endif
    
    self.numberOfRequestsInProgress--;
    if (self.numberOfRequestsInProgress < 1) {
        if (success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DashboardNeedsUpdating" object:self];

            [Tutorial triggerExplanationAfterAddingFriends:self.emailsSentToServer];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_LOCALIZE(@"Error") message:_LOCALIZE(@"Cannot invite people right now. Please check your internet connection and try again later.") delegate:nil cancelButtonTitle:_LOCALIZE(@"OK") otherButtonTitles:nil, nil];
            [alertView show];
            [self updateNavigationBar];
            
        }
    }
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.contactsFilter = searchText;

    //self.selectedEmails = [[NSMutableArray alloc] init];
    [self loadDataAsync];
    [self updateNavigationBar];
    
    // The user clicked the [X] button or otherwise cleared the text.
    if([searchText length] == 0) {
        [searchBar performSelector: @selector(resignFirstResponder)
                        withObject: nil
                        afterDelay: 0.1];
    }
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar performSelector: @selector(resignFirstResponder)
                    withObject: nil
                    afterDelay: 0.1];
    
}

@end
