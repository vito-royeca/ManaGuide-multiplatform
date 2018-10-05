//
//  CardGridTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 04.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit

protocol CardGridTableViewCellDelegate : NSObjectProtocol {
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String])
}

class CardGridTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardGridCell"
    
    // MARK: Variables
    var viewModel: SearchViewModel!
    var delegate: CardGridTableViewCellDelegate?

    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: "Header")
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: "HeaderEmpty")
        collectionView.register(UINib(nibName: "EmptyCollectionViewCell",
                                      bundle: nil),
                                forCellWithReuseIdentifier: EmptyCollectionViewCell.reuseIdentifier)
        collectionView.register(UINib(nibName: "CardImageCollectionViewCell",
                                      bundle: nil),
                                forCellWithReuseIdentifier: CardImageCollectionViewCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func updateItemSize(with size: CGSize) {
        flowLayout.itemSize = size
        flowLayout.minimumInteritemSpacing = CGFloat(0)
        flowLayout.minimumLineSpacing = CGFloat(10)
        flowLayout.headerReferenceSize = CGSize(width: size.width, height: 22)
        flowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.reloadData()
    }
}

// MARK: UICollectionViewDataSource
extension CardGridTableViewCell : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.collectionNumberOfSections() == 0 {
            return 1
        } else {
            return viewModel.collectionNumberOfRows(inSection: section)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.collectionNumberOfSections() == 0 {
            return 1
        } else {
            return viewModel.collectionNumberOfSections()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        if viewModel.collectionNumberOfSections() == 0 {
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyCollectionViewCell.reuseIdentifier, for: indexPath) as? EmptyCollectionViewCell else {
                fatalError("\(EmptyCollectionViewCell.reuseIdentifier) is nil")
            }
            cell = c
        } else {
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: CardImageCollectionViewCell.reuseIdentifier, for: indexPath) as? CardImageCollectionViewCell else {
                fatalError("\(CardImageCollectionViewCell.reuseIdentifier) is nil")
            }
            
            let card = viewModel.object(forRowAt: indexPath)
            c.card = card
            cell = c
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if viewModel.collectionNumberOfSections() == 0 {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                   withReuseIdentifier:"HeaderEmpty",
                                                                   for: indexPath)
        } else {
            let v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                    withReuseIdentifier:"Header",
                                                                    for: indexPath)
            
            if kind == UICollectionElementKindSectionHeader {
                v.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
                
                if v.subviews.count == 0 {
                    let label = UILabel(frame: CGRect(x: 20, y: 0, width: collectionView.frame.size.width - 20, height: 22))
                    label.tag = 100
                    v.addSubview(label)
                }
                
                guard let lab = v.viewWithTag(100) as? UILabel else {
                    return v
                }
                
                lab.text = viewModel.collectionTitleForHeaderInSection(section: indexPath.section)//SectionIndexTitles()?[indexPath.section]
            }
            
            return v
        }
    }
}

// MARK: UICollectionViewDelegate
extension CardGridTableViewCell : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = viewModel.object(forRowAt: indexPath)
        
        guard let cards = viewModel.allObjects(),
            let cardIndex = cards.index(of: card) else {
            return
        }
        
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        delegate?.showCard(identifier: identifier,
                           cardIndex: cardIndex,
                           cardIDs: cards.map({ $0.id! }))
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if viewModel.collectionNumberOfSections() == 0 {
            return false
        } else {
            return true
        }
    }
}
