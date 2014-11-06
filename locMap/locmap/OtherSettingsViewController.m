//
//  OtherSettingsViewController.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/5/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "OtherSettingsViewController.h"
#import "LocalStorage.h"
#import <MapKit/MapKit.h>
#import "FSConstants.h"

@interface OtherSettingsViewController ()
    @property (weak, nonatomic) IBOutlet UISegmentedControl *myVisibility;
    @property (weak, nonatomic) IBOutlet UISegmentedControl *mapMode;
    @property (weak, nonatomic) IBOutlet UIImageView *yourAvatar;
    @property (weak, nonatomic) IBOutlet UILabel *yourEmail;
    @property (weak, nonatomic) IBOutlet UILabel *yourName;
    @property (weak, nonatomic) IBOutlet UILabel *labelYourLokkiID;
    @property (weak, nonatomic) IBOutlet UILabel *labelYourLokkiIDDisclaimer;
    @property (strong, nonatomic) IBOutlet UITableView *table;

@end

@implementation OtherSettingsViewController

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
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)localize {
    self.navigationItem.title = _LOCALIZE(@"Settings");
    self.labelYourLokkiID.text = _LOCALIZE(@"Your Lokki ID is:");
    self.labelYourLokkiIDDisclaimer.text = _LOCALIZE(@"Your friends need to use this email to let you see them in Lokki.");
    
    [self.myVisibility setTitle:_LOCALIZE(@"Visible") forSegmentAtIndex:0];
    [self.myVisibility setTitle:_LOCALIZE(@"Invisible") forSegmentAtIndex:1];

    [self.mapMode setTitle:_LOCALIZE(@"Standard") forSegmentAtIndex:0];
    [self.mapMode setTitle:_LOCALIZE(@"Satellite") forSegmentAtIndex:1];
    [self.mapMode setTitle:_LOCALIZE(@"Hybrid") forSegmentAtIndex:2];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return _LOCALIZE(@"MY VISIBILITY");
    }
    if (section == 1) {
        return _LOCALIZE(@"MAP MODE");
    }
    return @"Unknown";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
-(void)viewWillAppear:(BOOL)animated
{
    [self setCorrectMapType];
    
    self.myVisibility.selectedSegmentIndex = ([LocalStorage isReportingEnabled] ? 0 : 1);
    [self initAvatarAndEmail];
}

    
    
-(void)setCorrectMapType
{
     switch([LocalStorage getMapType])
     {
         case MKMapTypeStandard:
            self.mapMode.selectedSegmentIndex = 0;
         break;
         case MKMapTypeSatellite:
            self.mapMode.selectedSegmentIndex = 1;
         break;
         case MKMapTypeHybrid:
            self.mapMode.selectedSegmentIndex = 2;
         break;
     }
}

-(void)initAvatarAndEmail
{
    NSString* me = [LocalStorage getLoggedInUserId];
    
    NSString* name = [LocalStorage getUserNameByUserID:me];
    NSData* avatar = [LocalStorage getAvatarDataByUserID:me];
    if (avatar) {
        self.yourAvatar.image = [UIImage imageWithData:avatar];
    } else {
        self.yourAvatar.image = [[FSConstants instance] getDefaultAvatarForUserWithName:name];
    }
    self.yourAvatar.layer.cornerRadius = self.yourAvatar.frame.size.width/2;
    self.yourAvatar.clipsToBounds = YES;
    
    self.yourEmail.text = [LocalStorage getEmailByUserID:me];

    if (!name) {
        name = _LOCALIZE(@"Name not found in contacts");
    }
    self.yourName.text = name;
}
    
- (IBAction)onMapModeChanged:(id)sender
{
    [LocalStorage setMapType:(int)self.mapMode.selectedSegmentIndex];
    [self setCorrectMapType];
}
    
- (IBAction)onMyVisibilityChanged:(id)sender
{
    [LocalStorage setReportingEnabled:(self.myVisibility.selectedSegmentIndex == 0 ? YES : NO)];
}
    
    
#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
    


- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    return 60;
}
        */
    
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
