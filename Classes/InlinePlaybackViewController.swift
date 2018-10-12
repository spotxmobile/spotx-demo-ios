//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotX

class InlinePlaybackViewController: UIViewController, SpotXAdPlayerDelegate {
  
  @IBOutlet weak var _containerView: UIView?
  @IBOutlet weak var _containerViewHeight: NSLayoutConstraint?
  @IBOutlet weak var _loadingIndicator: UIActivityIndicatorView?
  
  private var _player: SpotXInlineAdPlayer?
  
  public static func newInstance() -> InlinePlaybackViewController {
    return UIStoryboard(name: "InlinePlaybackViewController", bundle: nil).instantiateInitialViewController() as! InlinePlaybackViewController
  }
  
  public func playAd() {
    _player = SpotXInlineAdPlayer(in: _containerView)
    _player?.delegate = self
    _player?.load()
  }

  @IBAction public func onBackButtonPressed() {
    dismiss(animated: true, completion: nil)
  }
  
  func request(for player: SpotXAdPlayer) -> SpotXAdRequest? {
    return Preferences.getAdRequest()
  }
  
  func spotx(_ player: SpotXAdPlayer, didLoadAds group: SpotXAdGroup?, error: Error?) {
    _loadingIndicator?.stopAnimating()
    if error == nil {
      player.start()
    } else {
      NSLog("Failed to load ads: \(error!)")
    }
  }
  
  func spotx(_ player: SpotXAdPlayer, adGroupComplete group: SpotXAdGroup) {
    collapsePlayer()
  }
  
  func spotx(_ player: SpotXAdPlayer, adError ad: SpotXAd?, error: Error?) {
    collapsePlayer()
  }
  
  func collapsePlayer() {
    _containerViewHeight?.isActive = false
    UIView.animate(withDuration: 0.75) {
      self.view.layoutIfNeeded()
    }
  }
  
}
