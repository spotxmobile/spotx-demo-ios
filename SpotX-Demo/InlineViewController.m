//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import "InlineViewController.h"

@import SpotX;

@implementation InlineViewController {
  UIView *_topSection;
  UIView *_bottomSection;
  UIView *_adContainer;
  SpotXView *_adView;
  __weak IBOutlet UIScrollView *scrollView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // init SpotX
  [SpotX initializeWithApiKey:nil category:@"IAB1" section:@"Fiction" domain:@"com.spotxchange.demo" url:@""];
  [self setupScrollView];
  
  // setup adView
  _adView = [[SpotXView alloc] initWithFrame:_adContainer.bounds];
  [_adContainer addSubview:_adView];
  _adView.delegate = self;
  _adView.channelID = @"85394"; // this is a SpotX testing channelID
  [_adView startLoading];
}

/**
 * This function is mostly boilerplate.
 * 1. Add some gray bars to the scrollview
 * 2. Add the adContainer to the scrollView
 * 3. Add some gray bars to the scrollview
 */
- (void)setupScrollView {
  int numGrayBars = 20;
  
  // create some gray bars
  CGFloat ratio = 0.56338;
  CGFloat width = UIScreen.mainScreen.bounds.size.width - 40;
  UIColor * greyColor = UIColor.lightGrayColor;
  UIColor * playerBackgroundColor = UIColor.darkGrayColor;
  CGFloat yMark = 50;
  
  _topSection = [[UIView alloc] init];
  for (int i = 0; i < numGrayBars; i++) {
    CGRect rect = CGRectMake(0.0, yMark, width, 30.0);
    UIView *view = [[UIView alloc] initWithFrame:rect];
    [view setBackgroundColor:greyColor];
    [_topSection addSubview:view];
    yMark += 50;
  }
  yMark -= 10;
  _topSection.frame = CGRectMake(0.0, 0.0, width, yMark);
  [scrollView addSubview:_topSection];
  
  // add the adContainer to the scroll view
  _adContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, yMark, width, (width * ratio))];
  _adContainer.backgroundColor = playerBackgroundColor;
  [scrollView addSubview:_adContainer];
  yMark = yMark + _adContainer.frame.size.height + 10;
  
  
  // create some more gray bars
  _bottomSection = [[UIView alloc] initWithFrame:CGRectMake(0.0, yMark, width, 30.0)];
  for (int i = 0; i < numGrayBars; i++) {
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.0, (i*50), width, 30.0)];
    view.backgroundColor = greyColor;
    [_bottomSection addSubview:view];
    yMark += 50;
  }
  
  _bottomSection.frame = CGRectMake(_bottomSection.frame.origin.x, (_bottomSection.frame.origin.y - _adContainer.frame.size.height), _bottomSection.frame.size.width, (yMark - _bottomSection.frame.origin.y));
  [scrollView addSubview:_bottomSection];
  [scrollView setContentSize:CGSizeMake(width, (yMark - _adContainer.frame.size.height))];
}

-(void) openPlayer {
  _bottomSection.frame = CGRectMake(_bottomSection.frame.origin.x, (_bottomSection.frame.origin.y + _adContainer.frame.size.height), _bottomSection.frame.size.width, _bottomSection.frame.size.height);
  [scrollView setContentSize:CGSizeMake(scrollView.contentSize.width, (scrollView.contentSize.height + _adContainer.frame.size.height))];
  [_adContainer setHidden:false];
}

#pragma mark - SpotXAdViewDelegate

// NOTE: With inline ads, this delegate method is not used
- (void)presentViewController:(UIViewController *)viewControllerToPresent {
  [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)adFailedWithError:(NSError *)error {
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)adLoaded {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self openPlayer]; // open the player once the ad is loaded
}

- (void)adStarted {
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)adCompleted {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)adClosed {
  // this is triggered when the ad plays to completion
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)adSkipped {
  // This is triggered when the close button is pressed
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)adError:(NSString *)error {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
