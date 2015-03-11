//
//  MyCollectionViewCell.h
//  Blocstagram
//
//  Created by Corey Norford on 3/11/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyCollectionViewCell : UICollectionViewCell

+ (MyCollectionViewCell *)setup:(UICollectionViewCell *)cell image:(UIImage *)image title:(NSString *)title thumbnailEdgeSize:(CGFloat)thumbnailEdgeSize;

@end
