//
//  MessagePopMenuViewController.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/11.
//

import UIKit

protocol MessagePopMenuViewControllerDelegate: AnyObject {
    
    func replyButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController)
    func copyButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController)
    func stickerButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController)
    func showImageButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController)
    func unsendButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController)
    func reactionButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController, didSelectedReaction: String)
}

final class MessagePopMenuViewController: UIViewController {
    
    static let storyboardName = "MessagePopMenuViewController"
    static let storybaordId = "MessagePopMenuViewController"
    static let height = 130.0
    
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var stickerButton: UIButton!
    @IBOutlet weak var showImageButton: UIButton!
    @IBOutlet weak var unsendButton: UIButton!
    @IBOutlet weak var menuSpaceView: UIView!
    @IBOutlet weak var topReactionStackView: UIStackView!
    @IBOutlet weak var bottomReactionStackView: UIStackView!
    @IBOutlet var reactionButtons: [UIButton]!
    
    private let isLoginUser: Bool
    private let isUpper: Bool
    private let type: CustomMessageType
    
    weak var delegate: MessagePopMenuViewControllerDelegate?
    private let reactionArray = ["❤️", "😆", "😥", "😊", "👍"]
    
    init?(coder: NSCoder, isLoginUser: Bool, isUpper: Bool, type: CustomMessageType) {
        self.isLoginUser = isLoginUser
        self.isUpper = isUpper
        self.type = type
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // print("MessagePopMenuViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reactionButtons.forEach({
            $0.backgroundColor = .clear
            $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        })
        topReactionStackView.backgroundColor = .clear
        bottomReactionStackView.backgroundColor = .clear
        
        switch (isLoginUser, isUpper) {
        case (true, true) :
            topReactionStackView.isHidden = true
            menuSpaceView.isHidden = true
            self.preferredContentSize = CGSize(width: 261, height: 130)
            replyButton.clipsToBounds = true
            replyButton.layer.cornerRadius = 8.0
            replyButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            unsendButton.clipsToBounds = true
            unsendButton.layer.cornerRadius = 8.0
            unsendButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
        case (true, false):
            bottomReactionStackView.isHidden = true
            menuSpaceView.isHidden = true
            self.preferredContentSize = CGSize(width: 261, height: 130)
            replyButton.clipsToBounds = true
            replyButton.layer.cornerRadius = 8.0
            replyButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            unsendButton.clipsToBounds = true
            unsendButton.layer.cornerRadius = 8.0
            unsendButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
        case (false, true):
            topReactionStackView.isHidden = true
            unsendButton.isHidden = true
            self.preferredContentSize = CGSize(width: 251, height: 130)
            replyButton.clipsToBounds = true
            replyButton.layer.cornerRadius = 8.0
            replyButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            menuSpaceView.clipsToBounds = true
            menuSpaceView.layer.cornerRadius = 8.0
            menuSpaceView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            
        case (false, false):
            bottomReactionStackView.isHidden = true
            unsendButton.isHidden = true
            self.preferredContentSize = CGSize(width: 251, height: 130)
            replyButton.clipsToBounds = true
            replyButton.layer.cornerRadius = 8.0
            replyButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            menuSpaceView.clipsToBounds = true
            menuSpaceView.layer.cornerRadius = 8.0
            menuSpaceView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        
        switch type {
        case .text, .reply:
            stickerButton.isHidden = true
            showImageButton.isHidden = true
        case .image:
            copyButton.isHidden = true
            stickerButton.isHidden = true
        case .sticker:
            copyButton.isHidden = true
            showImageButton.isHidden = true
        case.talk:
            self.dismiss(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    @IBAction func replyButtonPressed(_ sender: UIButton) {
        delegate?.replyButtonPressed(self)
    }
    
    @IBAction func copyButtonPressed(_ sender: UIButton) {
        delegate?.copyButtonPressed(self)
    }
    
    @IBAction func stickerButtonPressed(_ sender: UIButton) {
        delegate?.stickerButtonPressed(self)
    }
    
    @IBAction func showImageButtonPressed(_ sender: UIButton) {
        delegate?.showImageButtonPressed(self)
    }
    
    @IBAction func unsendButtonPressed(_ sender: UIButton) {
        delegate?.unsendButtonPressed(self)
    }
    
    @IBAction func reactionButtonPressed(_ sender: UIButton) {
        let selectedReaction = reactionArray[sender.tag]
        delegate?.reactionButtonPressed(self, didSelectedReaction: selectedReaction)
    }
}
