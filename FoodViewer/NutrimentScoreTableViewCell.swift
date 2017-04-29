//
//  NutrimentScoreTableViewCell.swift
//  FoodViewer
//
//  Created by arnaud on 08/06/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import UIKit

class NutrimentScoreTableViewCell: UITableViewCell {
    
    enum NutritionScoreType {
        case good
        case bad
    }

    var nutrimentScore: (String, Int, Int, Int, NutritionScoreType) = ("", 0, 1, 0, .bad) {
        didSet {
            nutrimentLabel.text = nutrimentScore.0
            
            nutrimentScoreBarGaugeView.maxLimit = Float(nutrimentScore.2)
            nutrimentScoreBarGaugeView.numBars = nutrimentScore.2
            nutrimentScoreBarGaugeView.value = Float(nutrimentScore.1)

            switch nutrimentScore.4 {
            case .bad:
                nutrimentScoreBarGaugeView.reverse = true
                nutrimentScoreBarGaugeView.normalBarColor = .red
                nutrimentScoreBarGaugeView.dangerThreshold = nutrimentScoreBarGaugeView.maxLimit
                nutrimentScoreBarGaugeView.warnThreshold = nutrimentScoreBarGaugeView.maxLimit
            case .good:
                nutrimentScoreBarGaugeView.reverse = false
                nutrimentScoreBarGaugeView.normalBarColor = .green
                nutrimentScoreBarGaugeView.dangerThreshold = nutrimentScoreBarGaugeView.maxLimit
                nutrimentScoreBarGaugeView.warnThreshold = nutrimentScoreBarGaugeView.maxLimit
            }
        }
    }
    @IBOutlet weak var nutrimentScoreBarGaugeView: BarGaugeView! {
        didSet {
            nutrimentScoreBarGaugeView.litEffect = false
        }
    }

    @IBOutlet weak var nutrimentLabel: UILabel!
    
}
