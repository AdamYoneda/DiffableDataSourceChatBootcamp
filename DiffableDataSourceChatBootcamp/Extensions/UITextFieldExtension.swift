
import UIKit

extension UITextField {
    func setToolbar(action: Selector?) {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 45))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: action)
        toolbar.setItems([spacelItem, doneItem], animated: true)
        inputAccessoryView = toolbar
    }
}
