//
//  AvatarInPlacesCollectionViewCell.m
//  Lokki
//
//  Created by Oleg Fedorov on 1/9/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "AvatarInPlacesCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "FSConstants.h"
#import "LocalStorage.h"

@interface AvatarInPlacesCollectionViewCell()
    @property (weak, nonatomic) IBOutlet UIImageView *avatar;
    @property (strong) UserData* user;

    @property (strong) UITapGestureRecognizer* tapGesture;

@end


@implementation AvatarInPlacesCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)prepareForUserID:(UserData*)user {
    self.user = user;
    
    if (user.imgData) {
        self.avatar.image = [UIImage imageWithData:user.imgData];
    } else {
        self.avatar.image = [[FSConstants instance] getDefaultAvatarForUserWithName:user.userName];
    }
    CGRect f = self.bounds;
    self.avatar.frame = f;
    self.avatar.bounds = f;
    
    self.avatar.layer.cornerRadius = f.size.width/2;
    self.avatar.layer.borderWidth = AVATAR_BORDER_WIDTH;
    
    self.avatar.layer.borderColor = [self getAvatarColorForUser:user];
    
    self.avatar.clipsToBounds = YES;

    [self.avatar setContentMode:UIViewContentModeScaleToFill];
    
    [self assignTapGestureIfNeeded];
}

-(void)assignTapGestureIfNeeded {
    if (self.tapGesture) {
        return;
    }
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped:)];
    self.tapGesture.numberOfTapsRequired = 1;
    self.avatar.userInteractionEnabled = YES;
    [self.avatar addGestureRecognizer:self.tapGesture];
}


-(void)avatarTapped:(UITapGestureRecognizer*)tap {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivateMapAndSelectUser" object:nil userInfo:@{@"userID" : self.user.userID}];
}

// "show only own color, everyone else should not have color" (c) Igor
-(CGColorRef)getAvatarColorForUser:(UserData*)user {
    if ([[LocalStorage getLoggedInUserId] isEqualToString:user.userID]) {
        return [[[FSConstants instance] green] CGColor];
    }
    return [[UIColor clearColor] CGColor];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [self.avatar.image drawInRect:rect];
}
*/

@end
