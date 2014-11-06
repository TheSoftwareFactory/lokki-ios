//
//  PeopleViewController.m
//  locmap
//
//  Created by Oleg Fedorov on 11/25/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "PeopleViewController.h"
#import "PeopleTableViewCell.h"
#import "Users.h"
#import "LocMapFormatters.h"
#import "LocalStorage.h"
#import "ServerApi+messages.h"
#import "FSConstants.h"


@interface PeopleViewController () <PeopleTableViewCellDelegate, ServerApiDelegate>
    @property (strong, nonatomic) IBOutlet UITableView *tableView;
    @property (strong) ServerApi* serverApi;

    @property (strong) NSArray* people;// of UserData
    @property (weak, nonatomic) IBOutlet UILabel *labelCanSeeMeUpper;
    @property (weak, nonatomic) IBOutlet UILabel *labelCanSeeMeBottom;
    @property (weak, nonatomic) IBOutlet UILabel *labelShowOnMapUpper;
    @property (weak, nonatomic) IBOutlet UILabel *labelShowOnMapBottom;
@end

@implementation PeopleViewController

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

    self.serverApi = [[ServerApi alloc] initWithDelegate:self];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)localize {
    self.navigationItem.title = _LOCALIZE(@"People");
    
    self.labelCanSeeMeUpper.text = _LOCALIZE(@"Can");
    self.labelCanSeeMeBottom.text = _LOCALIZE(@"see me");
    self.labelShowOnMapUpper.text = _LOCALIZE(@"Show");
    self.labelShowOnMapBottom.text = _LOCALIZE(@"on map");
}
    
-(void)viewWillAppear:(BOOL)animated
{
    Users* users = [[Users alloc] init];
    self.people = [users getUsersIncludingPeopleWhoCanSeeMe:NO];

    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(dashboardUpdated:)
                                            name:@"DashboardUpdated"
                                            object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dashboardUpdated:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DashboardUpdated"]) {
        [self reloadPeople];
    }
}

-(void)reloadPeople
{
    Users* users = [[Users alloc] init];
    self.people = [users getUsersIncludingPeopleWhoCanSeeMe:NO];
    [self.tableView reloadData];
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
    return [self.people count];
}
    

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    return 60;
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"PersonCell";
    
    PeopleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[PeopleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (cell) {
        cell.delegate = self;
        UserData* user = self.people[indexPath.row];
        
        NSString* desc;
        BOOL invisible = NO;
        if ([user.userLastReportDate timeIntervalSince1970] < 1) {
            desc = _LOCALIZE(@"Not reported");
            invisible = YES;
        } else {
            desc = [LocMapFormatters dateDescription:user.userLastReportDate];
            invisible = NO;
        }
        
        [cell       initForUser:user.userID
                    email:user.userEmail
                    name:user.userName
                    desc:desc
                    avatar:(user.imgData ? [UIImage imageWithData:user.imgData] : [[FSConstants instance] getDefaultAvatarForUserWithName:user.userName])
                    canSeeMe:user.canSeeMe
                    showOnMap:user.showOnMap
                    personIsInvisible:invisible];
       
    }
    
    return cell;
}

// selection is not possible in this view
-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


- (IBAction)onAddButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"AddUserSegue" sender:self];
}

-(void)onPeopleTableViewCellAvatarTap:(PeopleTableViewCell*)cell
{
    NSLog(@"Avatar tapped: %@", cell.userID);
    if ([cell personIsVisibleOnMap]) {
        _userIDToCenterMap = cell.userID;
        [self performSegueWithIdentifier:@"unwindToMap" sender:self];
    }
    
}
    
    
-(void)onPeopleTableViewCell:(PeopleTableViewCell*)cell canSeeMeChanged:(BOOL)canSeeMe
{
    NSLog(@"Can see me changed to %d for %@", (int)canSeeMe, cell.userID);
    
    if (canSeeMe) {
        [self.serverApi allowContactToSeeMe:@[cell.userEmail]];
    } else {
        [self.serverApi disallowContactToSeeMe:cell.userID];
    }

}

-(void)onPeopleTableViewCell:(PeopleTableViewCell*)cell showOnMapChanged:(BOOL)showOnMap
{
    NSLog(@"Show on map changed to %d for %@", (int)showOnMap, cell.userID);
    
    [LocalStorage setShowOnMap:showOnMap forUser:cell.userID];
}



- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
#ifdef DEBUG
    NSLog(@"Operation %d finished with status: %d and response %@", (int)type, (int)success, response);
#endif
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DashboardNeedsUpdating" object:self];
    }
}

@end
