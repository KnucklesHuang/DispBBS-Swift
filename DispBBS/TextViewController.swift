//
//  TextViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/3/12.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit


class TextViewController: UIViewController, UIWebViewDelegate {
    //var urlString: String!
    var bi: String!
    var ti: String!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var goBackBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.delegate = self
        
        guard self.bi != nil, self.ti != nil else { return }
        let urlString = "https://disp.cc/m/\(bi!)-\(ti!)?fr=DispApp"
        //print(urlString)
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            self.webView.loadRequest(request)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.webView.reload()
    }

    @IBAction func goBack(_ sender: Any) {
        self.webView.goBack()
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        //NetworkActivityIndicatorManager.shared.incrementActivityCount()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if self.webView.canGoBack {
            self.goBackBtn.isEnabled = true
        } else {
            self.goBackBtn.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
