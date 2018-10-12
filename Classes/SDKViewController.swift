//
//  SDKViewController.swift
//  SpotX-Demo-Swift
//

import UIKit
import SpotX
import CoreLocation

// Segmented control values

// Presentation style
let SEGMENT_INTERSTITIAL: Int = 0
let SEGMENT_INLINE: Int = 1
let SEGMENT_RESIZABLE: Int = 2

let SEGMENT_MP4: Int = 0
let SEGMENT_VPAID: Int = 1

class SDKViewController: ViewControllerBase, SpotXAdPlayerDelegate, UITextFieldDelegate {
  
  var _player: SpotXInterstitialAdPlayer?
  
  @IBOutlet weak var _loadingIndicator: UIActivityIndicatorView?
  @IBOutlet weak var _playAdButton: UIButton?
  @IBOutlet weak var _vpaidControl: UISegmentedControl?
  @IBOutlet weak var _channelIDField: UITextField?
  @IBOutlet weak var _placementTypeControl: UISegmentedControl?
  
  var _locManager: CLLocationManager?
  
  private var _inlineVC: InlinePlaybackViewController?
  private var _resizableVC: ResizablePlaybackViewController?

  override func viewDidLoad() {
    super.viewDidLoad()
    _channelIDField?.inputAccessoryView = keyboardDoneButtonView
    _channelIDField?.delegate = self
    
    // Request location permissions if they haven't been granted yet.
    // In your own app, you can do this at any time to enable geo-targeting. If you don't request permission, or if the user denies it,
    // the SDK will not pass location info.
    if _locManager == nil {
      _locManager = CLLocationManager()
      _locManager?.requestWhenInUseAuthorization()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Update preference display
    let channelID: String? = Preferences.string(forKey: .CHANNEL)
    _channelIDField!.text = channelID ?? Preferences.DEFAULT_CHANNEL_ID
    let vpaid: Bool? = Preferences.bool(forKey: .VPAID)
    _vpaidControl?.selectedSegmentIndex = (vpaid ?? false) ? SEGMENT_VPAID : SEGMENT_MP4
    
    if _inlineVC != nil {
      // must be appearing after the inline viewcontroller has already been displayed
      _inlineVC = nil
      _playAdButton?.isEnabled = true
    }
    
    if _resizableVC != nil {
      // must be appearing after the resizable viewcontroller has already been displayed
      _resizableVC = nil
      _playAdButton?.isEnabled = true
    }
  }
  
  @IBAction func setVPAID(_ sender: UISegmentedControl) {
    let enable: Bool = sender.selectedSegmentIndex == SEGMENT_VPAID
    Preferences.set(enable, forKey: .VPAID)
  }
  
  override func dismissKeyboard() {
    self.view.endEditing(true)
    _channelIDField?.resignFirstResponder()
  }

  private func updateChannelID() {
    var channelID: String = _channelIDField?.text ?? ""
    if channelID == "" {
      channelID = Preferences.DEFAULT_CHANNEL_ID
    }
    Preferences.set(channelID, forKey: .CHANNEL)
  }
  
  public func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateChannelID()
  }
  
  @IBAction func play(_ sender: UIButton?) {
    _channelIDField?.resignFirstResponder()
    _playAdButton?.isEnabled = false
    
    switch (_placementTypeControl?.selectedSegmentIndex)! {
    case SEGMENT_INTERSTITIAL:
      self.playInterstitial()
    case SEGMENT_INLINE:
      self.playInline()
    case SEGMENT_RESIZABLE:
      self.playResizable()
    default:
      break
    }
  }
  
  private func playInterstitial() {
    _loadingIndicator?.startAnimating()
    
    _player = SpotXInterstitialAdPlayer()
    _player!.delegate = self
    _player!.load()
  }
  
  private func playInline() {
    _inlineVC = InlinePlaybackViewController.newInstance()
    present(_inlineVC!, animated: true) {
      self._inlineVC!.playAd()
    }
  }
  
  private func playResizable() {
    _resizableVC = ResizablePlaybackViewController.newInstance()
    present(_resizableVC!, animated: true) {
      self._resizableVC!.playAd()
    }
  }
  
  // MARK: SpotXAdPlayerDelegate methods
  public func request(for player: SpotXAdPlayer) -> SpotXAdRequest? {
    return Preferences.getAdRequest()
  }
  
  public func spotx(_ player: SpotXAdPlayer, didLoadAds group: SpotXAdGroup?, error: Error?) {
    _loadingIndicator?.stopAnimating()
    
    if group != nil && group!.ads.count > 0 {
      player.start()
    } else {
      self.showMessage("No Ads Available")
      _playAdButton?.isEnabled = true
    }
  }
  
  public func spotx(_ player: SpotXAdPlayer, adGroupStart group: SpotXAdGroup) {
    
  }
  
  public func spotx(_ player: SpotXAdPlayer, adGroupComplete group: SpotXAdGroup) {
    _playAdButton?.isEnabled = true
    _player = nil
  }
  
  public func spotx(_ player: SpotXAdPlayer, adTimeUpdate ad: SpotXAd, timeElapsed seconds: Double) {
    NSLog("SDK:Interstitial:adTimeUpdate: %f", seconds)
  }
  
  public func spotx(_ player: SpotXAdPlayer, adClicked ad: SpotXAd) {
    NSLog("SDK:Interstitial:adClicked")
  }
  
  public func spotx(_ player: SpotXAdPlayer, adComplete ad: SpotXAd) {
    NSLog("SDK:Interstitial:adComplete")
  }
  
  public func spotx(_ player: SpotXAdPlayer, adSkipped ad: SpotXAd) {
    NSLog("SDK:Interstitial:adSkipped")
  }
  
  public func spotx(_ player: SpotXAdPlayer, adUserClose ad: SpotXAd) {
    NSLog("SDK:Interstitial:adUserClose")
  }
  
  public func spotx(_ player: SpotXAdPlayer, adError ad: SpotXAd?, error: Error?) {
    _playAdButton?.isEnabled = true
    _player = nil
    
    if let errorCons = error {
      NSLog("SDK:Interstitial:adError: " + errorCons.localizedDescription)
    }
    self.presentingViewController?.dismiss(animated: true, completion: {
      self.showMessage(error?.localizedDescription)
    })
  }
  
  func spotx(_ player: SpotXAdPlayer, ad: SpotXAd, didChangeSkippableState skippable: Bool) {
    NSLog("SDK:Interstitial:didChangeSkippableState: " + skippable.description)
  }
}
