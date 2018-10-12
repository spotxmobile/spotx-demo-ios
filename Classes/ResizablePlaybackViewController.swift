//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotX

class ResizablePlaybackViewController: UIViewController, SpotXAdPlayerDelegate {
  
  @IBOutlet weak var _containerView: UIView?
  @IBOutlet weak var _containerViewHeight: NSLayoutConstraint?
  @IBOutlet weak var _loadingIndicator: UIActivityIndicatorView?
  
  private var _player: SpotXResizableAdPlayer?
  
  public static func newInstance() -> ResizablePlaybackViewController {
    return UIStoryboard(name: "ResizablePlaybackViewController", bundle: nil).instantiateInitialViewController() as! ResizablePlaybackViewController
  }
  
  public func playAd() {
    _player = SpotXResizableAdPlayer(in: _containerView)
    _player?.delegate = self
    _player?.load()
  }
  
  @IBAction public func onBackButtonPressed() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction public func sliderValueChanged(_ slider: UISlider) {
    let size = slider.value
    _player?.setSize(size)
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
    _containerViewHeight?.constant = 0
    UIView.animate(withDuration: 0.75) {
      self.view.layoutIfNeeded()
    }
  }

}
