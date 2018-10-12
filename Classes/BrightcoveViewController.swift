//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit

let PLAYER_SEGUE    = "playerSegue"
let SETTINGS_SEGUE  = "settingsSegue"

class BrightcoveViewController: ViewControllerBase, UITextFieldDelegate {
  
  @IBOutlet var _vpaidControl: UISegmentedControl!
  @IBOutlet var _channelIDField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    _channelIDField?.inputAccessoryView = keyboardDoneButtonView
    _channelIDField?.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Update preference display
    let channelID: String? = Preferences.string(forKey: .CHANNEL)
    _channelIDField!.text = channelID ?? Preferences.DEFAULT_CHANNEL_ID
    let vpaid: Bool? = Preferences.bool(forKey: .VPAID)
    _vpaidControl?.selectedSegmentIndex = (vpaid ?? false) ? SEGMENT_VPAID : SEGMENT_MP4
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
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == PLAYER_SEGUE {
      // Opening the player. Update channel ID first.
      updateChannelID()
    } else if segue.identifier == SETTINGS_SEGUE {
      // When opening the settings screen, ask it to display a blue toolbar to match this screen
      let destination = segue.destination as! SettingsViewController
      destination.setPreferredTint(UIColor(red: 0, green: 0x7A/255.0, blue: 1, alpha: 1))
    }
  }

}
