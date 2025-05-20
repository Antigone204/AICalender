//
//  ViewController.swift
//  AICalender
//
//  Created by 贝贝 on 2025/4/2.
//

import UIKit

class ViewController: UIViewController , CalendarViewDelegate {
    
    private lazy var calendarView: CalendarView = {
        let view = CalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        calendarView.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

       // 实现代理方法
    func calendarView1(_ calendarView: CalendarView, didSelectDate date: Date) {
        // 获取当天的日程安排
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let schedules = ScheduleManager.shared.fetchSchedules(for: startOfDay, to: endOfDay)
        
        // 创建并展示日程视图控制器
        let scheduleVC = ScheduleViewController(date: date, schedules: schedules)
        navigationController?.pushViewController(scheduleVC, animated: true)
    }
    
    // 示例：返回测试数据
    func calendarView1(_ calendarView: CalendarView, schedulesForDate date: Date) -> [Schedule] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return ScheduleManager.shared.fetchSchedules(for: startOfDay, to: endOfDay)
    }

    // 添加缺失的代理方法
    func openCalendarDetail() {
        // 获取当前日期的日程安排
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let schedules = ScheduleManager.shared.fetchSchedules(for: startOfDay, to: endOfDay)
        
        // 创建并展示日程视图控制器
        let scheduleVC = ScheduleViewController(date: Date(), schedules: schedules)
        navigationController?.pushViewController(scheduleVC, animated: true)
    }
    
    func openAIAssistant() {
        // 创建一个新的 AI 助手视图控制器
        let aiAssistantVC = AIAssistantViewController()
        aiAssistantVC.title = "AI 助手"
        navigationController?.pushViewController(aiAssistantVC, animated: true)
    }
}
