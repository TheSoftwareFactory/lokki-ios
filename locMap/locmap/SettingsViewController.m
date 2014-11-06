//
//  SettingsViewController.m
//  locmap
//
//  Created by Oleg Fedorov on 11/25/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "SettingsViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "Users.h"


@interface SettingsViewController () <MFMailComposeViewControllerDelegate, UIActivityItemSource>
    @property (strong, nonatomic) IBOutlet UITableView *settingsView;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelAddPeople;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelPeople;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelSettings;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelHelp;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelSendFeedback;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelTellFriend;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelFSecureProducts;
    @property (weak, nonatomic) IBOutlet UILabel *tableLabelAbout;

@end

@implementation SettingsViewController

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
    [self localize];
}

-(void)localize {
    self.navigationItem.title = _LOCALIZE(@"Menu");
    self.tableLabelAddPeople.text = _LOCALIZE(@"Add people");
    self.tableLabelPeople.text = _LOCALIZE(@"People");
    self.tableLabelSettings.text = _LOCALIZE(@"Settings");
    self.tableLabelHelp.text = _LOCALIZE(@"Help");
    self.tableLabelSendFeedback.text = _LOCALIZE(@"Send feedback");
    self.tableLabelTellFriend.text = _LOCALIZE(@"Tell a friend about Lokki");
    self.tableLabelFSecureProducts.text = _LOCALIZE(@"F-Secure products");
    self.tableLabelAbout.text = _LOCALIZE(@"About");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source
//itms://itunes.apple.com/fi/artist/f-secure/id425351654

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = (int)[indexPath indexAtPosition:0];
    int row = (int)[indexPath indexAtPosition:1];
    
    if (section == 0 && row == 3) {
        [self onHelp];
        return nil;
    }

    if (section == 1 && row == 0) {
        [self onSendFeedback];
        return nil;
    }

    if (section == 1 && row == 1) {
        [self onTellAFriend];
        return nil;
    }
    
    if (section == 1 && row == 2) {
        [self onFSecureProducts];
        return nil;
    }

    return indexPath;
}

-(void)onHelp {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_LOCALIZE(@"HelpLink")]];
}
    
-(void)onFSecureProducts
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/artist/f-secure/id425351654"]];
}
    
    
-(void)onTellAFriend
{
    NSArray * activityItems = @[self];
    NSArray * applicationActivities = nil;
    NSArray * excludeActivities = nil;//@[UIActivityTypeCopyToPasteboard];
    
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
    activityController.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityController animated:YES completion:nil];
}

// called to determine data type. only the class of the return type is consulted. it should match what -itemForActivityType: returns later
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}
    
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if ( [activityType isEqualToString:UIActivityTypeMessage] ) {
        return _LOCALIZE(@"TellAFriendSMS");
    }
    return _LOCALIZE(@"TellAFriendGeneric");
}
    
   
 // if activity supports a Subject field. iOS 7.0
- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return _LOCALIZE(@"F-Secure Lokki is awesome!");
}
    


-(void)onSendFeedback
{
    //        if ([MFMailComposeViewController canSendMail]) {
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [controller setSubject:_LOCALIZE(@"FeedbackEmailSubject")];
    [controller setMessageBody:_LOCALIZE(@"FeedbackEmailBody") isHTML:NO];
    [controller setToRecipients:@[@"lokki-feedback@f-secure.com"]];
    if (controller) {
        [self presentViewController:controller animated:YES completion:nil];
    }
//    } else {
// Handle the error
//  }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
        if (result == MFMailComposeResultSent) {
            NSLog(@"Mail sent away!");
        }
        [self dismissViewControllerAnimated:YES completion:nil];
}


-(BOOL)havePeopleForPeopleList {
    Users* users = [[Users alloc] init];
    NSArray* people = [users getUsersIncludingPeopleWhoCanSeeMe:NO];
    return [people count] > 0;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"PeopleSegue"]) {
        if ([self havePeopleForPeopleList]) {
            return YES;
        }
        [self performSegueWithIdentifier:@"AddPeopleSegue" sender:self];
        return NO;
    }
    
    return YES;
}

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}


@end
