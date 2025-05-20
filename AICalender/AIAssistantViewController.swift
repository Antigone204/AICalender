import UIKit

enum MessageSender {
    case user
    case ai
}

struct ChatMessage {
    let sender: MessageSender
    var content: String
}

class ChatBubbleCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.masksToBounds = true
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        // 约束
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
        let isUser = message.sender == .user
        bubbleView.backgroundColor = isUser ? UIColor.systemBlue : UIColor.systemGray5
        messageLabel.textColor = isUser ? .white : .label

        // 动态调整气泡位置
        leadingConstraint.isActive = !isUser
        trailingConstraint.isActive = isUser
    }
}

class AIAssistantViewController: UIViewController {
    private let aiService = LocalAIService()
    private var messages: [ChatMessage] = []
    
    private lazy var chatTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        table.separatorStyle = .none
        table.allowsSelection = false
        table.dataSource = self
        table.keyboardDismissMode = .onDrag
        return table
    }()
    
    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 16)
        textView.delegate = self
        textView.isScrollEnabled = false
        return textView
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("发送", for: .normal)
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(chatTableView)
        view.addSubview(inputTextView)
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            chatTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -8),
            
            inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            sendButton.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text, !text.isEmpty else { return }
        inputTextView.text = ""
        // 添加用户消息
        messages.append(ChatMessage(sender: .user, content: text))
        // 添加AI消息占位
        messages.append(ChatMessage(sender: .ai, content: ""))
        chatTableView.reloadData()
        scrollToBottom()
        
        let aiIndex = messages.count - 1
        
        aiService.sendMessageStream(
            prompt: text,
            onReceive: { [weak self] partial in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.messages[aiIndex].content += partial
                    self.chatTableView.reloadData()
                    self.scrollToBottom()
                }
            },
            onThinking: { _ in },
            onLoading: { _ in },
            onComplete: { [weak self] response, error in
                // 可选：处理最终回复
            }
        )
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

extension AIAssistantViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatBubbleCell", for: indexPath) as! ChatBubbleCell
        cell.configure(with: message)
        return cell
    }
}

extension AIAssistantViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendMessage()
            return false
        }
        return true
    }
} 
