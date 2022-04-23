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
import Firebase
import FontAwesome_swift
import iCarousel
import IDMPhotoBrowser
import ManaKit
import MBProgressHUD
import PromiseKit
import NYAlertViewController
import RealmSwift

class CardViewController: BaseSearchViewController {
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var activityButton: UIBarButtonItem!
    
    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        guard let viewModel = viewModel as? CardViewModel,
            let content = CardContent(rawValue: contentSegmentedControl.selectedSegmentIndex) else {
            return
        }
        
        viewModel.content = content
        title = content.description
        
        switch viewModel.content {
        case .card:
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                  at: .top,
                                  animated: true)
        case .details:
            loadCardDetails()
        case .store:
            loadStorePricing()
        }
    }
    
    @IBAction func activityAction(_ sender: UIBarButtonItem) {
        guard let viewModel = viewModel as? CardViewModel,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        if let _ = card.image(type: .normal,
                              faceOrder: viewModel.faceOrder,
                              roundCornered: true) {
            showActivityViewController(sender, card: card)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card,
                                                     type: .normal,
                                                     faceOrder: viewModel.faceOrder)
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
        showSearchController = false
        
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
        
        if let viewModel = viewModel as? CardViewModel {
            title = viewModel.content.description
            
            firstly {
                viewModel.fetchData()
            }.done {
                viewModel.downloadCardPricing()
                self.tableView.reloadData()
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardPricingUpdated),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardPricingUpdated),
                                               object: nil)
        
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
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRelatedDataUpdated),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadCardDetails(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardRelatedDataUpdated),
                                               object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardPricingUpdated),
                                                  object: nil)
        
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
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRelatedDataUpdated),
                                                  object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: fix this
