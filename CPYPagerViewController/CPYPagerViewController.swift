//
//  CPYPagerViewController.swift
//  CPYPagerViewController
//
//  Created by ciel on 16/3/23.
//  Copyright © 2016年 CPY. All rights reserved.
//

import UIKit

protocol CPYPagerViewControllerDatasource: NSObjectProtocol {
    func viewControllersOfPager(pagerViewController: CPYPagerViewController) -> [UIViewController]
    func titlesOfPager(pageViewController: CPYPagerViewController) -> [String]
//    func selectedViewController(pagerViewController:CPYPagerViewController, index: Int)
}

protocol CPYTabViewDelegate: NSObjectProtocol {
    func titlesOfTab(tabView: CPYTabView) -> [String]
    func selectedButton(tabView: CPYTabView, index:Int)
}


class CPYPagerViewController: UIViewController, CPYTabViewDelegate, UIScrollViewDelegate {
    
    private enum ScrollDirection {
        case Left
        case Right
    }
    
    weak var dataSource: CPYPagerViewControllerDatasource?
    
    private var viewControllers = [UIViewController]()
    
    private var titles = [String]()
    
    private var scrollView: UIScrollView!
    
    private var currentIndex = 0
    
    private var startOffsetX:CGFloat = 0
    
    private var scrollDirection = ScrollDirection.Right
    
    
    private var lastContentOffsetX:CGFloat = 0
    private var scrollDirectionFound = false
    
