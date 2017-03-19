//
//  HotTextViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/3/2.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class HotTextViewController: UITableViewController {
    var hotTextArray:[Any]?
    var cellBackgroundView = UIView()
    
    func loadData() {
        let urlString = "https://disp.cc/api/hot_text.json"
        Alamofire.request(urlString).responseJSON { response in
            self.refreshControl?.endRefreshing()
            guard response.result.isSuccess else {
                print("load data error: \(response.result.error)")
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                print("JSON formate error")
                return
            }
            //print("JSON: \(JSON)")
            if let list = JSON["list"] as? [Any] {
                self.hotTextArray = list
                self.tableView.reloadData()
            }
            
        }
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        loadData()
        
        self.refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: UIControlEvents.valueChanged)
        
        self.cellBackgroundView.backgroundColor = UIColor.darkGray

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let num = self.hotTextArray?.count {
            return num
        } else {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HotTextCell", for: indexPath) as! HotTextCell

        // Configure the cell...
//        cell.titleLabel?.text = "這是第 \(indexPath.row) 列"
//        cell.descLabel?.text = "測試文字 測試文字 測試文字 測試文字 測試文字 測試文字 測試文字 測試文字 測試文字 測試文字 "
//        cell.thumbImageView?.image = UIImage(named: "displogo120")
        
        cell.selectedBackgroundView = self.cellBackgroundView
        
        guard let hotText = self.hotTextArray?[indexPath.row] as? [String: Any] else {
            print("Get row \(indexPath.row) error")
            return cell
        }
        cell.titleLabel?.text = hotText["title"] as? String
        cell.descLabel?.text = hotText["desc"] as? String
        
        let img_list = hotText["img_list"] as? [String]
        if img_list?.count != 0 {
            let url = URL(string: (img_list?[0])!)!
            cell.thumbImageView?.af_setImage(withURL: url)
        } else {
            cell.thumbImageView?.image = UIImage(named: "displogo120")
        }
 

        return cell
    }
    
    @IBAction func refresh(_ sender: Any) {
        loadData()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "TextRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let row = self.tableView.indexPathForSelectedRow?.row,
                let hotText = self.hotTextArray?[row] as? [String: Any]
                else { return }

            textViewController.bi = hotText["bi"] as? String
            textViewController.ti = hotText["ti"] as? String
        }
    }
    

}


