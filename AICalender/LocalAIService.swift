import Foundation

class LocalAIService {
    // 修改API地址
    private let appID = "ed1923c113784126ba4fdc592222ea01"
    private let apiURL = "https://dashscope.aliyuncs.com/api/v1/apps/ed1923c113784126ba4fdc592222ea01/completion"
    // 添加认证token
    private let dashscopeAPIKey = "sk-1c76c3265ea64155b6bd72ceb039828f"

    private let modelName = "qwen-max"

    
    // 系统提示词，与原AIService保持一致
    private let systemPrompt = """
     你是一个日程安排助手，根据用户的需求，给出日程安排。   
    你需要以 JSON 格式返回数据，支持以下操作：
    1. 添加日程：创建新的日程
    2. 修改日程：更新现有日程的信息
    3. 删除日程：删除指定的日程
    
    JSON 格式示例：
    1. 添加日程：
    {
        "operation": "add",
        "schedule": {
            "title": "项目评审",
            "startTime": "2024-04-02T14:30:00",
            "endTime": "2024-04-02T16:00:00"
        }
    }
    
    2. 修改日程：
    {
        "operation": "update",
        "oldSchedule": {
            "title": "项目评审",
            "startTime": "2024-04-02T14:30:00",
            "endTime": "2024-04-02T16:00:00"
        },
        "newSchedule": {
            "title": "项目评审会议",
            "startTime": "2024-04-02T15:00:00",
            "endTime": "2024-04-02T16:30:00"
        }
    }
    
    3. 删除日程：
    {
        "operation": "delete",
        "schedule": {
            "title": "项目评审",
            "startTime": "2024-04-02T14:30:00",
            "endTime": "2024-04-02T16:00:00"
        }
    } 
    
    注意事项：
    1. 所有时间都使用 ISO 8601 格式
    2. 标题不能为空
    3. 结束时间必须晚于开始时间
    4. 查询时返回当天所有日程
    5. 修改和删除时需要提供完整的日程信息以准确定位
    6. 日程安排不能与现有日程冲突
    7. 在安排新日程时，请考虑用户已有的日程安排，避免时间冲突
    8. 如果用户没有指定具体时间，请根据已有日程合理安排时间
    9. 如果用户要求的时间段已被占用，请建议其他合适的时间
    
    注意：如果识别到用户增删改日程，则只允许返回json字符串 不需要返回任何其他思考信息。其他问题则保持正常回答
    """
    
    // 存储对话历史
    private var chatHistory: [(role: String, content: String)] = []
    // 最大历史消息数量
    private let maxHistoryMessages = 10
    
    // 定义回调类型
    typealias CompletionHandler = (String?, Error?) -> Void
    typealias StreamHandler = (String) -> Void
    typealias ThinkingHandler = (String) -> Void
    typealias LoadingHandler = (Bool) -> Void
    
    // 初始化方法
    init() {}
    
    // 清除对话历史
    func clearChatHistory() {
        chatHistory.removeAll()
    }
    
