import Foundation
import CoreData

class ScheduleManager {
    static let shared = ScheduleManager()
    
    private init() {
        printSQLitePath()
    }
    
    private func printSQLitePath() {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            print("无法获取 SQLite 文件路径")
            return
        }
        print("SQLite 文件路径: \(storeURL.path)")
        
        // 检查文件是否存在
        if FileManager.default.fileExists(atPath: storeURL.path) {
            print("SQLite 文件已存在")
        } else {
            print("SQLite 文件尚未创建")
        }
    }
    
    // MARK: - Core Data stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AICalender")
        
        // 获取应用程序的 Documents 目录
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[0]
        
        // 创建存储文件的 URL
        let storeURL = docURL.appendingPathComponent("AICalender.sqlite")
        
        // 配置存储描述
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - CRUD Operations
    func saveSchedule(_ schedule: Schedule) {
        print("开始保存日程: \(schedule.title)")
        let entity = ScheduleEntity(context: context)
        entity.title = schedule.title
        entity.startTime = schedule.startTime
        entity.endTime = schedule.endTime
        
        do {
            try context.save()
            print("日程保存成功: \(schedule.title)")
            printSQLitePath()
        } catch {
            print("保存日程失败: \(error)")
        }
    }
    
    func fetchSchedules(for startDate: Date, to endDate: Date) -> [Schedule] {
        print("开始获取从 \(startDate) 到 \(endDate) 的日程")
        
        let fetchRequest: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            print("成功获取到 \(entities.count) 个日程")
            return entities.map { entity in
                Schedule(
                    startTime: entity.startTime!,
                    endTime: entity.endTime!,
                    title: entity.title!
                )
            }
        } catch {
            print("获取日程失败: \(error)")
            return []
        }
    }
    
    func deleteSchedule(_ schedule: Schedule) {
        print("开始删除日程: \(schedule.title)")
        let fetchRequest: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@ AND startTime == %@ AND endTime == %@",
                                           schedule.title,
                                           schedule.startTime as NSDate,
                                           schedule.endTime as NSDate)
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                context.delete(entity)
                try context.save()
                print("日程删除成功: \(schedule.title)")
                printSQLitePath()
            }
        } catch {
            print("删除日程失败: \(error)")
        }
    }
} 