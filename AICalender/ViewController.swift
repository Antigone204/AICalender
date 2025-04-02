//
//  ViewController.swift
//  AICalender
//
//  Created by 贝贝 on 2025/4/2.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var calendarView: CalendarView = {
        let view = CalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalTo: calendarView.widthAnchor, multiplier: 1.2)
        ])
    }
}

