//
//  HotTextCell.swift
//  DispBBS
//
//  Created by knuckles on 2017/3/3.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit

class HotTextCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var thumbImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
