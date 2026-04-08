//
//  TodoItem.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import Foundation
import SwiftData
// TodoItem conforms to the shared sort protocol defined in TodoManager.swift

@Model
final class TodoItem: TodoSortable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var sortDate: Date = Date()

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.sortDate = Date()
    }
}