    lazy var tabView: CPYTabView = {
        let tabView = CPYTabView(frame: CGRectMake(0, 0, self.view.bounds.size.width, 40))
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
    
    private func setupUI() -> Void {
        setupTabView()
        setupScrollView()
        setupViewControllers()
    }
    
    //public
    
    //delegate
    
    func titlesOfTab(tabView: CPYTabView) -> [String] {
        return titles
    }
    
    func selectedButton(tabView: CPYTabView, index: Int) {
        tabView.nextSelectIndex = index
        scrollViewToIndex(index)
    }
    
    private func getScrollViewDirection(scrollView: UIScrollView) -> ScrollDirection {
        var direction: ScrollDirection = .Right
        if scrollView.contentOffset.x > lastContentOffsetX {
            print("right")
            direction = .Right
        }
        else if scrollView.contentOffset.x < lastContentOffsetX {
            print("left")
            direction = .Left
        }
        lastContentOffsetX = scrollView.contentOffset.x
        return direction
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x - startOffsetX
        let changeRate = offset / CGRectGetWidth(view.bounds)
        
        let direction = getScrollViewDirection(scrollView)
        
        if scrollDirection != direction {
            scrollDirectionFound = false
        }
        
        if scrollDirectionFound == false {
            scrollDirection = direction
            scrollDirectionFound = true
            let directionLeft = direction == .Left
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        print("scrollView will begin decelerating")
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollViewEndScrolling()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            scrollViewEndScrolling()
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollViewEndScrolling()
    }
    
    
    //mark private
    private func scrollViewToIndex(index: Int) -> Void {
        if index == currentIndex {
            return
        }
        let x = CGFloat(index) * CGRectGetWidth(view.bounds)
        scrollView.setContentOffset(CGPointMake(x, 0), animated: true)
        
        currentIndex = index
    }
    
    private func setupData() -> Void {
        guard let dataSource = dataSource else {
            fatalError("datasource cann't be nil")
        }
        
        if viewControllers.count != titles.count {
            fatalError("viewControllers count must equal to titles count")
        }
        
        viewControllers = dataSource.viewControllersOfPager(self)
        titles = dataSource.titlesOfPager(self)
    }
    
    private func setupTabView() -> Void {
        view.addSubview(tabView)
        tabView.setupViews()
    }
    
    private func setupScrollView() -> Void {
        let y = CGRectGetMaxY(tabView.frame)
        scrollView = UIScrollView(frame: CGRectMake(0, y, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds) - y))
        scrollView.contentSize = CGSizeMake(CGRectGetWidth(view.bounds) * CGFloat(viewControllers.count), CGRectGetHeight(scrollView.frame))
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.userInteractionEnabled = true
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    private func setupViewControllers() -> Void {
        for i in 0..<viewControllers.count {
            let viewController = viewControllers[i]
            addChildViewController(viewController)
            
            let x = CGFloat(i) * CGRectGetWidth(view.bounds)
            var frame = scrollView.bounds
            frame.origin.x = x
            viewController.view.frame = frame
            scrollView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
        }
    }
    
    private func scrollViewEndScrolling() -> Void {
        let page = scrollView.contentOffset.x / CGRectGetWidth(view.bounds)
        
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
    
    private var titles = [String]()
    private var scrollView: UIScrollView!
    private var buttons = [CPYButton]()
    private var currentIndex = 0
    private var lineView:UIView!
    
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
        
        let x = CGRectGetMidX(button.frame)
        
        let centerX = CGRectGetWidth(scrollView.bounds) / 2.0
        
        if x > centerX {
            if x > scrollView.contentSize.width - centerX {
                let maxOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.bounds)
                scrollView.setContentOffset(CGPointMake(maxOffset, 0), animated: true)
                return
            }
            scrollView.setContentOffset(CGPointMake(x - centerX, 0), animated: true)
        }
        else {
            scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
        }
        
    }
    
    func tabClicked(sender: CPYButton) -> Void {
        let index = buttons.indexOf(sender)
        delegate?.selectedButton(self, index: index!)
    }
    
    func selectButton(index: Int) -> Void {
        let currentSelectedButton = buttons[currentIndex]
        currentSelectedButton.selected = false
        
        let button = buttons[index]
        button.selected = true
        changeCurrentIndex(index)
    }
    
    func changeNextSelectIndex(directionLeft: Bool) -> Void {
        if directionLeft == true {
            nextSelectIndex = currentIndex - 1
        }
        else {
            nextSelectIndex = currentIndex + 1
        }
    }
    
    func changeState(changeRate:CGFloat) -> Void {
        moveLineView(changeRate)
        changeTabState(changeRate)
    }
    
    private func changeCurrentIndex(index: Int) -> Void {
        currentIndex = index
    }
    
    private func moveLineView(changeRate: CGFloat) -> Void {
        let xOffset = buttonWidth * changeRate
        
        var frame = lineView.frame
        frame.origin.x = buttonWidth * CGFloat(startIndex) + xOffset
        lineView.frame = frame
    }
    
    private func changeTabState(changeRate: CGFloat) -> Void {
        //no matter right or left, we only care about the next selected button
        let rate = abs(changeRate)
        
        let currentSelectedButton = getCurrentSelectedButton()
        currentSelectedButton.changeSelectedState(1 - rate)
        
        let button = getNextSelectButton()
        button.changeSelectedState(rate)
    }
    
    private func getCurrentSelectedButton() -> CPYButton {
        return buttons[currentIndex]
    }
    
    private func getNextSelectButton() -> CPYButton {
        return buttons[nextSelectIndex]
    }
    
    private func setupSelectedLine() -> Void {
        lineView = UIView(frame: CGRectMake(0, CGRectGetHeight(bounds) - lineHeight, buttonWidth, lineHeight))
        lineView.backgroundColor = UIColor.redColor()
        scrollView.addSubview(lineView)
    }
    
    private func setupTabButtons() -> Void {
        for i in 0..<titles.count {
            let button = CPYButton(type: .Custom)
            
            let x = CGFloat(i) * buttonWidth
            
            button.frame = CGRectMake(x, 0, buttonWidth, CGRectGetHeight(bounds))
            button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            button.setTitleColor(UIColor.redColor(), forState: .Selected)
            button.setTitle(titles[i], forState: .Normal)
            button.addTarget(self, action: #selector(CPYTabView.tabClicked(_:)), forControlEvents: .TouchUpInside)
            
            scrollView.addSubview(button)
            buttons.append(button)
        }
    }
    
    private func setupScrollView() -> Void {
        scrollView = UIScrollView(frame: bounds)
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(titles.count), CGRectGetHeight(bounds))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.userInteractionEnabled = true
        addSubview(scrollView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CPYButton: UIButton {
    private let maxScaleRate:CGFloat = 1.08
    
    func changeSelectedState(changeRate: CGFloat) -> Void {
        let rate = 1 + changeRate * (maxScaleRate - 1)
        changeScaleWithRate(rate)
    }
    
    private func changeScaleWithRate(scaleRate: CGFloat) -> Void {
        print("scale \(scaleRate)")
        transform = CGAffineTransformMakeScale(scaleRate, scaleRate)
    }
}

extension UIView {
    func drawBottomLine(color: UIColor) -> Void {
        let layer = CALayer()
        var frame = self.frame
        frame.size.height = 1
        frame.origin.y = CGRectGetHeight(bounds) - 1
        layer.frame = frame
        layer.backgroundColor = color.CGColor
        self.layer.addSublayer(layer)
    }
}