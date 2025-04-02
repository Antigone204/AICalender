import UIKit

class ScheduleViewController: UIViewController {
    private let date: Date
    private var schedules: [Schedule] = []
    
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
        self.schedules = schedules.sorted { $0.time < $1.time }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
}

extension ScheduleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.isEmpty ? 1 : schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if schedules.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "暂无日程安排"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .secondaryLabel
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as! ScheduleCell
        let schedule = schedules[indexPath.row]
        cell.configure(with: schedule)
        return cell
    }
}

class ScheduleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with schedule: Schedule) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        textLabel?.text = schedule.title
        detailTextLabel?.text = timeFormatter.string(from: schedule.time)
    }
} 