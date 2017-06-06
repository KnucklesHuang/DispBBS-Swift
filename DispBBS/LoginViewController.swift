//
//  LoginViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/25.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire
import KeychainSwift
import SafariServices

protocol LoginViewControllerDelegate {
    func didLogin(userId: Int, userName: String)
}

class LoginViewController: UIViewController, SFSafariViewControllerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var userId = 0

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButtom: UIButton!
    @IBOutlet weak var clearInputButtom: UIButton!
    
    var delegate: LoginViewControllerDelegate?
    var userDefault = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.userId = appDelegate.userId
        
        self.loadAccount()
        
        loginButtom.layer.cornerRadius = 5
        loginButtom.layer.borderWidth = 1
        loginButtom.layer.borderColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0.5, alpha: 0.5).cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
//        let screenName = "Login"
//        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
//        tracker.set(kGAIScreenName, value: screenName)
//        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
//        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    @IBAction func loginSubmit(_ sender: Any) {
        let inputName = usernameTextField.text!
        let inputPswd = passwordTextField.text!
        self.view.endEditing(true)
        
        if inputName.characters.count == 0 {
            alert(message: "請輸入帳號")
            return
        } else if inputPswd.characters.count == 0 {
            alert(message: "請輸入密碼")
            return
        }
   
        let urlString = "https://disp.cc/api/login.php"
        let parameters: Parameters = ["username": inputName, "password": inputPswd, "remember": 1]
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
            if let data = JSON["data"] as? [String: Any] {
                let userId = Int(data["id"] as! String) ?? 0
                let userName = data["name"] as! String
                let nickname = data["nickname"] as! String
                let loginNum = data["loginNum"] as! Int
                let loginAddr = data["loginAddr"] as! String
                let loginTime = data["loginTime"] as! String
                
                self.appDelegate.userId = userId
                self.delegate?.didLogin(userId: userId, userName: userName)
                let message = "歡迎 \(userName) (\(nickname))\n第 \(loginNum) 次登入本站 (同一天只算一次)\n上次您來自 \(loginAddr)\n那天是 \(loginTime)"
                self.saveCookies(response: response)
                self.saveAccount(userId: userId, userName: userName, password: inputPswd)
                self.welcomeAlert(message: message)
            }
        }

    }
    
    func alert(message: String) {
        let alert = UIAlertController(title: "登入失敗", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func welcomeAlert(message: String) {
        let alert = UIAlertController(title: "登入成功", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            _ = self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveCookies(response: DataResponse<Any>) {
        let headerFields = response.response?.allHeaderFields as! [String: String]
        let url = response.response?.url
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
        var cookieArray = [[HTTPCookiePropertyKey: Any]]()
        for cookie in cookies {
            cookieArray.append(cookie.properties!)
        }
        self.userDefault.set(cookieArray, forKey: "loginCookies")
        self.userDefault.synchronize()
    }
    
    func saveAccount(userId: Int, userName: String, password: String) {
        self.userDefault.set(userId, forKey: "userId")
        self.userDefault.set(userName, forKey: "userName")
        
        let keychain = KeychainSwift()
        keychain.set(userName, forKey: "userName")
        keychain.set(password, forKey: "password")
    }
    
    func loadAccount() {
        guard let userName = self.userDefault.string(forKey: "userName") else { return }
        self.usernameTextField.text = userName
        
        let keychain = KeychainSwift()
        if let savedName = keychain.get("userName"),
            let password = keychain.get("password") {
            if savedName == userName {
                self.passwordTextField.text = password
            }
        }
        
        self.clearInputButtom.isHidden = false
    }

    @IBAction func register(_ sender: Any) {
        let url = URL(string: "https://disp.cc/m/login.php?act=register")!
        if #available(iOS 9.0, *) { //確保是在 iOS9 之後的版本執行
            let safariVC = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            safariVC.delegate = self
            self.present(safariVC, animated: true, completion: nil)
        } else { // iOS 8 以下的話跳出 App 使用 Safari 開啟
            UIApplication.shared.openURL(url)
        }
    }

    @IBAction func hideKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func clearInput(_ sender: Any) {
        self.userDefault.removeObject(forKey: "userId")
        self.userDefault.removeObject(forKey: "userName")
        self.userDefault.synchronize()
        
        let keychain = KeychainSwift()
        keychain.delete("userName")
        keychain.delete("password")
        
        self.usernameTextField.text = ""
        self.passwordTextField.text = ""
        
        self.clearInputButtom.isHidden = true
    }


}
