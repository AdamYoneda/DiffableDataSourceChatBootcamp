//


import UIKit

protocol OwnMessageCollectionViewImageCellDelegate: AnyObject {
    func onOwnImageViewTapped(cell: OwnMessageCollectionViewImageCell, imageView: UIImageView)
    func longTapImageCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool, image: UIImage)
}

final class OwnMessageCollectionViewImageCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    
    @IBOutlet var subStackViews: [UIStackView]!
    @IBOutlet var subStackImageViews: [UIImageView]!
    
    //MARK: NSConstraints
    
    // stackView
    @IBOutlet weak var stackViewWidthConstraintWithSingleImage: NSLayoutConstraint!
    @IBOutlet weak var stackViewWidthConstraintWithMultiImage: NSLayoutConstraint!
    
    // リアクションなし
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var stackViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    static let nib = UINib(nibName: "OwnMessageCollectionViewImageCell", bundle: nil)
    static let nibName = "OwnMessageCollectionViewImageCell"
    static let cellIdentifier = "OwnMessageCollectionViewImageCell"
    
    weak var delegate: OwnMessageCollectionViewImageCellDelegate?
    
    private var indexPath: IndexPath?
    private var message: Message?
    
    var elaspedTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var pastTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy/MM/dd/ HH:mm"
        return formatter
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUpStackView()
        setUpTapGesture()
        setUpImageViews()
    }
    
    private func setUpStackView() {
        stackView.clipsToBounds = true
        stackView.allMaskedCorners()
    }
    
    private func setUpTapGesture() {
        subStackImageViews.forEach({
            let tapGesture = UITapGestureRecognizer(
                target: self,
                action: #selector(onOwnImageViewTapped(_:))
            )
            $0.addGestureRecognizer(tapGesture)
            
            let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapImageCell(_:)))
            longTapGesture.minimumPressDuration = 0.3
            longTapGesture.delegate = self
            $0.addGestureRecognizer(longTapGesture)
        })
    }
    
    private func setUpImageViews() {
        subStackImageViews.forEach {
            $0.backgroundColor = .systemGray6
        }
    }
    
    func configure(_ message: Message, delegate: OwnMessageCollectionViewImageCellDelegate, indexPath: IndexPath) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        self.message = message
        
        if message.read {
            readLabel.isHidden = false
        } else {
            readLabel.isHidden = true
        }
        
        let date = message.updated_at.dateValue()
        if Calendar.current.isDateInToday(date) {
            dateLabel.text = elaspedTime.string(from: message.updated_at.dateValue())
        } else if Calendar.current.isDateInYesterday(date) {
            dateLabel.text = "昨日 " + elaspedTime.string(from: message.updated_at.dateValue())
        } else {
            dateLabel.text = pastTime.string(from: message.updated_at.dateValue())
        }
        
        let mediaURLs = message.photos
        // stackViewの大枠のサイズを決定
        if mediaURLs.count == 1 {
            stackViewWidthConstraintWithSingleImage.isActive = true
            stackViewWidthConstraintWithMultiImage.isActive = false
        } else if mediaURLs.count > 1 {
            stackViewWidthConstraintWithSingleImage.isActive = false
            stackViewWidthConstraintWithMultiImage.isActive = true
        }
        // stackViewに表示するimageViewを判定
        subStackImageViews.forEach({
            if let mediaURL = mediaURLs[safe: $0.tag] {
                $0.isHidden = false
                $0.setImage(withURLString: mediaURL)
            } else {
                $0.isHidden = true
            }
        })
        // stackViewに表示を判定
        subStackViews.forEach({
            $0.isHidden = (mediaURLs[safe: $0.tag * 2] == nil ? true : false)
        })
        
        if message.reactionEmoji.isEmpty {
            reactionLabel.isHidden = true
            dateLabelBottomConstraint.isActive = true
            dateLabelBottomConstraintWithReaction.isActive = false
            stackViewBottomConstraint.isActive = true
            stackViewBottomConstraintWithReaction.isActive = false
        } else {
            reactionLabel.isHidden = false
            reactionLabel.text = message.reactionEmoji
            dateLabelBottomConstraint.isActive = false
            dateLabelBottomConstraintWithReaction.isActive = true
            stackViewBottomConstraint.isActive = false
            stackViewBottomConstraintWithReaction.isActive = true
        }
    }
    
    @objc private func onOwnImageViewTapped(_ sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag {
            if let imageView = subStackImageViews[safe: tag] {
                delegate?.onOwnImageViewTapped(cell: self, imageView: imageView)
            }
        }
    }
    
    func animateReactionLabel(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.reactionBottomConstraint.constant += 50
            self?.layoutIfNeeded()
            self?.reactionLabel.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.5, animations: {
                self?.reactionBottomConstraint.constant = 0
                self?.layoutIfNeeded()
                self?.reactionLabel.transform = .identity
            }, completion: completion)
        }
    }
    
    @objc private func longTapImageCell(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed,
              let _indexPath = indexPath,
              let imageView = sender.view as? UIImageView, let image = imageView.image else { return }
        delegate?.longTapImageCell(indexPath: _indexPath, rect: stackView.frame, type: .image, isOwn: true, image: image)
    }
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
}
