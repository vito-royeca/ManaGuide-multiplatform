//
//  CardViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos
import CoreData
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKMessengerShareKit
import Firebase
import FontAwesome_swift
import iCarousel
import IDMPhotoBrowser
import ManaKit
import MBProgressHUD
import PromiseKit
import NYAlertViewController

class CardViewController: BaseViewController {
    // MARK: Variables
    var viewModel: CardViewModel!
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var activityButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        guard let content = CardContent(rawValue: contentSegmentedControl.selectedSegmentIndex) else {
            return
        }
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        viewModel.content = content
        title = content.description
        
        switch viewModel.content {
        case .card:
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        case .details:
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
            if !viewModel.cardViewIncremented {
                viewModel.cardViewIncremented = true
                incrementCardViews()
            }
            
        case .store:
            MBProgressHUD.showAdded(to: tableView, animated: true)
            firstly {
                ManaKit.sharedInstance.fetchTCGPlayerStorePricing(card: card)
            }.done {
                MBProgressHUD.hide(for: self.tableView, animated: true)
                self.tableView.reloadData()
            }.catch { error in
                MBProgressHUD.hide(for: self.tableView, animated: true)
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func activityAction(_ sender: UIBarButtonItem) {
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        
        if let _ = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            showActivityViewController(sender, card: card)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showActivityViewController(sender, card: card)
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setImage(UIImage.fontAwesomeIcon(name: .image,
                                                                 style: .regular,
                                                                 textColor: LookAndFeel.GlobalTintColor,
                                                                 size: CGSize(width: 30, height: 30)),
                                         forSegmentAt: 0)
        contentSegmentedControl.setImage(UIImage.fontAwesomeIcon(name: .eye,
                                                                 style: .regular,
                                                                 textColor: LookAndFeel.GlobalTintColor,
                                                                 size: CGSize(width: 30, height: 30)),
                                         forSegmentAt: 1)
        contentSegmentedControl.setImage(UIImage.fontAwesomeIcon(name: .shoppingCart,
                                                                 style: .solid,
                                                                 textColor: LookAndFeel.GlobalTintColor,
                                                                 size: CGSize(width: 30, height: 30)),
                                         forSegmentAt: 2)
        
        tableView.register(UINib(nibName: "DynamicHeightTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: DynamicHeightTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "CardGridTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: CardGridTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "StoreTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: StoreTableViewCell.reuseIdentifier)

        title = viewModel.content.description
        viewModel.reloadRelatedCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String]else {
                    return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs, withSortDescriptors: nil)
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: dict["title"] as? String,
                                             andMode: .loading)
            
        } else if segue.identifier == "showLogin" {
            guard let dest = segue.destination as? UINavigationController,
                let loginVC = dest.children.first as? LoginViewController else {
                return
            }
            loginVC.delegate = self
        }
    }
    
    @objc func reloadViewController(_ notification: Notification) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch self.viewModel.content {
            case .card:
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
                                               IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
                                          with: .automatic)
            case .store:
                self.tableView.reloadData()
            default:
                ()
            }
        }
    }
    
    // MARK: Core Data notifications
    @objc func changeNotification(_ notification: Notification) {
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        var willReload = false
        
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] {
            if let set = updatedObjects as? NSSet {
                for o in set.allObjects {
                    if let c = o as? CMCard {
                        if c.objectID == card.objectID {
                            willReload = true
                            break
                        }
                    }
                }
            }
        }
        
        if willReload {
            reloadViewController(notification)
        }
    }

    // MARK: Custom methods
    func showActivityViewController(_ sender: UIBarButtonItem, card: CMCard) {
        let provider = CardActivityItemProvider(card)
        let activityVC = UIActivityViewController(activityItems: [provider],
                                                  applicationActivities: [FacebookShareActivity(parent: self)])

        var excludedActivityTypes: [UIActivity.ActivityType] = [.addToReadingList, .openInIBooks, .postToFacebook, .postToTwitter]

        if #available(iOS 11.0, *) {
            excludedActivityTypes.append(.markupAsPDF)
        }

        if let popoverPresentationController = activityVC.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        
        activityVC.excludedActivityTypes = excludedActivityTypes
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            // user did not cancel
            if success {
                if let e = error {
                    print("error: \(e.localizedDescription)")
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }

    func showUpdateRatingDialog() {
        let rating = viewModel.userRatingForCurrentCard()
        let ratingView = CosmosView(frame: CGRect.zero)
        ratingView.rating = rating
        ratingView.settings.emptyBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledColor = LookAndFeel.GlobalTintColor
        ratingView.settings.fillMode = .full
        
        let nyAlertController = NYAlertViewController(nibName: nil, bundle: nil)
        let confirmAction = NYAlertAction(title: "Ok",
                                          style: .default,
                                          handler: {  (action: NYAlertAction?) -> Void in
                                                    self.dismiss(animated: false, completion: nil)
            
                                                MBProgressHUD.showAdded(to: self.view, animated: true)
                                                self.viewModel.updateCardRatings(rating: ratingView.rating, firstAttempt: true)
        })
        let cancelAction = NYAlertAction(title: "Cancel",
                                         style: .default, handler:  {(action: NYAlertAction?) -> Void in
            self.dismiss(animated: false, completion: nil)
        })

        nyAlertController.title = "Rating"
        nyAlertController.message = rating > 0 ? "Update your rating for this card." : "Submit your rating for this card."
        nyAlertController.buttonColor = LookAndFeel.GlobalTintColor
        nyAlertController.addAction(cancelAction)
        nyAlertController.addAction(confirmAction)
        nyAlertController.alertViewContentView = ratingView
        
        self.present(nyAlertController, animated: true, completion: nil)
    }
    
    func incrementCardViews() {
        viewModel.incrementCardViews(firstAttempt: true)
    }
    
    func toggleCardFavorite() {
        MBProgressHUD.showAdded(to: view, animated: true)
        viewModel.toggleCardFavorite(firstAttempt: true)
    }
    
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView) {
        if let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            imageView.image = image
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done {
                guard let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) else {
                    return
                }
                
                let animations = {
                    imageView.image = image
                }
                UIView.transition(with: imageView,
                                  duration: 1.0,
                                  options: .transitionCrossDissolve,
                                  animations: animations,
                                  completion: nil)
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func movePhotoTo(index: Int) {
        viewModel.cardIndex = index
        viewModel.cardViewIncremented = false
        
        if viewModel.content == .card {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
                                      IndexPath(row: 0, section: CardImageSection.actions.rawValue)], with: .automatic)
        }
        viewModel.loadCardData()
        viewModel.reloadRelatedCards()
    }
    
    @objc func handleLink(_ tapGesture: UITapGestureRecognizer) {
        guard let label = tapGesture.view as? UILabel else {
            return
        }
        guard let attributedText = label.attributedText else {
            return
        }

        let storage = NSTextStorage(attributedString: attributedText)
        let textContainer = NSTextContainer(size: label.bounds.size)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)
        
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        
        let location = tapGesture.location(in: label)
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex < storage.length {
            guard let link = attributedText.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) else {
                return
            }
            guard let url = URL(string: "\(link)") else {
                return
            }
            open(url)
        }
    }
    
    func setupCardGridCell(cell: CardGridTableViewCell, withViewModel model: SearchViewModel) {
        
        let width = CGFloat(138)
        let height = CGFloat(100)
        
        cell.delegate = self
        cell.imageType = .artCrop
        cell.animationOptions = .transitionCrossDissolve
        cell.flowLayout.itemSize = CGSize(width: width, height: height)
        cell.flowLayout.minimumInteritemSpacing = CGFloat(10)
        cell.flowLayout.scrollDirection = .horizontal
        
        cell.viewModel = model

        if model.mode == .loading {
            firstly {
                model.fetchData()
            }.done {
                model.mode = model.isEmpty() ? .noResultsFound : .resultsFound
                cell.collectionView.reloadData()
            }.catch { error in
                model.mode = .error
                cell.collectionView.reloadData()
            }
        }
    }
    
    func createMainDataCell(forCard card: CMCard, inRow row: Int) -> UITableViewCell {
        switch row {
        case CardDetailsMainDataSection.name.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: CardNameTableViewCell.reuseIdentifier) as? CardNameTableViewCell else {
                fatalError("\(CardNameTableViewCell.reuseIdentifier) is nil")
            }
            c.selectionStyle = .none
            c.accessoryType = .none
            c.card = card
            return c
            
        case CardDetailsMainDataSection.type.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: CardTypeTableViewCell.reuseIdentifier) as? CardTypeTableViewCell else {
                fatalError("\(CardTypeTableViewCell.reuseIdentifier) is nil")
            }
            c.selectionStyle = .none
            c.accessoryType = .none
            c.card = card
            return c
            
        case CardDetailsMainDataSection.text.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
            }
            c.selectionStyle = .none
            c.accessoryType = .none
            c.dynamicLabel.attributedText = viewModel.cardText(inRow: row,
                                                               cardIndex: 0,
                                                               pointSize: c.dynamicLabel.font.pointSize)
            return c
            
        default:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") else {
                fatalError("BasicCell is nil")
            }
            
            if let type = card.typeLine,
                let name = type.name {
                if name.contains("Creature") {
                    c.textLabel?.text = "\(card.power!)/\(card.toughness!)"
                } else if name.contains("Plainswalker") {
                    c.textLabel?.text = "Loyalty: \(card.loyalty!)"
                }
            }
            c.textLabel?.textAlignment = .right
            c.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            c.selectionStyle = .none
            c.accessoryType = .none
            return c
        }
    }
}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        var cell: UITableViewCell?
        
        switch viewModel.content {
        case .card:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardImageSection.pricing.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardPricingTableViewCell.reuseIdentifier,
                                                            for: indexPath ) as? CardPricingTableViewCell else {
                    fatalError("CardPricingTableViewCell not found")
                }
                
                c.card = card
                cell = c
                
            case CardImageSection.image.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "CardImageCell"),
                    let carouselView = c.viewWithTag(100) as? iCarousel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                carouselView.dataSource = self
                carouselView.delegate = self
                carouselView.type = .coverFlow2
                carouselView.isPagingEnabled = true
                carouselView.currentItemIndex = viewModel.cardIndex
            
                if let imageView = carouselView.itemView(at: viewModel.cardIndex) as? UIImageView {
                    showImage(ofCard: card, inImageView: imageView)
                }
            
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardImageSection.actions.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardActionsTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardActionsTableViewCell else {
                    fatalError("ActionsTableViewCell not found")
                }
                
                c.delegate = self
                c.ratingView.rating = card.firebaseRating
                c.ratingLabel.text = viewModel.ratingStringForCard()
                c.favoriteButton.setImage(UIImage.fontAwesomeIcon(name: .heart,
                                                                  style: viewModel.isCurrentCardFavorite() ? .solid : .regular,
                                                                  textColor: LookAndFeel.GlobalTintColor,
                                                                  size: CGSize(width: 30, height: 30)),
                                                                  for: .normal)
                c.viewsLabel.text = "\u{f06e} \(card.firebaseViews)"
                cell = c
                
            default:
                ()
            }
            
        case .details:
            tableView.separatorStyle = .singleLine
            
            switch indexPath.section {
                case CardDetailsSection.mainData.rawValue:
                    if let facesSet = card.faces,
                        let faces = facesSet.allObjects as? [CMCard] {
                        
                        if faces.count > 0 {
                            let rows = viewModel.numberOfRows(inSection: indexPath.section)
                            let rowsPerFace = rows/faces.count
                            let row = indexPath.row % rowsPerFace
                            let face = faces[indexPath.row / rowsPerFace]
                            cell = createMainDataCell(forCard: face, inRow: row)
                        } else {
                            cell = createMainDataCell(forCard: card, inRow: indexPath.row)
                        }
                    }

            case CardDetailsSection.set.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardSetTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardSetTableViewCell else {
                    fatalError("\(CardSetTableViewCell.reuseIdentifier) is nil")
                }
                c.card = card
                cell = c

            case CardDetailsSection.artist.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                    fatalError("BasicCell is nil")
                }
                
                if let artist = card.artist {
                    label.adjustsFontSizeToFitWidth = true
                    label.text = artist.name
                } else {
                    label.text = " "
                }
                label.textAlignment = .left
                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c
            
            case CardDetailsSection.parts.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardGridTableViewCell else {
                                                                fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                }
                setupCardGridCell(cell: c, withViewModel: viewModel.partsViewModel!)
                cell = c

            case CardDetailsSection.variations.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardGridTableViewCell else {
                    fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                }
                setupCardGridCell(cell: c, withViewModel: viewModel.variationsViewModel!)
                cell = c
                
            case CardDetailsSection.otherPrintings.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardGridTableViewCell else {
                    fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                }
                setupCardGridCell(cell: c, withViewModel: viewModel.otherPrintingsViewModel!)
                cell = c
                
            case CardDetailsSection.rulings.rawValue:
                if viewModel.numberOfRulings() == 0 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? CardGridTableViewCell else {
                        fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                    }
                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                    request.predicate = NSPredicate(format: "name = nil")
                    setupCardGridCell(cell: c,
                                      withViewModel: SearchViewModel(withRequest: nil, andTitle: nil, andMode: .noResultsFound))
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? DynamicHeightTableViewCell else {
                        fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                    }
                    c.dynamicLabel.attributedText = viewModel.rulingText(inRow: indexPath.row,
                                                                         pointSize: c.dynamicLabel.font.pointSize)
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardDetailsSection.legalities.rawValue:
                if viewModel.numberOfLegalities() == 0 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? CardGridTableViewCell else {
                        fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                    }
                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                    request.predicate = NSPredicate(format: "name = nil")
                    setupCardGridCell(cell: c,
                                      withViewModel: SearchViewModel(withRequest: nil, andTitle: nil, andMode: .noResultsFound))
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                        let label = c.textLabel,
                        let detailTextLabel = c.detailTextLabel,
                        let cardLegalitiesSet = card.cardLegalities,
                        let cardLegalities = cardLegalitiesSet.allObjects as? [CMCardLegality] else {
                        fatalError("RightDetailCell is nil")
                    }
                    
                    if cardLegalities.count > 0 {
                        let orderedCardLegalities = cardLegalities.sorted(by: {(a: CMCardLegality, b: CMCardLegality) -> Bool in
                            return a.format!.name! < b.format!.name!
                        })
                        let cardLegality = orderedCardLegalities[indexPath.row]
                        label.text = cardLegality.format!.name
                        detailTextLabel.text = cardLegality.legality!.name
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardDetailsSection.otherDetails.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel,
                    let otherDetails = CardOtherDetailsSection(rawValue: indexPath.row) else {
                    fatalError("RightDetailCell is nil")
                }
                label.text = otherDetails.description
                detailTextLabel.adjustsFontSizeToFitWidth = true
                detailTextLabel.text = viewModel.textOf(otherDetails: otherDetails)
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            default:
                ()
            }
            
        case .store:
            guard let storePricing = card.tcgplayerStorePricing,
                let suppliersSet = storePricing.suppliers,
                let suppliers = suppliersSet.allObjects as? [CMStoreSupplier] else {
                return UITableViewCell(frame: CGRect.zero)
            }
            let count = suppliers.count
            
            if count == 0 {
                if storePricing.lastUpdate == nil {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? DynamicHeightTableViewCell else {
                        fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                    }
                    c.dynamicLabel.attributedText = NSAttributedString(html: "<html><center>Loading...</center></html>")
                    c.dynamicLabel.isUserInteractionEnabled = false
                    if let taps = c.dynamicLabel.gestureRecognizers {
                        for tap in taps {
                            c.dynamicLabel.removeGestureRecognizer(tap)
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? SearchModeTableViewCell else {
                        fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
                    }
                    c.mode = .noResultsFound
                    cell = c
                }
                
            } else {
                if indexPath.row <= count - 1 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "StoreCell") as? StoreTableViewCell,
                        let storePricing = card.tcgplayerStorePricing,
                        let suppliersSet = storePricing.suppliers,
                        let suppliers = suppliersSet.allObjects as? [CMStoreSupplier] else {
                        return UITableViewCell(frame: CGRect.zero)
                    }
                    
                    c.delegate = self
                    c.display(suppliers[indexPath.row])
                
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                    
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier,
                                                                for: indexPath) as? DynamicHeightTableViewCell,
                        let storePricing = card.tcgplayerStorePricing,
                        let note = storePricing.notes else {
                        fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                    }
                    
                    c.dynamicLabel.attributedText = NSAttributedString(html: note)
                    c.dynamicLabel.isUserInteractionEnabled = true
                    c.dynamicLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLink(_:))))
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeaderInSection(section: section)
    }
}

