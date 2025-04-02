import UIKit

struct Schedule {
    let time: Date
    let title: String
}

protocol CalendarViewDelegate: AnyObject {
    func calendarView1(_ calendarView: CalendarView, didSelectDate date: Date)
    // 可选：获取某天的日程安排
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
    
    private enum AnimationDirection {
        case up
        case down
    }
    
    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var weekStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var daysCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateCalendar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateCalendar()
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(monthLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(weekStackView)
        addSubview(daysCollectionView)
        
        setupWeekDays()
        setupConstraints()
        setupGestures()
    }
    
    private func setupWeekDays() {
        let weekDays = ["日", "一", "二", "三", "四", "五", "六"]
        for (index, day) in weekDays.enumerated() {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14)
            label.textColor = (index == 0 || index == 6) ? .systemRed : .label
            weekStackView.addArrangedSubview(label)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            monthLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            previousButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            previousButton.widthAnchor.constraint(equalToConstant: 44),
            previousButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            weekStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 16),
            weekStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekStackView.heightAnchor.constraint(equalToConstant: 30),
            
            daysCollectionView.topAnchor.constraint(equalTo: weekStackView.bottomAnchor, constant: 8),
            daysCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            daysCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            daysCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        daysCollectionView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .changed:
            if abs(translation.y) > 50 && !isAnimating {
                isAnimating = true
                if translation.y > 0 {
                    // 向下滑动，显示上个月
                    moveToPreviousMonth()
                } else {
                    // 向上滑动，显示下个月
                    moveToNextMonth()
                }
            }
        case .ended:
            isAnimating = false
        default:
            break
        }
    }
    
    @objc private func previousButtonTapped() {
        moveToPreviousMonth()
    }
    
    @objc private func nextButtonTapped() {
        moveToNextMonth()
    }
    
    private func moveToPreviousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else { return }
        animateMonthChange(to: newDate, direction: .down)
    }
    
    private func moveToNextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { return }
        animateMonthChange(to: newDate, direction: .up)
    }
    
    private func animateMonthChange(to newDate: Date, direction: AnimationDirection) {
        let oldDays = days
        currentDate = newDate
        days = getDaysInMonth()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.monthLabel.alpha = 0
            self.daysCollectionView.alpha = 0
        }) { _ in
            self.updateCalendar()
            self.daysCollectionView.reloadData()
            
            UIView.animate(withDuration: 0.3) {
                self.monthLabel.alpha = 1
                self.daysCollectionView.alpha = 1
            }
        }
    }
    
    private func updateCalendar() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy年MM月"
        monthLabel.text = monthFormatter.string(from: currentDate)
        
        days = getDaysInMonth()
        daysCollectionView.reloadData()
    }
    
    private func getDaysInMonth() -> [Date] {
        let interval = calendar.dateInterval(of: .month, for: currentDate)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - 1
        
        var days: [Date] = []
        
        if offsetDays > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDay)!
            for i in 1...offsetDays {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstDay) {
                    days.insert(date, at: 0)
                }
            }
        }
        
        let currentMonthDays = calendar.range(of: .day, in: .month, for: currentDate)!.count
        for i in 0..<currentMonthDays {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            let nextMonthFirstDay = calendar.date(byAdding: .day, value: currentMonthDays, to: firstDay)!
            for i in 0..<remainingDays {
                if let date = calendar.date(byAdding: .day, value: i, to: nextMonthFirstDay) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
}

extension CalendarView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        let date = days[indexPath.item]
        cell.configure(with: date, isCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDate = days[indexPath.item]
        delegate?.calendarView1(self, didSelectDate: selectedDate)
    }
}

class DayCell: UICollectionViewCell {
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
    
    func configure(with date: Date, isCurrentMonth: Bool) {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayLabel.text = dayFormatter.string(from: date)
        
        let weekday = Calendar.current.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        
        if Calendar.current.isDateInToday(date) {
            dayLabel.textColor = .systemBlue
            dayLabel.font = .systemFont(ofSize: 16, weight: .bold)
        } else if isWeekend {
            dayLabel.textColor = isCurrentMonth ? .systemRed : .systemRed.withAlphaComponent(0.3)
            dayLabel.font = .systemFont(ofSize: 16)
        } else {
            dayLabel.textColor = isCurrentMonth ? .label : .secondaryLabel
            dayLabel.font = .systemFont(ofSize: 16)
        }
    }
}
