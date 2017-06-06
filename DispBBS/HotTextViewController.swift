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
import GoogleMobileAds

class HotTextViewController: UITableViewController, TextViewControllerDelegate {
    var mainViewController: MainViewController!

    var hotTextArray:[Any]?
    var cellBackgroundView = UIView()
    var isDebug = (UIApplication.shared.delegate as! AppDelegate).isDebug
    var keys: NSDictionary?
    
    func loadData() {
        //print("hotText loadData")
        let urlString = "https://disp.cc/api/hot_text.json"
        Alamofire.request(urlString).responseJSON { response in
            if (self.refreshControl?.isRefreshing)! {
                self.refreshControl?.endRefreshing()
            }
            
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                self.alert(message: "JSON formate error")
                return
            }
            if let list = JSON["list"] as? [Any] {
                self.hotTextArray = list
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
        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        self.cellBackgroundView.backgroundColor = UIColor.darkGray
        
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Google Analytics
//        let screenName = "HotText"
//        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
//        tracker.set(kGAIScreenName, value: screenName)
//        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
//        tracker.send(builder.build() as [NSObject : AnyObject])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let num = self.hotTextArray?.count else {
            return 0
        }
        if num >= 10 { // add native ads *2
            return num + 2
        } else if num >= 5 { // add native ads
            return num + 1
        } else {
            return num
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let num = hotTextArray?.count ?? 0
        if indexPath.row == num + 1 {
            return 320.0
        } else {
            return 100.0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let num = hotTextArray?.count ?? 0
        if indexPath.row == 5 || indexPath.row == num + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAdsCell", for: indexPath) as! NativeAdsCell
            if let nativeExpressAdView = cell.nativeExpressAdView {
                let testUnitID = "ca-app-pub-3940256099942544/2562852117"
                if indexPath.row == 5 {
                    nativeExpressAdView.adUnitID = keys?["AdMobUnitIdHotText"] as? String ?? testUnitID
                } else {
                    nativeExpressAdView.adUnitID = keys?["AdMobUnitIdHotTextBot"] as? String ?? testUnitID
                }
                nativeExpressAdView.rootViewController = self
                
                let request = GADRequest()
                if(isDebug){
                    var testDevices: [Any] = [kGADSimulatorID]
                    if let deviceIdList = keys?["AdMobDeviceId"] as? [Any] {
                        testDevices.append(contentsOf: deviceIdList)
                    }
                    request.testDevices = testDevices
                }
                nativeExpressAdView.load(request)
            }
            cell.backgroundColor = UIColor.black
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HotTextCell", for: indexPath) as! TableViewCell
        
        var index = indexPath.row
        if indexPath.row > 5 {
            index = indexPath.row - 1
        }
        guard let hotText = self.hotTextArray?[index] as? [String: Any] else {
            print("Get row \(indexPath.row) error")
            return cell
        }
        
        //cell.titleLabel?.text = hotText["title"] as? String
        let hotNumStr = hotText["hot_num"] as! String
        let darkRed = UIColor(red: 0x80/255.0, green: 0, blue: 0, alpha: 1.0)
        let attributes = [NSForegroundColorAttributeName: UIColor.black,
            NSBackgroundColorAttributeName: darkRed]
        let titleAttrStr = NSMutableAttributedString(string: hotNumStr, attributes: attributes)
        var title = hotText["title"] as! String
        let boardName = hotText["board_name"] as! String
        title = " \(title) - \(boardName)板"
        titleAttrStr.append(NSAttributedString(string: title))
        cell.titleLabel?.attributedText = titleAttrStr
        
        let author = hotText["author"] as! String
        let desc = hotText["desc"] as! String
        cell.descLabel?.text = "\(author) \(desc)"
        
        let imgList = hotText["img_list"] as? [String]
        let placeholderImage = UIImage(named: "displogo120")
        if imgList?.count != 0 {
            let url = URL(string: (imgList?.first)!)!
            cell.thumbImageView?.af_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            cell.thumbImageView?.image = placeholderImage
        }
 
        cell.backgroundColor = UIColor.black
        cell.selectedBackgroundView = self.cellBackgroundView
        return cell
    }
    
    // MARK: - TextViewController delegate
    
    func didLogin(userId: Int, userName: String) {
        refresh()
        mainViewController.didLogin(userId: userId, userName: userName)
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TextRead" {
            guard let textViewController = segue.destination as? TextViewController,
                let row = self.tableView.indexPathForSelectedRow?.row
                else { return }

            var index = row
            if row == 5 { return }
            else if row > 5 { index = row - 1 }
            guard let hotText = self.hotTextArray?[index] as? [String: Any]
                else { return }
            
            textViewController.boardId = hotText["bi"] as? String
            textViewController.textId = hotText["ti"] as? String
            textViewController.authorId = hotText["ai"] as? Int
            textViewController.authorName = hotText["author"] as? String
            textViewController.textTitle = hotText["title"] as? String
            textViewController.boardName = hotText["board_name"] as? String
            textViewController.delegate = self
        }
    }
}


