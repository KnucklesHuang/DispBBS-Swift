//
//  BoardListViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/10.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class BoardListViewController: UITableViewController {

    var boardListArray = [Any]()
    var numBoardListLoad: Int = 0
    var numBoardListTotal: Int = 0
    var numPageLoad: Int = 0
    var cellSelectedBackgroundView = UIView()
    
    func loadData() {
        //print("BoardList loadData")
        let urlString = "https://disp.cc/api/board.php?act=blist&pageNum=\(numPageLoad)"
        let userId = (UIApplication.shared.delegate as! AppDelegate).userId
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
                let blist = data["blist"] as? [Any] {
                self.boardListArray.append(contentsOf: blist)
                self.numBoardListLoad = self.boardListArray.count
                self.numBoardListTotal = data["totalNum"] as! Int
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
        boardListArray.removeAll()
        self.numPageLoad = 0
        self.numBoardListLoad = 0
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.boardListArray.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: TableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "BoardListCell", for: indexPath) as! TableViewCell
            
            guard let board = self.boardListArray[indexPath.row] as? [String: Any] else {
                print("Get row \(indexPath.row) error")
                return cell
            }
            let hotNumStr = board["hot"] as! String
            let hotNum = Int(hotNumStr) ?? 0
            if hotNum < 10 {
                cell.titleLabel?.text = board["name"] as? String
            } else {
                let darkRed = UIColor(red: 0x80/255.0, green: 0, blue: 0, alpha: 1.0)
                let hotNumAttr = [NSForegroundColorAttributeName: UIColor.black,
                                  NSBackgroundColorAttributeName: darkRed]
                let attrStr = NSMutableAttributedString(string: hotNumStr, attributes: hotNumAttr)
                let boardName = board["name"] as! String
                attrStr.append(NSAttributedString(string: " \(boardName)"))
                cell.titleLabel?.attributedText = attrStr
            }

            cell.descLabel?.text = board["title"] as? String
            
            let imgUrlString = board["icon"] as? String
            let placeholderImage = UIImage(named: "displogo120")
            if imgUrlString != nil && imgUrlString != "" {
                let url = URL(string: imgUrlString!)!
                cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
            } else {
                cell.thumbImageView?.image = placeholderImage
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "BoardListMoreCell", for: indexPath) as! TableViewCell
            let remainNum = self.numBoardListTotal - self.numBoardListLoad
            if remainNum > 0 {
                cell.titleLabel?.text = "還有 \(remainNum) 個看板\n點此再多載入 20 個"
            } else if self.numBoardListLoad > 0{
                cell.titleLabel?.text = "看板都載入完了"
            }
        }
        cell.selectedBackgroundView = self.cellSelectedBackgroundView
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Board" {
            guard let textListViewController = segue.destination as? TextListViewController,
                let row = self.tableView.indexPathForSelectedRow?.row,
                let board = self.boardListArray[row] as? [String: Any]
                else { return }
            textListViewController.boardName = board["name"] as? String
            textListViewController.boardTitle = board["title"] as? String
            textListViewController.boardIcon = board["icon"] as? String
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if numBoardListLoad == 0 || numBoardListTotal - numBoardListLoad > 0 {
                loadData()
            }
        }
    }


}
