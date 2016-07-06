//
//  Copyright © 2016 SpotX, Inc. All rights reserved.
//

#import "MainViewController.h"

@import SpotX;

@implementation MainViewController {
  IBOutlet UIButton *_button;
  SpotXView *_ad;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [SpotX initializeWithApiKey:nil category:@"IAB1" section:@"Fiction" domain:@"com.spotxchange.demo" url:@""];
  [self loadNextAd];
}

- (void)loadNextAd {
  _ad = [[SpotXView alloc] initWithFrame:self.view.bounds];
  _ad.delegate = self;
  _ad.channelID = @"85394";

  [self showLoadingIndicator];
  [_ad startLoading];
}

- (void)showLoadingIndicator {
  _button.enabled = NO;
}

- (void)hideLoadingIndicator {
  _button.enabled = YES;
}

- (IBAction)playAd:(id)sender {
  [_ad show];
}


#pragma mark - SpotXAdViewDelegate

- (void)presentViewController:(UIViewController *)viewControllerToPresent {
  [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)adFailedWithError:(NSError *)error {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self hideLoadingIndicator];
  [self loadNextAd];
}

- (void)adLoaded {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self hideLoadingIndicator];
}

- (void)adStarted {
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)adCompleted {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
  [self loadNextAd];
}

- (void)adClosed {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
  [self loadNextAd];
}

- (void)adError:(NSString *)error {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [self dismissViewControllerAnimated:YES completion:nil];
  [self loadNextAd];
}

@end
