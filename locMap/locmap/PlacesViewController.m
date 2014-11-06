//
//  PlacesViewController.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/8/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "PlacesViewController.h"
#import "PlaceTableViewCell.h"
#import "LocalStorage.h"
#import "ServerApi+messages.h"

@interface PlacesViewController () <ServerApiDelegate, UIAlertViewDelegate>
    @property (atomic, strong) ServerApi* serverApi;

    @property (strong) NSDictionary* places;

    @property (strong) NSString* editingNameForPlace;
@end

@implementation PlacesViewController

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
    
    self.places = [LocalStorage getPlaces];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object: nil];

    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(onPlacesViewPlaceCellTapped:)
                                                   name:@"PlacesViewPlaceCellTapped"
                                                 object:nil];
    
}


-(void)orientationDidChange:(NSNotification*)notif {
    [self reloadData:nil];
}

-(void)onPlacesViewPlaceCellTapped:(NSNotification *) notification {
    NSLog(@"onPlacesViewPlaceCellTapped data received: %@", [notification userInfo]);
    
    NSString* placeID = [notification userInfo][@"placeID"];
    [self editPlaceWithID:placeID];
    
}



-(void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self.serverApi getPlaces];
}

// making reloadData in view will appear not working correctly
-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    
    // sometimes icons are not correctly sized so we do twice reload data and hope it helps
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reloadData:) userInfo:nil repeats:NO];
}

-(void)reloadData:(NSTimer*)t {
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfPlaces {
    return [self.places count];
}

-(NSString*)placeIDForPlaceAtIndex:(NSInteger)index {
    NSArray* keys = [self.places allKeys];
    if (index >= 0 && index < keys.count) {
        return keys[index];
    }
    return @"";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfPlaces];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaceCell";
    PlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.tag = indexPath.row;
    
    [cell prepareForPlace:[self placeIDForPlaceAtIndex:indexPath.row]];
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 91;
}






// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView beginUpdates];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        NSString* placeID = [self placeIDForPlaceAtIndex:indexPath.row];
        NSMutableDictionary* md = [self.places mutableCopy];
        [md removeObjectForKey:placeID];
        self.places = [md copy];
        
        [self.serverApi deletePlaceWithID:placeID];
        
        [tableView endUpdates];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}


-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return _LOCALIZE(@"Long press on the map to create new place");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 100.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}


- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    // Background color
    
    view.tintColor = [UIColor whiteColor];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    //[header.textLabel setNumberOfLines:0];
    //[header.textLabel setTextColor:[UIColor whiteColor]];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    header.contentView.backgroundColor = [UIColor whiteColor];
}


-(void)editPlaceWithID:(NSString*)placeID {
    self.editingNameForPlace = placeID;
    NSDictionary* place = self.places[self.editingNameForPlace];
    if (!place) {
        return;
    }
    
    // ask for name
    UIAlertView *alert = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Edit place name")
                                                      message:_LOCALIZE(@"Enter the name for the place")
                                                     delegate:self
                                            cancelButtonTitle:_LOCALIZE(@"Cancel")
                                            otherButtonTitles:_LOCALIZE(@"Done"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alert show];
    [alert textFieldAtIndex:0].text = place[@"name"];
}

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // edit name
    [self editPlaceWithID:[self placeIDForPlaceAtIndex:indexPath.row]];
    return nil;
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        //create place, open places view
        NSString* newPlaceName = [alertView textFieldAtIndex:0].text;
        NSLog(@"Editing place with new name: %@", newPlaceName);
        NSDictionary* place = self.places[self.editingNameForPlace];
        
        if (!place || [newPlaceName isEqualToString:@""] || [newPlaceName isEqualToString:place[@"name"]]) {
            return;// place name must not be empty and must not be the same
        }
        
        NSString* image = place[@"img"];
        NSString* sLat = place[@"lat"];
        NSString* sLon = place[@"lon"];
        double lat = [sLat doubleValue];
        double lon = [sLon doubleValue];

        NSNumber* n = place[@"rad"];
        double rad = [n doubleValue];
        
        [self.serverApi updatePlaceWithID:self.editingNameForPlace newName:newPlaceName newImage:image newLat:lat newLon:lon newRadius:rad];
    }
}



-(void)showDeletePlaceError {
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Error")
                                                          message:_LOCALIZE(@"Failed to delete place")
                                                         delegate:nil
                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                otherButtonTitles:nil, nil];
    [alertView show];
    
}


-(void)showEditPlaceError {
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Error")
                                                          message:_LOCALIZE(@"Failed to edit place name")
                                                         delegate:nil
                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                otherButtonTitles:nil, nil];
    [alertView show];
    
}



- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
#ifdef DEBUG
    NSLog(@"Operation %d finished with status: %d and response %@", (int)type, (int)success, response);
#endif
    int errorCode = 0;
    if (success == NO) {
        if (response && [response objectForKey:@"serverErrorCode"]) {
            NSNumber* err = response[@"serverErrorCode"];
            errorCode = (int)[err integerValue];
        }
    }
    
    switch(type) {
        case ServerOperationGetPlaces:
            if (success) {
                [LocalStorage setPlaces:response];
                self.places = [LocalStorage getPlaces];
                [self.tableView reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlacesUpdated" object:nil userInfo:nil];
            }
            break;
        case ServerOperationDeletePlace:
            if (success) {
                [self.serverApi getPlaces];
            } else {
                [self showDeletePlaceError];
            }
            [self.tableView reloadData];
            break;
        case ServerOperationEditPlace:
            if (success) {
                [self.serverApi getPlaces];
            } else {
                [self showEditPlaceError];
            }
            [self.tableView reloadData];
            break;
        default:
            NSLog(@"Unknown server operation finished!");
            break;
    }
}



@end
