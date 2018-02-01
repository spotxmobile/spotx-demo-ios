//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import "InterstitialViewController.h"

@import SpotX;

@implementation InterstitialViewController {
  SpotXView *_ad;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (IBAction)playAd:(id)sender {
  [SpotX initializeWithApiKey:nil category:@"IAB1" section:@"Fiction" domain:@"com.spotxchange.demo" url:@""];
  _ad = [[SpotXView alloc] initWithFrame:self.view.bounds];
  _ad.delegate = self;
  _ad.channelID = @"85394";
  [_ad startLoading];
}


#pragma mark - SpotXAdViewDelegate

- (void)presentViewController:(UIViewController *)viewControllerToPresent {
  [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)adFailedWithError:(NSError *)error {
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)adLoaded {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [_ad show];
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