//        if segue.identifier == "showCard" {
//            guard let dest = segue.destination as? CardViewController,
//                let dict = sender as? [String: Any],
//                let cardIndex = dict["cardIndex"] as? Int,
//                let cardIDs = dict["cardIDs"] as? [String] else {
//                return
//            }
//
//            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
//                                           withCardIDs: cardIDs,
//                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
//
//        } else if segue.identifier == "showCardModal" {
//            guard let nav = segue.destination as? UINavigationController,
//                let dest = nav.children.first as? CardViewController,
//                let dict = sender as? [String: Any],
//                let cardIndex = dict["cardIndex"] as? Int,
//                let cardIDs = dict["cardIDs"] as? [String] else {
//                return
//            }
//
//            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
//                                           withCardIDs: cardIDs,
//                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
//
//        } else if segue.identifier == "showSearch" {
//            guard let dest = segue.destination as? SearchViewController,
//                let dict = sender as? [String: Any],
//                let request = dict["request"] as? NSFetchRequest<CMCard> else {
//                return
//            }
//
//            dest.viewModel = SearchViewModel(withRequest: request,
//                                             andTitle: dict["title"] as? String,
//                                             andMode: .loading)
//
//        } else if segue.identifier == "showLogin" {
//            guard let dest = segue.destination as? UINavigationController,
//                let loginVC = dest.children.first as? LoginViewController else {
//                return
//            }
//            loginVC.delegate = self
//
//        } else if segue.identifier == "showSet" {
//            guard let dest = segue.destination as? SetViewController,
//                let dict = sender as? [String: Any],
//                let set = dict["set"] as? CMSet,
//                let languageCode = dict["languageCode"] as? String else {
//                return
//            }
//
//            dest.viewModel = SetViewModel(withSet: set,
//                                          languageCode: languageCode)
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel as? CardViewModel,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var cell: UITableViewCell?
        
        switch viewModel.content {
        case .card:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardImageSection.pricing.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardPricingTableViewCell.reuseIdentifier,
                                                            for: indexPath ) as? CardPricingTableViewCell else {
                    fatalError("\(CardPricingTableViewCell.reuseIdentifier) not found")
                }
                
                c.card = card
                cell = c
                
            case CardImageSection.image.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardCarouselTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardCarouselTableViewCell else {
                    fatalError("\(CardCarouselTableViewCell.reuseIdentifier) not found")
                }
                c.viewModel = viewModel
                c.delegate = self
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
                let cardMainDetails = viewModel.cardMainDetails()
                for (k,v) in cardMainDetails[indexPath.row] {
                    cell = createMainDataCell(forCard: v, inRow: k.rawValue)
                }
                
            case CardDetailsSection.set.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardSetTableViewCell.reuseIdentifier,
                                                            for: indexPath) as? CardSetTableViewCell else {
                    fatalError("\(CardSetTableViewCell.reuseIdentifier) is nil")
                }
                c.card = card
                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c
            case CardDetailsSection.relatedData.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel else {
                    fatalError("RightDetailCell is nil")
                }
                
                switch indexPath.row {
                case CardRelatedDataSection.artist.rawValue:
                    label.text = CardRelatedDataSection.artist.description
                    if let artist = card.artist {
                        detailTextLabel.adjustsFontSizeToFitWidth = true
                        detailTextLabel.text = artist.name
                    } else {
                        detailTextLabel.text = " "
                    }
                    c.selectionStyle = .default
                    c.accessoryType = .disclosureIndicator
                    cell = c

                case CardRelatedDataSection.parts.rawValue:
                    label.text = CardRelatedDataSection.parts.description
                    if viewModel.numberOfParts() > 0 {
                        detailTextLabel.text = "\(viewModel.numberOfParts())"
                        c.selectionStyle = .default
                        c.accessoryType = .disclosureIndicator
                    } else {
                        detailTextLabel.text = "None"
                        c.selectionStyle = .none
                        c.accessoryType = .none
                    }
                    c.accessoryView = nil
                    cell = c

                case CardRelatedDataSection.variations.rawValue:
                    label.text = CardRelatedDataSection.variations.description
                    if viewModel.numberOfVariations() > 0 {
                        detailTextLabel.text = "\(viewModel.numberOfVariations())"
                        c.selectionStyle = .default
                        c.accessoryType = .disclosureIndicator
                    } else {
                        detailTextLabel.text = "None"
                        c.selectionStyle = .none
                        c.accessoryType = .none
                    }
                    c.accessoryView = nil
                    cell = c
                    
                case CardRelatedDataSection.otherPrintings.rawValue:
                    label.text = CardRelatedDataSection.otherPrintings.description
                    if viewModel.numberOfOtherPrintings() > 0 {
                        detailTextLabel.text = "\(viewModel.numberOfOtherPrintings())"
                        c.selectionStyle = .default
                        c.accessoryType = .disclosureIndicator
                    } else {
                        detailTextLabel.text = "None"
                        c.selectionStyle = .none
                        c.accessoryType = .none
                    }
                    c.accessoryView = nil
                    cell = c
                    
                default:
                    ()
                }
                
            case CardDetailsSection.rulings.rawValue:
                if viewModel.numberOfRulings() == 0 {
                    cell = createEmptyCardGridCell(for: indexPath)
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
                    cell = createEmptyCardGridCell(for: indexPath)
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                        let label = c.textLabel else {
                            fatalError("BasicCell is nil")
                    }

                    if card.cardLegalities.count > 0 {
                        let orderedCardLegalities = card.cardLegalities.sorted(by: {(a: CMCardLegality, b: CMCardLegality) -> Bool in
                            return a.format!.name! < b.format!.name!
                        })
                        let cardLegality = orderedCardLegalities[indexPath.row]
                        label.text = cardLegality.format!.name
                        c.accessoryView = createBadge(withCheck: cardLegality.legality!.name == "Legal")
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardDetailsSection.otherDetails.rawValue:
                switch indexPath.row {
                case CardOtherDetailsSection.colorshifted.rawValue,
                     CardOtherDetailsSection.reservedList.rawValue,
                     CardOtherDetailsSection.setOnlineOnly.rawValue,
                     CardOtherDetailsSection.storySpotlight.rawValue,
                     CardOtherDetailsSection.timeshifted.rawValue:
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                        let label = c.textLabel,
                        let otherDetails = CardOtherDetailsSection(rawValue: indexPath.row) else {
                        fatalError("BasicCell is nil")
                    }
                    label.text = otherDetails.description
                    c.accessoryView = createBadge(withCheck: viewModel.textOf(otherDetails: otherDetails) == "Yes")
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c

                default:
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                        let label = c.textLabel,
                        let detailTextLabel = c.detailTextLabel,
                        let otherDetails = CardOtherDetailsSection(rawValue: indexPath.row) else {
                        fatalError("RightDetailCell is nil")
                    }
                    
                    label.text = otherDetails.description
                    detailTextLabel.adjustsFontSizeToFitWidth = true
                    detailTextLabel.text = viewModel.textOf(otherDetails: otherDetails)
                    c.accessoryView = nil
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
                
            default:
                ()
            }
        
        case .store:
            tableView.separatorStyle = .singleLine

            switch viewModel.mode {
            case .resultsFound:
                guard let storePricing = card.tcgplayerStorePricing else {
                    fatalError("storePricing is nil")
                }

                if indexPath.row <= storePricing.suppliers.count - 1 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: StoreTableViewCell.reuseIdentifier) as? StoreTableViewCell else {
                        fatalError("\(StoreTableViewCell.reuseIdentifier) is nil")
                    }

                    c.delegate = self
                    c.display(storePricing.suppliers[indexPath.row])
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
            default:
                guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                    fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
                }
                c.mode = viewModel.mode
                cell = c
            }
        }
        
        return cell!
    }
    
    // MARK: Notification handlers
    @objc func reloadViewController(_ notification: Notification) {
        guard let viewModel = viewModel as? CardViewModel else {
//            let userInfo = notification.userInfo,
//            let card = userInfo["card"] as? CMCard,
//            let currentCard = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            return
        }
//
//        if card.id == currentCard.id {
//            DispatchQueue.main.async {
//                switch viewModel.content {
//                case .card:
//                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
//                                                   IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
//                                              with: .automatic)
//                default:
//                    ()
//                }
//            }
//        }
        switch viewModel.content {
        case .card:
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
                                           IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
                                      with: .automatic)
        default:
            ()
        }
    }

    @objc func reloadCardDetails(_ notification: Notification) {
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                              at: .top,
                              animated: true)
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
        guard let viewModel = viewModel as? CardViewModel else {
            fatalError()
        }
        
        let rating = viewModel.userRatingForCurrentCard()
        let ratingView = CosmosView(frame: CGRect.zero)
        ratingView.rating = rating
        ratingView.settings.emptyBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledColor = LookAndFeel.GlobalTintColor
        ratingView.settings.fillMode = .full
        
        let nyAlertController = NYAlertViewController(nibName: nil, bundle: nil)
        let confirmHandler = {  (action: NYAlertAction?) -> Void in
            self.dismiss(animated: false, completion: nil)
            guard let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard,
                let firebaseID = card.firebaseID else {
                return
            }
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            firstly {
                viewModel.updateCardRatings(rating: ratingView.rating)
            }.then {
                viewModel.updateUserRatings(rating: ratingView.rating)
            }.then {
                viewModel.saveFirebaseData(with: firebaseID)
            }.done {
                MBProgressHUD.hide(for: self.view, animated: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                object: nil,
                                                userInfo: nil)
            }.catch { error in
                MBProgressHUD.hide(for: self.view, animated: true)
                print("\(error)")
            }
        }
        let cancelHandler = {  (action: NYAlertAction?) -> Void in
            self.dismiss(animated: false, completion: nil)
        }
        let confirmAction = NYAlertAction(title: "Ok",
                                          style: .default,
                                          handler: confirmHandler)
        let cancelAction = NYAlertAction(title: "Cancel",
                                         style: .default,
                                         handler:  cancelHandler)

        nyAlertController.title = "Rating"
        nyAlertController.message = rating > 0 ? "Update your rating for this card." : "Submit your rating for this card."
        nyAlertController.buttonColor = LookAndFeel.GlobalTintColor
        nyAlertController.addAction(cancelAction)
        nyAlertController.addAction(confirmAction)
        nyAlertController.alertViewContentView = ratingView
        
        self.present(nyAlertController, animated: true, completion: nil)
    }
    
    func toggleCardFavorite() {
        guard let viewModel = viewModel as? CardViewModel else {
            fatalError()
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        firstly {
            viewModel.toggleCardFavorite()
        }.done {
            MBProgressHUD.hide(for: self.view, animated: true)
        }.catch { error in
            MBProgressHUD.hide(for: self.view, animated: true)
            print("\(error)")
        }
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
    
    func loadCardDetails() {
        guard let viewModel = viewModel as? CardViewModel else {
            fatalError()
        }
        viewModel.reloadRelatedCards()
        
        if !viewModel.cardViewsIncremented {
            firstly {
                viewModel.incrementCardViews()
            }.done {
                viewModel.cardViewsIncremented = true
            }.catch { error in
                viewModel.mode = .error
                self.tableView.reloadData()
            }
        }
    }
    
    func loadStorePricing() {
        guard let viewModel = viewModel as? CardViewModel,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }

        viewModel.mode = .loading
        firstly {
            ManaKit.sharedInstance.fetchTCGPlayerStorePricing(card: card)
        }.done {
            if let storePricing = card.tcgplayerStorePricing {
                viewModel.mode = storePricing.suppliers.isEmpty ? .noResultsFound : .resultsFound
            } else {
                viewModel.mode = .error
            }
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                       at: .top,
                                       animated: true)
        }.catch { error in
            viewModel.mode = .error
            self.tableView.reloadData()
        }
    }

    func createEmptyCardGridCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? CardGridTableViewCell else {
            fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
        }
        
        let width = CGFloat(138)
        let height = CGFloat(100)
        
        cell.delegate = self
        cell.imageType = .artCrop
        cell.animationOptions = .transitionCrossDissolve
        cell.flowLayout.itemSize = CGSize(width: width, height: height)
        cell.flowLayout.minimumInteritemSpacing = CGFloat(10)
        cell.flowLayout.scrollDirection = .horizontal
        
        let predicate = NSPredicate(format: "name = nil")
        cell.viewModel = SearchViewModel(withPredicate: predicate,
                                         andSortDescriptors: nil,
                                         andTitle: nil,
                                         andMode: .noResultsFound)
        return cell
    }
    
    func createMainDataCell(forCard card: CMCard, inRow row: Int) -> UITableViewCell {
        guard let viewModel = viewModel as? CardViewModel else {
            fatalError()
        }

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
            c.dynamicLabel.attributedText = viewModel.text(ofCard: card,
                                                           pointSize: c.dynamicLabel.font.pointSize)
            return c
            
        default:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell") else {
                fatalError("RightDetailCell is nil")
            }
            
            if let type = card.typeLine,
                let name = type.name {
                if name.contains("Creature") {
                    c.textLabel?.text = "Power/Toughness"
                    c.detailTextLabel?.text = "\(card.power!)/\(card.toughness!)"
                } else if name.contains("Planeswalker") {
                    c.textLabel?.text = "Loyalty"
                    c.detailTextLabel?.text = "\(card.loyalty!)"
                }
            }
            c.selectionStyle = .none
            c.accessoryType = .none
            return c
        }
    }
    
    func createBadge(withCheck check: Bool) -> UILabel {
        let label = UILabel()
        
        label.text = check ? String.fontAwesomeIcon(name: .checkCircle) : String.fontAwesomeIcon(name: .timesCircle)
        label.textColor = check ? .green : .red
        label.backgroundColor = .white
        label.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        label.textAlignment = NSTextAlignment.center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return label
    }
}

