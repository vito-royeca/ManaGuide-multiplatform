//
//  StoreTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 17/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

let kStoreTableViewCellHeight = CGFloat(60)

protocol StoreTableViewCellDelegate : NSObjectProtocol {
    func open(_ link: URL)
}

class StoreTableViewCell: UITableViewCell {
    // MARK: Variables
    var supplier: CMSupplier?
    var delegate: StoreTableViewCellDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    // MARK: Actions
    
    @IBAction func cartAction(_ sender: UIButton) {
        guard let delegate = delegate else {
            return
        }
        guard let supplier = supplier else {
            return
        }
        guard let link = supplier.link else {
            return
        }
        guard let url = URL(string: link) else {
            return
        }
        
        delegate.open(url)
    }
    
    // MARK: Ocerrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func display(_ supplier: CMSupplier) {
        self.supplier = supplier
        
        nameLabel.text = supplier.name
        conditionLabel.text = supplier.condition
        quantityLabel.text = "Qty: \(supplier.qty)"
        priceLabel.text = String(format: "$%.2f", supplier.price)
    }
    
}
