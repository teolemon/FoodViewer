//
//  CommunityTableViewCell.swift
//  FoodViewer
//
//  Created by arnaud on 12/02/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import UIKit
import TagListView

class CommunityTableViewCell: UITableViewCell {

    var product: FoodProduct? = nil {
        didSet {
            if let users = product?.productContributors.contributors {
            communityTagListView.removeAllTags()
                for user in users {
                    communityTagListView.addTag(user.name)
                }
            }
        }
    }
    
    @IBOutlet weak var communityTagListView: TagListView! {
        didSet {
            communityTagListView.textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            communityTagListView.alignment = .Center
            communityTagListView.tagBackgroundColor = UIColor.greenColor()
            communityTagListView.cornerRadius = 10
        }
    }


}
