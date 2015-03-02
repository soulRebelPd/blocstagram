//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Corey Norford on 2/27/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

 @class Media;

@interface MediaTableViewCell : UITableViewCell
@property (nonatomic, strong) Media *mediaItem;
 + (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width;
@end
