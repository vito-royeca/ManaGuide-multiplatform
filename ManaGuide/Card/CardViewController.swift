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
        
        switch viewModel.content {
        case .image:
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        case .details:
            if !viewModel.cardViewIncremented {
                viewModel.cardViewIncremented = true
                incrementCardViews()
            }
            
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        case .store:
            tableView.reloadData()
            
            MBProgressHUD.showAdded(to: tableView, animated: true)
            firstly {
                ManaKit.sharedInstance.fetchTCGPlayerStorePricing(card: card)
            }.done {
                MBProgressHUD.hide(for: self.tableView, animated: true)
            }.catch { error in
                MBProgressHUD.hide(for: self.tableView, animated: true)
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
        tableView.register(UINib(nibName: "EmptyTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: EmptyTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "StoreTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: StoreTableViewCell.reuseIdentifier)

        let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0))
        title = card.name
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
//                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                    return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: 0,
                                           withCardIDs: cardIDs, withSortDescriptors: nil)
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request, andTitle: dict["title"] as? String)
            
        } else if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let dict = sender as? [String: Any],
                let set = dict["set"] as? CMSet else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set)
            
        } else if segue.identifier == "showLogin" {
            guard let dest = segue.destination as? UINavigationController,
                let loginVC = dest.childViewControllers.first as? LoginViewController else {
                return
            }
            loginVC.delegate = self
        }
    }
    
    @objc func reloadViewController(_ notification: Notification) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch self.viewModel.content {
            case .image:
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

        var excludedActivityTypes: [UIActivityType] = [.addToReadingList, .openInIBooks, .postToFacebook, .postToTwitter]

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
        let card = viewModel.object(forRowAt: IndexPath(row: index, section: 0))
        
        viewModel.cardIndex = index
        viewModel.cardViewIncremented = false
        title = card.name
        
        if viewModel.content == .image {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
                                      IndexPath(row: 0, section: CardImageSection.actions.rawValue)], with: .automatic)
        }
        viewModel.loadCardData()
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
            guard let link = attributedText.attribute(NSLinkAttributeName, at: characterIndex, effectiveRange: nil) else {
                return
            }
            guard let url = URL(string: "\(link)") else {
                return
            }
            open(url)
        }
    }
    
    func setupCardGridCell(cell: CardGridTableViewCell, withRequest request: NSFetchRequest<CMCard>) {
        let vm = SearchViewModel(withRequest: request, andTitle: nil)
        let width = CGFloat(138)
        let height = CGFloat(100)
        
        vm.fetchData()
        cell.viewModel = vm
        cell.delegate = self
        cell.imageType = .artCrop
        cell.animationOptions = .transitionCrossDissolve
        cell.flowLayout.itemSize = CGSize(width: width, height: height)
        cell.flowLayout.minimumInteritemSpacing = CGFloat(10)
        cell.flowLayout.scrollDirection = .horizontal
        cell.collectionView.reloadData()
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
        case .image:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardImageSection.pricing.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardPricingTableViewCell.reuseIdentifier, for: indexPath ) as? CardPricingTableViewCell else {
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
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardActionsTableViewCell.reuseIdentifier, for: indexPath) as? CardActionsTableViewCell else {
                    fatalError("ActionsTableViewCell not found")
                }
                
                c.delegate = self
                c.ratingView.rating = card.rating
                c.ratingLabel.text = viewModel.ratingStringForCard()
                c.favoriteButton.setImage(UIImage.fontAwesomeIcon(name: .heart,
                                                                  style: viewModel.isCurrentCardFavorite() ? .solid : .regular,
                                                                  textColor: LookAndFeel.GlobalTintColor,
                                                                  size: CGSize(width: 30, height: 30)),
                                          for: .normal)
                c.viewsLabel.text = "\u{f06e} \(card.views)"
                cell = c
                
            default:
                ()
            }
            
        case .details:
            tableView.separatorStyle = .singleLine
            
            switch indexPath.section {
            case CardDetailsSection.manaCost.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let text = card.manaCost {
                    label.attributedText = NSAttributedString(symbol: text, pointSize: label.font.pointSize)
                } else {
                    label.text = "\n"
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardDetailsSection.type.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let _ = card.type_ {
                    label.attributedText = MGUtilities.composeType(of: card, pointSize: label.font.pointSize)
                    label.adjustsFontSizeToFitWidth = true
                } else {
                    label.text = "\n"
                    label.adjustsFontSizeToFitWidth = false
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardDetailsSection.oracleText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                    fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                }
                
                if let text = card.text {
                    c.dynamicLabel.attributedText = NSAttributedString(symbol: "\n\(text)\n ",
                                                                      pointSize: c.dynamicLabel.font.pointSize)
                } else {
                    c.dynamicLabel.text = "\n"
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardDetailsSection.originalText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                    fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                }
                
                if let text = card.originalText {
                    c.dynamicLabel.attributedText = NSAttributedString(symbol: "\n\(text)\n ",
                                                                       pointSize: c.dynamicLabel.font.pointSize)
                } else {
                    c.dynamicLabel.text = "\n"
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardDetailsSection.flavorText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                    fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                }
                
                if let text = card.flavor {
                    c.dynamicLabel.text = "\n\(text)\n"
                } else {
                    c.dynamicLabel.text = "\n"
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
            
            case CardDetailsSection.set.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel,
                    let set = card.set,
                    let setName = set.name,
                    let keyruneUnicode = ManaKit.sharedInstance.keyruneUnicode(forSet: set),
                    let keyruneColor = ManaKit.sharedInstance.keyruneColor(forCard: card) else {
                        return UITableViewCell(frame: CGRect.zero)
                }
                
                let attributes = [NSFontAttributeName: UIFont(name: "Keyrune", size: 17)!,
                                  NSForegroundColorAttributeName: keyruneColor]
                let attributedString = NSMutableAttributedString(string: keyruneUnicode,
                                                                 attributes: attributes)
                
                attributedString.append(NSMutableAttributedString(string: " \(setName)",
                    attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
                
                label.attributedText = attributedString
                label.adjustsFontSizeToFitWidth = true
                detailTextLabel.text = "More Cards"
                
                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c

            case CardDetailsSection.artist.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let artist = card.artist_ {
                    label.adjustsFontSizeToFitWidth = true
                    label.text = artist.name
                    detailTextLabel.text = "More Cards"
                } else {
                    label.text = " "
                    detailTextLabel.text = " "
                }

                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c
                
            case CardDetailsSection.otherNames.rawValue:
                if viewModel.numberOfOtherNames() == 0 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                        fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                    }
                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                    request.predicate = NSPredicate(format: "name = nil")
                    setupCardGridCell(cell: c, withRequest: request)
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                        let label = c.textLabel else {
                            fatalError("BasicCell is nil")
                    }
                    
                    if let otherCard = viewModel.otherCard(inRow: indexPath.row) {
                        label.text = otherCard.name
                    }
                    c.selectionStyle = .default
                    c.accessoryType = .disclosureIndicator
                    cell = c
                }
                

            case CardDetailsSection.otherPrintings.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                    fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                }
                setupCardGridCell(cell: c, withRequest: viewModel.requestForOtherPrintings())
                cell = c
                
            case CardDetailsSection.variations.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                    fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                }
                setupCardGridCell(cell: c, withRequest: viewModel.requestForVariations())
                cell = c
                
            case CardDetailsSection.rulings.rawValue:
                if viewModel.numberOfRulings() == 0 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                        fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                    }
                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                    request.predicate = NSPredicate(format: "name = nil")
                    setupCardGridCell(cell: c, withRequest: request)
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
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
                    guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                        fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
                    }
                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                    request.predicate = NSPredicate(format: "name = nil")
                    setupCardGridCell(cell: c, withRequest: request)
                    cell = c
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                        let label = c.textLabel,
                        let detailTextLabel = c.detailTextLabel,
                        let cardLegalities_ = card.cardLegalities_ else {
                        fatalError("RightDetailCell is nil")
                    }
                    let array = cardLegalities_.allObjects as! [CMCardLegality]
                    
                    if array.count > 0 {
                        let cardLegality = array[indexPath.row]
                        label.text = cardLegality.format!.name
                        detailTextLabel.text = cardLegality.legality!.name
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardDetailsSection.otherDetails.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                    fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
                }
                c.dynamicLabel.attributedText = MGUtilities.composeOtherDetails(forCard: card)
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            default:
                ()
            }
            
        case .store:
            guard let suppliers = card.suppliers else {
                return UITableViewCell(frame: CGRect.zero)
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                if card.storePricingLastUpdate == nil {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
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
                    guard let c = tableView.dequeueReusableCell(withIdentifier: EmptyTableViewCell.reuseIdentifier) as? EmptyTableViewCell else {
                        fatalError("\(EmptyTableViewCell.reuseIdentifier) is nil")
                    }
                    cell = c
                }
                
            } else {
                if indexPath.row <= count - 1 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "StoreCell") as? StoreTableViewCell,
                        let suppliers = card.suppliers,
                        let supplier = suppliers.allObjects[indexPath.row] as? CMSupplier else {
                        return UITableViewCell(frame: CGRect.zero)
                    }
                    
                    c.delegate = self
                    c.display(supplier)
                
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                    
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell,
                        let note = card.storePricingNote else {
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
        case .image:
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
            case CardDetailsSection.otherNames.rawValue:
                if viewModel.numberOfOtherNames() == 0 {
                    height = CGFloat(100)
                } else {
                    height = UITableViewAutomaticDimension
                }
            case CardDetailsSection.otherPrintings.rawValue,
                 CardDetailsSection.variations.rawValue:
                height = CGFloat(100)
            case CardDetailsSection.rulings.rawValue:
                if viewModel.numberOfRulings() == 0 {
                    height = CGFloat(100)
                } else {
                    height = UITableViewAutomaticDimension
                }
            case CardDetailsSection.legalities.rawValue:
                if viewModel.numberOfLegalities() == 0 {
                    height = CGFloat(100)
                } else {
                    height = UITableViewAutomaticDimension
                }
            default:
                height = UITableViewAutomaticDimension
            }
            
        case .store:
            guard let suppliers = card.suppliers else {
                return tableView.frame.size.height
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                height = UITableViewAutomaticDimension
            } else {
                if indexPath.row <= count - 1 {
                    height = kStoreTableViewCellHeight
                } else {
                    height = UITableViewAutomaticDimension
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
            case CardDetailsSection.set.rawValue,
                 CardDetailsSection.artist.rawValue:
                path = indexPath
            case CardDetailsSection.otherNames.rawValue:
                if let _ = viewModel.otherCard(inRow: indexPath.row) {
                    path = indexPath
                }
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
            case CardDetailsSection.set.rawValue:
                guard let set = card.set else {
                    return
                }
                
                performSegue(withIdentifier: "showSet", sender: ["set": set])

            case CardDetailsSection.artist.rawValue:
                guard let artist = card.artist_ else {
                    return
                }
                
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                let predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
                
                request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                           NSSortDescriptor(key: "name", ascending: true),
                                           NSSortDescriptor(key: "set.releaseDate", ascending: true)]
                request.predicate = predicate
                
                performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                                    "title": artist.name!])
                
            case CardDetailsSection.otherNames.rawValue:
                if let otherCard = viewModel.otherCard(inRow: indexPath.row) {
                    performSegue(withIdentifier: "showCard", sender: ["card": otherCard])
                }
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
