//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotX

let DEFAULT_INTERSTITIAL_ID = "034709d6e1a4493d8b5da8c7a3e0249c"
let DEFAULT_REWARDED_ID     = "e3b23c46dd6a41d1a2f049eea9ca2f81"

let DEFAULT_AD_UNITS = [
  "MP4 Ad":     "034709d6e1a4493d8b5da8c7a3e0249c",
  "VPAID Ad":   "ec9e43b19e8646c19f28f08581153472",
  "Podded Ad":  "b102fcc5233b48e0b52eaee1fad500c6"
]

class MoPubViewController: ViewControllerBase, MPInterstitialAdControllerDelegate, MPRewardedVideoDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
  @IBOutlet var _loadingIndicator: UIActivityIndicatorView!
  @IBOutlet var _playInterstitialButton: UIButton!
  @IBOutlet var _playRewardedButton: UIButton!
  @IBOutlet var _interstitialID: UITextField!
  @IBOutlet var _rewardedID: UITextField!
  
  var _adController: MPInterstitialAdController?
  
  var customAdUnit = false      // for pop-up control
  
  override func viewDidLoad() {
    super.viewDidLoad()
    _interstitialID.text = Preferences.string(forKey: .MOPUB_INTERSTITIAL) ?? DEFAULT_INTERSTITIAL_ID
    _rewardedID.text = Preferences.string(forKey: .MOPUB_REWARDED) ?? DEFAULT_REWARDED_ID
    
    _interstitialID.delegate = self
    _rewardedID.delegate = self
  }
  
  override func dismissKeyboard() {
    self.view.endEditing(true)
    _interstitialID.resignFirstResponder()
    _rewardedID.resignFirstResponder()
  }
  
  @IBAction func playInterstitial(_ sender: Any) {
    dismissKeyboard()
    _playInterstitialButton.isEnabled = false
    _playRewardedButton.isEnabled = false
    
    // MoPub requires a global API key as it can't be set per-request
    SpotX.setAPIKey(Preferences.SPOTX_API_KEY)
    
    _adController = MPInterstitialAdController(forAdUnitId: interstitialID())
    guard let adController = _adController else {
      showMessage("Failed to create MoPub ad controller")
      return
    }
    adController.delegate = self
    _loadingIndicator.startAnimating()
    adController.loadAd()
  }
  
  @IBAction func playRewarded(_ sender: Any) {
    dismissKeyboard()
    _playInterstitialButton.isEnabled = false
    _playRewardedButton.isEnabled = false
    
    // MoPub requires a global API key as it can't be set per-request
    SpotX.setAPIKey(Preferences.SPOTX_API_KEY)
    
    MoPub.sharedInstance().initializeRewardedVideo(withGlobalMediationSettings: [Any](), delegate: self)
    MPRewardedVideo.loadAd(withAdUnitID: rewardedID(), withMediationSettings: [Any]())
    _loadingIndicator.startAnimating()
  }
  
  func interstitialID() -> String {
    let adId = _interstitialID.text ?? ""
    if adId == "" {
      _interstitialID.text = DEFAULT_INTERSTITIAL_ID
      return DEFAULT_INTERSTITIAL_ID
    }
    return adId
  }
  
  func rewardedID() -> String {
    let adId = _rewardedID.text ?? ""
    if adId == "" {
      _rewardedID.text = DEFAULT_REWARDED_ID
      return DEFAULT_REWARDED_ID
    }
    return adId
  }
  
  func updateAdIDs() {
    Preferences.set(interstitialID(), forKey: .MOPUB_INTERSTITIAL)
    Preferences.set(rewardedID(), forKey: .MOPUB_REWARDED)
  }
  
  func showAdFailure() {
    _loadingIndicator.stopAnimating()
    _adController = nil
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
    showMessage("Ad playback failed")
  }
  
  // MARK: Pop-up ad unit selector
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "pickerSegue" {
      // Showing the pop-up with picker view
      let vc = segue.destination
      vc.modalPresentationStyle = .popover
      vc.popoverPresentationController?.delegate = self
      
      let picker = vc.view.subviews.first as! UIPickerView
      picker.delegate = self
      picker.dataSource = self
      let adUnitArray = Array(DEFAULT_AD_UNITS.values)
      if let adUnitIndex = adUnitArray.index(of: interstitialID()) {
        customAdUnit = false
        picker.selectRow(adUnitIndex.hashValue, inComponent: 0, animated: false)
      } else {
        customAdUnit = true
        picker.selectRow(DEFAULT_AD_UNITS.count, inComponent: 0, animated: false)
      }
    }
  }
  
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
  
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return DEFAULT_AD_UNITS.count + (customAdUnit ? 1 : 0)
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    if row >= DEFAULT_AD_UNITS.count {
      return "---"
    }
    return Array(DEFAULT_AD_UNITS.keys)[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let adUnit = Array(DEFAULT_AD_UNITS.values)[row]
    _interstitialID.text = adUnit
    updateAdIDs()
  }
  
  // MARK: UITextFieldDelegate
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    updateAdIDs()
  }
  
  // MARK: MPInterstitialAdControllerDelegate
  
  func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
    NSLog("MoPub:interstitialDidLoadAd")
    // Ad loaded; play the ad
    _loadingIndicator.stopAnimating()
    _adController!.show(from: self)
  }
  
  func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
    NSLog("MoPub:interstitialDidFail")
    showAdFailure()
  }
  
  func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
    NSLog("MoPub:interstitialDidDisappear")
    _adController = nil
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
  func interstitialDidExpire(_ interstitial: MPInterstitialAdController!) {
    NSLog("MoPub:interstitialDidExpire")
    _adController = nil
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
  func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
    // Use this event to monitor click-thru
    NSLog("MoPub:interstitialDidReceiveTapEvent")
  }
  
  // MARK: MPRewardedVideoDelegate
  
  func rewardedVideoAdDidLoad(forAdUnitID adUnitID: String!) {
    NSLog("MoPub:rewardedVideoAdDidLoad")
    _loadingIndicator.stopAnimating()
    MPRewardedVideo.presentAd(forAdUnitID: adUnitID, from: self, with: nil)   // add your reward here
  }
  
  func rewardedVideoAdDidFailToLoad(forAdUnitID adUnitID: String!, error: Error!) {
    NSLog("MoPub:rewardedVideoAdDidFailToLoad")
    showAdFailure()
  }
  
  func rewardedVideoAdDidFailToPlay(forAdUnitID adUnitID: String!, error: Error!) {
    NSLog("MoPub:rewardedVideoAdDidFailToPlay")
    showAdFailure()
  }
  
  func rewardedVideoAdDidReceiveTapEvent(forAdUnitID adUnitID: String!) {
    // Use this event to monitor click-thru
    NSLog("MoPub:rewardedVideoAdDidReceiveTapEvent")
  }
  
  func rewardedVideoAdDidDisappear(forAdUnitID adUnitID: String!) {
    NSLog("MoPub:rewardedVideoAdDidDisappear")
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
  func rewardedVideoAdDidExpire(forAdUnitID adUnitID: String!) {
    NSLog("MoPub:rewardedVideoAdDidExpire")
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
}
