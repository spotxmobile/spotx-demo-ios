//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotX
import GoogleMobileAds;

let SPOTX_ADMOB_APPID       = "ca-app-pub-3831702055122907~6634335857"

let SPOTX_INTERSTITIAL_ID   = "ca-app-pub-3831702055122907/7657534644"
let SPOTX_REWARDED_ID       = "ca-app-pub-3831702055122907/3610069309"

let interPresetUnits = [
  "Google Ad Unit":     "ca-app-pub-3940256099942544/4411468910",
  "SpotX Regular Ad Unit":   SPOTX_INTERSTITIAL_ID,
  "SpotX VPAID Ad Unit":   "ca-app-pub-3831702055122907/6100501279",
  "SpotX Podding Ad Unit": "ca-app-pub-3831702055122907/2943854894"
]

let rewardPresetUnits = [
  "Google Ad Unit":         "ca-app-pub-3940256099942544/1712485313",
  "SpotX Regular Ad Unit":       SPOTX_REWARDED_ID,
  "SpotX VPAID Ad Unit":   "ca-app-pub-3831702055122907/2161256264",
  "SpotX Podding Ad Unit": "ca-app-pub-3831702055122907/2313299501"
]

class AdMobViewController: ViewControllerBase, GADInterstitialDelegate, GADRewardBasedVideoAdDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
  @IBOutlet var _loadingIndicator: UIActivityIndicatorView!
  @IBOutlet var _playInterstitialButton: UIButton!
  @IBOutlet var _playRewardedButton: UIButton!
  
  @IBOutlet var _interstitialID: UITextField!
  @IBOutlet var _rewardedID: UITextField!
  var _interstitial: GADInterstitial!
  
  // For the UIPicker
  var _presetUnits: [String: String]?
  weak var _pickerField: UITextField?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    _interstitialID.text = Preferences.string(forKey: .ADMOB_INTERSTITIAL) ?? SPOTX_INTERSTITIAL_ID
    _rewardedID.text = Preferences.string(forKey: .ADMOB_REWARDED) ?? SPOTX_REWARDED_ID
    
    _interstitialID.delegate = self
    _rewardedID.delegate = self
    
    GADMobileAds.configure(withApplicationID: SPOTX_ADMOB_APPID)
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
    
    let request: GADRequest = GADRequest.init()
    request.testDevices = [ kGADSimulatorID ]
    let extras: GADCustomEventExtras = GADCustomEventExtras.init()
    
    extras.setExtras(["SampleExtra" : true], forLabel: "Swift Interstitial")
    request.register(extras)
    
    _interstitial = GADInterstitial.init(adUnitID: interstitialID())
    guard let _ = _interstitial else {
      showMessage("Failed to create AdMob ad controller")
      return
    }
    _interstitial.delegate = self
    _loadingIndicator.startAnimating()
    _interstitial.load(request)
  }
  
  @IBAction func playRewarded(_ sender: Any) {
    dismissKeyboard()
    _playInterstitialButton.isEnabled = false
    _playRewardedButton.isEnabled = false
    
    let request: GADRequest = GADRequest.init()
    let extras: GADCustomEventExtras = GADCustomEventExtras.init()
    extras.setExtras(["SampleExtra" : true], forLabel: "Swift Rewarded")
    request.register(extras)
    
    GADRewardBasedVideoAd.sharedInstance().delegate = self
    GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: rewardedID())
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
    Preferences.set(interstitialID(), forKey: .ADMOB_INTERSTITIAL)
    Preferences.set(rewardedID(), forKey: .ADMOB_REWARDED)
  }
  
  func showAdFailure() {
    _loadingIndicator.stopAnimating()
    _interstitial = nil
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
    showMessage("Ad playback failed")
  }
  
  // MARK: Pop-up ad unit selector
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let isInterSegue: Bool = segue.identifier == "interPickerSegue"
    let isRewardSegue = segue.identifier == "rewardPickerSegue"
    
    if (isInterSegue || isRewardSegue) {
      var adUnitIndex: Int? = NSNotFound
      if (isInterSegue) {
        _presetUnits = interPresetUnits
        adUnitIndex = Array(_presetUnits!.values).index(of: self.interstitialID())
        _pickerField = _interstitialID
      } else if (isRewardSegue) {
        _presetUnits = rewardPresetUnits
        adUnitIndex = Array(_presetUnits!.values).index(of: self.rewardedID())
        _pickerField = _rewardedID
      }
      
      // Showing the pop-up with picker view
      let vc: UIViewController = segue.destination
      vc.modalPresentationStyle = .popover
      vc.popoverPresentationController!.delegate = self
      
      // Set ourselves as the picker source
      let picker:UIPickerView = vc.view.subviews[0] as! UIPickerView
      picker.delegate = self
      picker.dataSource = self
      // Select the current ad unit (if any)
      if let _ = adUnitIndex {
        if (adUnitIndex != NSNotFound) {
          picker.selectRow(adUnitIndex!, inComponent: 0, animated: false)
        }
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
    return _presetUnits!.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return Array(_presetUnits!.keys)[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    // Set Ad Unit text field to the selected ad
    let adUnit = Array(_presetUnits!.values)[row]
    _pickerField!.text = adUnit
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
  
  // MARK: GADInterstitialDelegate
  func interstitialDidReceiveAd(_ ad: GADInterstitial) {
    NSLog("AdMob:interstitialDidReceiveAd")
    // Ad loaded; play the ad
    _loadingIndicator.stopAnimating()
    if (_interstitial.isReady) {
      _interstitial.present(fromRootViewController: self)
    } else {
      NSLog("AdMob:interstitialDidReceiveAd - Ad Not Ready")
    }
  }
  
  func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
    NSLog("AdMob:didFailToReceiveAdWithError")
    self.showAdFailure()
  }
  
  func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    NSLog("AdMob:interstitialDidFailToPresentScreen")
    self.showAdFailure()
  }
  
  func interstitialDidDismissScreen(_ ad: GADInterstitial) {
    NSLog("AdMob:interstitialDidDismissScreen")
    _interstitial = nil
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
  func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
    // Use this event to monitor click-thru
    NSLog("AdMob:interstitialWillLeaveApplication")
  }
  
  // MARK: GADRewardBasedVideoAdDelegate
  
  func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
    NSLog("AdMob:rewardBasedVideoAd:didRewardUserWithReward")
  }
  
  func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
    NSLog("AdMob:rewardBasedVideoAd:didFailToLoadWithError")
    self.showAdFailure()
  }
  
  func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    NSLog("AdMob:rewardBasedVideoAdDidReceiveAd")
    _loadingIndicator.stopAnimating()
    if (GADRewardBasedVideoAd.sharedInstance().isReady) {
      GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
    } else {
      NSLog("AdMob:rewardBasedVideoAdDidReceiveAd - Ad Not Ready")
    }
  }
  
  func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    NSLog("AdMob:rewardBasedVideoAdDidClose")
    _playInterstitialButton.isEnabled = true
    _playRewardedButton.isEnabled = true
  }
  
  func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    // Use this event to monitor click-thru
    NSLog("AdMob:rewardBasedVideoAdWillLeaveApplication")
  }
  
}

