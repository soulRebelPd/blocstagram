//
//  MediaFullScreenViewController.h
//  Blocstagram
//
//  Created by Corey Norford on 3/3/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media;

@interface MediaFullScreenViewController : UIViewController

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) Media *media;
- (instancetype) initWithMedia:(Media *)media;
- (void) centerScrollView;
- (void) recalculateZoomScale;

@end
