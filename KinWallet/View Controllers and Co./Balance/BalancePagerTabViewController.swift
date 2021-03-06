//
//  BalancePagerTabViewController.swift
//  Kinit
//

import UIKit

class BalancePagerTabViewController: ButtonBarPagerTabStripViewController {
    @IBOutlet weak var separatorView: UIView! {
        didSet {
            separatorView.backgroundColor = UIColor.kin.lightGray
        }
    }

    override func viewDidLoad() {
        settings.style.selectedBarHeight = 2
        settings.style.selectedBarBackgroundColor = UIColor.kin.appTint
        settings.style.buttonBarItemFont = FontFamily.Roboto.regular.font(size: 16)
        settings.style.buttonBarItemTitleColor = UIColor.kin.gray
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.buttonBarLeftContentInset = 25
        settings.style.buttonBarRightContentInset = 25
        settings.style.buttonBarItemLeftRightMargin = 2

        super.viewDidLoad()
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [TransactionHistoryViewController(), RedeemedGoodsViewController()]
    }
}
