//
//  MainViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/10.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire
import KeychainSwift

class MainViewController: UIViewController, LoginViewControllerDelegate {

    @IBOutlet weak var tabBarScrollView: UIScrollView!
    @IBOutlet weak var tabBarHeight: NSLayoutConstraint!
    @IBOutlet weak var hotTextButton: UIButton!
    @IBOutlet weak var boardListButton: UIButton!
    @IBOutlet weak var boardSearchButton: UIButton!
    @IBOutlet weak var mailListButton: UIButton!
    lazy var orderedTabButtons: [UIButton] = {
        [self.hotTextButton, self.boardListButton, self.boardSearchButton, self.mailListButton]
    }()
    var selectedTabIndex: Int! = 0
    
    var pageViewController: PageViewController!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var userId = 0
    var userName = ""
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    let userDefault = UserDefaults.standard
    
    @IBOutlet weak var addMailButton: UIBarButtonItem!
    
    func changeTab(byIndex index: Int) {
        guard index >= 0 && index < orderedTabButtons.count else { return }
        let selectedButton = orderedTabButtons[self.selectedTabIndex]
        let newButton = orderedTabButtons[index]
        let linkColor = newButton.currentTitleColor
        selectedButton.backgroundColor = UIColor.black
        selectedButton.setTitleColor(linkColor, for: .normal)
        
        newButton.backgroundColor = UIColor.lightGray
        newButton.setTitleColor(UIColor.black, for: .normal)

        self.selectedTabIndex = index
    }
    
    func appInit() {
        self.loadCookies()
        
        let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let urlString = "https://disp.cc/api/get.php?act=appInit&app=ios&appVer=\(appVer)"
        let parameters: Parameters = ["isLogin": 1]
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any],
                let isSuccess = JSON["isSuccess"] as? Int else {
                    self.alert(message: "JSON formate error")
                    return
            }
            guard isSuccess == 1 else {
                let errorMessage = JSON["errorMessage"] as? String ?? "error"
                self.alert(message: errorMessage)
                return
            }
            
            // check update
            if let needUpdate = JSON["needUpdate"] as? Bool {
                if needUpdate {
                    let message = JSON["updateMessage"] as? String ?? "有新的版本出來了，要現在更新嗎？"
                    let url = JSON["updateUrl"] as? String ?? "https://itunes.apple.com/tw/app/disp-bbs/id939152921"
                    self.updateConform(message: message, url: url)
                }
            }
            
            // check login
            let ui = JSON["ui"] as? Int ?? 0
            if ui != 0 {
                self.appDelegate.userId = ui
                let userName = JSON["username"] as? String ?? ""
                self.didLogin(userId: ui, userName: userName)
            } else {
                self.loginButton.title = "登入"
            }
        }
    }
    
    func loadCookies() {
        guard let cookieArray = self.userDefault.array(forKey: "loginCookies") as? [[HTTPCookiePropertyKey: Any]] else { return }
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
    
    func alert(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func updateConform(message: String, url: String) {
        let alert = UIAlertController(title: "系統訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            UIApplication.shared.openURL(URL(string: url)!)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    
    func logoutConform() {
        let message = "確定要登出帳號 \(self.userName) 嗎？"
        let alert = UIAlertController(title: "登出", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            self.logout()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func logout() {
        let urlString = "https://disp.cc/api/logout.php"
        let parameters: Parameters = ["isLogin": 1]
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any],
                let isSuccess = JSON["isSuccess"] as? Int else {
                    self.alert(message: "JSON formate error")
                    return
            }
            guard isSuccess == 1 else {
                let errorMessage = JSON["errorMessage"] as? String ?? "error"
                self.alert(message: errorMessage)
                return
            }
            self.userId = 0
            self.appDelegate.userId = 0
            self.userName = ""
            self.loginButton.title = "登入"
            self.refresh(self)
        }
    }
    
    func showAddMailButton() {
        addMailButton.isEnabled = true
        addMailButton.tintColor = UIColor.white
    }
    
    func hideAddMailButton() {
        self.addMailButton.isEnabled = false
        self.addMailButton.tintColor = UIColor.clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.definesPresentationContext = true
        self.tabBarScrollView.scrollsToTop = false

        self.loginButton.title = ""
        hideAddMailButton()
        
        appInit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - LoginViewControllerDelegate
    
    func didLogin(userId: Int, userName: String) {
        self.userId = userId
        self.userName = userName
        self.loginButton.title = "登出"
        refresh(self)
    }

    @IBAction func showHotText(_ sender: Any) {
        changeTab(byIndex: 0)
        pageViewController.showPage(byIndex: 0)
    }
    @IBAction func showBoardList(_ sender: Any) {
        changeTab(byIndex: 1)
        pageViewController.showPage(byIndex: 1)
    }
    @IBAction func showBoardSearch(_ sender: Any) {
        changeTab(byIndex: 2)
        pageViewController.showPage(byIndex: 2)
    }
    @IBAction func showMailList(_ sender: Any) {
        changeTab(byIndex: 3)
        pageViewController.showPage(byIndex: 3)
    }
    
    @IBAction func refresh(_ sender: Any) {
        switch(self.selectedTabIndex){
        case 0: pageViewController.hotTextViewController.refresh()
        case 1: pageViewController.boardListViewController.refresh()
        case 2: pageViewController.boardSearchViewController.refresh()
        case 3: pageViewController.mailListViewController.refresh()
        default: return
        }
    }
    
    @IBAction func addMail(_ sender: Any) {
        if userId == 0 {
            let alert = UIAlertController(title: "尚未登入", message: "發表文章需要登入帳號，要現在登入嗎？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
                self.performSegue(withIdentifier: "Login", sender: self)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            pageViewController.mailListViewController.addMail()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ContainerViewSegue" {
            pageViewController = segue.destination as! PageViewController
            pageViewController.mainViewController = self
        } else if segue.identifier == "Login" {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.delegate = self
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "Login" {
            if userId != 0 {
                logoutConform()
                return false
            }
        }
        return true
    }
    
}


