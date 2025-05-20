import UIKit

class ScheduleViewController: UIViewController {
    private let date: Date
    private var schedules: [Schedule] = []
    private var selectedDate: Date
    private var days: [Date] = []
    private let calendar = Calendar.current
    
    // MARK: - UI Components
    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加周一到周日的标签
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        weekdays.forEach { day in
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14)
            stack.addArrangedSubview(label)
        }
        return stack
    }()
    
    private lazy var calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(CalendarDayCell.self, forCellWithReuseIdentifier: "CalendarDayCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private lazy var scheduleTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: - Initialization
    init(date: Date, schedules: [Schedule]) {
        self.date = date
        self.selectedDate = date
        self.schedules = schedules.sorted { $0.startTime < $1.startTime }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        generateDaysForCurrentMonth()
        updateMonthLabel()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(monthLabel)
        view.addSubview(weekdayStackView)
        view.addSubview(calendarCollectionView)
        view.addSubview(scheduleTableView)
        
        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            monthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            monthLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            weekdayStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 16),
            weekdayStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weekdayStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            weekdayStackView.heightAnchor.constraint(equalToConstant: 30),
            
            calendarCollectionView.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor),
            calendarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarCollectionView.heightAnchor.constraint(equalToConstant: 300),
            
            scheduleTableView.topAnchor.constraint(equalTo: calendarCollectionView.bottomAnchor),
            scheduleTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scheduleTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scheduleTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addScheduleTapped))
        let previousMonth = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(previousMonthTapped))
        let nextMonth = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(nextMonthTapped))
        
        // 添加返回按钮
        let backButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissView))
        
        // 左侧：返回 + 上个月
        navigationItem.leftBarButtonItems = [backButton, previousMonth]
        // 右侧：新增 + 下个月
        navigationItem.rightBarButtonItems = [addButton, nextMonth]
    }
    
    // MARK: - Calendar Logic
    private func generateDaysForCurrentMonth() {
        days.removeAll()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        // 获取月初是周几（1是周日，2是周一，以此类推）
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // 添加上个月的日期
        if firstWeekday > 1 {
            // 获取上个月的最后一天
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth)!
            let previousMonthLastDay = previousMonthRange.count
            
            // 计算需要显示多少天
            let daysToAdd = firstWeekday - 1
            
            // 添加上个月的日期
            for day in (previousMonthLastDay - daysToAdd + 1)...previousMonthLastDay {
                if let date = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth)).flatMap({ calendar.date(byAdding: .day, value: day - 1, to: $0) }) {
                    days.append(date)
                }
            }
        }
        
        // 添加当月日期
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // 添加下个月的日期以填满最后一周
        let totalDays = days.count
        let remainingDays = 42 - totalDays // 6周 × 7天 = 42
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            for day in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    days.append(date)
                }
            }
        }
        
        calendarCollectionView.reloadData()
    }
    
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        monthLabel.text = formatter.string(from: selectedDate)
    }
    
    // MARK: - Actions
    @objc private func previousMonthTapped() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
        generateDaysForCurrentMonth()
        updateMonthLabel()
    }
    
    @objc private func nextMonthTapped() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
        generateDaysForCurrentMonth()
        updateMonthLabel()
    }
    
    @objc private func addScheduleTapped() {
        let addScheduleVC = AddScheduleViewController(date: selectedDate)
        addScheduleVC.delegate = self
        let nav = UINavigationController(rootViewController: addScheduleVC)
        present(nav, animated: true)
    }
    
    // 添加关闭方法
    @objc private func dismissView() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Collection View
extension ScheduleViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell
        let date = days[indexPath.item]
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        cell.configure(with: date, isCurrentMonth: isCurrentMonth, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDate = days[indexPath.item]
        collectionView.reloadData()
        
        // 更新日程列表
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        schedules = ScheduleManager.shared.fetchSchedules(for: startOfDay, to: endOfDay)
        scheduleTableView.reloadData()
    }
}

// MARK: - Day Cell
class CalendarDayCell: UICollectionViewCell {
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(dayLabel)
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with date: Date, isCurrentMonth: Bool, isSelected: Bool) {
        let day = Calendar.current.component(.day, from: date)
        dayLabel.text = "\(day)"
        
        if isSelected {
            contentView.backgroundColor = .systemBlue
            dayLabel.textColor = .white
        } else {
            contentView.backgroundColor = .clear
            dayLabel.textColor = isCurrentMonth ? .label : .tertiaryLabel
        }
    }
}

extension ScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.isEmpty ? days.count : schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if schedules.isEmpty {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let date = days[indexPath.row]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            cell.textLabel?.text = dateFormatter.string(from: date)
            cell.detailTextLabel?.text = "空闲"
            cell.detailTextLabel?.textColor = .systemGreen
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as! ScheduleCell
        let schedule = schedules[indexPath.row]
        cell.configure(with: schedule)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return schedules.isEmpty ? "全天空闲时间" : "日程安排"
    }
}

extension ScheduleViewController: AddScheduleViewControllerDelegate {
    func addScheduleViewController(_ controller: AddScheduleViewController, didAddSchedule schedule: Schedule) {
        ScheduleManager.shared.saveSchedule(schedule)
        schedules.append(schedule)
        schedules.sort { $0.startTime < $1.startTime }
        scheduleTableView.reloadData()
    }
}

class ScheduleCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            durationLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
            durationLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with schedule: Schedule) {
        titleLabel.text = schedule.title
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeText = "\(timeFormatter.string(from: schedule.startTime)) - \(timeFormatter.string(from: schedule.endTime))"
        timeLabel.text = timeText
        
        durationLabel.text = schedule.durationText
    }
} 