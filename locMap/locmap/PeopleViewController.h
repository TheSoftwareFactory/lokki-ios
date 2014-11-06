//
//  PeopleViewController.h
//  locmap
//
//  Created by Oleg Fedorov on 11/25/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeopleViewController : UITableViewController

    @property (strong, readonly) NSString* userIDToCenterMap;// if this is not nil then use it to center map on this user ID

    -(void)reloadPeople;// reload table data when, for instance, new dashboard comes
@end
