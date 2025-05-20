import UIKit

private let aiService = LocalAIService()

struct Schedule {
    let startTime: Date
    let endTime: Date
    let title: String
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    // 格式化的持续时间
    var durationText: String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        } else {
            return "\(remainingMinutes)分钟"
        }
    }
}

protocol CalendarViewDelegate: AnyObject {
    func openCalendarDetail()
    func openAIAssistant()
    func calendarView1(_ calendarView: CalendarView, didSelectDate date: Date)
    func calendarView1(_ calendarView: CalendarView, schedulesForDate date: Date) -> [Schedule]
}

// 设置可选方法
extension CalendarViewDelegate {
    func calendarView1(_ calendarView: CalendarView, schedulesForDate date: Date) -> [Schedule] {
        return []
    }
}

class CalendarView: UIView {
    weak var delegate: CalendarViewDelegate?
    
    private let calendar = Calendar.current
    private var currentDate = Date()
    private var days: [Date] = []
    private var isAnimating = false
    
    // 添加日程数据源
    private var schedules: [Schedule] = []
    
    // 标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "代办事项"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 待办事项表格
    private lazy var todoTableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.register(TodoCell.self, forCellReuseIdentifier: "TodoCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemBackground
        table.separatorStyle = .none
        table.rowHeight = 80
        return table
    }()
    
    // 底部按钮
    private lazy var todoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("待办事项", for: .normal)
        btn.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(todoButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        return btn
    }()
    
    private lazy var aiButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("AI助手", for: .normal)
        btn.setImage(UIImage(systemName: "message.circle"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(aiButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        return btn
    }()
    
    private lazy var calendarButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("日历", for: .normal)
        btn.setImage(UIImage(systemName: "calendar"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        return btn
    }()
    
    private lazy var bottomButtonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [todoButton, aiButton, calendarButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNewUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNewUI()
    }
    
    private func setupNewUI() {
        backgroundColor = .systemBackground
        addSubview(titleLabel)
        addSubview(todoTableView)
        addSubview(bottomButtonStack)
        setupNewConstraints()
        loadTodaySchedules()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshSchedules), for: .valueChanged)
        todoTableView.refreshControl = refreshControl
    }
    
    private func setupNewConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            todoTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            todoTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            todoTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            todoTableView.bottomAnchor.constraint(equalTo: bottomButtonStack.topAnchor, constant: -16),
            
            bottomButtonStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            bottomButtonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            bottomButtonStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            bottomButtonStack.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    // 添加加载日程的方法
    private func loadTodaySchedules() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        schedules = ScheduleManager.shared.fetchSchedules(for: startOfDay, to: endOfDay)
        todoTableView.reloadData()
    }
    
    // 添加刷新方法
    @objc private func refreshSchedules() {
        loadTodaySchedules()
        todoTableView.refreshControl?.endRefreshing()
    }
    
    @objc private func todoButtonTapped() {
        // 这里可以切换到待办事项页面或弹窗
    }
    
    @objc private func aiButtonTapped() {
        delegate?.openAIAssistant()
    }
    
    @objc private func calendarButtonTapped() {
        delegate?.openCalendarDetail()
    }
    
    deinit {
        // NotificationCenter.default.removeObserver(self)
    }
}

// 新增待办事项单元格
class TodoCell: UITableViewCell {
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
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, time: String) {
        titleLabel.text = title
        timeLabel.text = time
        
        // 添加右箭头指示器
        accessoryType = .disclosureIndicator
    }
}

// 表格代理
extension CalendarView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        let schedule = schedules[indexPath.row]
        
        // 创建日期格式化器
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let timeText = "\(formatter.string(from: schedule.startTime)) - \(formatter.string(from: schedule.endTime))"
        cell.configure(title: schedule.title, time: timeText)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == todoTableView {
            let schedule = schedules[indexPath.row]
            // 通知代理显示日程详情
            delegate?.calendarView1(self, didSelectDate: schedule.startTime)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == todoTableView {
            let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (action, view, completion) in
                guard let self = self else { return }
                
                let schedule = self.schedules[indexPath.row]
                ScheduleManager.shared.deleteSchedule(schedule)
                self.schedules.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                completion(true)
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return nil
    }
}
