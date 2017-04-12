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

    var textListArray:[Any]?
    var cellBackgroundView = UIView()
    var boardId: String!
    var boardName: String!
    
    func loadData() {
        let urlString = "https://disp.cc/api/board.php?act=tlist&bn=\(boardName!)"
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
                self.boardId = data["bi"] as? String
                self.textListArray = tlist
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let num = self.textListArray?.count {
            return num
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextListCell", for: indexPath) as! TableViewCell
        
        cell.selectedBackgroundView = self.cellBackgroundView
        
        guard let text = self.textListArray?[indexPath.row] as? [String: Any] else {
            print("Get row \(indexPath.row) error")
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
        let imgUrlString = text["thumb"] as? String
        let placeholderImage = UIImage(named: "displogo120")
        if imgUrlString != nil && imgUrlString != "" {
            let url = URL(string: imgUrlString!)!
            cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            cell.thumbImageView?.image = placeholderImage
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TextRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let row = self.tableView.indexPathForSelectedRow?.row,
                let text = self.textListArray?[row] as? [String: Any]
                else { return }
            
            textViewController.bi = self.boardId
            textViewController.ti = text["ti"] as? String
        }
    }
 
}
