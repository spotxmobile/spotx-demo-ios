//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotXBrightcovePlugin

let TEST_VIDEO_URL = "https://cdn.spotxcdn.com/media/videos/orig/d/3/d35ba3e292f811e5b08c1680da020d5a.mp4"

class BrightcovePlayerController: UIViewController, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate {
  
  @IBOutlet var containerView: UIView!
  var controller: BCOVPlaybackController!
  var playerView: BCOVPUIPlayerView!
  
  @IBAction public func onBackButtonPressed() {
    dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
    loadVideo()
  }
  
  func setup() {
    // Create a player view
    let options = BCOVPUIPlayerViewOptions()
    options.presentingViewController = self
    let controlView = BCOVPUIBasicControlView.withVODLayout()
    playerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: controlView)
    playerView.delegate = self
    
    // Place the player in our container and expand it to the full size of that container
    containerView.addSubview(playerView)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    playerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    containerView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
    containerView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true
    playerView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    
    // Create the SpotX playback controller with a standard ad request
    let adRequest = Preferences.getAdRequest()
    let manager = BCOVPlayerSDKManager.shared()
    // You can customize the cue point policy. For instance, this prevents ads from being replayed if the user has already seen them:
    let policy = BCOVCuePointProgressPolicy(processingCuePoints: .processAllCuePoints, resumingPlaybackFrom: .fromContentPlayhead, ignoringPreviouslyProcessedCuePoints: true)
    controller = manager?.createSpotXPlaybackController(with: adRequest, cuePointPolicy: policy, adContainer: playerView.contentOverlayView)
    playerView.playbackController = controller
  }
  
  func loadVideo() {
    // Load our test video
    let videoURL = URL(string: TEST_VIDEO_URL)
    var video = BCOVVideo.withURL(videoURL, deliveryMethod: kBCOVSourceDeliveryMP4)
    video = video?.update({ (mutableVideo) in
      // Create a pre-roll ad
      let pointBegin = BCOVCuePoint(type: kBCOVCuePointTypeAdSlot, position: kCMTimeZero)!
      
      // Create a mid-roll ad at the 15-second mark
      let pointMid = BCOVCuePoint(type: kBCOVCuePointTypeAdSlot, position: CMTimeMake(15000, 1000))!
      
      // Create a post-roll ad
      let pointEnd = BCOVCuePoint(type: kBCOVCuePointTypeAdSlot, position: kCMTimePositiveInfinity)!
      
      mutableVideo?.cuePoints = BCOVCuePointCollection(array: [pointBegin, pointMid, pointEnd])
    })
    
    // Play the video
    controller.delegate = self
    let videos = [video!]
    controller.setVideos(videos as NSFastEnumeration)
    controller.play()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    if #available(iOS 11.0, *) {
      // Potentially rotating into landscape mode. On iPhone X, update home button status after the rotation is finished.
      DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration) {
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
      }
    }
  }
  
  private var hideBars: Bool {
    get {
      return _hideBars
    }
    set (newBool) {
      _hideBars = newBool
      setNeedsStatusBarAppearanceUpdate()
      if #available(iOS 11.0, *) {
        setNeedsUpdateOfHomeIndicatorAutoHidden()
      }
    }
  }
  private var _hideBars: Bool = false
  
  override var prefersStatusBarHidden: Bool {
    // Hide status bar in full screen
    get {
      return hideBars || super.prefersStatusBarHidden
    }
  }
  
  @available(iOS 11.0, *)
  override func prefersHomeIndicatorAutoHidden() -> Bool {
    // Hide home button in full screen, or in landscape
    return hideBars || UIApplication.shared.statusBarOrientation.isLandscape || super.prefersHomeIndicatorAutoHidden()
  }
  
  // MARK: Delegate functions
  
  func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
    // Ad is interrupting playback. Hide the player controls so they don't get in the way
    playerView.controlsContainerView.alpha = 0
  }
  
  func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
    // Ad break complete. Bring back the controls
    playerView.controlsContainerView.alpha = 1
  }
  
  func playerView(_ playerView: BCOVPUIPlayerView!, didTransitionTo screenMode: BCOVPUIScreenMode) {
    // Hide status bar when entering full screen mode
    hideBars = (screenMode == .full)
  }

}
