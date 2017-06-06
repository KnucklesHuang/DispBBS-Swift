//
//  MailListViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/5/10.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire

class MailListViewController: UITableViewController, EditorViewControllerDelegate {
    var textListArray = [Any]()
    var numTextListLoad: Int = 0
    var numTextListTotal: Int = 0
    var numPageLoad: Int = 0
    
    var cellSelectedBackgroundView = UIView()

    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var userId = 0
    
    var targetName: String?

    func loadData() {
        //print("loadData")
        let urlString = "https://disp.cc/api/mail.php?act=list&pageNum=\(numPageLoad)"
        let isLogin = (userId > 0) ? 1 : 0
        let parameters: Parameters = ["isLogin": isLogin]
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            if (self.refreshControl?.isRefreshing)! {
                self.refreshControl?.endRefreshing()
            }
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
            if let data = JSON["data"] as? [String: Any],
                let tlist = data["tlist"] as? [Any] {
                self.textListArray.append(contentsOf: tlist)
                self.numTextListLoad = self.textListArray.count
                self.numTextListTotal = data["totalNum"] as! Int
                self.numPageLoad += 1
                self.tableView.reloadData()
            }
        }
    }
    
    func alert(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func refresh() {
        textListArray.removeAll()
        self.numPageLoad = 0
        self.numTextListLoad = 0
        tableView.reloadData()
        
        userId = appDelegate.userId
        if userId != 0 {
            loadData()
        } else {
            tableView.reloadData()
        }
    }
    
    func viewDidShowPage() {
        if appDelegate.userId == 0 && numTextListLoad != 0 {
            refresh()
        } else if appDelegate.userId != 0 && numTextListLoad == 0 {
            refresh()
        }
    }
    
    func addMail() { //由 MainViewController 的按鈕觸發
        let alert = UIAlertController(title: "新增信件", message: "輸入收件者帳號\n或是空著以新增備忘錄", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "請輸入收件者帳號"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            if let nameTextField = alert.textFields?.first {
                self.targetName = nameTextField.text
                self.performSegue(withIdentifier: "AddMail", sender: self)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        userId = appDelegate.userId
//        if userId != 0 {
//            loadData()
//        }
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        self.cellSelectedBackgroundView.backgroundColor = UIColor.darkGray
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
//        let screenName = "MailList"
//        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
//        tracker.set(kGAIScreenName, value: screenName)
//        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
//        tracker.send(builder.build() as [NSObject : AnyObject])
    }

    @IBAction func unwindToMailList(segue: UIStoryboardSegue) {
        refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return self.numTextListLoad
        case 1: return 1
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: TableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "MailListCell", for: indexPath) as! TableViewCell
            //print("load: \(numTextListLoad), row: \(indexPath.row)")
            guard let text = textListArray[indexPath.row] as? [String: Any] else {
                return cell
            }
            
            cell.titleLabel?.text = text["title"] as? String
            cell.descLabel?.text = text["desc"] as? String

            if let timeString = text["time"] as? String,
                let authorString = text["author"] as? String {
                let start = timeString.index(timeString.startIndex, offsetBy: 5)
                let end = timeString.index(timeString.startIndex, offsetBy: 16)
                cell.infoLabel?.text = timeString.substring(with: start..<end)+" "+authorString
            }
            
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "MailListMoreCell", for: indexPath) as! TableViewCell
            let remainNum = self.numTextListTotal - self.numTextListLoad
            if userId == 0 {
                cell.titleLabel?.text = "尚未登入"
            } else if remainNum > 0 {
                cell.titleLabel?.text = "還有 \(remainNum) 封信件\n點此再多載入 20 封"
            } else if self.numTextListLoad > 0 {
                cell.titleLabel?.text = "信件都載入完了"
            }
        }
        
        cell.backgroundColor = UIColor.black
        cell.selectedBackgroundView = self.cellSelectedBackgroundView
        return cell
    }

    // 點擊了某一列
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 { //點擊載入更多按鈕
            if userId == 0 {
                return
            } else if numTextListLoad == 0 || numTextListTotal - numTextListLoad > 0 {
                loadData()
            }
        }
    }
    
    // MARK: - EditorViewController delegate
    
    func editorDidSaveText() {
        refresh()
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TextRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let indexPath = self.tableView.indexPathForSelectedRow
                else { return }
            
            var text = self.textListArray[indexPath.row] as? [String: Any]
            
            textViewController.boardId = "0"
            textViewController.textId = text?["ti"] as? String
            textViewController.authorId = text?["ai"] as? Int
            textViewController.authorName = text?["author"] as? String
            textViewController.textTitle = text?["title"] as? String
            textViewController.boardName = ""
            
        } else if segue.identifier == "AddMail" {
            guard let navigationController = segue.destination as? UINavigationController,
                let editorViewController = navigationController.topViewController as? EditorViewController
                else { return }
            
            editorViewController.boardId = "0"
            editorViewController.textId = ""
            editorViewController.targetName = self.targetName
            editorViewController.type = "new"
            editorViewController.delegate = self
     
        }
    }

}
