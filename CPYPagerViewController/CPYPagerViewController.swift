//
//  CPYPagerViewController.swift
//  CPYPagerViewController
//
//  Created by ciel on 16/3/23.
//  Copyright © 2016年 CPY. All rights reserved.
//

import UIKit

protocol CPYPagerViewControllerDatasource: NSObjectProtocol {
    func viewControllersOfPager(_ pagerViewController: CPYPagerViewController) -> [UIViewController]
    func titlesOfPager(_ pageViewController: CPYPagerViewController) -> [String]
//    func selectedViewController(pagerViewController:CPYPagerViewController, index: Int)
}

protocol CPYTabViewDelegate: NSObjectProtocol {
    func titlesOfTab(_ tabView: CPYTabView) -> [String]
    func selectedButton(_ tabView: CPYTabView, index:Int)
}


class CPYPagerViewController: UIViewController, CPYTabViewDelegate, UIScrollViewDelegate {
    
    fileprivate enum ScrollDirection {
        case left
        case right
    }
    
    weak var dataSource: CPYPagerViewControllerDatasource?
    
    fileprivate var viewControllers = [UIViewController]()
    
    fileprivate var titles = [String]()
    
    fileprivate var scrollView: UIScrollView!
    
    fileprivate var currentIndex = 0
    
    fileprivate var startOffsetX:CGFloat = 0
    
    fileprivate var scrollDirection = ScrollDirection.right
    
    
    fileprivate var lastContentOffsetX:CGFloat = 0
    fileprivate var scrollDirectionFound = false
    
