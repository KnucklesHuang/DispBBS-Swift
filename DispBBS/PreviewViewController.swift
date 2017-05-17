//
//  PreviewViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/5/3.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import Alamofire

protocol PreviewViewControllerDelegate {
    func previewDidSaveText()
}

class PreviewViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    var boardId: String!
    var textId: String!
    var targetName: String!
    var type: String!
    var ri: String!
    var inputTitle: String!
    var inputText: String!
    
    @IBOutlet weak var submitButton: UIBarButtonItem!
    var delegate: PreviewViewControllerDelegate?
    
    func loadPreview() {
        let urlString = "https://disp.cc/api/editor.php?act=preview&isWebview=1&bi=\(boardId!)&type=\(type!)"
        let parameters: Parameters = ["isLogin": 1, "targetName": targetName, "title": inputTitle, "text": inputText]
        Alamofire.request(urlString, method: .post, parameters: parameters).responseJSON { response in
            guard response.result.isSuccess else {
                let errorMessage = response.result.error?.localizedDescription
                self.alert(message: errorMessage!)
                return
            }
            guard let JSON = response.result.value as? [String: Any] else {
                    self.alert(message: "JSON formate error")
                    return
            }
            // 這個 API 的 isSuccess 會是 true 或 0
            if let isSuccess = JSON["isSuccess"] as? Int {
                if isSuccess == 0 {
                    let errorMessage = JSON["errorMessage"] as? String ?? "error"
                    self.alert(message: errorMessage)
                    return
                }
            }

            if let data = JSON["data"] as? [String: Any],
                let htmlString = data["html"] as? String {
                //print(htmlString)
                self.webView.loadHTMLString(htmlString, baseURL: nil)
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

        loadPreview()
        
        if boardId == "0" {
            submitButton.title = "寄出信件"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveText(_ sender: Any) {
        self.delegate?.previewDidSaveText()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
