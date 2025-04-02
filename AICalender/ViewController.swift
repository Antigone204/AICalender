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
            calendarView.heightAnchor.constraint(equalTo: calendarView.widthAnchor, multiplier: 1.2)
        ])
    }

       // 实现代理方法
    func calendarView1(_ calendarView: CalendarView, didSelectDate date: Date) {
        // 获取当天的日程安排
        let schedules = calendarView1(calendarView, schedulesForDate: date)
        
        // 创建并展示日程视图控制器
        let scheduleVC = ScheduleViewController(date: date, schedules: schedules)
        let nav = UINavigationController(rootViewController: scheduleVC)
        present(nav, animated: true)
    }
    
    // 示例：返回测试数据
    func calendarView1(_ calendarView: CalendarView, schedulesForDate date: Date) -> [Schedule] {
        let calendar = Calendar.current
        var schedules: [Schedule] = []
        
        // 创建当天 9:00 的会议
        if let meetingStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date),
           let meetingEndTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) {
            schedules.append(Schedule(
                startTime: meetingStartTime,
                endTime: meetingEndTime,
                title: "晨会"
            ))
        }
        
        // 创建当天 14:30 的任务
        if let taskStartTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date),
           let taskEndTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) {
            schedules.append(Schedule(
                startTime: taskStartTime,
                endTime: taskEndTime,
                title: "项目评审"
            ))
        }
        
        return schedules
    }
}
