import Foundation
import CoreData

class ScheduleManager {
    static let shared = ScheduleManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AICalender")
        let description = NSPersistentStoreDescription()
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
        let entity = ScheduleEntity(context: context)
        entity.title = schedule.title
        entity.startTime = schedule.startTime
        entity.endTime = schedule.endTime
        
        do {
            try context.save()
        } catch {
            print("Error saving schedule: \(error)")
        }
    }
    
    func fetchSchedules(for date: Date) -> [Schedule] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { entity in
                Schedule(
                    startTime: entity.startTime!,
                    endTime: entity.endTime!,
                    title: entity.title!
                )
            }
        } catch {
            print("Error fetching schedules: \(error)")
            return []
        }
    }
    
    func deleteSchedule(_ schedule: Schedule) {
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
            }
        } catch {
            print("Error deleting schedule: \(error)")
        }
    }
} 