    lazy var tabView: CPYTabView = {
        let tabView = CPYTabView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 40))
        tabView.delegate = self
        return tabView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.redColor()

        // Do any additional setup after loading the view.
        
        //must be called first!
        setupData()
        
        setupUI()
    }
    
    fileprivate func setupUI() -> Void {
        setupTabView()
        setupScrollView()
        setupViewControllers()
    }
    
    //public
    
    //delegate
    
    func titlesOfTab(_ tabView: CPYTabView) -> [String] {
        return titles
    }
    
    func selectedButton(_ tabView: CPYTabView, index: Int) {
        tabView.nextSelectIndex = index
        scrollViewToIndex(index)
    }
    
    fileprivate func getScrollViewDirection(_ scrollView: UIScrollView) -> ScrollDirection {
        var direction: ScrollDirection = .right
        if scrollView.contentOffset.x > lastContentOffsetX {
            print("right")
            direction = .right
        }
        else if scrollView.contentOffset.x < lastContentOffsetX {
            print("left")
            direction = .left
        }
        lastContentOffsetX = scrollView.contentOffset.x
        return direction
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x - startOffsetX
        let changeRate = offset / view.bounds.width
        
        let direction = getScrollViewDirection(scrollView)
        
        if scrollDirection != direction {
            scrollDirectionFound = false
        }
        
        if scrollDirectionFound == false {
            scrollDirection = direction
            scrollDirectionFound = true
            let directionLeft = direction == .left
            tabView.changeNextSelectIndex(directionLeft)
        }
        
        tabView.changeState(changeRate)

        if abs(changeRate) > 0.5 {
            print("seleted")
            tabView.selectButton(tabView.nextSelectIndex)
        }
        else {
            tabView.selectButton(tabView.currentIndex)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("scrollView will begin decelerating")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewEndScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            scrollViewEndScrolling()
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewEndScrolling()
    }
    
    
    //mark private
    fileprivate func scrollViewToIndex(_ index: Int) -> Void {
        if index == currentIndex {
            return
        }
        let x = CGFloat(index) * view.bounds.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        
        currentIndex = index
    }
    
    fileprivate func setupData() -> Void {
        guard let dataSource = dataSource else {
            fatalError("datasource cann't be nil")
        }
        
        if viewControllers.count != titles.count {
            fatalError("viewControllers count must equal to titles count")
        }
        
        viewControllers = dataSource.viewControllersOfPager(self)
        titles = dataSource.titlesOfPager(self)
    }
    
    fileprivate func setupTabView() -> Void {
        view.addSubview(tabView)
        tabView.setupViews()
    }
    
    fileprivate func setupScrollView() -> Void {
        let y = tabView.frame.maxY
        scrollView = UIScrollView(frame: CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y))
        scrollView.contentSize = CGSize(width: view.bounds.width * CGFloat(viewControllers.count), height: scrollView.frame.height)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    fileprivate func setupViewControllers() -> Void {
        for i in 0..<viewControllers.count {
            let viewController = viewControllers[i]
            addChildViewController(viewController)
            
            let x = CGFloat(i) * view.bounds.width
            var frame = scrollView.bounds
            frame.origin.x = x
            viewController.view.frame = frame
            scrollView.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate func scrollViewEndScrolling() -> Void {
        let page = scrollView.contentOffset.x / view.bounds.width
        
        tabView.startIndex = Int(page)
        
        tabView.selectButton(Int(page))
        
        currentIndex = Int(page)
        
        startOffsetX = scrollView.contentOffset.x
        
        scrollDirectionFound = false
        
        tabView.scrollToCenter()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class CPYTabView: UIView {
    weak var delegate: CPYTabViewDelegate?
    var buttonWidth:CGFloat = 80
    var lineHeight:CGFloat = 3
    var startIndex = 0
    var nextSelectIndex = 0 {
        didSet {
            if nextSelectIndex < 0 {
                nextSelectIndex = 0
            }
            let max = titles.count - 1
            if nextSelectIndex >= max {
                nextSelectIndex = max
            }
            print("next \(nextSelectIndex)")
        }
    }
    
    fileprivate var titles = [String]()
    fileprivate var scrollView: UIScrollView!
    fileprivate var buttons = [CPYButton]()
    fileprivate var currentIndex = 0
    fileprivate var lineView:UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func setupViews() -> Void {
        guard let delegate = delegate else {
            fatalError("delegate conn't be nil")
        }
        titles = delegate.titlesOfTab(self)
        
        setupScrollView()
        setupTabButtons()
        selectButton(currentIndex)
        
        let button = getCurrentSelectedButton()
        button.changeSelectedState(1)
        
        let color = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        drawBottomLine(color)
        
        setupSelectedLine()
    }
    
    func scrollToCenter() -> Void {
        let button = buttons[currentIndex]
        
        let x = button.frame.midX
        
        let centerX = scrollView.bounds.width / 2.0
        
        if x > centerX {
            if x > scrollView.contentSize.width - centerX {
                let maxOffset = scrollView.contentSize.width - scrollView.bounds.width
                scrollView.setContentOffset(CGPoint(x: maxOffset, y: 0), animated: true)
                return
            }
            scrollView.setContentOffset(CGPoint(x: x - centerX, y: 0), animated: true)
        }
        else {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        
    }
    
    func tabClicked(_ sender: CPYButton) -> Void {
        let index = buttons.index(of: sender)
        delegate?.selectedButton(self, index: index!)
    }
    
    func selectButton(_ index: Int) -> Void {
        let currentSelectedButton = buttons[currentIndex]
        currentSelectedButton.isSelected = false
        
        let button = buttons[index]
        button.isSelected = true
        changeCurrentIndex(index)
    }
    
    func changeNextSelectIndex(_ directionLeft: Bool) -> Void {
        if directionLeft == true {
            nextSelectIndex = currentIndex - 1
        }
        else {
            nextSelectIndex = currentIndex + 1
        }
    }
    
    func changeState(_ changeRate:CGFloat) -> Void {
        moveLineView(changeRate)
        changeTabState(changeRate)
    }
    
    fileprivate func changeCurrentIndex(_ index: Int) -> Void {
        currentIndex = index
    }
    
    fileprivate func moveLineView(_ changeRate: CGFloat) -> Void {
        let xOffset = buttonWidth * changeRate
        
        var frame = lineView.frame
        frame.origin.x = buttonWidth * CGFloat(startIndex) + xOffset
        lineView.frame = frame
    }
    
    fileprivate func changeTabState(_ changeRate: CGFloat) -> Void {
        //no matter right or left, we only care about the next selected button
        let rate = abs(changeRate)
        
        let currentSelectedButton = getCurrentSelectedButton()
        currentSelectedButton.changeSelectedState(1 - rate)
        
        let button = getNextSelectButton()
        button.changeSelectedState(rate)
    }
    
    fileprivate func getCurrentSelectedButton() -> CPYButton {
        return buttons[currentIndex]
    }
    
    fileprivate func getNextSelectButton() -> CPYButton {
        return buttons[nextSelectIndex]
    }
    
    fileprivate func setupSelectedLine() -> Void {
        lineView = UIView(frame: CGRect(x: 0, y: bounds.height - lineHeight, width: buttonWidth, height: lineHeight))
        lineView.backgroundColor = UIColor.red
        scrollView.addSubview(lineView)
    }
    
    fileprivate func setupTabButtons() -> Void {
        for i in 0..<titles.count {
            let button = CPYButton(type: .custom)
            
            let x = CGFloat(i) * buttonWidth
            
            button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: bounds.height)
            button.setTitleColor(UIColor.black, for: UIControlState())
            button.setTitleColor(UIColor.red, for: .selected)
            button.setTitle(titles[i], for: UIControlState())
            button.addTarget(self, action: #selector(CPYTabView.tabClicked(_:)), for: .touchUpInside)
            
            scrollView.addSubview(button)
            buttons.append(button)
        }
    }
    
    fileprivate func setupScrollView() -> Void {
        scrollView = UIScrollView(frame: bounds)
        scrollView.contentSize = CGSize(width: buttonWidth * CGFloat(titles.count), height: bounds.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
        addSubview(scrollView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CPYButton: UIButton {
    fileprivate let maxScaleRate:CGFloat = 1.08
    
    func changeSelectedState(_ changeRate: CGFloat) -> Void {
        let rate = 1 + changeRate * (maxScaleRate - 1)
        changeScaleWithRate(rate)
    }
    
    fileprivate func changeScaleWithRate(_ scaleRate: CGFloat) -> Void {
        print("scale \(scaleRate)")
        transform = CGAffineTransform(scaleX: scaleRate, y: scaleRate)
    }
}

extension UIView {
    func drawBottomLine(_ color: UIColor) -> Void {
        let layer = CALayer()
        var frame = self.frame
        frame.size.height = 1
        frame.origin.y = bounds.height - 1
        layer.frame = frame
        layer.backgroundColor = color.cgColor
        self.layer.addSublayer(layer)
    }
}
