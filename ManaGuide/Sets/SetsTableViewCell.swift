//
//  SetsTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

protocol SetsTableViewCellDelegate: NSObjectProtocol {
    func languageAction(cell: UITableViewCell, code: String)
}

class SetsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SetsCell"
    static let cellHeight = CGFloat(110)
    
    // MARK: Outlets
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var enButton: UIButton!
    @IBOutlet weak var esButton: UIButton!
    @IBOutlet weak var frButton: UIButton!
    @IBOutlet weak var deButton: UIButton!
    @IBOutlet weak var itButton: UIButton!
    @IBOutlet weak var ptButton: UIButton!
    @IBOutlet weak var jaButton: UIButton!
    @IBOutlet weak var koButton: UIButton!
    @IBOutlet weak var ruButton: UIButton!
    @IBOutlet weak var zhsButton: UIButton!
    @IBOutlet weak var zhtButton: UIButton!
    @IBOutlet weak var blankButton: UIButton!
    
    // MARK: Actions
    @IBAction func languageAction(_ sender: UIButton) {
        var code = ""
        
        if sender == enButton {
            code = "en"
        } else if sender == esButton {
            code = "es"
        } else if sender == frButton {
            code = "fr"
        } else if sender == deButton {
            code = "de"
        } else if sender == itButton {
            code = "it"
        } else if sender == ptButton {
            code = "pt"
        } else if sender == jaButton {
            code = "ja"
        } else if sender == koButton {
            code = "ko"
        } else if sender == ruButton {
            code = "ru"
        } else if sender == zhsButton {
            code = "zhs"
        } else if sender == zhtButton {
            code = "zht"
        }
        
        delegate?.languageAction(cell: self, code: code)
    }
    
    // MARK: Variables
    var set: CMSet! {
        didSet {
            logoLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            nameLabel.text = set.name
            codeLabel.text = set.code
            releaseDateLabel.text = set.releaseDate ?? " "
            numberLabel.text = "\(set.cardCount) cards"
            
            enButton.isEnabled = false
            esButton.isEnabled = false
            frButton.isEnabled = false
            deButton.isEnabled = false
            itButton.isEnabled = false
            ptButton.isEnabled = false
            jaButton.isEnabled = false
            koButton.isEnabled = false
            ruButton.isEnabled = false
            zhsButton.isEnabled = false
            zhtButton.isEnabled = false
            
            if let languagesSet = set.languages,
                let languages = languagesSet.allObjects as? [CMLanguage] {
                for language in languages {
                    if language.code == "en" {
                        enButton.isEnabled = true
                    } else if language.code == "es" {
                        esButton.isEnabled = true
                    } else if language.code == "fr" {
                        frButton.isEnabled = true
                    } else if language.code == "de" {
                        deButton.isEnabled = true
                    } else if language.code == "it" {
                        itButton.isEnabled = true
                    } else if language.code == "pt" {
                        ptButton.isEnabled = true
                    } else if language.code == "ja" {
                        jaButton.isEnabled = true
                    } else if language.code == "ko" {
                        koButton.isEnabled = true
                    } else if language.code == "ru" {
                        ruButton.isEnabled = true
                    } else if language.code == "zhs" {
                        zhsButton.isEnabled = true
                    } else if language.code == "zht" {
                        zhtButton.isEnabled = true
                    }
                }
            }
        }
    }
    var delegate: SetsTableViewCellDelegate?
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        enButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        enButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        esButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        esButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        frButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        frButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        deButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        deButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        itButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        itButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        ptButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        ptButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        jaButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        jaButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        koButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        koButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        ruButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        ruButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        zhsButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        zhsButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        zhtButton.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
        zhtButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
        
        blankButton.setBackgroundColor(UIColor.lightGray, for: .disabled)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
