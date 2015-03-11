//
//  ImagesTableViewController.m
//  Blocstagram
//
//  Created by Corey Norford on 2/27/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import "ImagesTableViewController.h"
#import "DataSource.h"
#import "Media.h"
#import "User.h"
#import "Comment.h"
#import "MediaTableViewCell.h"
#import "MediaFullScreenViewController.h"
#import "MediaFullScreenAnimator.h"
#import "CameraViewController.h"
#import "ImageLibraryViewController.h"
#import "PostToInstagramViewController.h"

@interface ImagesTableViewController () <MediaTableViewCellDelegate, UIViewControllerTransitioningDelegate, CameraViewControllerDelegate, ImageLibraryViewControllerDelegate>

@property (nonatomic, weak) UIImageView *lastTappedImageView;
@property (nonatomic, weak) UIView *lastSelectedCommentView;
@property (nonatomic, assign) CGFloat lastKeyboardAdjustment;
@property (nonatomic, strong) UIPopoverController *cameraPopover;

@end


@implementation ImagesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[DataSource sharedInstance] addObserver:self forKeyPath:@"mediaItems" options:0 context:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidFire:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[MediaTableViewCell class] forCellReuseIdentifier:@"mediaCell"];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ||
        [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraPressed:)];
        self.navigationItem.rightBarButtonItem = cameraButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDidFinish:)
                                                 name:ImageFinishedNotification
                                               object:nil];
}

-(void)deleteImage {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self items].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.mediaItem = [DataSource sharedInstance].mediaItems[indexPath.row];

    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *item = [self items][indexPath.row];
    return [MediaTableViewCell heightForMediaItem:item width:CGRectGetWidth(self.view.frame)];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (NSArray *) items {
    return [DataSource sharedInstance].mediaItems;
}

