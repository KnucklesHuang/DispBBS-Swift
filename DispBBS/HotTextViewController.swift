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
        
        cell.selectedBackgroundView = self.cellBackgroundView
        
        guard let hotText = self.hotTextArray?[indexPath.row] as? [String: Any] else {
            print("Get row \(indexPath.row) error")
            return cell
        }
        cell.titleLabel?.text = hotText["title"] as? String
        cell.descLabel?.text = hotText["desc"] as? String
        
        let img_list = hotText["img_list"] as? [String]
        let placeholderImage = UIImage(named: "displogo120")
        if img_list?.count != 0 {
            let url = URL(string: (img_list?[0])!)!
            cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            cell.thumbImageView?.image = placeholderImage
        }
 

        return cell
    }
    
    @IBAction func refresh(_ sender: Any) {
        loadData()
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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


