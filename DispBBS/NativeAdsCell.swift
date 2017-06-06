//
//  NativeAdsCell.swift
//  DispBBS
//
//  Created by knuckles on 2017/5/31.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit
import GoogleMobileAds

class NativeAdsCell: UITableViewCell {
    @IBOutlet weak var nativeExpressAdView: GADNativeExpressAdView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
