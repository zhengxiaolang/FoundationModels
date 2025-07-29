//
//  ViewController.swift
//  appleAI
//
//  Created by Brown Zheng on 2025/7/24.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFoundationModelsDemo()
    }

    private func setupFoundationModelsDemo() {
        // 创建 SwiftUI 视图
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // 添加为子视图控制器
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // 设置约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 设置导航栏标题
        title = "Apple Foundation Models Demo"

        // 设置导航栏样式
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.backgroundColor = UIColor.systemBackground
    }
}

