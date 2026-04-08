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
    @State private var hasSynced = false

    @AppStorage("todoFontSize") private var todoFontSize: Double = 18
    @AppStorage("todoFontWeight") private var todoFontWeight: String = "regular"

    private var sortedTodos: [TodoItem] {
        todos.sortedByCompletion()
    }

    @State private var isAddSheetPresented = false
    @State private var newTodoTitle = ""
    @FocusState private var isFocused: Bool

    private var fontWeight: Font.Weight {
        switch todoFontWeight {
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        default: return .regular
        }
    }

    var body: some View {
        NavigationStack {
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
                                        .font(.system(size: CGFloat(todoFontSize), weight: fontWeight, design: .default))
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
                        }
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75), value: sortedTodos.map(\.id)
                        )
                        .padding(.top, 24)
                        .hideListSeparators()
                    }
                }
                .background(Color(.systemBackground))

                // Customization Menu Button (Top Right)
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Section("Font Size") {
                                Button { todoFontSize += 1 } label: {
                                    Label("Increase", systemImage: "plus")
                                }
                                .menuActionDismissBehavior(.disabled)

                                Button { todoFontSize -= 1 } label: {
                                    Label("Decrease", systemImage: "minus")
                                }
                                .menuActionDismissBehavior(.disabled)
                            }

                            Section("Font Weight") {
                                Picker("Weight", selection: $todoFontWeight) {
                                    Text("Light").tag("light")
                                    Text("Regular").tag("regular")
                                    Text("Medium").tag("medium")
                                    Text("Semibold").tag("semibold")
                                    Text("Bold").tag("bold")
                                }
                                .pickerStyle(.menu)
                                .menuActionDismissBehavior(.disabled)
                            }

                            Button(role: .destructive) {
                                todoFontSize = 18
                                todoFontWeight = "regular"
                            } label: {
                                Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground).opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }

                FAB { isAddSheetPresented = true }
                    .padding(24)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: todos) { _, newTodos in
                TodoManager.shared.syncTodosToUserDefaults(newTodos)
            }
            .onAppear {
                syncFromWidget()
                TodoManager.shared.syncTodosToUserDefaults(todos)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    syncFromWidget()
                    if auth.isAuthenticated, let userId = auth.currentUserId {
                        Task {
                            await DataSyncManager.shared.syncIfStale(
                                userId: userId, context: modelContext)
                        }
                    }
                }
            }
            .task {
                guard !hasSynced, auth.isAuthenticated, let userId = auth.currentUserId else {
                    return
                }
                hasSynced = true
                await DataSyncManager.shared.loadFromSupabase(userId: userId, context: modelContext)
                TodoManager.shared.syncTodosToUserDefaults(todos)
            }
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
