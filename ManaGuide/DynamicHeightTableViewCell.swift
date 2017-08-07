//
//  DynamicHeightTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit

class DynamicHeightTableViewCell: UITableViewCell {

    // MARK: Variables
    var isExpanded = false

    // MARK: Outlets
    @IBOutlet weak var dynamicTextLabel: UILabel!
    @IBOutlet weak var expandButton: UIButton!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func updateDataDisplay(text: String, level: Int) {
        dynamicTextLabel.text = text

//        let indent = CGFloat(16 * level)
//        let margin = CGFloat(8.0)
//        
//        let x = margin + indent
//        let width = contentView.frame.size.width - margin - x
//
//        for c in contentView.constraints {
//            contentView.removeConstraint(c)
//        }
//        for c in dynamicTextLabel.constraints {
//            dynamicTextLabel.removeConstraint(c)
//        }
//        dynamicTextLabel.frame = CGRect(x: x, y: 0, width: width, height: contentView.frame.size.height)
//        dynamicTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // top
//        var constraint = NSLayoutConstraint(item: dynamicTextLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0.0)
//        contentView.addConstraint(constraint)
//        
//        // left
//        constraint = NSLayoutConstraint(item: dynamicTextLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: x)
//        contentView.addConstraint(constraint)
//        
//        // bottom
//        constraint = NSLayoutConstraint(item: dynamicTextLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
//        contentView.addConstraint(constraint)
//        
//        // right
//        constraint = NSLayoutConstraint(item: dynamicTextLabel, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: -margin)
//        contentView.addConstraint(constraint)
        
        // minimum height
//        constraint = NSLayoutConstraint(item: dynamicTextLabel, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(44))
//        dynamicTextLabel.addConstraint(constraint)
        
//        dynamicTextLabel.backgroundColor = UIColor.green
//        contentView.backgroundColor = UIColor.gray
    }
    
}
