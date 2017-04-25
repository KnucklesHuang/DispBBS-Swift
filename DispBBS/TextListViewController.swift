//
//  TextListViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/12.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import AlamofireImage

class TextListViewController: UITableViewController {

    var textListArray:[Any] = []
    var botListArray:[Any] = []
    var numTextListLoad: Int = 0
    var numTextListTotal: Int = 0
    var numPageLoad: Int = 0
    
    var cellSelectedBackgroundView = UIView()
    var boardId: String!
    var boardName: String!
    var boardTitle: String!
    var boardIcon: String!
    
    func loadData() {
        let urlString = "https://disp.cc/api/board.php?act=tlist&bn=\(boardName!)&pageNum=\(numPageLoad)"
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
                if self.numPageLoad == 0 {
                    self.boardId = data["bi"] as? String
                    self.boardName = data["board_name"] as? String
                    self.boardTitle = data["board_title"] as? String
                    self.boardIcon = data["board_icon"] as? String
                    if let botList = data["botList"] as? [Any] {
                        self.botListArray.append(contentsOf: botList)
                    }
                    self.setTableHeaderView()
                }
                self.textListArray.append(contentsOf: tlist)
                self.numTextListLoad = self.textListArray.count
                self.numTextListTotal = data["totalNum"] as! Int
                self.numPageLoad += 1
                self.tableView.reloadData()
                self.saveBoardHistory()
            }
        }
    }
    
    func alert(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveBoardHistory() {
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "BoardHistory", in: managedContext)!

        // 先刪除這個看板之前的瀏覽記錄
        let fetchRequest = NSFetchRequest<BoardHistory>(entityName: "BoardHistory")
        fetchRequest.predicate = NSPredicate(format: "name == %@", self.boardName!)
        if let fetchResult = try? managedContext.fetch(fetchRequest) {
            for delBoard in fetchResult {
                managedContext.delete(delBoard)
            }
        }
        
        let insBoard = BoardHistory(entity: entity, insertInto: managedContext)
        insBoard.bi = Int16(self.boardId)!
        insBoard.name = self.boardName
        insBoard.title = self.boardTitle
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func setTableHeaderView() {
        // set TableHeaderView
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BoardHeaderCell") as? TableViewCell{
            cell.titleLabel.text = self.boardName
            cell.descLabel.text = self.boardTitle
            
            let placeholderImage = UIImage(named: "displogo120")
            if self.boardIcon != nil && self.boardIcon != "" {
                let url = URL(string: self.boardIcon!)!
                cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
            } else {
                cell.thumbImageView?.image = placeholderImage
            }
            self.tableView.tableHeaderView = cell
        }
    }
    
    func refresh() {
        textListArray.removeAll()
        botListArray.removeAll()
        self.numPageLoad = 0
        self.numTextListLoad = 0
        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        self.cellSelectedBackgroundView.backgroundColor = UIColor.darkGray
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return self.botListArray.count
        case 1: return self.numTextListLoad
        case 2: return 1
        default: return 0
        }
    }

    // section header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && self.botListArray.count > 0 {
            return 18
        } else if section == 1 && self.numTextListLoad > 0 {
            return 18
        } else {
            return 0
        }
    }
    
    // row height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch(indexPath.section) {
        case 0: return 46
        default: return 100
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextListHeaderCell") as! TableViewCell
        if section == 0 {
            cell.titleLabel.text = "置頂文章"
            cell.descLabel.text = ""
        } else if section == 1 {
            cell.titleLabel.text = "最新文章"
            cell.descLabel.text = "看板《\(self.boardName!)》"
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: TableViewCell
        if indexPath.section == 0 || indexPath.section == 1 {
            var dataArray: [Any]
            if indexPath.section == 0 {
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
            let titleStr = text["title"] as! String
            if pushNum == 0 {
                cell.titleLabel?.text = titleStr
            } else {
                var pushNumStr = "+\(pushNum)"
                var pushNumColor = UIColor.white
                if pushNum < 0 {
                    pushNumStr = "\(pushNum)"
                    pushNumColor = UIColor.darkGray
                }
                let pushNumAttr = [NSForegroundColorAttributeName: pushNumColor]
                let attrStr = NSMutableAttributedString(string: pushNumStr, attributes: pushNumAttr)
                attrStr.append(NSAttributedString(string: " \(titleStr)"))
                cell.titleLabel.attributedText = attrStr
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
                let hotAttrStr = NSAttributedString(string: hotNumStr, attributes: attributes)
                cell.hotNumLabel.attributedText = hotAttrStr
            }
            
            if let timeString = text["time"] as? String,
                let authorString = text["author"] as? String {
                let start = timeString.index(timeString.startIndex, offsetBy: 5)
                let end = timeString.index(timeString.startIndex, offsetBy: 16)
                cell.infoLabel?.text = timeString.substring(with: start..<end)+" "+authorString
            }
            
            if indexPath.section == 1 {
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
            
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "TextListMoreCell", for: indexPath) as! TableViewCell
            let remainNum = self.numTextListTotal - self.numTextListLoad
            if remainNum > 0 {
                cell.titleLabel?.text = "還有 \(remainNum) 篇文章\n點此再多載入 20 篇"
            } else if self.numTextListLoad > 0 {
                cell.titleLabel?.text = "文章都載入完了"
            }
        }

        cell.selectedBackgroundView = self.cellSelectedBackgroundView
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
        if indexPath.section == 2 { //點擊載入更多按鈕
            if numTextListLoad == 0 || numTextListTotal - numTextListLoad > 0 {
                loadData()
            }
        }
    }

}
