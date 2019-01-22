//
//  Copyright © 2018 SpotX. All rights reserved.
//

import UIKit
import SpotX

class ViewControllerBase: UIViewController {
  
  @IBOutlet weak var _versionLabel: UILabel?
  
  var keyboardDoneButtonView: UIToolbar!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    _versionLabel?.text = "VERSION \(SpotX.version())"
    
    // create "done" button on keyboard
    keyboardDoneButtonView = UIToolbar()
    keyboardDoneButtonView.sizeToFit()
    let doneButton: UIBarButtonItem! = UIBarButtonItem(title: "Done ", style: UIBarButtonItem.Style.plain, target: self, action: #selector(doneClicked))
    let fakeButton: UIBarButtonItem! = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
    keyboardDoneButtonView.setItems([fakeButton, doneButton], animated: false)
  }
  
  @IBAction func doneClicked(_ sender: UIButton) {
    dismissKeyboard()
  }
  
  @IBAction func backgroundTap(_ sender: UITapGestureRecognizer) {
    dismissKeyboard()
  }
  
  // Used to display a message to the user
  func showMessage(_ message: String!) {
    let alert: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
    
    let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
    alert.addAction(defaultAction)
    self.present(alert, animated: true, completion: nil)
  }
  
  // Implemented by subclasses
  func dismissKeyboard() {
  }
  
}
