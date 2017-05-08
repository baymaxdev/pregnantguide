//
//  MIPivotPageController.swift
//  MIPivotPageController
//
//  Created by Mario on 17/09/16.
//  Copyright © 2016 Mario Iannotta. All rights reserved.
//

import UIKit

@objc protocol MIPivotRootPage: class {
    
    func imageForPivotPage() -> UIImage?
    func stringForPivotPage() -> String?
    
    @objc optional func rootPivotPageDidShow()
    @objc optional func rootPivotPageWillHide()
    
}

class MIPivotPage: UIViewController, MIPivotRootPage {
    
    weak var pivotPageController: MIPivotPageController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if pivotPageController == nil {
            pivotPageController = (navigationController?.viewControllers.first as? MIPivotPage)?.pivotPageController
        }
        
        pivotPageController.pagesCollectionView.isScrollEnabled = pivotPageShouldHandleNavigation()
        
        pivotPageController.menuCollectionViewHeightConstraint.constant = shouldShowPivotMenu() ? pivotPageController.menuHeight : 0
        pivotPageController.pagesCollectionView.collectionViewLayout.invalidateLayout()
        
        UIView.animate(withDuration: 0.2) {
            self.pivotPageController.view.layoutIfNeeded()
            
        }
        
    }
    
    func shouldShowPivotMenu() -> Bool { return true }
    func pivotPageShouldHandleNavigation() -> Bool { return true }
    
    // MARK: - MIPivotRootPage
    func imageForPivotPage() -> UIImage? { return nil }
    func stringForPivotPage() -> String? { return nil }
    
}

protocol MIPivotPageControllerDelegate: class {
    
    func miPivotPageControllerWillShow(miPivotPageController: MIPivotPageController)
    
}

class MIPivotPageController: UIViewController {
    
    typealias SetupClosure = (MIPivotPageController) -> ()
    
    var barBI: UIBarButtonItem?
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var menuView: UIView!
    
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var pagesCollectionView: UICollectionView!
    
    @IBOutlet weak var menuCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuCollectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerContainerViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: MIPivotPageControllerDelegate?
    
    private var setupClosure: SetupClosure?
    
    fileprivate var menuHeight: CGFloat = 80
    
    private var statusBarStyle = UIStatusBarStyle.default
    
    fileprivate let pivotPageCellBaseIdentifier = MIPivotPageControllerPageCell.cellIdentifier

    var selectedIndex: Int = 0
    var rootPages: [MIPivotRootPage]!
    var pagesNumber: Int {
        return rootPages?.count ?? 0
    }
    
    // MARK: - Init
    
    public static func get(rootPages: [MIPivotRootPage], setupClosure: SetupClosure?) -> MIPivotPageController {
        
        let pivotPageController = MIPivotPageController(nibName: "MIPivotPageController", bundle: nil)
        
        pivotPageController.addRootPages(rootPages)
        pivotPageController.setupClosure = setupClosure
        
        return pivotPageController
        
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupHeaderView()
        
        setupClosure?(self)
        setNeedsStatusBarAppearanceUpdate()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        delegate?.miPivotPageControllerWillShow(miPivotPageController: self)
        
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return statusBarStyle
        
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        
        menuCollectionView.register(MIPivotPageControllerMenuCell.cellNib, forCellWithReuseIdentifier: MIPivotPageControllerMenuCell.cellIdentifier)
        
        for i in 0...(rootPages.count-1) {
            pagesCollectionView.register(MIPivotPageControllerPageCell.cellNib, forCellWithReuseIdentifier: pivotPageCellBaseIdentifier + String(i))
        }
        
    }
    private func setupHeaderView() {
        
        headerContainerViewHeightConstraint.constant = 0
        
    }
    private func addRootPages(_ rootPages: [MIPivotRootPage]) {
        
        func setParentForNavigationController(_ navigationController: UINavigationController) {
            
            guard let rootViewController = navigationController.viewControllers.first as? MIPivotPage else { return }
            
            rootViewController.pivotPageController = self
            
        }
        func setParentForRootPivotPage(_ pivotRootPage: MIPivotRootPage) {
            
            guard let pivotPage = pivotRootPage as? MIPivotPage else { return }
            
            pivotPage.pivotPageController = self
            
        }
        func setParentForTabBarController(_ tabBarController: UITabBarController) {
         
            guard let tabBarChildControllers = tabBarController.viewControllers else { return }
                
            for childController in tabBarChildControllers {
                
                if let navController = childController as? UINavigationController {
                    setParentForNavigationController(navController)
                } else if let childController = childController as? MIPivotPage {
                    childController.pivotPageController = self
                }
                
            }
            
        }
        
        self.rootPages = rootPages
        
        for pivotRootPage in rootPages {
            
            if let tabBarController = pivotRootPage as? UITabBarController {

                setParentForTabBarController(tabBarController)
   
            } else if let navigationController = pivotRootPage as? UINavigationController {
                
                setParentForNavigationController(navigationController)
                
            } else {
                
                setParentForRootPivotPage(pivotRootPage)
                
            }
            
        }
        
    }
    
    // MARK: - Customization
    
