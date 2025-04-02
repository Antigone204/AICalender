import UIKit

class ScheduleViewController: UIViewController {
    private let date: Date
    private var schedules: [Schedule] = []
    
    private var timeSlots: [(time: Date, isOccupied: Bool, schedule: Schedule?)] = []
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    init(date: Date, schedules: [Schedule]) {
        self.date = date
        self.schedules = schedules.sorted { $0.startTime < $1.startTime }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimeSlots()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 设置导航栏标题
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        title = dateFormatter.string(from: date)
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTimeSlots() {
        // 创建当天的时间槽（每30分钟一个）
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        for hour in 0..<24 {
            for minute in stride(from: 0, to: 60, by: 30) {
                if let slotTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    // 检查这个时间槽是否被占用
                    let occupyingSchedule = schedules.first { schedule in
                        slotTime >= schedule.startTime && slotTime < schedule.endTime
                    }
                    timeSlots.append((slotTime, occupyingSchedule != nil, occupyingSchedule))
                }
            }
        }
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addScheduleTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func addScheduleTapped() {
        // 这里添加新建日程的逻辑
        // 可以弹出一个表单让用户输入日程详情
    }
}

extension ScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.isEmpty ? timeSlots.count : schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if schedules.isEmpty {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let timeSlot = timeSlots[indexPath.row]
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            cell.textLabel?.text = timeFormatter.string(from: timeSlot.time)
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