// MARK: UITableViewDelegate
extension CardViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let viewModel = viewModel as? CardViewModel,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var height = CGFloat(0)
        
        switch viewModel.content {
        case .card:
            switch indexPath.section {
            case CardImageSection.pricing.rawValue:
                height = CardPricingTableViewCell.cellHeight
            case CardImageSection.image.rawValue:
                height = tableView.frame.size.height - CardPricingTableViewCell.cellHeight - CardActionsTableViewCell.cellHeight
            case CardImageSection.actions.rawValue:
                height = CardActionsTableViewCell.cellHeight
            default:
                ()
            }
            
        case .details:
            switch indexPath.section {
            case CardDetailsSection.set.rawValue:
                height = CGFloat(56)
            case CardDetailsSection.relatedData.rawValue:
                height = UITableView.automaticDimension
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
            guard let storePricing = card.tcgplayerStorePricing else {
                return tableView.frame.size.height
            }
            let count = storePricing.suppliers.count
            
            if count == 0 {
                height = tableView.frame.size.height / 3
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
        guard let viewModel = viewModel as? CardViewModel else {
            fatalError()
        }
        var path: IndexPath?
        
        switch viewModel.content {
        case .details:
            switch indexPath.section {
            case CardDetailsSection.set.rawValue,
                 CardDetailsSection.relatedData.rawValue:
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
        guard let viewModel = viewModel as? CardViewModel,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var cardVM: CardViewModel?

        switch viewModel.content {
        case .details:
            switch indexPath.section {
            case CardDetailsSection.set.rawValue:
                guard let set = card.set,
                    let language = card.language,
                    let languageCode = language.code else {
                    return
                }
                let identifier = "showSet"
                let sender = ["set": set,
                              "languageCode": languageCode] as [String : Any]
                performSegue(withIdentifier: identifier, sender: sender)
            case CardDetailsSection.relatedData.rawValue:
                switch indexPath.row {
                case CardRelatedDataSection.artist.rawValue:
                    guard let artist = card.artist else {
                        return
                    }
                    
                    // TODO: fix this
//                    let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
//                    let predicate = NSPredicate(format: "artist.name = %@",
//                                                artist.name!)
//
//                    request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
//                                               NSSortDescriptor(key: "name", ascending: true),
//                                               NSSortDescriptor(key: "myNumberOrder", ascending: true)]
//                    request.predicate = predicate
//                    let identifier = "showSearch"
//                    let sender = ["request": request,
//                                  "title": artist.name!] as [String : Any]
//                    performSegue(withIdentifier: identifier, sender: sender)
                    
                case CardRelatedDataSection.parts.rawValue:
                    // TODO: fix this
                    ()
//                    guard let model = viewModel.partsViewModel,
//                        let cards = model.allObjects() as? [CMCard] else {
//                        return
//                    }
//                    cardVM = CardViewModel(withCardIndex: 0,
//                                           withCardIDs: cards.map({ $0.id! }),
//                                           withSortDescriptors: model.sortDescriptors)
                case CardRelatedDataSection.variations.rawValue:
                    // TODO: fix this
                    ()
//                    guard let model = viewModel.variationsViewModel,
//                        let cards = model.allObjects() as? [CMCard] else {
//                        return
//                    }
//                    cardVM = CardViewModel(withCardIndex: 0,
//                                           withCardIDs: cards.map({ $0.id! }),
//                                           withSortDescriptors: model.sortDescriptors)
                    
                case CardRelatedDataSection.otherPrintings.rawValue:
                    // TODO: fix this
                    ()
//                    guard let model = viewModel.otherPrintingsViewModel,
//                        let cards = model.allObjects() as? [CMCard] else {
//                        return
//                    }
//                    cardVM = CardViewModel(withCardIndex: 0,
//                                           withCardIDs: cards.map({ $0.id! }),
//                                           withSortDescriptors: model.sortDescriptors)
                default:
                    ()
                }
            default:
                ()
            }
        default:
            ()
        }
        
        if let cardVM = cardVM {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if let dest = storyboard.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController,
                let navigationController = navigationController {
                dest.viewModel = cardVM
                navigationController.pushViewController(dest, animated: true)
            }
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
// TODO: fix this
//extension CardViewController : LoginViewControllerDelegate {
//    func actionAfterLogin(error: Error?) {
//        if let error = error {
//
//        } else {
//            self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
//                                      with: .automatic)
//            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.UserLoggedIn),
//                                            object: nil,
//                                            userInfo: nil)
//        }
//    }
//}

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
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String], sortDescriptors: [SortDescriptor]) {
        let sender = ["cardIndex": cardIndex,
                      "cardIDs": cardIDs,
                      "sortDescriptors": sortDescriptors] as [String : Any]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// MARK: CardCarouselTableViewCellDelegate
extension CardViewController : CardCarouselTableViewCellDelegate {
    func showPhotoBrowser(_ browser: IDMPhotoBrowser) {
        present(browser, animated: true, completion: nil)
    }
    
    func updatePricingAndActions() {
        if let viewModel = viewModel as? CardViewModel {
            firstly {
                viewModel.loadFirebaseData()
            }.done {
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.pricing.rawValue),
                                               IndexPath(row: 0, section: CardImageSection.actions.rawValue)],
                                          with: .automatic)
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func updateCardImage() {
        tableView.reloadRows(at: [IndexPath(row: 0, section: CardImageSection.image.rawValue)],
                             with: .automatic)
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
