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
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String], sorters: [NSSortDescriptor]?)
}

class CardGridTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardGridCell"
    
    // MARK: Variables
    var viewModel: SearchViewModel!
    var delegate: CardGridTableViewCellDelegate?
    var imageType: CardImageType = .normal
    var animationOptions: UIView.AnimationOptions = []
    
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "Header")
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "HeaderEmpty")
        collectionView.register(UINib(nibName: "SearchModeCollectionViewCell",
                                      bundle: nil),
                                forCellWithReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier)
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
        if viewModel.isEmpty() {
            return 1
        } else {
            return viewModel.numberOfRows(inSection: section)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.isEmpty() {
            return 1
        } else {
            return viewModel.numberOfSections()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        switch viewModel.mode {
        case .resultsFound:
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: CardImageCollectionViewCell.reuseIdentifier, for: indexPath) as? CardImageCollectionViewCell,
                let card = viewModel.object(forRowAt: indexPath) as? CMCard else {
                fatalError("\(CardImageCollectionViewCell.reuseIdentifier) is nil")
            }
            
            c.imageType = imageType
            c.animationOptions = animationOptions
            c.card = card
            cell = c
            
        default:
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier,
                                                             for: indexPath) as? SearchModeCollectionViewCell else {
                fatalError("\(SearchModeCollectionViewCell.reuseIdentifier) is nil")
            }
            if imageType == .artCrop {
                c.messageLabel.font = UIFont(name: "Beleren", size: 15.0)
            }
            c.mode = viewModel.mode
            cell = c
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if viewModel.isEmpty() {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                   withReuseIdentifier:"HeaderEmpty",
                                                                   for: indexPath)
        } else {
            let v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                    withReuseIdentifier:"Header",
                                                                    for: indexPath)
            
            if kind == UICollectionView.elementKindSectionHeader {
                v.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
                
                if v.subviews.count == 0 {
                    let label = UILabel(frame: CGRect(x: 20, y: 0, width: collectionView.frame.size.width - 20, height: 22))
                    label.tag = 100
                    v.addSubview(label)
                }
                
                guard let lab = v.viewWithTag(100) as? UILabel else {
                    return v
                }
                
                lab.text = viewModel.titleForHeaderInSection(section: indexPath.section)//SectionIndexTitles()?[indexPath.section]
            }
            
            return v
        }
    }
}

// MARK: UICollectionViewDelegate
extension CardGridTableViewCell : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.isEmpty() {
            return
        }
        
        // TODO: fix this
//        guard let cards = viewModel.allObjects() as? [CMCard],
//            let card = viewModel.object(forRowAt: indexPath) as? CMCard,
//            let cardIndex = cards.index(of: card) else {
//            return
//        }
//
//        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
//        delegate?.showCard(identifier: identifier,
//                           cardIndex: cardIndex,
//                           cardIDs: cards.map({ $0.id! }),
//                           sorters: viewModel.sortDescriptors)
    }
}