// MARK: UITableViewDelegate
extension CardViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        var height = CGFloat(0)
        
        switch viewModel.content {
        case .card:
            switch indexPath.section {
            case CardImageSection.pricing.rawValue:
                height = 44
            case CardImageSection.image.rawValue:
                height = tableView.frame.size.height - 88
            case CardImageSection.actions.rawValue:
                height = 44
            default:
                ()
            }
            
        case .details:
            switch indexPath.section {
            case CardDetailsSection.set.rawValue:
                height = CGFloat(56)
            case CardDetailsSection.variations.rawValue,
                 CardDetailsSection.parts.rawValue,
                 CardDetailsSection.otherPrintings.rawValue:
                height = CGFloat(100)
            case CardDetailsSection.rulings.rawValue:
                if viewModel.numberOfRulings() == 0 {
                    height = CGFloat(100)
                } else {
                    height = UITableView.automaticDimension
                }
            case CardDetailsSection.legalities.rawValue:
                if viewModel.numberOfLegalities() == 0 {
                    height = CGFloat(100)
                } else {
                    height = UITableView.automaticDimension
                }
            default:
                height = UITableView.automaticDimension
            }
            
        case .store:
            guard let storePricing = card.tcgplayerStorePricing,
                let suppliersSet = storePricing.suppliers,
                let suppliers = suppliersSet.allObjects as? [CMStoreSupplier] else {
                return tableView.frame.size.height
            }
            let count = suppliers.count
            
            if count == 0 {
                height = UITableView.automaticDimension
            } else {
                if indexPath.row <= count - 1 {
                    height = kStoreTableViewCellHeight
                } else {
                    height = UITableView.automaticDimension
                }
            }
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var path: IndexPath?
        
        switch viewModel.content {
        case .details:
            switch indexPath.section {
            case CardDetailsSection.artist.rawValue:
                path = indexPath
            default:
                ()
            }
        default:
            ()
        }

        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        
        switch viewModel.content {
        case .details:
            switch indexPath.section {
            case CardDetailsSection.artist.rawValue:
                guard let artist = card.artist else {
                    return
                }
                
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                let predicate = NSPredicate(format: "artist.name = %@", artist.name!)
                
                request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                           NSSortDescriptor(key: "name", ascending: true),
                                           NSSortDescriptor(key: "set.releaseDate", ascending: true)]
                request.predicate = predicate
                
                performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                                    "title": artist.name!])
                
            default:
                ()
            }
        default:
            ()
        }
    }
}

