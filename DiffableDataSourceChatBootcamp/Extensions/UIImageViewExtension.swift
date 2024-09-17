

import UIKit
import Nuke
import NukeExtensions

extension UIImageView {
    func setImage(withURLString urlString: String, isFade: Bool = true) {
        if let url = URL(string: urlString) {
            loadImage(with: ImageRequest(url: url), into: self)
        }
    }
}
