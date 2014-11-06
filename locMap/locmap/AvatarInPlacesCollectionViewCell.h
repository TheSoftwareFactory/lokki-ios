//
//  AvatarInPlacesCollectionViewCell.h
//  Lokki
//
//  Created by Oleg Fedorov on 1/9/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserData.h"

@interface AvatarInPlacesCollectionViewCell : UICollectionViewCell

    -(void)prepareForUserID:(UserData*)user;
@end
