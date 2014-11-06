//
//  PeopleTableViewCell.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/2/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "PeopleTableViewCell.h"

@interface PeopleTableViewCell()
    // TODO: delete properties and init all in initCell
    @property (weak, nonatomic) IBOutlet UIImageView *personAvatar;
    @property (weak, nonatomic) IBOutlet UILabel *personName;
    @property (weak, nonatomic) IBOutlet UILabel *personDesc;
    @property (weak, nonatomic) IBOutlet UILabel *personEmail;
    @property (weak, nonatomic) IBOutlet UIButton *personCheckboxCanSeeMe;
    @property (weak, nonatomic) IBOutlet UIButton *personCheckboxShowOnMap;

    @property (strong) UITapGestureRecognizer *tapRecognizerForAvatar;
@end


@implementation PeopleTableViewCell


    
// designated initializer
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}
    
- (void)prepareForReuse {
    
}
    
    // half of width gives pure round
-(void)setRoundedAvatar:(UIImageView *)avatarView cornerRadius:(float)cornerRadius {
    avatarView.layer.cornerRadius = cornerRadius;
    avatarView.clipsToBounds = YES;
}

    
-(void)initForUser:(NSString*)userID  email:(NSString*)email  name:(NSString*)name desc:(NSString*)desc avatar:(UIImage*)avatar canSeeMe:(BOOL)canSeeMe showOnMap:(BOOL)showOnMap personIsInvisible:(BOOL)invisible{
    // detects taps on avatar
    if (!self.tapRecognizerForAvatar) {
        self.tapRecognizerForAvatar = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAvatarTap)];
        self.tapRecognizerForAvatar.numberOfTapsRequired = 1;
        self.personAvatar.userInteractionEnabled = YES;
        [self.personAvatar addGestureRecognizer:self.tapRecognizerForAvatar];
    }
    
    _userID = userID;
    _userEmail = email;
    self.personAvatar.image = avatar;
    [self setRoundedAvatar:self.personAvatar cornerRadius:25];
    
    self.personDesc.text = desc;
    self.personName.text = name;
    self.personEmail.text = email;
    [self.personCheckboxCanSeeMe setSelected:canSeeMe];
    [self.personCheckboxShowOnMap setSelected:showOnMap];
    
    self.personCheckboxShowOnMap.hidden = invisible;
}
    

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)onCanSeeMeClicked:(UIButton *)sender {
    if (self.personCheckboxCanSeeMe.selected){
        [self.personCheckboxCanSeeMe setSelected:NO];
    } else {
        [self.personCheckboxCanSeeMe setSelected:YES];
    }
    
    [self.delegate onPeopleTableViewCell:self canSeeMeChanged:self.personCheckboxCanSeeMe.selected];
}
    
    
- (IBAction)onShowOnMapClicked:(UIButton *)sender {
    if (self.personCheckboxShowOnMap.selected){
        [self.personCheckboxShowOnMap setSelected:NO];
    } else {
        [self.personCheckboxShowOnMap setSelected:YES];
    }
    [self.delegate onPeopleTableViewCell:self showOnMapChanged:self.personCheckboxShowOnMap.selected];
}

-(void)onAvatarTap {
    [self.delegate onPeopleTableViewCellAvatarTap:self];
}
    
-(BOOL)personIsVisibleOnMap {
    return !self.personCheckboxShowOnMap.hidden;
}

    
@end
