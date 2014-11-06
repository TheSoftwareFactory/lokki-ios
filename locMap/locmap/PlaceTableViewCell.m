//
//  PlaceTableViewCell.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/9/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "PlaceTableViewCell.h"
#import "AvatarInPlacesCollectionViewCell.h"
#import "FSConstants.h"
#import "LocalStorage.h"
#import "Users.h"


@interface PlaceTableViewCell() <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

    @property (weak, nonatomic) IBOutlet UILabel *placeName;
    @property (weak, nonatomic) IBOutlet UICollectionView *avatarsCollection;

    @property (strong) UIImageView* backgroundImageView;

    @property (strong) NSString* placeID;
    @property (strong) NSDictionary* placeInfo;
    @property (strong) CLLocation* placeLocation;
    @property double placeRadius;
    @property (strong) NSArray* avatarsData;//array of UserData*
@end

@implementation PlaceTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(NSString*)getBackgroundImageName {
    int idx = (int)self.tag;
    NSArray* allImages = @[@"place_01.jpg", @"place_02.jpg", @"place_03.jpg", @"place_04.jpg", @"place_05.jpg", @"place_06.jpg", @"place_07.jpg", @"place_08.jpg", @"place_09.jpg"];
    idx = idx%allImages.count;
    return allImages[idx];
}


-(void)prepareBackgroundImageView {
    if (self.backgroundImageView) {
        return;
    }
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    
    CGRect f = self.contentView.frame;
    f.size.width = 320;
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:f];
    
    UIImage* im = [UIImage imageNamed:[self getBackgroundImageName]];
    
    self.backgroundImageView.image = im;
    [self.contentView addSubview:self.backgroundImageView];

    UIImageView* blackGradient = [[UIImageView alloc] initWithFrame:f];
    im = [UIImage imageNamed:@"blackgradient"];
    blackGradient.image = im;
    [self.contentView addSubview:blackGradient];
    
    UIImageView* whiteGradient = [[UIImageView alloc] initWithFrame:f];
    im = [UIImage imageNamed:@"whitegradient"];
    whiteGradient.image = im;
    [self.contentView addSubview:whiteGradient];
    
    [self.contentView sendSubviewToBack:whiteGradient];
    [self.contentView sendSubviewToBack:blackGradient];
    [self.contentView sendSubviewToBack:self.backgroundImageView];
    
    
}

-(void)cellTapped:(UITapGestureRecognizer*)tap {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlacesViewPlaceCellTapped" object:nil userInfo:@{@"placeID" : self.placeID}];
}


-(void)prepareForPlace:(NSString*)placeID {
    self.placeID = placeID;
    NSDictionary* places = [LocalStorage getPlaces];
    self.placeInfo = places[placeID];
    self.placeName.text = self.placeInfo[@"name"];
    self.placeRadius = [self.placeInfo[@"rad"] doubleValue];

    self.avatarsCollection.dataSource = self;
    self.avatarsCollection.delegate = self;
    
    [self recalculateWhoIsInPlace];
    [self prepareBackgroundImageView];

    [self.avatarsCollection reloadData];
}

-(CLLocation*)getPlaceLocation {
    NSString* sLat = self.placeInfo[@"lat"];
    NSString* sLon = self.placeInfo[@"lon"];
    double lat = [sLat doubleValue];
    double lon = [sLon doubleValue];
    CLLocation* loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    return loc;
}

-(void)recalculateWhoIsInPlace {
    self.avatarsData = @[];
    self.placeLocation = [self getPlaceLocation];
    Users* u = [[Users alloc] init];
    NSArray* users = [u getUsersIncludingMyself:YES excludingOnesIDontWantToSee:YES];
    
    for(UserData* user in users) {
        if ([self isUserInPlace:user]) {
            self.avatarsData = [self.avatarsData arrayByAddingObject:user];
        }
    }
    
    
//    self.avatarsData = @[@"defaultAvatar", @"defaultAvatar", @"defaultAvatar"];
    
}


-(BOOL)isUserInPlace:(UserData*)user {
    CLLocation* loc = [[CLLocation alloc] initWithLatitude:user.coord.latitude longitude:user.coord.longitude];
    if ([self.placeLocation distanceFromLocation:loc] <= self.placeRadius) {
        return YES;
    }
    return NO;
    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.avatarsData.count;
    return count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //int row = indexPath.row;
    AvatarInPlacesCollectionViewCell *cell = (AvatarInPlacesCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"AvatarCell" forIndexPath:indexPath];

    [cell prepareForUserID:self.avatarsData[indexPath.row]];
    
    return cell;
    
}

-(float)currentAvatarSize {
    CGRect f = self.avatarsCollection.frame;
    float d = 5;//distance between items
    float w = f.size.width;//full container width
    float n = self.avatarsData.count;//amount of items
    if (n == 0) {
        return AVATAR_WIDTH;
    }
    float x = (w - d*n + d)/n - 1;
    if (x > AVATAR_WIDTH + AVATAR_BORDER_WIDTH*2) {
        return AVATAR_WIDTH + AVATAR_BORDER_WIDTH*2;
    }
    return x;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float avatarSize = [self currentAvatarSize];
    return CGSizeMake(avatarSize, avatarSize);
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    float avatarSize = [self currentAvatarSize];
    CGRect f = collectionView.frame;
    CGFloat leftInset = (f.size.width - (avatarSize + 10)*self.avatarsData.count)/2;//5 is for distance between objects
    CGFloat topInset = (f.size.height/2 - avatarSize/2);
    if (leftInset < 1) {
        leftInset = 1;
    }
    if (topInset < 1) {
        topInset = 1;
    }
    
    
    //leftInset = 0;
    //topInset = 0;
    return UIEdgeInsetsMake(topInset, leftInset, 0, 0);
}

@end
