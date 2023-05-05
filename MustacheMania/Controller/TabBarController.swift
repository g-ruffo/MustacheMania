//
//  TabBarController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit

class TabBarController: UITabBarController {
    @IBInspectable var tabBarHeight: CGFloat = 0
    @IBInspectable var tabBarCornerRadius: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        delegate = self
        
        setupTabBarItems()
    }

    func setupTabBarItems() {
        // Initiate view controllers
        let videoListNav = self.storyboard?.instantiateViewController(withIdentifier: K.Navigation.videoListNav) as! UINavigationController
        let recordVideoNav = self.storyboard?.instantiateViewController(withIdentifier: K.Navigation.recordVideoNav) as! UINavigationController
        
        // Create tab bar items
        videoListNav.tabBarItem = UITabBarItem(title: "Videos", image: UIImage(systemName: "video"), selectedImage: UIImage(systemName: "video.fill"))
        recordVideoNav.tabBarItem = UITabBarItem(title: "Videos", image: UIImage(systemName: "list.bullet.rectangle"), selectedImage: UIImage(systemName: "list.bullet.rectangle.fill"))
        
        // Assign ViewControllers to TabBarController
        let viewControllers = [videoListNav, recordVideoNav]
        self.setViewControllers(viewControllers, animated: false)

    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.frame.size.height = tabBarHeight
        tabBar.frame.origin.y = view.frame.height - tabBarHeight
        // Set corner radius of tab bar.
        tabBar.layer.cornerRadius = tabBarCornerRadius
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Set the tab bar item color.
        if viewController is RecordVideoViewController {
            self.tabBar.tintColor = .red
        } else {
            self.tabBar.tintColor = .systemBlue
        }
    }
}
