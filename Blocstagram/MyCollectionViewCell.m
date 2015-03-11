//
//  MyCollectionViewCell.m
//  Blocstagram
//
//  Created by Corey Norford on 3/11/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import "MyCollectionViewCell.h"

@implementation MyCollectionViewCell

+ (MyCollectionViewCell *)setup:(MyCollectionViewCell *)cell image:(UIImage *)image title:(NSString *)title thumbnailEdgeSize:(CGFloat)thumbnailEdgeSize{
    
    //can simply pass in contentView likely
    static NSInteger imageViewTag = 1000;
    static NSInteger labelTag = 1001;
    
    UIImageView *thumbnail = (UIImageView *)[cell.contentView viewWithTag:imageViewTag];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:labelTag];
    
    thumbnailEdgeSize = thumbnailEdgeSize;
    
    if (!thumbnail) {
        thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbnailEdgeSize, thumbnailEdgeSize)];
        thumbnail.contentMode = UIViewContentModeScaleAspectFill;
        thumbnail.tag = imageViewTag;
        thumbnail.clipsToBounds = YES;
        
        [cell.contentView addSubview:thumbnail];
    }
    
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, thumbnailEdgeSize, thumbnailEdgeSize, 20)];
        label.tag = labelTag;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
        [cell.contentView addSubview:label];
    }
    
    thumbnail.image = image;
    label.text = title;
    
    return cell;
}

@end
