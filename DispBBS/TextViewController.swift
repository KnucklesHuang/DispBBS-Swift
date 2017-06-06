//
//  TextViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/3/12.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit

protocol TextViewControllerDelegate {
    func didLogin(userId: Int, userName: String)
}

class TextViewController: UIViewController, UIWebViewDelegate, EditorViewControllerDelegate, LoginViewControllerDelegate {
    var boardId: String!
    var textId: String!
    var authorId: Int!
    var authorName: String!
    var textTitle: String!
    var boardName: String!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var goBackButton: UIBarButtonItem!
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var delegate: TextViewControllerDelegate?
    var userId = (UIApplication.shared.delegate as! AppDelegate).userId
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.delegate = self
        
        let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        if self.boardId != nil && self.textId != nil {
            let urlString = "https://disp.cc/m/\(boardId!)-\(textId!)?fr=DispApp&app=ios&appVer=\(appVer)"
            //print(urlString)
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                self.webView.loadRequest(request)
            }
        }
        
        //self.moreButton.imageInsets = UIEdgeInsetsMake(0, -15, 0, 0)
        
        if boardId == "0" {
            shareButton.isEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
//        let screenName = "Text:\(self.boardId)-\(self.textId)"
//        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
//        tracker.set(kGAIScreenName, value: screenName)
//        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
//        tracker.send(builder.build() as [NSObject : AnyObject])
    }

    
    @IBAction func refresh(_ sender: Any) {
        self.webView.reload()
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.webView.goBack()
    }
    
    @IBAction func more(_ sender: Any) {
        var title = "文章選項"
        if boardId == "0" { title = "信件選項" }
        var message: String?
        if userId == 0 {
            message = "要編輯或回覆文章必需先登入"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        // 要加這行，不然在iPad會閃退
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem

        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        if boardId == "0" {
            if authorName == ">備忘錄" {
                alert.addAction(UIAlertAction(title: "編輯備忘錄", style: .default, handler: { action in
                    self.performSegue(withIdentifier: "Edit", sender: self)
                }))
            }
            alert.addAction(UIAlertAction(title: "回覆信件", style: .default, handler: { action in
                self.performSegue(withIdentifier: "Reply", sender: self)
            }))
            
        } else {
            if userId == 0 {
                alert.addAction(UIAlertAction(title: "登入帳號", style: .default, handler: { action in
                    self.performSegue(withIdentifier: "Login", sender: self)
                }))
            }
            if userId != 0 && userId == authorId {
                alert.addAction(UIAlertAction(title: "編輯文章", style: .default, handler: { action in
                    self.performSegue(withIdentifier: "Edit", sender: self)
                }))
            }
            if userId != 0 {
                alert.addAction(UIAlertAction(title: "回覆文章", style: .default, handler: { action in
                    self.performSegue(withIdentifier: "Reply", sender: self)
                }))
            }
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func share(_ sender: Any) {
        guard textTitle != nil, boardName != nil, boardId != nil, textId != nil
            else { return }
        let shareTitle = "\(textTitle!) - \(boardName!)板 - DispBBS"
        let urlString = "https://disp.cc/b/\(boardId!)-\(textId!)"
        let shareUrl = NSURL(string: urlString)!
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [shareTitle, shareUrl], applicationActivities: nil)

        // 要加這行，不然在iPad會閃退
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        // Anything you want to exclude
        //activityViewController.excludedActivityTypes = [ .postToWeibo, .print, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - WebView delegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        //NetworkActivityIndicatorManager.shared.incrementActivityCount()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if self.webView.canGoBack {
            self.goBackButton.isEnabled = true
        } else {
            self.goBackButton.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // MARK: - EditorViewController delegate
    
    func editorDidSaveText() {
        refresh(self)
    }
    
    // MARK: - LoginViewController delegate
    
    func didLogin(userId: Int, userName: String) {
        self.userId = userId
        refresh(self)
        self.delegate?.didLogin(userId: userId, userName: userName)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit" || segue.identifier == "Reply" {
            guard let navigationController = segue.destination as? UINavigationController,
            let editorViewController = navigationController.topViewController as? EditorViewController
            else { return }
            
            var targetName = self.boardName
            if boardId == "0" {
                if segue.identifier == "Edit" {
                    targetName = "備忘錄"
                } else {
                    targetName = self.authorName
                }
            }
            
            editorViewController.boardId = self.boardId
            editorViewController.textId = self.textId
            editorViewController.type = segue.identifier?.lowercased()
            editorViewController.targetName = targetName
            editorViewController.delegate = self
            
        } else if segue.identifier == "Login" {
            guard let loginViewController = segue.destination as? LoginViewController
                else { return }
            loginViewController.delegate = self

        }
    }

}
