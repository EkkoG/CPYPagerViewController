//
//  ViewController.swift
//  CPYPagerViewController
//
//  Created by ciel on 16/3/23.
//  Copyright © 2016年 CPY. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CPYPagerViewControllerDatasource {
    fileprivate let titles = ["做", "个", "好", "人", "记", "得", "要", "卡"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let pager = CPYPagerViewController()
        pager.dataSource = self
        self.view.addSubview(pager.view)
        self.addChildViewController(pager)
    }
    
    func viewControllersOfPager(_ pagerViewController: CPYPagerViewController) -> [UIViewController] {
        var viewControllers = [UIViewController]()
        for i in 0..<titles.count {
            let vc = UIViewController()
            let red = CGFloat(i) * 30
            let color = UIColor(red: red / 255.0, green: (255.0 - red) / 255.0, blue: 255 / 255.0, alpha: 1.0)
            vc.view.backgroundColor = color
            viewControllers.append(vc)
        }
        return viewControllers
    }
    
    func titlesOfPager(_ pageViewController: CPYPagerViewController) -> [String] {
        return titles
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

