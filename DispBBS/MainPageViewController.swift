//
//  MainPageViewController.swift
//  DispBBS
//
//  Created by knuckles on 2017/4/10.
//  Copyright © 2017年 Disp. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var mainViewController: MainViewController!
    
    lazy var hotTextViewController: HotTextViewController = {
        self.storyboard!.instantiateViewController(withIdentifier: "HotText") as! HotTextViewController
    }()
    lazy var boardListViewController: BoardListViewController = {
        self.storyboard!.instantiateViewController(withIdentifier: "BoardList") as! BoardListViewController
    }()
    lazy var orderedViewControllers: [UIViewController] = {
        [self.hotTextViewController,
         self.boardListViewController]
    }()

    var willTransitionTo: UIViewController!
    var selectedViewControllerIndex: Int!

    func showPage(byIndex index: Int) {
        guard index >= 0 && index < self.orderedViewControllers.count else { return }
        if index == self.selectedViewControllerIndex { return }
        
        var direction: UIPageViewControllerNavigationDirection!
        if index > self.selectedViewControllerIndex {
            direction = .forward
        }else if index < self.selectedViewControllerIndex {
            direction = .reverse
        }
        let viewController = orderedViewControllers[index]
        setViewControllers([viewController], direction: direction, animated: true, completion: nil)
        selectedViewControllerIndex = index
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        self.selectedViewControllerIndex = 0

        setViewControllers([hotTextViewController], direction: .forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = index - 1
        guard previousIndex >= 0 && previousIndex < orderedViewControllers.count else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let nextIndex = index + 1
        guard nextIndex >= 0 && nextIndex < orderedViewControllers.count else {
            return nil
        }
        return orderedViewControllers[nextIndex]
    }
    
    // MARK: - UIPageViewControllerDeleage
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        self.willTransitionTo = pendingViewControllers.first
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let index = orderedViewControllers.index(of: self.willTransitionTo) {
                mainViewController.changeTab(byIndex: index)
                self.selectedViewControllerIndex = index
            }
        }
    }
    
    


}