    // 添加获取上下文的方法
    private func getContextPrompt() -> String {
        // 获取当前日期前后30天的日程
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let thirtyDaysLater = calendar.date(byAdding: .day, value: 30, to: now)!
        
        let schedules = ScheduleManager.shared.fetchSchedules(for: thirtyDaysAgo, to: thirtyDaysLater)
        
        if schedules.isEmpty {
            return "用户目前没有已安排的日程。"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var context = "用户已有的日程安排：\n"
        for schedule in schedules {
            let startTime = dateFormatter.string(from: schedule.startTime)
            let endTime = dateFormatter.string(from: schedule.endTime)
            context += "- \(schedule.title): \(startTime) 到 \(endTime)\n"
        }
        
        return context
    }
    
    // 发送消息到AI并获取流式回复
    func sendMessageStream(prompt: String,
                          onReceive: @escaping StreamHandler,
                          onThinking: @escaping ThinkingHandler,
                          onLoading: @escaping LoadingHandler,
                          onComplete: @escaping CompletionHandler) {
        print("开始流式请求，提示词: \(prompt)")
        
        // 添加用户消息到历史记录
        addMessageToHistory(role: "user", content: prompt)
        
        // 获取上下文信息
        let context = getContextPrompt()
        
        // 合并上下文和用户需求
        let combinedPrompt = """
        
        \(context)
        
        用户需求：\(prompt)
        """
        
        // 应用的请求体（参照阿里云文档）
        let requestBody: [String: Any] = [
            "input": [
                "prompt": combinedPrompt
            ],
            "parameters": [
                "incremental_output": true
            ],
            "debug": [:]
        ]
        
        // 创建URL（确保apiURL已包含APP_ID）
        guard let url = URL(string: apiURL) else {
            onComplete(nil, NSError(domain: "LocalAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        // 创建请求（保留原有header设置）
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(dashscopeAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("enable", forHTTPHeaderField: "X-DashScope-SSE")
        request.addValue("*/*", forHTTPHeaderField: "Accept")  // 添加Accept header
        request.timeoutInterval = 60  // 增加超时时间到60秒
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            print("发送请求体：\(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        } catch {
            print("请求体序列化失败: \(error)")
            onComplete(nil, error)
            return
        }
        
        // 创建URLSession配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300  // 资源超时时间设置更长
        
        let streamDelegate = StreamDelegate(
            onReceive: onReceive,
            onThinking: onThinking,
            onLoading: onLoading,
            onComplete: { content, error in
                if let content = content, error == nil {
                    self.addMessageToHistory(role: "assistant", content: content)
                }
                onComplete(content, error)
            }
        )
        
        let session = URLSession(configuration: config, delegate: streamDelegate, delegateQueue: .main)
        let task = session.dataTask(with: request)
        streamDelegate.task = task
        task.resume()
        print("流式请求已发送")
        
        // 使用新的公共方法检查响应状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !streamDelegate.hasResponse() {
                print("警告：5秒内没有收到任何响应")
                print("请求URL: \(request.url?.absoluteString ?? "未知")")
                print("请求头: \(request.allHTTPHeaderFields ?? [:])")
                // 打印更多调试信息
                if let requestBody = request.httpBody,
                   let bodyString = String(data: requestBody, encoding: .utf8) {
                    print("请求体: \(bodyString)")
                }
            }
        }
    }
    
    // 添加消息到历史记录
    private func addMessageToHistory(role: String, content: String) {
        chatHistory.append((role: role, content: content))
        
        // 如果历史记录超过最大数量，移除最早的非系统消息
        if chatHistory.count > maxHistoryMessages {
            if let index = chatHistory.firstIndex(where: { $0.role != "system" }) {
                chatHistory.remove(at: index)
            }
        }
    }
    
    // StreamDelegate类实现
    private class StreamDelegate: NSObject, URLSessionDataDelegate {
        private let onReceive: (String) -> Void
        private let onThinking: (String) -> Void
        private let onComplete: (String?, Error?) -> Void
        private let onLoading: (Bool) -> Void // 这里的回调和一开始的typealias很像，或许要统一一下
        private var fullResponse = ""
        private var tmpAnswer = ""  // 用于存储临时答案
        private var buffer = Data()
        private var messageId: String?
        private var conversationId: String?
        private var lastPingTime: Date?
        private var hasReceivedResponse = false  // 添加响应状态标志
        
        var task: URLSessionDataTask?
        
        // 添加公共方法来检查是否收到响应
        func hasResponse() -> Bool {
            return hasReceivedResponse
        }
        
        init(onReceive: @escaping (String) -> Void,
             onThinking: @escaping (String) -> Void,
             onLoading: @escaping (Bool) -> Void,
             onComplete: @escaping (String?, Error?) -> Void) {
            self.onReceive = onReceive
            self.onThinking = onThinking
            self.onLoading = onLoading
            self.onComplete = onComplete
            super.init()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            buffer.append(data)
            hasReceivedResponse = true  // 设置接收到响应的标志
            processBuffer()
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            DispatchQueue.main.async {
                self.onLoading(false)
                
                if let error = error {
                    self.onComplete(nil, error)
                    return
                }
                
                self.processBuffer(isComplete: true)
                self.onComplete(self.fullResponse, nil)
            }
        }
        
        private func processBuffer(isComplete: Bool = false) {
            guard let bufferString = String(data: buffer, encoding: .utf8) else { return }
            
            // 处理阿里云 SSE 格式数据
            let chunks = bufferString.components(separatedBy: "\n\n")
            
            for chunk in chunks {
                guard !chunk.isEmpty else { continue }
                
                // 解析SSE数据块
                let lines = chunk.components(separatedBy: "\n")
                var dataLine: String?
                var eventType: String?
                
                for line in lines {
                    if line.hasPrefix("data:") {
                        dataLine = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("event:") {
                        eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // 处理数据行
                if let dataLine = dataLine {
                    do {
                        guard let jsonData = dataLine.data(using: .utf8),
                              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                              let output = json["output"] as? [String: Any] else {
                            continue
                        }
                        
                        // 获取文本内容
                        if let text = output["text"] as? String {
                            self.fullResponse += text
                            DispatchQueue.main.async {
                                self.onReceive(text)
                            }
                        }
                        
                        // 检查是否完成
                        if let finishReason = output["finish_reason"] as? String,
                           finishReason == "stop" {
                            // 尝试将完整响应解析为JSON
                            if let jsonStart = self.fullResponse.firstIndex(of: "{"),
                               let jsonEnd = self.fullResponse.lastIndex(of: "}") {
                                let jsonString = String(self.fullResponse[jsonStart...jsonEnd])
                                do {
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let scheduleJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                        DispatchQueue.main.async {
                                            self.handleScheduleJSON(scheduleJson)
                                        }
                                    }
                                } catch {
                                    print("JSON解析失败：\(error)")
                                }
                            }
                            DispatchQueue.main.async {
                                self.onComplete(self.fullResponse, nil)
                            }
                        }
                    } catch {
                        print("数据处理错误: \(error)")
                    }
                }
            }
            
            // 清空缓冲区（除非是最后一次处理）
            if !isComplete {
                buffer = Data()
            }
        }

        private func handlePingEvent() {
            let currentTime = Date()
            lastPingTime = currentTime
            
            DispatchQueue.main.async {
                self.onLoading(true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    guard let self = self else { return }
                    if let lastPing = self.lastPingTime,
                       currentTime == lastPing {
                        self.onLoading(false)
                    }
                }
            }
        }
        
        // 处理 JSON 数据并更新 CoreData
        private func handleScheduleJSON(_ json: [String: Any]) {
            guard let operation = (json["operation"] as? String) ?? (json["action"] as? String) else { return }
            
            // 创建日期格式化器
            let parseFormatter = DateFormatter()
            parseFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            parseFormatter.locale = Locale(identifier: "en_US_POSIX")
            parseFormatter.timeZone = TimeZone.current
            
            // 创建日期格式化器（用于显示）
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            displayFormatter.timeZone = TimeZone.current
            
            switch operation {
            case "add":
                if let schedule = json["schedule"] as? [String: Any],
                   let title = schedule["title"] as? String,
                   let startTimeStr = schedule["startTime"] as? String,
                   let endTimeStr = schedule["endTime"] as? String,
                   let startTime = parseFormatter.date(from: startTimeStr),
                   let endTime = parseFormatter.date(from: endTimeStr) {
                    
                    let newSchedule = Schedule(startTime: startTime, endTime: endTime, title: title)
                    ScheduleManager.shared.saveSchedule(newSchedule)
                    print("已添加日程：\(title)")
                    print("时间：\(displayFormatter.string(from: startTime)) 至 \(displayFormatter.string(from: endTime))")
                }
                
            case "update":
                if let oldSchedule = json["oldSchedule"] as? [String: Any],
                   let newSchedule = json["newSchedule"] as? [String: Any],
                   let oldTitle = oldSchedule["title"] as? String,
                   let newTitle = newSchedule["title"] as? String,
                   let oldStartTime = parseFormatter.date(from: oldSchedule["startTime"] as? String ?? ""),
                   let oldEndTime = parseFormatter.date(from: oldSchedule["endTime"] as? String ?? ""),
                   let newStartTime = parseFormatter.date(from: newSchedule["startTime"] as? String ?? ""),
                   let newEndTime = parseFormatter.date(from: newSchedule["endTime"] as? String ?? "") {
                    
                    ScheduleManager.shared.deleteSchedule(Schedule(startTime: oldStartTime, endTime: oldEndTime, title: oldTitle))
                    ScheduleManager.shared.saveSchedule(Schedule(startTime: newStartTime, endTime: newEndTime, title: newTitle))
                    print("已更新日程：\(oldTitle) -> \(newTitle)")
                }
                
            case "delete":
                if let schedule = json["schedule"] as? [String: Any],
                   let title = schedule["title"] as? String,
                   let startTime = parseFormatter.date(from: schedule["startTime"] as? String ?? ""),
                   let endTime = parseFormatter.date(from: schedule["endTime"] as? String ?? "") {
                    
                    ScheduleManager.shared.deleteSchedule(Schedule(startTime: startTime, endTime: endTime, title: title))
                    print("已删除日程：\(title)")
                }
                
            default:
                print("未知的操作类型：\(operation)")
            }
        }
    }
    
    // 发送请求的通用方法
    private func sendRequest(requestBody: [String: Any], isStreaming: Bool, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: apiURL) else {
            completion(nil, NSError(domain: "LocalAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(nil, error)
            return
        }
        
        print("开始发送请求到：\(apiURL)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            completion(data, nil)
        }
        
        task.resume()
    }
    
    // 添加这个辅助方法来构建 prompt
    private func buildPrompt(messages: [[String: String]]) -> String {
        return messages.map { message in
            switch message["role"] {
                case "system":
                    return "System: \(message["content"] ?? "")"
                case "assistant":
                    return "Assistant: \(message["content"] ?? "")"
                case "user":
                    return "Human: \(message["content"] ?? "")"
                default:
                    return message["content"] ?? ""
            }
        }.joined(separator: "\n")
    }
}