// MARK: iCarouselDataSource
extension CardViewController : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        return viewModel.numberOfCards()
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var imageView = UIImageView(frame: CGRect.zero)
        
        //reuse view if available, otherwise create a new view
        if let v = view as? UIImageView {
            imageView = v
            
        } else {
            let height = tableView.frame.size.height - 88
            let width = tableView.frame.size.width - 40
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageView.contentMode = .scaleAspectFit

            // add drop shadow
            imageView.layer.shadowColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.45).cgColor
            imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
            imageView.layer.shadowOpacity = 1
            imageView.layer.shadowRadius = 6.0
            imageView.clipsToBounds = false
        }
        
        let card = viewModel.object(forRowAt: IndexPath(row: index, section: 0))
        showImage(ofCard: card, inImageView: imageView)
        
        return imageView
    }
}

// MARK: iCarouselDelegate
extension CardViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        movePhotoTo(index: carousel.currentItemIndex)
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        var photos = [ManaGuidePhoto]()
        
        for i in 0...viewModel.numberOfCards() - 1 {
            let card = viewModel.object(forRowAt: IndexPath(row: i, section: 0))
            photos.append(ManaGuidePhoto(withCard: card))
        }
        
        if let browser = IDMPhotoBrowser(photos: photos) {
            browser.setInitialPageIndex(UInt(index))
            browser.displayActionButton = false
            browser.usePopAnimation = true
            browser.forceHideStatusBar = true
            browser.delegate = self

            present(browser, animated: true, completion: nil)
        }
    }
}

