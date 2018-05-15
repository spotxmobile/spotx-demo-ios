//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

@import BrightcovePlayerSDK;
@import SpotXBrightcovePlugin;

#import "BrightcovePlayerController.h"
#import "Preferences.h"

#define kBigBuckBunnyVideo @"https://spotxchange-a.akamaihd.net/media/videos/orig/d/3/d35ba3e292f811e5b08c1680da020d5a.mp4"

@interface BrightcovePlayerController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property(nonatomic, strong) id<BCOVPlaybackController> controller;
@property(nonatomic, strong) BCOVPUIPlayerView* playerView;

@property(nonatomic, readwrite) BOOL prefersStatusBarHidden;

@end

@implementation BrightcovePlayerController {
  BOOL _prefersStatusBarHidden;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setup];
  [self loadVideo];
}
- (IBAction)dismiss:(id)sender {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setup {
  // Create a player view
  BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
  options.presentingViewController = self;
  BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
  BCOVPUIPlayerView* playerView = self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:controlView];
  playerView.delegate = self;
  
  // Place the player in our container and expand it to the full size of that container
  UIView* containerView = self.containerView;
  [self.containerView addSubview:playerView];
  playerView.translatesAutoresizingMaskIntoConstraints = NO;
  [playerView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor].active = YES;
  [containerView.trailingAnchor constraintEqualToAnchor:playerView.trailingAnchor].active = YES;
  [containerView.bottomAnchor constraintEqualToAnchor:playerView.bottomAnchor].active = YES;
  [playerView.topAnchor constraintEqualToAnchor:containerView.topAnchor].active = YES;
  
  // Create the SpotX playback controller with a standard ad request
  SpotXAdRequest* request = [Preferences requestWithSettings];
  BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
  // You can customize the cue point policy. For instance, this prevents ads from being replayed if the user has already seen them:
  BCOVCuePointProgressPolicy* policy = [BCOVCuePointProgressPolicy progressPolicyProcessingCuePoints:BCOVProgressPolicyProcessAllCuePoints resumingPlaybackFrom:BCOVProgressPolicyResumeFromContentPlayhead ignoringPreviouslyProcessedCuePoints:YES];
  id<BCOVPlaybackController> controller = self.controller = [manager createSpotXPlaybackControllerWithRequest:request cuePointPolicy:policy adContainer:playerView.contentOverlayView];
  playerView.playbackController = controller;
}

- (void)loadVideo {
  // Load our test video
  NSURL* videoURL = [NSURL URLWithString:kBigBuckBunnyVideo];
  BCOVVideo* video = [BCOVVideo videoWithURL:videoURL deliveryMethod:kBCOVSourceDeliveryMP4];
  
  video = [video update:^(id<BCOVMutableVideo> mutableVideo)
            {
              // Create a pre-roll ad
              BCOVCuePoint* pointBegin = [[BCOVCuePoint alloc] initWithType:kBCOVCuePointTypeAdSlot position:kCMTimeZero];
              
              // Create a mid-roll ad at the 15-second mark
              BCOVCuePoint* pointMid = [[BCOVCuePoint alloc] initWithType:kBCOVCuePointTypeAdSlot position:CMTimeMake(15000, 1000)];
              
              // Create a post-roll ad
              BCOVCuePoint* pointEnd = [[BCOVCuePoint alloc] initWithType:kBCOVCuePointTypeAdSlot position:kCMTimePositiveInfinity];
              
              mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[pointBegin, pointMid, pointEnd]];
            }];
  
  // Play the video
  _controller.delegate = self;
  [_controller setVideos:@[video]];
  [_controller play];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence {
  // Ad is interrupting playback. Hide the player controls so they don't get in the way
  self.playerView.controlsContainerView.alpha = 0.;
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence {
  self.playerView.controlsContainerView.alpha = 1.;
}

- (void)playerView:(BCOVPUIPlayerView *)playerView didTransitionToScreenMode:(BCOVPUIScreenMode)screenMode {
  self.prefersStatusBarHidden = (screenMode == BCOVPUIScreenModeFull);
}

- (BOOL)prefersStatusBarHidden {
  return _prefersStatusBarHidden || [super prefersStatusBarHidden];
}

- (void)setPrefersStatusBarHidden:(BOOL)prefersStatusBarHidden {
  _prefersStatusBarHidden = prefersStatusBarHidden;
  [self setNeedsStatusBarAppearanceUpdate];
}

@end
