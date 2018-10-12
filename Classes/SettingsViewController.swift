//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit

// MARK: One-off class used to track the settings on this screen
class SettingsEntry {
  public let label: String
  public let preferenceKey: Preferences.Key
  public weak var parent: SettingsEntry?
  public let cellType: String
  public let defaultValue: Any
  public let keyboardType: UIKeyboardType
  
  public init(_ label: String, key: Preferences.Key, parent: SettingsEntry?, type: String, default defaultValue: Any, keyboardType:UIKeyboardType = .default) {
    self.label = label
    self.preferenceKey = key
    self.parent = parent
    self.cellType = type
    self.defaultValue = defaultValue
    self.keyboardType = keyboardType
  }
  
  public func boolValue() -> Bool {
    return Preferences.bool(forKey: preferenceKey) ?? (defaultValue as! Bool)
  }
  
  public func stringValue() -> String {
    return Preferences.string(forKey: preferenceKey) ?? (defaultValue as! String)
  }
}

// MARK: Table view cells
protocol SettingsCell {
  var controller: SettingsViewController! { get set }
  var setting: SettingsEntry! { get set }
}

class SettingsToggleCell: UITableViewCell, SettingsCell {
  @IBOutlet var label: UILabel!
  @IBOutlet var toggle: UISwitch!
  
  weak var controller: SettingsViewController!
  var setting: SettingsEntry! {
    get {
      return _setting
    }
    set(setting) {
      _setting = setting
      self.label.text = setting.label
      self.toggle.isOn = setting.boolValue()
    }
  }
  private var _setting: SettingsEntry!
  
  @IBAction public func settingToggled(_ sender: UISwitch){
    Preferences.set(sender.isOn, forKey: self.setting.preferenceKey)
    // For top-level preferences, update the table if needed
    if self.setting.parent == nil {
      self.controller.updateSettings()
    }
  }
}

class SettingsInputCell: UITableViewCell, SettingsCell, UITextFieldDelegate {
  @IBOutlet var label: UILabel!
  @IBOutlet var input: UITextField!
  
  weak var controller: SettingsViewController!
  var setting: SettingsEntry! {
    get {
      return _setting
    }
    set(setting) {
      _setting = setting
      self.label.text = setting.label
      self.input.text = setting.stringValue()
      self.input.keyboardType = setting.keyboardType
    }
  }
  private var _setting: SettingsEntry!
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    controller.editingField = textField
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = textField.text ?? ""
    let value = text.replacingCharacters(in: Range(range, in: text)!, with: string)
    Preferences.set(value, forKey: self.setting.preferenceKey)
    return true
  }
}

// MARK: Main Controller
class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  @IBOutlet public var tableView: UITableView!
  @IBOutlet public var toolbarView: UIToolbar!
  
  fileprivate var editingField: UITextField?
  
  // Table view cell reuse identifiers
  private static let ToggleReuseIdentifier = "SettingsToggleCell"
  private static let InputReuseIdentifier = "SettingsInputCell"
  
  let fullSettingsArray: [SettingsEntry]
  var settingsArray: [SettingsEntry]!
  
  required init?(coder aDecoder: NSCoder) {
    let podEntry = SettingsEntry("Enable Podding", key: .POD_ENABLE, parent: nil, type: SettingsViewController.ToggleReuseIdentifier, default: false)
    let gdprEntry = SettingsEntry("Enable GDPR", key: .GDPR_ENABLE, parent: nil, type: SettingsViewController.ToggleReuseIdentifier, default: false)
    fullSettingsArray = [
      podEntry,
      SettingsEntry("Ad Count", key: .POD_COUNT, parent: podEntry, type: SettingsViewController.InputReuseIdentifier, default: "3", keyboardType: .numberPad),
      SettingsEntry("Max Ad Duration", key: .POD_AD_DURATION, parent: podEntry, type: SettingsViewController.InputReuseIdentifier, default: "60", keyboardType: .numberPad),
      SettingsEntry("Max Pod Duration", key: .POD_DURATION, parent: podEntry, type: SettingsViewController.InputReuseIdentifier, default: "180", keyboardType: .numberPad),
      
      gdprEntry,
      SettingsEntry("Consent String", key: .GDPR_CONSENT, parent: gdprEntry, type: SettingsViewController.InputReuseIdentifier, default: "GDPR Consent String", keyboardType: .asciiCapable)
    ]
    
    super.init(coder: aDecoder)
    
    updateSettings()
  }
  
  public func setPreferredTint(_ color: UIColor) {
    loadViewIfNeeded()
    toolbarView.backgroundColor = color
  }
  
  fileprivate func updateSettings() {
    var available = [SettingsEntry]()
    for option in fullSettingsArray {
      // If the parent exists, and is NOT enabled, hide this item
      if let parent = option.parent,
        !parent.boolValue() {
        continue
      }
      available.append(option)
    }
    // If the array has already been set, we're updating the table.
    // Trigger an animation if anything changed.
    if let settingsArray = self.settingsArray, settingsArray.count != available.count {
      var deletions = [IndexPath]()
      var insertions = [IndexPath]()
      // Find deletions
      for idx in 0..<settingsArray.count {
        let entry = settingsArray[idx]
        if !available.contains(where: { $0 === entry }) {
          deletions.append(IndexPath(indexes: [0, idx]))
        }
      }
      // Find insertions
      for idx in 0..<available.count {
        let entry = available[idx]
        if !settingsArray.contains(where: { $0 === entry }) {
          insertions.append(IndexPath(indexes: [0, idx]))
        }
      }
      
      self.settingsArray = available
      self.tableView.beginUpdates()
      self.tableView.deleteRows(at: deletions, with: .automatic)
      self.tableView.insertRows(at: insertions, with: .automatic)
      self.tableView.endUpdates()
    } else {
      // No changes made, or assigning for the first time.
      self.settingsArray = available
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.settingsArray.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let setting = self.settingsArray[indexPath.row]
    var cell = tableView.dequeueReusableCell(withIdentifier: setting.cellType) as! SettingsCell
    cell.controller = self
    cell.setting = setting
    return cell as! UITableViewCell
  }
  
  // MARK: Actions
  
  @IBAction public func onBackButtonPressed() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction public func onTapGesture() {
    self.editingField?.resignFirstResponder()
    self.editingField = nil
  }

}
