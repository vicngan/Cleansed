//
//  TodoView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftData
import SwiftUI

struct TodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var auth: AuthManager
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var todos: [TodoItem]

    /// Incomplete first (Oldest sortDate -> Newest), then Completed (Most recently completed -> Oldest).
    private var sortedTodos: [TodoItem] {
        todos.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.isCompleted {
                let d0 = $0.completedAt ?? $0.createdAt
                let d1 = $1.completedAt ?? $1.createdAt
                return d0 > d1
            } else {
                return $0.sortDate < $1.sortDate
            }
        }
    }

    @State private var isAddSheetPresented = false
    @State private var newTodoTitle = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                if todos.isEmpty {
                    ContentUnavailableView(
                        "All clear",
                        systemImage: "checkmark.circle",
                        description: Text("Tap + to add a task")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedTodos) { todo in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    todo.isCompleted.toggle()
                                    if todo.isCompleted {
                                        todo.completedAt = Date()
                                    } else {
                                        todo.completedAt = nil
                                        todo.sortDate = Date()
                                    }
                                    try? modelContext.save()
                                    TodoManager.shared.syncTodosToUserDefaults(todos)
                                    // Mirror to Supabase if signed in
                                    if auth.isAuthenticated {
                                        Task {
                                            try? await SupabaseManager.shared.completeTodo(
                                                id: todo.id, isCompleted: todo.isCompleted)
                                        }
                                    }
                                }
                            } label: {
                                Text(todo.title)
                                    .font(.system(size: 18, weight: .regular, design: .default))
                                    .foregroundStyle(
                                        todo.isCompleted ? Color.secondary : Color.primary
                                    )
                                    .strikethrough(todo.isCompleted, color: Color.secondary)
                                    .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                        }
                        .onDelete(perform: deleteTodos)
                        .onMove { from, to in }
                    }
                    .padding(.top, 24)
                    .hideListSeparators()
                }
            }
            .background(Color(.systemBackground))
            .onChange(of: todos) { _, newTodos in
                TodoManager.shared.syncTodosToUserDefaults(newTodos)
            }
            .onAppear {
                syncFromWidget()
                TodoManager.shared.syncTodosToUserDefaults(todos)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { syncFromWidget() }
            }
            .task {
                // Load account todos from Supabase on appear when signed in
                if auth.isAuthenticated, let userId = auth.currentUserId {
                    await DataSyncManager.shared.loadFromSupabase(
                        userId: userId, context: modelContext)
                    TodoManager.shared.syncTodosToUserDefaults(todos)
                }
            }

            FAB { isAddSheetPresented = true }
                .padding(24)
        }
        .sheet(isPresented: $isAddSheetPresented) {
            NavigationStack {
                Form {
                    TextField("New Task", text: $newTodoTitle)
                        .focused($isFocused)
                        .onSubmit { addTodo() }
                }
                .navigationTitle("New Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isAddSheetPresented = false
                            newTodoTitle = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addTodo() }
                            .disabled(
                                newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                    }
                }
                .onAppear { isFocused = true }
            }
            .presentationDetents([.height(180)])
            .presentationDetents([.height(180)])
        }
    }

    // MARK: - Actions

    private func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newTodo = TodoItem(title: trimmed)
        modelContext.insert(newTodo)
        try? modelContext.save()
        newTodoTitle = ""
        isAddSheetPresented = false

        // Mirror to Supabase if signed in
        if auth.isAuthenticated, let userId = auth.currentUserId {
            Task {
                try? await SupabaseManager.shared.createTodoWithId(
                    id: newTodo.id, title: newTodo.title,
                    isCompleted: false, completedAt: nil,
                    sortDate: newTodo.sortDate, userId: userId)
            }
        }
    }

    private func deleteTodos(at offsets: IndexSet) {
        let toDelete = offsets.map { sortedTodos[$0] }
        for todo in toDelete {
            if auth.isAuthenticated {
                Task { try? await SupabaseManager.shared.deleteTodo(id: todo.id) }
            }
            modelContext.delete(todo)
        }
        try? modelContext.save()
    }

    private func syncFromWidget() {
        let widgetTodos = TodoManager.shared.getTodosFromUserDefaults()
        for widgetTodo in widgetTodos {
            if let existing = todos.first(where: { $0.id == widgetTodo.id }) {
                if existing.isCompleted != widgetTodo.isCompleted {
                    existing.isCompleted = widgetTodo.isCompleted
                    existing.completedAt = widgetTodo.completedAt
                    existing.sortDate = widgetTodo.sortDate
                }
            }
        }
        try? modelContext.save()
    }
}

#Preview {
    TodoView()
        .modelContainer(for: TodoItem.self, inMemory: true)
        .environmentObject(AuthManager())
}
