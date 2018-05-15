//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "InlinePlaybackViewController.h"
#import "Preferences.h"

@interface InlinePlaybackViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewHeight;

@property (nonatomic, strong) SpotXInlineAdPlayer* player;

@end

@implementation InlinePlaybackViewController

+ (instancetype)newInstance {
  return (InlinePlaybackViewController *) [[UIStoryboard storyboardWithName:@"InlinePlaybackViewController" bundle:nil] instantiateInitialViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];

  [_loadingIndicator startAnimating];
}

- (void)dismiss:(id)sender {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playAd {
  _player = [[SpotXInlineAdPlayer alloc] initInView:_containerView];
  _player.delegate = self;
  [_player load];
}

-(void)showMessage:(NSString *)message completion:(void (^)(void))completion {
  UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * action) {}];
  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:completion];
}

#pragma mark - Methods for demoing improved user experience

- (void)collapsePlayerAnimated {
  self.containerViewHeight.active = NO;
  [UIView animateWithDuration:0.75 animations:^{
    [self.view layoutIfNeeded];
  }];
}

#pragma mark - SpotXAdPlayerDelegate

- (SpotXAdRequest *_Nullable)requestForPlayer:(SpotXAdPlayer *_Nonnull)player {
  return [Preferences requestWithSettings];
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player didLoadAds:(SpotXAdGroup *_Nullable)group error:(NSError *_Nullable)error {
  [_loadingIndicator stopAnimating];

  if (group.ads.count > 0) {
    [player start];
  }
  else {
    [self showMessage:@"No Ads Available" completion: ^() {
      // NOTE: For `Inline` placements, don't dismiss the VC
      // NOTE: We can hide the player if we want though, for example:
      [self collapsePlayerAnimated];
    }];
  }
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupStart:(SpotXAdGroup *_Nonnull)group {

}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupComplete:(SpotXAdGroup *_Nonnull)group {
  // NOTE: For `Inline` placements, don't dismiss the VC
  // NOTE: We can hide the player if we want though, for example:
  [self collapsePlayerAnimated];
}


- (void)spotx:(SpotXAdPlayer *_Nonnull)player adTimeUpdate:(SpotXAd *_Nonnull)ad timeElapsed:(double)seconds {
  NSLog(@"SDK:Inline:adTimeUpdate: %f", seconds);
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adClicked:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Inline:adClicked");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adComplete:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Inline:adComplete");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adSkipped:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Inline:adSkipped");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adUserClose:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Inline:adUserClose");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adError:(SpotXAd *_Nullable)ad error:(NSError *_Nullable)error {
  NSLog(@"SDK:Inline:adError: %@", error.localizedDescription);
  [self showMessage:error.localizedDescription completion:^() {
    // NOTE: For `Inline` placements, don't dismiss the VC
    // NOTE: We can hide the player if we want though, for example:
    [self collapsePlayerAnimated];
  }];
}
@end
