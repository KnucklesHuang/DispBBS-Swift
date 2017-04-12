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
    var boardListArray:[Any]?
    var cellBackgroundView = UIView()
    
    func loadData() {
        let urlString = "https://disp.cc/api/board.php?act=blist"
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
                let blist = data["blist"] as? [Any] {
                self.boardListArray = blist
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
        if let num = self.boardListArray?.count {
            return num
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardListCell", for: indexPath) as! TableViewCell
        
        cell.selectedBackgroundView = self.cellBackgroundView
        
        guard let board = self.boardListArray?[indexPath.row] as? [String: Any] else {
            print("Get row \(indexPath.row) error")
            return cell
        }
        cell.titleLabel?.text = board["name"] as? String
        cell.descLabel?.text = board["title"] as? String
        
        let imgUrlString = board["icon"] as? String
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Board" {
            guard let textListViewController = segue.destination as? TextListViewController,
                let row = self.tableView.indexPathForSelectedRow?.row,
                let board = self.boardListArray?[row] as? [String: Any]
                else { return }
            textListViewController.boardName = board["name"] as? String
        }
    }
    


}
