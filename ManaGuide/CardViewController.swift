//
//  CardViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift
import ManaKit

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cards: [CMCard]?
    var cardsCollectionView: UICollectionView?

    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Card")
    }
    
    @IBAction func segmentedAction(_ sender: UISegmentedControl) {
        print("\(sender.selectedSegmentIndex)")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cardsCollectionView = cardsCollectionView {
            cardsCollectionView.scrollToItem(at: IndexPath(item: cardIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch indexPath.row {
        case 0:
            if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                let cards = cards {
                c.card = cards[cardIndex]
                c.updateDataDisplay()
                cell = c
            }
        case 1:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                cell = c
            }
        case 2:
            if let c = tableView.dequeueReusableCell(withIdentifier: "CollectionViewCell") {
                if let collectionView = c.viewWithTag(100) as? UICollectionView {
                    cardsCollectionView = collectionView
                    
                    if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                        collectionView.backgroundColor = UIColor(patternImage: bgImage)
                    }
                    
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        let width = tableView.frame.size.width - 80
                        let height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44) - 40
                        flowLayout.itemSize = CGSize(width: width, height: height)
                        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                }
                cell = c
            }
        default:
            ()
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension CardViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch indexPath.row {
        case 0:
            height = kCardTableViewCellHeight
        case 1:
            height = CGFloat(44)
        case 2:
            height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44)
        default:
            ()
        }
        
        return height
    }
}

// MARK: UICollectionViewDataSource
extension CardViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var items = 0
        
        if let cards = cards {
            items = cards.count
        }
        return items
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardImageCell", for: indexPath)
        
        if let imageView = cell.viewWithTag(100) as? UIImageView,
            let cards = cards {
            let card = cards[indexPath.row]
            
            imageView.image = ManaKit.sharedInstance.cardImage(card)
        }
        return cell
    }
}

// UICollectionViewDelegate
extension CardViewController : UICollectionViewDelegate {
    
}

// MARK: UIScrollViewDelegate
extension CardViewController : UIScrollViewDelegate {
    func scrollToNearestVisibleCollectionViewCell() {
        if let collectionView = cardsCollectionView {
            let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + (collectionView.bounds.size.width / 2))
            var closestCellIndex = -1
            var closestDistance: Float = .greatestFiniteMagnitude
            
            for i in 0..<collectionView.visibleCells.count {
                let cell = collectionView.visibleCells[i]
                let cellWidth = cell.bounds.size.width
                let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
                
                // Now calculate closest cell
                let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
                if distance < closestDistance {
                    closestDistance = distance
                    closestCellIndex = collectionView.indexPath(for: cell)!.row
                }
            }
            if closestCellIndex != -1 {
                collectionView.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: false)
                
                // update the first table row cell
                cardIndex = closestCellIndex
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == cardsCollectionView {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == cardsCollectionView && !decelerate {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
}

