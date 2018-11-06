//
//  StoreTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 17/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift
import ManaKit

let kStoreTableViewCellHeight = CGFloat(60)

protocol StoreTableViewCellDelegate : NSObjectProtocol {
    func open(_ link: URL)
}

class StoreTableViewCell: UITableViewCell {
    static let reuseIdentifier = "StoreCell"
    
    // MARK: Variables
    var supplier: CMStoreSupplier?
    var delegate: StoreTableViewCellDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var shoppingCartButton: UIButton!
    
    
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
        shoppingCartButton.setImage(UIImage.fontAwesomeIcon(name: .shoppingCart,
                                                            style: .solid,
                                                            textColor: LookAndFeel.GlobalTintColor,
                                                            size: CGSize(width: 20, height: 20)),
                                    for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func display(_ supplier: CMStoreSupplier) {
        self.supplier = supplier
        
        nameLabel.text = supplier.name
        conditionLabel.text = supplier.condition
        quantityLabel.text = "Qty: \(supplier.qty)"
        priceLabel.text = String(format: "$%.2f", supplier.price)
    }
    
}
