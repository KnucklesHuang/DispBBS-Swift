//
//  TextListViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/12.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class TextListViewController: UITableViewController {

    var textListArray:[Any] = []
    var botListArray:[Any] = []
    var numTextListLoad: Int = 0
    var numTextListTotal: Int = 0
    var numPageLoad: Int = 0
    
    var cellBackgroundView = UIView()
    var boardId: String!
    var boardName: String!
    var boardTitle: String!
    var boardIcon: String!
    
    func loadData() {
        let urlString = "https://disp.cc/api/board.php?act=tlist&bn=\(self.boardName!)&pageNum=\(self.numPageLoad)"
        Alamofire.request(urlString).responseJSON { response in
            if (self.refreshControl?.isRefreshing)! {
                self.refreshControl?.endRefreshing()
            }
            
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any],
                let isSuccess = JSON["isSuccess"] as? Int,
                let errorMessage = JSON["errorMessage"] as? String else {
                    self.alert(message: "JSON formate error")
                    return
            }
            if isSuccess != 1 {
                self.alert(message: errorMessage)
                return
            }
            if let data = JSON["data"] as? [String: Any],
                let tlist = data["tlist"] as? [Any] {
                if self.numPageLoad == 0 {
                    self.boardId = data["bi"] as? String
                    self.boardName = data["board_name"] as? String
                    self.boardTitle = data["board_title"] as? String
                    self.boardIcon = data["board_icon"] as? String
                    if let botList = data["botList"] as? [Any] {
                        self.botListArray.append(contentsOf: botList)
                    }
                }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        self.refreshControl?.addTarget(self, action: #selector(loadData), for: UIControlEvents.valueChanged)
        
        self.cellBackgroundView.backgroundColor = UIColor.darkGray
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 1
        case 1: return self.botListArray.count
        case 2: return self.numTextListLoad
        case 3: return 1
        default: return 0
        }
    }

    // section header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && self.botListArray.count > 0 {
            return 18
        } else if section == 2 && self.numTextListLoad > 0 {
            return 18
        } else {
            return 0
        }
    }
    
    // row height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch(indexPath.section) {
        case 0: return 80
        case 1: return 46
        default: return 100
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextListHeaderCell") as! TableViewCell
        if section == 1 {
            cell.titleLabel.text = "置頂文章"
            cell.descLabel.text = ""
        } else if section == 2 {
            cell.titleLabel.text = "最新文章"
            cell.descLabel.text = "看板《\(self.boardName!)》"
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: TableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "BoardHeaderCell", for: indexPath) as! TableViewCell
            cell.titleLabel.text = self.boardName
            cell.descLabel.text = self.boardTitle
            
            let placeholderImage = UIImage(named: "displogo120")
            if self.boardIcon != nil && self.boardIcon != "" {
                let url = URL(string: self.boardIcon!)!
                cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
            } else {
                cell.thumbImageView?.image = placeholderImage
            }
            
        } else if indexPath.section == 1 || indexPath.section == 2 {
            var dataArray: [Any]
            if indexPath.section == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "BotListCell", for: indexPath) as! TableViewCell
                dataArray = self.botListArray
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "TextListCell", for: indexPath) as! TableViewCell
                dataArray = self.textListArray
            }
            guard let text = dataArray[indexPath.row] as? [String: Any] else {
                return cell
            }
            
            let pushNum = text["push_num"] as! Int
            let title = text["title"] as! String
            if pushNum == 0 {
                cell.titleLabel?.text = title
            } else {
                var pushNumStr = "+\(pushNum)"
                var pushNumColor = UIColor.white
                if pushNum < 0 {
                    pushNumStr = "\(pushNum)"
                    pushNumColor = UIColor.darkGray
                }
                let attributes = [NSForegroundColorAttributeName: pushNumColor]
                let titleAttrStr = NSMutableAttributedString(string: pushNumStr, attributes: attributes)
                titleAttrStr.append(NSAttributedString(string: " \(title)"))
                cell.titleLabel.attributedText = titleAttrStr
            }
            
            cell.descLabel?.text = text["desc"] as? String
            
            let hotNumStr = text["hot"] as! String
            let hotNum = Int(hotNumStr) ?? 0
            if hotNum < 10 {
                cell.hotNumLabel.text = ""
            } else {
                let darkRed = UIColor(red: 0x80/255.0, green: 0, blue: 0, alpha: 1.0)
                let attributes = [NSForegroundColorAttributeName: UIColor.black,
                                  NSBackgroundColorAttributeName: darkRed]
                let hotAttrStr = NSMutableAttributedString(string: hotNumStr, attributes: attributes)
                cell.hotNumLabel.attributedText = hotAttrStr
            }
            
            if let timeString = text["time"] as? String,
                let authorString = text["author"] as? String {
                let start = timeString.index(timeString.startIndex, offsetBy: 5)
                let end = timeString.index(timeString.startIndex, offsetBy: 16)
                cell.infoLabel?.text = timeString.substring(with: start..<end)+" "+authorString
            }
            
            if indexPath.section == 2 {
                let imgUrlString = text["thumb"] as? String
                let placeholderImage = UIImage(named: "displogo120")
                if imgUrlString != nil && imgUrlString != "" {
                    let url = URL(string: imgUrlString!)!
                    cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
                    cell.thumbWidthConstraint.constant = 100
                } else {
                    //cell.thumbImageView?.image = placeholderImage
                    cell.thumbWidthConstraint.constant = 0
                }
            }
            cell.selectedBackgroundView = self.cellBackgroundView
            
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "TextListMoreCell", for: indexPath) as! TableViewCell
            let remainNum = self.numTextListTotal - self.numTextListLoad
            if remainNum > 0 {
                cell.titleLabel?.text = "還有 \(remainNum) 篇文章\n點此再多載入 20 篇"
            } else if self.numTextListLoad != 0 {
                cell.titleLabel?.text = "文章都載入完了"
            }
            cell.selectedBackgroundView = self.cellBackgroundView
        }

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BotRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let indexPath = self.tableView.indexPathForSelectedRow,
                let text = self.botListArray[indexPath.row] as? [String: Any]
                else { return }
            
            textViewController.bi = self.boardId
            textViewController.ti = text["ti"] as? String
            
        } else if segue.identifier == "TextRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let indexPath = self.tableView.indexPathForSelectedRow,
                let text = self.textListArray[indexPath.row] as? [String: Any]
                else { return }
            
            textViewController.bi = self.boardId
            textViewController.ti = text["ti"] as? String
        }
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 { //點擊載入更多按鈕
            if self.numTextListTotal - self.numTextListLoad > 0 {
                loadData()
            }
        }
    }

}