- (void) dealloc
{
    [[DataSource sharedInstance] removeObserver:self forKeyPath:@"mediaItems"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DataSource sharedInstance] && [keyPath isEqualToString:@"mediaItems"]) {
        // Nothing… YET
        // We know mediaItems changed.  Let's see what kind of change it is.
        int kindOfChange = [change[NSKeyValueChangeKindKey] intValue];
        
        if (kindOfChange == NSKeyValueChangeSetting) {
            // Someone set a brand new images array
            [self.tableView reloadData];
        } else if (kindOfChange == NSKeyValueChangeInsertion ||
                   kindOfChange == NSKeyValueChangeRemoval ||
                   kindOfChange == NSKeyValueChangeReplacement) {
            // We have an incremental change: inserted, deleted, or replaced images
            
            // Get a list of the index (or indices) that changed
            NSIndexSet *indexSetOfChanges = change[NSKeyValueChangeIndexesKey];
            
            // Convert this NSIndexSet to an NSArray of NSIndexPaths (which is what the table view animation methods require)
            NSMutableArray *indexPathsThatChanged = [NSMutableArray array];
            [indexSetOfChanges enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [indexPathsThatChanged addObject:newIndexPath];
            }];
            
            // Call `beginUpdates` to tell the table view we're about to make changes
            [self.tableView beginUpdates];
            
            // Tell the table view what the changes are
            if (kindOfChange == NSKeyValueChangeInsertion) {
                [self.tableView insertRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeRemoval) {
                [self.tableView deleteRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeReplacement) {
                [self.tableView reloadRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            // Tell the table view that we're done telling it about changes, and to complete the animation
            [self.tableView endUpdates];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
        [[DataSource sharedInstance] deleteMediaItem:item];
    }
}

- (void) refreshControlDidFire:(UIRefreshControl *) sender {
    [[DataSource sharedInstance] requestNewItemsWithCompletionHandler:^(NSError *error) {
        [sender endRefreshing];
    }];
}

- (void) infiniteScrollIfNecessary {
    NSIndexPath *bottomIndexPath = [[self.tableView indexPathsForVisibleRows] lastObject];
    
    if (bottomIndexPath && bottomIndexPath.row == [DataSource sharedInstance].mediaItems.count - 1) {
        // The very last cell is on screen
        [[DataSource sharedInstance] requestOldItemsWithCompletionHandler:nil];
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
    if (item.image) {
        return 450;
    } else {
        return 250;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self infiniteScrollIfNecessary];
}

#pragma mark - BLCMediaTableViewCellDelegate

- (void) cell:(MediaTableViewCell *)cell didTapImageView:(UIImageView *)imageView {
    self.lastTappedImageView = imageView;
    
    MediaFullScreenViewController *fullScreenVC = [[MediaFullScreenViewController alloc] initWithMedia:cell.mediaItem];
    if (isPhone) {
        fullScreenVC.transitioningDelegate = self;
        fullScreenVC.modalPresentationStyle = UIModalPresentationCustom;
    } else {
        fullScreenVC.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:fullScreenVC animated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    
    MediaFullScreenAnimator *animator = [MediaFullScreenAnimator new];
    animator.presenting = YES;
    animator.cellImageView = self.lastTappedImageView;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    MediaFullScreenAnimator *animator = [MediaFullScreenAnimator new];
    animator.cellImageView = self.lastTappedImageView;
    return animator;
}

- (void) cell:(MediaTableViewCell *)cell didLongPressImageView:(UIImageView *)imageView {
    NSMutableArray *itemsToShare = [NSMutableArray array];
    
    if (cell.mediaItem.caption.length > 0) {
        [itemsToShare addObject:cell.mediaItem.caption];
    }
    
    if (cell.mediaItem.image) {
        [itemsToShare addObject:cell.mediaItem.image];
    }
    
    if (itemsToShare.count > 0) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        //[self presentViewController:activityVC animated:YES completion:nil];
        
        //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageVC];
        
        if (isPhone) {
            [self presentViewController:activityVC animated:YES completion:nil];
        } else {
            self.cameraPopover = [[UIPopoverController alloc] initWithContentViewController:activityVC];
            self.cameraPopover.popoverContentSize = CGSizeMake(320, 568);
            [self.cameraPopover presentPopoverFromBarButtonItem:nil permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

- (void) cell:(MediaTableViewCell *)cell didTwoFingerTapView:(UIImageView *)imageView {
    [[DataSource sharedInstance] downloadImageForMediaItem:cell.mediaItem];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *mediaItem = [DataSource sharedInstance].mediaItems[indexPath.row];
    if (mediaItem.downloadState == MediaDownloadStateNeedsImage) {
        [[DataSource sharedInstance] downloadImageForMediaItem:mediaItem];
    }
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    //NSArray *visibleCells = self.tableView.visibleCells;
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    
    for(NSIndexPath *path in visiblePaths)
    {
        Media *mediaItem = [DataSource sharedInstance].mediaItems[path.row];
        
        if (mediaItem.downloadState == MediaDownloadStateNeedsImage) {
            [[DataSource sharedInstance] downloadImageForMediaItem:mediaItem];
        }
    }
    
    //UITableViewCell *genericCell = [visibleCells firstObject];
    //MediaTableViewCell *mediaCell = [visiblePaths firstObject];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //[self infiniteScrollIfNecessary];
}

- (void) cellDidPressLikeButton:(MediaTableViewCell *)cell {
    [[DataSource sharedInstance] toggleLikeOnMediaItem:cell.mediaItem];
}

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MediaTableViewCell *cell = (MediaTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell stopComposingComment];
}

- (void) cellWillStartComposingComment:(MediaTableViewCell *)cell {
    self.lastSelectedCommentView = (UIView *)cell.commentView;
}

- (void) cell:(MediaTableViewCell *)cell didComposeComment:(NSString *)comment {
    [[DataSource sharedInstance] commentOnMediaItem:cell.mediaItem withCommentText:comment];
}

- (void) viewWillDisappear:(BOOL)animated {
}

#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification
{
    // Get the frame of the keyboard within self.view's coordinate system
    NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameInScreenCoordinates = frameValue.CGRectValue;
    CGRect keyboardFrameInViewCoordinates = [self.navigationController.view convertRect:keyboardFrameInScreenCoordinates fromView:nil];
    
    // Get the frame of the comment view in the same coordinate system
    CGRect commentViewFrameInViewCoordinates = [self.navigationController.view convertRect:self.lastSelectedCommentView.bounds fromView:self.lastSelectedCommentView];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    CGFloat heightToScroll = 0;
    
    CGFloat keyboardY = CGRectGetMinY(keyboardFrameInViewCoordinates);
    CGFloat commentViewY = CGRectGetMinY(commentViewFrameInViewCoordinates);
    CGFloat difference = commentViewY - keyboardY;
    
    if (difference > 0) {
        heightToScroll += difference;
    }
    
    if (CGRectIntersectsRect(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates)) {
        // The two frames intersect (the keyboard would block the view)
        CGRect intersectionRect = CGRectIntersection(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates);
        heightToScroll += CGRectGetHeight(intersectionRect);
    }
    
    if (heightToScroll > 0) {
        contentInsets.bottom += heightToScroll;
        scrollIndicatorInsets.bottom += heightToScroll;
        contentOffset.y += heightToScroll;
        
        NSNumber *durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
        NSNumber *curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
        
        NSTimeInterval duration = durationNumber.doubleValue;
        UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
        UIViewAnimationOptions options = curve << 16;
        
        [UIView animateWithDuration:duration delay:0 options:options animations:^{
            self.tableView.contentInset = contentInsets;
            self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
            self.tableView.contentOffset = contentOffset;
        } completion:nil];
    }
    
    self.lastKeyboardAdjustment = heightToScroll;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom -= self.lastKeyboardAdjustment;
    
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom -= self.lastKeyboardAdjustment;
    
    NSNumber *durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    
    NSTimeInterval duration = durationNumber.doubleValue;
    UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
    UIViewAnimationOptions options = curve << 16;
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
    } completion:nil];
}


#pragma mark - Camera, CameraViewControllerDelegate, and ImageLibraryViewControllerDelegate

- (void) cameraPressed:(UIBarButtonItem *) sender {
    
    UIViewController *imageVC;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        CameraViewController *cameraVC = [[CameraViewController alloc] init];
        cameraVC.delegate = self;
        imageVC = cameraVC;
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        ImageLibraryViewController *imageLibraryVC = [[ImageLibraryViewController alloc] init];
        imageLibraryVC.delegate = self;
        imageVC = imageLibraryVC;
    }
    
    if (imageVC) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageVC];
        
        if (isPhone) {
            [self presentViewController:nav animated:YES completion:nil];
        } else {
            self.cameraPopover = [[UIPopoverController alloc] initWithContentViewController:nav];
            self.cameraPopover.popoverContentSize = CGSizeMake(320, 568);
            [self.cameraPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    
    return;
}

- (void) cameraViewController:(CameraViewController *)cameraViewController didCompleteWithImage:(UIImage *)image {
    [self handleImage:image withNavigationController:cameraViewController.navigationController];
}

- (void) imageLibraryViewController:(ImageLibraryViewController *)imageLibraryViewController didCompleteWithImage:(UIImage *)image {
    [self handleImage:image withNavigationController:imageLibraryViewController.navigationController];
}

- (void) handleImage:(UIImage *)image withNavigationController:(UINavigationController *)nav {
    if (image) {
        PostToInstagramViewController *postVC = [[PostToInstagramViewController alloc] initWithImage:image];
        
        [nav pushViewController:postVC animated:YES];
    } else {
        if (isPhone) {
            [nav dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.cameraPopover dismissPopoverAnimated:YES];
            self.cameraPopover = nil;
        }
    }
}

#pragma mark - Popover Handling

- (void) imageDidFinish:(NSNotification *)notification {
    if (isPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.cameraPopover dismissPopoverAnimated:YES];
        self.cameraPopover = nil;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration{
    [self.cameraPopover dismissPopoverAnimated:YES];
}

@end
