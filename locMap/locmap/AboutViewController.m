//
//  AboutViewController.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/5/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController () <UITableViewDataSource, UITableViewDelegate>
    @property (weak, nonatomic) IBOutlet UITableView *table;
    @property (weak, nonatomic) IBOutlet UILabel *labelVersion;
    @property (weak, nonatomic) IBOutlet UILabel *labelCopyright;

@end

@implementation AboutViewController

    
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.table.dataSource = self;
    self.table.delegate = self;
    
    [self localize];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)localize {
    self.navigationItem.title = _LOCALIZE(@"About");
    NSString* version = _LOCALIZE(@"Version: %@");
    NSString *majorVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    version = [NSString stringWithFormat:version, majorVersion];
    
    self.labelVersion.text = version;

    self.labelCopyright.text = _LOCALIZE(@"Copyright © 2013 F-Secure Corporation All rights reserved");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AboutCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (cell) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"www.f-secure.com";
        } else {
            cell.textLabel.text = _LOCALIZE(@"Privacy policy");
        }
    }
    
    return cell;
}

    
-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.f-secure.com"]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.f-secure.com/en/web/home_global/privacy/privacy-summary"]];
    }
    
    return nil;
}
 
 
@end
