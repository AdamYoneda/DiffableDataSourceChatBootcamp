//
//  ImageDetailViewController.swift
//  Tauch
//
//  Created by Apple on 2022/08/15.
//

import UIKit
import FirebaseFirestore

protocol ImageDetailViewControllerDelegate: AnyObject {
    func deletePostPhoto(_ viewController: ImageDetailViewController, photoId: String)
}

final class ImageDetailViewController: UIBaseViewController {
    
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var pickedImageView: UIImageView!
    
    weak var delegate: ImageDetailViewControllerDelegate?
    
    var profiletUser: User?
    var pickedImage: UIImage!
    var photoId: String?
    var isPresentFromProfilePhotosView = false // trueのときのみ削除機能が有効
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pickedImageView.image = pickedImage
    }
    
    private func setUp() {
        setUpScrollView()
    }
    
    private func setUpScrollView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        
        imageScrollView.delegate = self
        imageScrollView.maximumZoomScale = 2
        imageScrollView.addGestureRecognizer(tapGesture)
        imageScrollView.addGestureRecognizer(swipeGesture)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return pickedImageView
    }
}

// タップ / スワイプ / 削除 / 保存 関連
extension ImageDetailViewController {
    
    @objc private func onDoubleTap(_ sender: UITapGestureRecognizer) {
        let scale = min(imageScrollView.zoomScale * 2, imageScrollView.maximumZoomScale)
        
        if scale != imageScrollView.zoomScale {
            let tapPoint = sender.location(in: pickedImageView)
            let size = CGSize(width: imageScrollView.bounds.width / scale, height: imageScrollView.bounds.height / scale)
            let origin = CGPoint(x: tapPoint.x - size.width / 2, y: tapPoint.y - size.height / 2)
            imageScrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        } else {
            imageScrollView.zoom(to: imageScrollView.frame, animated: true)
        }
        Log.event(name: "messageImageZoom")
    }
    
    @objc private func handleSwipe(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
    
    @IBAction func onCloseButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func onMoreButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "写真を削除", style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    try await self.delete()
                } catch {
                    self.alert(title: "失敗", message: "画像の削除に失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                }
            }
        }
        let save = UIAlertAction(title: "写真を保存", style: .default) { [weak self] _ in
            guard let self else { return }
            self.save()
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .default)

        if profiletUser?.uid == GlobalVar.shared.loginUser?.uid && isPresentFromProfilePhotosView {
            alert.addAction(delete)
        }
        alert.addAction(save)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    private func delete() async throws {
        do {
            guard let profiletUser = profiletUser else { return }
            guard let photoId = photoId else { return }
            let userDocument = db.collection("users").document(profiletUser.uid)
            let postPhotoDocument = userDocument.collection("post_photos").document(photoId)
            
            try await postPhotoDocument.delete()
            
            delegate?.deletePostPhoto(self, photoId: photoId)
            dismiss(animated: true)
        } catch {
            throw error
        }
    }
    
    private func save() {
        UIImageWriteToSavedPhotosAlbum(
            pickedImage,
            self,
            #selector(saveImage(image:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
    
    @objc private func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Failed to save photo: \(error)")
            alert(title: "画像の保存に失敗しました", message: "再度ダウンロードをしてください。\nうまくいかない場合は、アプリを再起動して再度実行してください", actiontitle: "OK")
        } else {
            alert(title: "画像を保存しました", message: "", actiontitle: "OK")
            Log.event(name: "messageImageSave")
        }
    }
}
