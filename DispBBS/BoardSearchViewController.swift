//
//  BoardSearchViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/19.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class BoardSearchViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var mainViewController: MainViewController!

    var boardHistoryList = [BoardHistory]()
    var boardAllList = [Any]()
    var boardSearchResult = [Any]()
    var shouldShowSearchResult = false
    var searchController: UISearchController!
    var cellSelectedBackgroundView = UIView()

    func loadBoardHistoryList() {
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

        let fetchRequest = NSFetchRequest<BoardHistory>(entityName: "BoardHistory")

        do {
            self.boardHistoryList = try managedContext.fetch(fetchRequest).reversed()
            self.tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func clearBoardHistoryList() {
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

        let fetchRequest = NSFetchRequest<BoardHistory>(entityName: "BoardHistory")
        if let fetchResult = try? managedContext.fetch(fetchRequest) {
            for delBoard in fetchResult {
                managedContext.delete(delBoard)
            }
        }
        do {
            try managedContext.save()
            self.boardHistoryList.removeAll()
            self.tableView.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func loadBoardAllList() {
        let urlString = "https://disp.cc/api/get.php?act=bSearchList"
        Alamofire.request(urlString).responseJSON { response in
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
            if let list = JSON["list"] as? [Any] {
                self.boardAllList = list
            }
        }
    }
    
    func alert(message: String) {
        let alert = UIAlertController(title: "錯誤訊息", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        //searchController.hidesNavigationBarDuringPresentation = false
        let searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.placeholder = "請輸入看板名稱"
        searchBar.sizeToFit()
        
        tableView.tableHeaderView = searchBar
        tableView.backgroundView = UIView()
    }

    // 在 PageViewController 顯示此頁時執行
    func viewDidShowPage() {
        loadBoardHistoryList()
    }
    
    // 在 PageViewController 隱藏此頁時執行
    func viewDidHidePage() {
        self.searchController.isActive = false
        mainViewController.tabBarHeight.constant = 36
    }
    
    func refresh() {
        loadBoardHistoryList()
        loadBoardAllList()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.cellSelectedBackgroundView.backgroundColor = UIColor.darkGray
        configureSearchController()
        
        //要加在主頁面才行
        //self.definesPresentationContext = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowSearchResult {
            return boardSearchResult.count
        } else {
            if boardHistoryList.count > 0 {
                return boardHistoryList.count + 1
            } else {
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // section header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardSearchHeaderCell")
        if shouldShowSearchResult {
            cell?.textLabel?.text = "搜尋結果"
        } else {
            cell?.textLabel?.text = "瀏覽過的看板"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 看板瀏覽記錄下方按鈕
        if !shouldShowSearchResult && boardHistoryList.count > 0 && indexPath.row == boardHistoryList.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BoardSearchClearCell", for: indexPath)
            cell.textLabel?.text = "清除瀏覽記錄"
            cell.selectedBackgroundView = self.cellSelectedBackgroundView
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardSearchCell", for: indexPath)
        
        var boardName: String, boardTitle: String
        if shouldShowSearchResult {
            let board = boardSearchResult[indexPath.row] as! [String: Any]
            boardName = board["name"] as! String
            boardTitle = board["title"] as! String
        } else {
            let board = boardHistoryList[indexPath.row]
            boardName = board.name!
            boardTitle = board.title!
        }
        let attrStr = NSMutableAttributedString(string: boardName)
        let titleAttr = [NSForegroundColorAttributeName: UIColor.white]
        let titleAttrStr = NSAttributedString(string: " \(boardTitle)", attributes: titleAttr)
        attrStr.append(titleAttrStr)
        cell.textLabel?.attributedText = attrStr

        cell.selectedBackgroundView = self.cellSelectedBackgroundView
        return cell
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Board" {
            guard let textListViewController = segue.destination as? TextListViewController,
                let row = self.tableView.indexPathForSelectedRow?.row
                else { return }

            var boardName: String, boardTitle: String
            if shouldShowSearchResult {
                let board = self.boardSearchResult[row] as! [String: Any]
                boardName = board["name"] as! String
                boardTitle = board["title"] as! String
            } else {
                let board = self.boardHistoryList[row]
                boardName = board.name!
                boardTitle = board.title!
            }
            textListViewController.boardName = boardName
            textListViewController.boardTitle = boardTitle
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !shouldShowSearchResult && boardHistoryList.count > 0 && indexPath.row == boardHistoryList.count {
            let alert = UIAlertController(title: "清除瀏覽記錄", message: "確定要清除看板的瀏覽記錄嗎？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
                self.clearBoardHistoryList()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    // MARK: - UISearchBarDelegate

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if boardAllList.count == 0 {
            loadBoardAllList()
        }

        UIView.animate(withDuration: 0.5) {
            self.mainViewController.tabBarHeight.constant = 0
            self.mainViewController.view.layoutIfNeeded()
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let searchString = searchBar.text {
            if searchString.characters.count > 0 {
                shouldShowSearchResult = true
                tableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        UIView.animate(withDuration: 0.5) {
            self.mainViewController.tabBarHeight.constant = 36
            self.mainViewController.view.layoutIfNeeded()
        }
        shouldShowSearchResult = false
        loadBoardHistoryList()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        shouldShowSearchResult = true
        tableView.reloadData()
        searchController.searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        if searchString.characters.count == 0 {
            shouldShowSearchResult = false
            loadBoardHistoryList()
            return
        }
        boardSearchResult = boardAllList.filter({ obj -> Bool in
            let board = obj as! [String: Any]
            let boardName = board["name"] as! String
            
            if searchString.characters.count == 1 {
                if boardName.lowercased().characters.first == searchString.lowercased().characters.first {
                    return true
                }
            } else if boardName.range(of: searchString, options: NSString.CompareOptions.caseInsensitive) != nil {
                return true
            }
            return false
        })
        shouldShowSearchResult = true
        tableView.reloadData()
    }

}