    func setMenuHeight(_ menuHeight: CGFloat) {
        
        self.menuHeight = menuHeight
        menuCollectionViewHeightConstraint.constant = menuHeight
        
    }
    func setStatusBarStyle(_ statusBarStyle: UIStatusBarStyle) {
        
        self.statusBarStyle = statusBarStyle
        
    }
    func addHeader(headerView: UIView, withHeight height: CGFloat) {
        
        headerContainerView.addSubview(headerView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainerView.addConstraints([
            NSLayoutConstraint(
                item: headerView,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: headerContainerView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: headerView,
                attribute: .top,
                relatedBy: .equal,
                toItem: headerContainerView,
                attribute: .top,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: headerView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: headerContainerView,
                attribute: .leading,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: headerView,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: headerContainerView,
                attribute: .trailing,
                multiplier: 1,
                constant: 0
            )
        ])
        
        headerContainerViewHeightConstraint.constant = height
        menuCollectionViewTopConstraint.constant = 0
        
    }
    
    // MARK: - Shortcuts
    
    func pivotPage(atIndex index: Int) -> MIPivotRootPage {
        
        let index = max(0, min(pagesNumber, index))
        return rootPages[index]
        
    }
    func menuImage(atIndex index: Int) -> UIImage? {

        return pivotPage(atIndex: index).imageForPivotPage()
        
    }
    func menuString(atIndex index: Int) -> String? {
        
        return Language.get(pivotPage(atIndex: index).stringForPivotPage()!)
        
    }
    func viewController(atIndex index: Int) -> UIViewController? {
        
        return pivotPage(atIndex: index) as? UIViewController
        
    }
    
    // MARK: - Menu stuff
    
    func updateMenu(forAnimationProgress animationProgress: Float) {
        
        for i in 0...pagesNumber {
            
            guard let cell = menuCollectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? MIPivotPageControllerMenuCell else { return }
            
            let cellAnimationProgress = 1 - abs(animationProgress - Float(i))
            
            cell.updateForAnimationProgress(cellAnimationProgress)
            
        }
        
    }
    func scrollToPage(atIndex index: Int) {
        //selectedIndex = index
        pagesCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .left, animated: true)
        
    }

}

extension MIPivotPageController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pagesNumber
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
            
        case menuCollectionView:
            
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MIPivotPageControllerMenuCell.cellIdentifier, for: indexPath) as? MIPivotPageControllerMenuCell
                else { return UICollectionViewCell() }
            
            cell.configure(image: menuImage(atIndex: indexPath.item), str: menuString(atIndex: indexPath.item)!, selected: selectedIndex == indexPath.item)
            
            //NSLog(menuString(atIndex: indexPath.item)!)
            
            return cell
            
        case pagesCollectionView:
            
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pivotPageCellBaseIdentifier + String(indexPath.item), for: indexPath) as? MIPivotPageControllerPageCell,
                let viewController = viewController(atIndex: indexPath.item)
                else { return UICollectionViewCell() }
            
            cell.configure(viewController: viewController)
            
            return cell
            
        default:
            
            return UICollectionViewCell()
            
        }
        
    }
    
    // UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
            
        case menuCollectionView:
            
            return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
            
        case pagesCollectionView:
            
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
            
        default:
            
            return CGSize.zero
            
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch collectionView {
            
        case menuCollectionView:
            
            let cellCount = CGFloat(collectionView.numberOfItems(inSection: section))
            let collectionViewWidth = collectionView.bounds.size.width
            
            let totalCellWidth = cellCount * collectionView.frame.height
            let totalCellSpacing = cellCount - 1
            
            let totalCellsWidth = totalCellWidth + totalCellSpacing
            
            let edgeInsets = (collectionViewWidth - totalCellsWidth) / 2.0
            
            return edgeInsets > 0 ? UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets) : UIEdgeInsets.zero
            
        default:
            
            return UIEdgeInsets.zero
            
        }
    }
    
    // UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let oldSelectedIndex = selectedIndex
        selectedIndex = indexPath.item
        
        pivotPage(atIndex: oldSelectedIndex).rootPivotPageWillHide?()
        pivotPage(atIndex: selectedIndex).rootPivotPageDidShow?()
        
        scrollToPage(atIndex: self.selectedIndex)
        if(selectedIndex==0) {
            barBI?.isEnabled = false
            
        }
        else {
            barBI?.isEnabled = true
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension MIPivotPageController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        updateMenu(forAnimationProgress: Float(scrollView.contentOffset.x/scrollView.frame.width))
        
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        pivotPage(atIndex: Int(floor(targetContentOffset.pointee.x/scrollView.frame.width))).rootPivotPageDidShow?()
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        selectedIndex = Int(floor(scrollView.contentOffset.x/scrollView.frame.width))
        if(selectedIndex==0) {
            barBI?.isEnabled = false
            
        }
        else {
            barBI?.isEnabled = true
        }
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        pivotPage(atIndex: selectedIndex).rootPivotPageWillHide?()
        if(selectedIndex==0) {
            barBI?.isEnabled = false
            
        }
        else {
            barBI?.isEnabled = true
        }
    }
    
}
