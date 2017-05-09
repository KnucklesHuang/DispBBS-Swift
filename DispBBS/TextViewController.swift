//
//  TextViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/3/12.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit


class TextViewController: UIViewController, UIWebViewDelegate, EditorViewControllerDelegate, LoginViewControllerDelegate {
    //var urlString: String!
    var boardId: String!
    var textId: String!
    var authorId: Int!
    var textTitle: String!
    var boardName: String!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var goBackBtn: UIBarButtonItem!
    
    var userId = (UIApplication.shared.delegate as! AppDelegate).userId

    @IBOutlet weak var moreButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.delegate = self
        
        if self.boardId != nil && self.textId != nil {
            let urlString = "https://disp.cc/m/\(boardId!)-\(textId!)?fr=DispApp"
            //print(urlString)
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                self.webView.loadRequest(request)
            }
        }
        
        //self.moreButton.imageInsets = UIEdgeInsetsMake(0, -15, 0, 0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.webView.reload()
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.webView.goBack()
    }
    
    @IBAction func more(_ sender: Any) {
        let alert = UIAlertController(title: "文章選項", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        if userId == 0 {
            alert.addAction(UIAlertAction(title: "登入網站", style: .default, handler: { action in
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
            self.goBackBtn.isEnabled = true
        } else {
            self.goBackBtn.isEnabled = false
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
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit" || segue.identifier == "Reply" {
            guard let navigationController = segue.destination as? UINavigationController,
            let editorViewController = navigationController.topViewController as? EditorViewController
            else { return }
            
            editorViewController.boardId = self.boardId
            editorViewController.textId = self.textId
            editorViewController.type = segue.identifier?.lowercased()
            editorViewController.delegate = self
            
        } else if segue.identifier == "Login" {
            guard let loginViewController = segue.destination as? LoginViewController
                else { return }
            loginViewController.delegate = self

        }
    }

}
