//
//  PeopleTableViewCell.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/2/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PeopleTableViewCell;

@protocol PeopleTableViewCellDelegate
    -(void)onPeopleTableViewCellAvatarTap:(PeopleTableViewCell*)cell;
    -(void)onPeopleTableViewCell:(PeopleTableViewCell*)cell canSeeMeChanged:(BOOL)canSeeMe;
    -(void)onPeopleTableViewCell:(PeopleTableViewCell*)cell showOnMapChanged:(BOOL)showOnMap;
@end


@interface PeopleTableViewCell : UITableViewCell

    @property (weak, nonatomic) id<PeopleTableViewCellDelegate> delegate;// to receive events
    @property (strong, readonly) NSString* userID;
    @property (strong, readonly) NSString* userEmail;
    
    
    // designated initializer
    //- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
    
    -(void)initForUser:(NSString*)userID email:(NSString*)email name:(NSString*)name desc:(NSString*)desc avatar:(UIImage*)avatar canSeeMe:(BOOL)canSeeMe showOnMap:(BOOL)showOnMap personIsInvisible:(BOOL)invisible;

    -(BOOL)personIsVisibleOnMap;
@end

