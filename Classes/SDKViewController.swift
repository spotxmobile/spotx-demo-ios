//
//  SDKViewController.swift
//  SpotX-Demo-Swift
//

import UIKit
import SpotX
import CoreLocation

// Segmented control values

let SEGMENT_MP4: Int = 0;
let SEGMENT_VPAID: Int = 1;

// User Default preferences
let PREF_SDK_CHANNEL = "Channel";   // Channel ID (SDK view)
let PREF_VPAID = "VPAID";           // VPAID on or off

// Default values when we can't find the User Default
let DEFAULT_CHANNEL_ID = "85394";   // Channel ID Default

class SDKViewController: UIViewController, SpotXAdPlayerDelegate, UITextFieldDelegate {
  
  var _player: SpotXInterstitialAdPlayer?;
  
  @IBOutlet weak var _loadingIndicator: UIActivityIndicatorView?;
  @IBOutlet weak var _playAdButton: UIButton?;
  @IBOutlet weak var _vpaidControl: UISegmentedControl?;
  @IBOutlet weak var _channelIDField: UITextField?;
  @IBOutlet weak var _versionLabel: UILabel?;
  
  var _locManager: CLLocationManager?;

  override func viewDidLoad() {
    super.viewDidLoad();
    
    _versionLabel?.text = "VERSION \(SpotX.version())";
    
    // create "done" button on keyboard
    let keyboardDoneButtonView: UIToolbar! = UIToolbar();
    keyboardDoneButtonView.sizeToFit();
    let doneButton: UIBarButtonItem! = UIBarButtonItem(title: "Done ", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SDKViewController.doneClicked));
    let fakeButton: UIBarButtonItem! = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil);
    keyboardDoneButtonView.setItems([fakeButton, doneButton], animated: false);
    _channelIDField?.inputAccessoryView = keyboardDoneButtonView;
    _channelIDField?.delegate = self;
    
    // Request location permissions if they haven't been granted yet.
    // In your own app, you can do this at any time to enable geo-targeting. If you don't request permission, or if the user denies it,
    // the SDK will not pass location info.
    if(_locManager == nil){
      _locManager = CLLocationManager();
      _locManager?.requestWhenInUseAuthorization();
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated);
    
    // Update preference display
    let channelID: String? = UserDefaults.standard.string(forKey: PREF_SDK_CHANNEL);
    if let channelIDCons = channelID {
      _channelIDField!.text = channelIDCons;
    } else {
      _channelIDField!.text = DEFAULT_CHANNEL_ID;
    }
    let vpaid: Bool? = UserDefaults.standard.bool(forKey: PREF_VPAID);
    if let vpaidCons = vpaid {
      _vpaidControl?.selectedSegmentIndex = vpaidCons ? SEGMENT_VPAID : SEGMENT_MP4;
    } else {
      _vpaidControl?.selectedSegmentIndex = SEGMENT_MP4;
    }
  }
  
  @IBAction func setVPAID(_ sender: UISegmentedControl) {
    let enable: Bool = sender.selectedSegmentIndex == SEGMENT_VPAID;
    UserDefaults.standard.set(enable, forKey: PREF_VPAID);
  }
  
  @IBAction func doneClicked(_ sender: UIButton) {
    self.view.endEditing(true);
    _channelIDField?.resignFirstResponder();
  }
  
  @IBAction func backgroundTap(_ sender: UITapGestureRecognizer) {
    self.view.endEditing(true);
    _channelIDField?.resignFirstResponder();
  }

  private func updateChannelID() {
    var channelID: String? = _channelIDField?.text;
    if (channelID == nil) {
      channelID = DEFAULT_CHANNEL_ID;
    }
    UserDefaults.standard.set(channelID, forKey: PREF_SDK_CHANNEL);
  }
  
  public func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateChannelID();
  }
  
  @IBAction func play(_ sender: UIButton?) {
    _channelIDField?.resignFirstResponder();
    _playAdButton?.isEnabled = false;
    
    self.playInterstitial();
  }
  
  private func showMessage(message: String!) {
    let alert: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert);
    
    let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action: UIAlertAction) in
      }
    alert.addAction(defaultAction);
    self.present(alert, animated: true, completion: nil);
  }
  
  private func playInterstitial() {
    _loadingIndicator?.startAnimating();
    
    _player = SpotXInterstitialAdPlayer();
    _player!.delegate = self;
    _player!.load();
  }
  
  // MARK: SpotXAdPlayerDelegate methods
  public func request(for player: SpotXAdPlayer) -> SpotXAdRequest? {
    // Create a request with our API key
    let request: SpotXAdRequest = SpotXAdRequest(apiKey: "apikey-1234")!;
    
    var channelID: String? = UserDefaults.standard.string(forKey: PREF_SDK_CHANNEL);
    if (channelID == nil) {
      channelID = DEFAULT_CHANNEL_ID;
    }
    request.setChannel(channelID!);
    
    // This is how to request a VPAID ad
    let vpaid: Bool? = UserDefaults.standard.bool(forKey: PREF_VPAID);
    if let vpaidCons = vpaid {
      if (vpaidCons) {
        request.setParam("VPAID", value: "js");
      }
    }
    
    return request;
  }
  
  public func spotx(_ player: SpotXAdPlayer, didLoadAds group: SpotXAdGroup?, error: Error?) {
    _loadingIndicator?.stopAnimating();
    
    if (group != nil && group!.ads.count > 0) {
      player.start();
    } else {
      self.showMessage(message: "No Ads Available");
      _playAdButton?.isEnabled = true;
    }
  }
  
  public func spotx(_ player: SpotXAdPlayer, adGroupStart group: SpotXAdGroup) {
    
  }
  
  public func spotx(_ player: SpotXAdPlayer, adGroupComplete group: SpotXAdGroup) {
    _playAdButton?.isEnabled = true;
    _player = nil;
  }
  
  public func spotx(_ player: SpotXAdPlayer, adTimeUpdate ad: SpotXAd, timeElapsed seconds: Double) {
    NSLog("SDK:Interstitial:adTimeUpdate: %f", seconds);
  }
  
  public func spotx(_ player: SpotXAdPlayer, adClicked ad: SpotXAd) {
    NSLog("SDK:Interstitial:adClicked");
  }
  
  public func spotx(_ player: SpotXAdPlayer, adComplete ad: SpotXAd) {
    NSLog("SDK:Interstitial:adComplete");
  }
  
  public func spotx(_ player: SpotXAdPlayer, adSkipped ad: SpotXAd) {
    NSLog("SDK:Interstitial:adSkipped");
  }
  
  public func spotx(_ player: SpotXAdPlayer, adUserClose ad: SpotXAd) {
    NSLog("SDK:Interstitial:adUserClose");
  }
  
  public func spotx(_ player: SpotXAdPlayer, adError ad: SpotXAd?, error: Error?) {
    _playAdButton?.isEnabled = true;
    _player = nil;
    
    if let errorCons = error {
      NSLog("SDK:Interstitial:adError: " + errorCons.localizedDescription);
    }
    self.presentingViewController?.dismiss(animated: true, completion: {
      self.showMessage(message: error?.localizedDescription);
    });
  }
}
