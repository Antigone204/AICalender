import UIKit

protocol AddScheduleViewControllerDelegate: AnyObject {
    func addScheduleViewController(_ controller: AddScheduleViewController, didAddSchedule schedule: Schedule)
}

class AddScheduleViewController: UIViewController {
    weak var delegate: AddScheduleViewControllerDelegate?
    private let date: Date
    
    private lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "日程标题"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var startTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var endTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "开始时间"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "结束时间"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleTextField)
        view.addSubview(startTimeLabel)
        view.addSubview(startTimePicker)
        view.addSubview(endTimeLabel)
        view.addSubview(endTimePicker)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            startTimeLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            startTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            startTimePicker.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 8),
            startTimePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startTimePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            endTimeLabel.topAnchor.constraint(equalTo: startTimePicker.bottomAnchor, constant: 20),
            endTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            endTimePicker.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 8),
            endTimePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endTimePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: endTimePicker.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupNavigationBar() {
        title = "添加日程"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "请输入日程标题")
            return
        }
        
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: calendar.component(.hour, from: startTimePicker.date),
                                    minute: calendar.component(.minute, from: startTimePicker.date),
                                    second: 0,
                                    of: date)!
        
        let endTime = calendar.date(bySettingHour: calendar.component(.hour, from: endTimePicker.date),
                                  minute: calendar.component(.minute, from: endTimePicker.date),
                                  second: 0,
                                  of: date)!
        
        guard endTime > startTime else {
            showAlert(message: "结束时间必须晚于开始时间")
            return
        }
        
        let schedule = Schedule(startTime: startTime, endTime: endTime, title: title)
        delegate?.addScheduleViewController(self, didAddSchedule: schedule)
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
} 