// MARK: IDMPhotoBrowserDelegate
extension CardViewController : IDMPhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser,  didShowPhotoAt index: UInt) {
        let i = Int(index)
        
        if i != viewModel.cardIndex {
            movePhotoTo(index: i)
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.image.rawValue)], with: .none)
        }
    }
}

// MARK: StoreTableViewCellDelegate
extension CardViewController : StoreTableViewCellDelegate {
    func open(_ link: URL) {
        UIApplication.shared.open(link)
    }
}

// MARK: LoginViewControllerDelegate
extension CardViewController : LoginViewControllerDelegate {
    func actionAfterLogin(error: Error?) {
        if let error = error {
            
        } else {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
                                      with: .automatic)
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.UserLoggedIn),
                                            object: nil,
                                            userInfo: nil)
        }
    }
}

// MARK: CardActionsTableViewCellDelegate
extension CardViewController : CardActionsTableViewCellDelegate {
    func favoriteAction() {
        if let _ = Auth.auth().currentUser {
            toggleCardFavorite()
        } else {
            performSegue(withIdentifier: "showLogin",
                         sender: nil)
        }
    }
    
    func ratingAction() {
        if let _ = Auth.auth().currentUser {
            self.showUpdateRatingDialog()
        } else {
            performSegue(withIdentifier: "showLogin",
                         sender: nil)
        }
    }
}

// MARK: CardGridTableViewCellDelegate
extension CardViewController : CardGridTableViewCellDelegate {
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String]) {
        let sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cardIDs]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
