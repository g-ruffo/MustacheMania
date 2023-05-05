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
    private var recordVideoTabView: UIView!
    private var videoListTabView: UIView!

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
        videoListNav.tabBarItem = UITabBarItem(title: "Videos", image: UIImage(systemName: "list.bullet.rectangle"), selectedImage: UIImage(systemName: "list.bullet.rectangle.fill")?.withTintColor(.red))
        recordVideoNav.tabBarItem = UITabBarItem(title: "Record", image: UIImage(systemName: "video"), selectedImage: UIImage(systemName: "video.fill"))

        // Assign ViewControllers to TabBarController.
        let viewControllers = [videoListNav, recordVideoNav]
        self.setViewControllers(viewControllers, animated: false)
        
        // Assign tab bar items to ui view variables.
        videoListTabView = tabBar.subviews[0]
        recordVideoTabView = tabBar.subviews[1]
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.frame.size.height = tabBarHeight
        tabBar.frame.origin.y = view.frame.height - tabBarHeight
        // Set corner radius of tab bar.
        tabBar.layer.cornerRadius = tabBarCornerRadius
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    }
    
    private func animate(_ imageView: UIView) {
          UIView.animate(withDuration: 0.1, animations: {
              imageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
          }) { _ in
              UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3.0, options: .curveEaseInOut, animations: {
                  imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
              }, completion: nil)
          }
      }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Set the tab bar item color.
        if viewController.restorationIdentifier == K.Navigation.recordVideoNav {
            self.tabBar.tintColor = .red
            animate(recordVideoTabView)
        } else {
            self.tabBar.tintColor = .systemBlue
            animate(videoListTabView)
        }
    }
}
