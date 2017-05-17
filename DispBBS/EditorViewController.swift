//
//  EditorViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/5/1.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire

protocol EditorViewControllerDelegate {
    func editorDidSaveText()
}

class EditorViewController: UIViewController, UITextViewDelegate, PreviewViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var textTextView: UITextView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    let userId = (UIApplication.shared.delegate as! AppDelegate).userId

    var boardId: String!
    var textId: String!
    var targetName: String!
    var type: String!
    var ri: String!
    
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    var delegate: EditorViewControllerDelegate?
    
    let imagePicker = UIImagePickerController()
    
    func loadText() {
        let urlString = "https://disp.cc/api/editor.php?act=textRead&bi=\(boardId!)&ti=\(textId!)&type=\(type!)"
        //print(urlString)
        let isLogin = (userId > 0) ? 1 : 0
        let parameters: Parameters = ["isLogin": isLogin, "targetName": targetName]
        self.loadingIndicator.startAnimating()
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            self.loadingIndicator.stopAnimating()
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alertAndBack(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                self.alertAndBack(message: "JSON formate error")
                return
            }
            // 這個 API 的 isSuccess 會是 true 或 0
            if let isSuccess = JSON["isSuccess"] as? Int {
                if isSuccess == 0 {
                    let errorMessage = JSON["errorMessage"] as? String ?? "error"
                    self.alertAndBack(message: errorMessage)
                    return
                }
            }
            guard let data = JSON["data"] as? [String: Any] else {
                self.alertAndBack(message: "JSON formate error")
                return
            }
            if self.type != "new" {
                self.titleTextField.text = data["title"] as? String ?? ""
                self.textTextView.text = data["text"] as? String ?? ""
                self.ri = data["ri"] as? String ?? "0"
            }
            self.targetName = data["targetName"] as? String ?? ""
            if self.boardId == "0" {
                if self.targetName == "" {
                    self.targetLabel.text = "收件者: 備忘錄"
                } else {
                    self.targetLabel.text = "收件者: \(self.targetName!)"
                }
            } else {
                self.targetLabel.text = "看板:  \(self.targetName!)"
            }
        }
    }
        
    func alert(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func alertAndBack(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func saveText() {
        let inputTitle = self.titleTextField.text ?? ""
        let inputText = self.textTextView.text ?? ""
        let urlString = "https://disp.cc/api/editor.php?act=save&type=\(type!)&bi=\(boardId!)&ti=\(textId!)"
        let parameters: Parameters = ["isLogin": 1, "targetName": targetName, "title": inputTitle, "text": inputText]
        self.loadingIndicator.startAnimating()
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            self.loadingIndicator.stopAnimating()
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                self.alert(message: "JSON formate error")
                return
            }
            // 這個 API 的 isSuccess 會是 true 或 0
            if let isSuccess = JSON["isSuccess"] as? Int {
                if isSuccess == 0 {
                    let errorMessage = JSON["errorMessage"] as? String ?? "error"
                    self.alert(message: errorMessage)
                    return
                }
            }
            if self.boardId == "0" {
                if(self.type == "reply") {
                    self.performSegue(withIdentifier: "UnwindToMailList", sender: self)
                } else {
                    self.delegate?.editorDidSaveText()
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                if(self.type == "reply") {
                    self.performSegue(withIdentifier: "UnwindToTextList", sender: self)
                } else {
                    self.delegate?.editorDidSaveText()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func uploadImage(image: UIImage) {
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        let clientId = keys?["ImgurClientId"] as? String ?? "在此輸入 Client ID"
        let mashapeKey = keys?["MashapeKey"] as? String ?? "在此輸入 Mashape Key"
        
        let urlString = "https://imgur-apiv3.p.mashape.com/3/image/"
        
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        //print("width: \(width), height: \(height), scale: \(image.scale)")
        
        var scaledWidth = width, scaledHeight = height
        let deviceScale = UIScreen.main.scale
        if width > 1200 {
            // af_imageScaled 產生的 size 會乘以 deviceScale，所以設定的寬高要先除 deviceScale
            scaledWidth = 1024.0 / deviceScale
            scaledHeight = (height * 1024.0 / width) / deviceScale
        }
        //print("scaled width: \(scaledWidth), height: \(scaledHeight)")

        let size = CGSize(width: scaledWidth, height: scaledHeight)
        let scaledImage = image.af_imageScaled(to: size)
        //print("scaledImage width: \(scaledImage.size.width), height: \(scaledImage.size.height), scale: \(scaledImage.scale)")
        
        let imageData = UIImagePNGRepresentation(scaledImage)!
        let imageBase64 = imageData.base64EncodedString()
        
        let headers: HTTPHeaders = ["Authorization": "Client-ID \(clientId)", "X-Mashape-Key": mashapeKey]
        let parameters: Parameters = ["image": imageBase64]
        self.loadingIndicator.startAnimating()
        Alamofire.request(urlString, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            self.loadingIndicator.stopAnimating()
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                self.alert(message: "JSON formate error")
                return
            }
            guard let success = JSON["success"] as? Bool,
                let data = JSON["data"] as? [String: Any] else {
                self.alert(message: "JSON formate error")
                return
            }
            if !success {
                let message = data["error"] as? String ?? "error"
                self.alert(message: message)
                return
            }
            if let link = data["link"] as? String,
                let width = data["width"] as? Int,
                let height = data["height"] as? Int {
                let bbcode = "[img=\(width)x\(height)]\(link)[/img]\n"
                //print(bbcode)
                self.textViewInsert(string: bbcode)
            }
        }
    }
    
    func textViewInsert(string: String) {
        if let range = textTextView.selectedTextRange {
            self.textTextView.replace(range, withText: string)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadText()
        
        if boardId == "0" {
            if type == "new" && targetName == "" { title = "備忘錄" }
            else if type == "new" { title = "開新信件" }
            else if type == "reply" { self.title = "回覆信件" }
            else if type == "edit" { title = "備忘錄" }
        } else {
            if type == "new" { title = "發表文章" }
            else if self.type == "reply" { title = "回覆文章" }
            else if type == "edit" { title = "編輯文章" }
        }
        //sendButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, -15)
        //moreButton.imageInsets = UIEdgeInsetsMake(0, -15, 0, 0)
        
        imagePicker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.view.endEditing(true)
        
        let message = "確定要不存檔離開嗎？"
        let alert = UIAlertController(title: "取消編輯", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "確定", style: .destructive, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func more(_ sender: Any) {
        let alert = UIAlertController(title: "選項", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "預覽文章", style: .default, handler: { action in
            self.performSegue(withIdentifier: "Preview", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "發佈文章", style: .default, handler: { action in
            self.saveText()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func preview(_ sender: Any) {
        if self.titleTextField.text == "" || self.textTextView.text == "" {
            alert(message: "請輸入標題及內容")
            return
        }

        //iPad要加這行關閉popover選單，不然會閃退
        self.presentedViewController?.dismiss(animated: true, completion: nil)
        
        self.performSegue(withIdentifier: "Preview", sender: sender)
    }
    
    @IBAction func addPhoto(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)

    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            uploadImage(image: pickedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Action
    
    func keyboardWillShow(_ notification: Notification){
        guard let value = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue else { return }
        let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
        let keyboardHeight = value.cgRectValue.height
        //print("keyboardHeight: \(keyboardHeight)")
        
        self.scrollViewBottomConstraint.constant = keyboardHeight
        self.contentViewHeight.constant = 60
        
        //self.view.setNeedsLayout()
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(_ notification: Notification){
        self.contentViewHeight.constant = 0
        self.scrollViewBottomConstraint.constant = 0
    }
    
    @IBAction func hideKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    // MARK: - TextView delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    // MARK: - Preview delegate
    
    func previewDidSaveText() {
        saveText()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Preview" {
            guard let previewViewController = segue.destination as? PreviewViewController
                else { return }
            previewViewController.boardId = self.boardId
            previewViewController.textId = self.textId
            previewViewController.targetName = self.targetName
            previewViewController.type = self.type
            previewViewController.ri = self.ri
            previewViewController.inputTitle = self.titleTextField.text
            previewViewController.inputText = self.textTextView.text
            previewViewController.delegate = self
        }
    }

}
