//
//  FeaturedTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 16/11/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit
import RealmSwift

protocol FeaturedTableViewCellDelegate: NSObjectProtocol {
    func showSet(_ set: CMSet)
    func showCards(_ cards: Results<CMCard>, withIndex index: Int)
    func seeAllItems(section: FeaturedSection)
}

class FeaturedTableViewCell: UITableViewCell {

    static let reuseIdentifier = "FeaturedCell"
    
    // MARK: Variables
    var viewModel: BaseSearchViewModel!
    var section: FeaturedSection = .latestSets
    var delegate: FeaturedTableViewCellDelegate?

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Actions
    @IBAction func seeAllAction(_ sender: UIButton) {
        delegate?.seeAllItems(section: section)
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.register(UINib(nibName: "SearchModeCollectionViewCell",
                                      bundle: nil),
                                forCellWithReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Custom methods
    func setupCollectionView(itemSize: CGSize) {
        if let flowLayout = flowLayout {
            flowLayout.itemSize = itemSize
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumInteritemSpacing = CGFloat(5)
            flowLayout.sectionInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 0)
        }
    }
}

// MARK: UICollectionViewDataSource
extension FeaturedTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        switch section {
        case .latestSets:
            if viewModel.mode == .resultsFound {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: LatestSetItemCell.reuseIdentifier,
                                                                 for: indexPath) as? LatestSetItemCell else {
                    fatalError("\(LatestSetItemCell.reuseIdentifier) not found")
                }
                c.set = viewModel.object(forRowAt: indexPath) as? CMSet
                cell = c
            } else {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier,
                                                                 for: indexPath) as? SearchModeCollectionViewCell else {
                    fatalError("\(SearchModeCollectionViewCell.reuseIdentifier) is nil")
                }
                c.mode = viewModel.mode
                cell = c
            }
            
        case .topRated:
            if viewModel.mode == .resultsFound {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: TopRatedItemCell.reuseIdentifier,
                                                                 for: indexPath) as? TopRatedItemCell else {
                    fatalError("\(TopRatedItemCell.reuseIdentifier) not found")
                }
                c.card = viewModel.object(forRowAt: indexPath) as? CMCard
                cell = c
            } else {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier,
                                                                 for: indexPath) as? SearchModeCollectionViewCell else {
                    fatalError("\(SearchModeCollectionViewCell.reuseIdentifier) is nil")
                }
                c.mode = viewModel.mode
                cell = c
            }

        case .topViewed:
            if viewModel.mode == .resultsFound {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: TopViewedItemCell.reuseIdentifier,
                                                                 for: indexPath) as? TopViewedItemCell else {
                    fatalError("\(TopViewedItemCell.reuseIdentifier) not found")
                }
                c.card = viewModel.object(forRowAt: indexPath) as? CMCard
                cell = c
            } else {
                guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: SearchModeCollectionViewCell.reuseIdentifier,
                                                                 for: indexPath) as? SearchModeCollectionViewCell else {
                    fatalError("\(SearchModeCollectionViewCell.reuseIdentifier) is nil")
                }
                c.mode = viewModel.mode
                cell = c
            }
            
        default:
            ()
        }
        
        if let cell = cell {
            cell.setNeedsLayout()
        }
        return cell!
    }
}

// MARK: UICollectionViewDelegate
extension FeaturedTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.isEmpty() {
            return
        }

        switch section {
        case .latestSets:
            if let set = viewModel.object(forRowAt: indexPath) as? CMSet {
                delegate?.showSet(set)
            }
        case .topRated,
             .topViewed:
            let index = indexPath.item
            var ids = [String]()
            
            for i in 0...viewModel.count() - 1 {
                if let card = viewModel.object(forRowAt: IndexPath(row: i, section: 0)) as? CMCard,
                    let id = card.id {
                    ids.append(id)
                }
            }
            var cards = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("id in %@", ids)
            if let sortDescriptors = viewModel.sortDescriptors {
                cards = cards.sorted(by: sortDescriptors)
            }
            
            delegate?.showCards(cards,
                                withIndex: index)
        default:
            ()
        }
    }
}
