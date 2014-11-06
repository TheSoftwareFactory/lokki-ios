//
//  SubscriptionsTableViewController.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/7/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "SubscriptionsTableViewController.h"
#import "InAppPurchase.h"

@interface SubscriptionsTableViewController () <InAppPurchaseDelegate>
    @property (strong) NSArray* products;

    @property (strong) InAppPurchase* inAppPurchase;
@end

@implementation SubscriptionsTableViewController

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
    self.inAppPurchase = [[InAppPurchase alloc] initWithDelegate:self];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    
    [self reload];
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reload
{
    [self.refreshControl beginRefreshing];
    [self.inAppPurchase load:@[@"LokkiPremium1Month", @"LokkiPremium1Year", @"testNonExistingS"]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"InAppPurchaseCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary* dict = self.products[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)", dict[@"title"], dict[@"id"]];
    cell.detailTextLabel.text = dict[@"price"];
    
    return cell;
}


// called when load function fails for some reason
-(void)InAppPurchase:(InAppPurchase*)inAppPurchase onLoadFailedWithError:(NSString*)error
{
    NSLog(@"InAppPurchase onLoadFailedWithError:%@", error);
    [self.refreshControl endRefreshing];
}

// called when app store request fails for some reason. error description is in error
-(void)InAppPurchase:(InAppPurchase*)inAppPurchase onRequestFailedWithError:(NSError*)error
{
    NSLog(@"InAppPurchase onRequestFailedWithError:%@", error);
    [self.refreshControl endRefreshing];
}

// called as result of load function - returns which products are valid and info about them in validProducts. invalid product id's returned in inValidProducts
// validProducts is array of NSDictionary (strings, can be NSNull):
//"id" - product ID
// "title" - product title  from appstore
// "description" - product description from appstore
// "price" - localized product price from appstore
-(void)InAppPurchase:(InAppPurchase*)inAppPurchase listOfValidProducts:(NSArray*)validProducts listOfInvalidProducts:(NSArray*)inValidProducts
{
    NSLog(@"InAppPurchase listOfValidProducts:%@, invalid:%@", validProducts, inValidProducts);
    self.products = validProducts;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}


// called when transaction state is updated. transaction contains:
// "state" - state of the transaction. can be "", "PaymentTransactionStatePurchased", "PaymentTransactionStateFailed" or PaymentTransactionStateRestored ,
// "errorCode" - NSNumber with integer error code,
// "error" - NSString with error description,
// "transactionIdentifier" - NSString identifier of the transaction,
// "productId" - NSString product ID
// "transactionDate" - NSNumber with double value of timeIntervalSince1970
-(void)InAppPurchase:(InAppPurchase*)inAppPurchase onTransactionUpdated:(NSDictionary*)transaction
{
    NSLog(@"InAppPurchase onTransactionUpdated:%@", transaction);
}


// called if restoring purchases failed
-(void)InAppPurchase:(InAppPurchase*)inAppPurchase restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"InAppPurchase restoreCompletedTransactionsFailedWithError:%@", error);
}

// called if restoring purchases succeeded
-(void)InAppPurchaseFinishedRestoringCompletedTransactions:(InAppPurchase*)inAppPurchase
{
    NSLog(@"InAppPurchase InAppPurchaseFinishedRestoringCompletedTransactions");
}


@end
