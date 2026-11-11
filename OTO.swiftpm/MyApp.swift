import SwiftUI

// MARK: - Tema

enum Theme {
    static let accent = Color(red: 0.49, green: 0.38, blue: 0.78)
    static let accentSoft = Color(red: 0.93, green: 0.91, blue: 0.99)
    static let dark = Color(red: 0.17, green: 0.14, blue: 0.23)
    static let background = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let muted = Color.gray.opacity(0.8)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

// MARK: - Modelos

enum Priority: String, CaseIterable, Identifiable {
    case alta = "Alta", media = "Media", baja = "Baja"
    var id: String { rawValue }
    var fg: Color {
        switch self {
        case .alta: return Color(red: 0.80, green: 0.30, blue: 0.35)
        case .media: return Color(red: 0.75, green: 0.50, blue: 0.15)
        case .baja: return Color(red: 0.25, green: 0.60, blue: 0.40)
        }
    }
    var bg: Color { fg.opacity(0.14) }
}

struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
    var subject: String
    var due: Date
    var priority: Priority
    var done = false
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case pendientes = "Pendientes", completadas = "Completadas", todas = "Todas"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .pendientes: return "clock"
        case .completadas: return "checkmark"
        case .todas: return "tray"
        }
    }
}

struct StudySession: Identifiable {
    let id = UUID()
    let dayOffset: Int      // 0 = lunes
    let time: String
    let minutes: Int
    let subject: String
    let topic: String
}

let subjectColors: [String: Color] = [
    "Matemáticas": Color(red: 0.49, green: 0.38, blue: 0.78),
    "Historia": Color(red: 0.49, green: 0.38, blue: 0.78),
    "Ciencias": Color(red: 0.85, green: 0.60, blue: 0.25),
    "Literatura": Color(red: 0.25, green: 0.65, blue: 0.45)
]
let subjects = ["Historia", "Matemáticas", "Ciencias", "Literatura"]

// MARK: - Estado

final class AppStore: ObservableObject {
    @Published var tasks: [TaskItem]
    @Published var showAdd = false
    @Published var isPlus = false
    @Published var firstName = "Laura"
    @Published var lastName = "Martínez"
    @Published var email = "laura@correo.com"
    @Published var timeZone = "Madrid (GMT+2)"
    @Published var dailySummary = true
    @Published var focusSounds = false
    
    let sessions: [StudySession] = [
        .init(dayOffset: 0, time: "10:00 · 45 MIN", minutes: 45, subject: "Matemáticas", topic: "Ejercicios"),
        .init(dayOffset: 0, time: "16:30 · 30 MIN", minutes: 30, subject: "Literatura", topic: "Lectura"),
        .init(dayOffset: 1, time: "17:00 · 60 MIN", minutes: 60, subject: "Ciencias", topic: "Presentación"),
        .init(dayOffset: 2, time: "16:30 · 45 MIN", minutes: 45, subject: "Historia", topic: "Repaso"),
        .init(dayOffset: 3, time: "19:00 · 25 MIN", minutes: 25, subject: "Literatura", topic: "Resumen")
    ]
    
    init() {
        let cal = Calendar.current
        let now = Date()
        func at(_ dayOffset: Int, _ hour: Int) -> Date {
            let d = cal.date(byAdding: .day, value: dayOffset, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: d) ?? d
        }
        tasks = [
            TaskItem(title: "Terminar ensayo de Historia", subject: "Historia", due: at(0, 18), priority: .alta),
            TaskItem(title: "Resolver ejercicios 12–20", subject: "Matemáticas", due: at(1, 12), priority: .media),
            TaskItem(title: "Preparar presentación grupal", subject: "Ciencias", due: at(5, 12), priority: .alta),
            TaskItem(title: "Leer capítulo 4", subject: "Literatura", due: at(-1, 12), priority: .baja, done: true)
        ]
    }
    
    var pending: [TaskItem] { tasks.filter { !$0.done }.sorted { $0.due < $1.due } }
    var completed: [TaskItem] { tasks.filter { $0.done } }
    
    func add(title: String, subject: String = "Historia", due: Date = Date(), priority: Priority = .media) {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        tasks.append(TaskItem(title: t, subject: subject, due: due, priority: priority))
    }
    func toggle(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i].done.toggle() }
    }
    func delete(_ task: TaskItem) { tasks.removeAll { $0.id == task.id } }
}

final class FocusTimer: ObservableObject {
    @Published var total = 25 * 60
    @Published var remaining = 25 * 60
    @Published var running = false
    private var timer: Timer?
    
    var display: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    var progress: Double { total == 0 ? 0 : 1 - Double(remaining) / Double(total) }
    
    func setMinutes(_ m: Int) {
        stop()
        total = max(1, min(m, 90)) * 60
        remaining = total
    }
    func toggle() { running ? stop() : start() }
    func start() {
        guard !running, timer == nil, remaining > 0 else { return }
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remaining = max(0, self.remaining - 1)
            if self.remaining == 0 { self.stop() }
        }
    }
    func stop() {
        running = false
        timer?.invalidate()
        timer = nil
    }
    func reset() { stop(); remaining = total }

    deinit { timer?.invalidate() }
}

// MARK: - Helpers de fecha

func dueLabel(_ date: Date) -> String {
    let cal = Calendar.current
    let f = DateFormatter()
    f.locale = Locale(identifier: "es_ES")
    if cal.isDateInToday(date) {
        f.dateFormat = "HH:mm"
        return "Hoy, \(f.string(from: date))"
    }
    if cal.isDateInTomorrow(date) { return "Mañana" }
    f.dateFormat = "EEE, d MMM"
    return f.string(from: date).capitalized.replacingOccurrences(of: ".", with: "")
}

// MARK: - App

@main
struct OtoApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var timer = FocusTimer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(timer)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab = 0
    
    var body: some View {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("Inicio", systemImage: "house") }.tag(0)
            TasksView().tabItem { Label("Mis tareas", systemImage: "checkmark") }.tag(1)
            PlanView().tabItem { Label("Plan", systemImage: "calendar") }.tag(2)
            FocusView().tabItem { Label("Enfoque", systemImage: "viewfinder") }.tag(3)
            SettingsView().tabItem { Label("Ajustes", systemImage: "gearshape") }.tag(4)
        }
        .sheet(isPresented: $store.showAdd) { AddTaskSheet() }
    }
}

// MARK: - Contenedor con barra superior

struct Screen<Content: View>: View {
    @EnvironmentObject var store: AppStore
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OTO")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .tracking(2)
                Spacer()
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                Button { store.showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) { content() }
                    .padding(20)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
        }
    }
}

struct Header: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold)).tracking(1.5)
                .foregroundColor(Theme.accent)
            Text(title).font(.system(size: 34, weight: .semibold))
            Text(subtitle).font(.subheadline).foregroundColor(Theme.muted)
        }
    }
}

struct QuickAddField: View {
    @EnvironmentObject var store: AppStore
    let placeholder: String
    let button: String
    @State private var text = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .foregroundColor(Theme.accent)
                .frame(width: 38, height: 38)
                .background(Theme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            TextField(placeholder, text: $text)
                .submitLabel(.done)
                .onSubmit(submit)
            Button(button, action: submit)
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }
    private func submit() {
        store.add(title: text)
        text = ""
    }
}

struct PriorityBadge: View {
    let priority: Priority
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundColor(priority.fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(priority.bg)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TaskItem
    var showDelete = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { withAnimation { store.toggle(task) } } label: {
                Image(systemName: task.done ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(task.done ? Theme.accent : .gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.done)
                    .foregroundColor(task.done ? .gray : .primary)
                HStack(spacing: 8) {
                    Text(task.subject)
                    Label(dueLabel(task.due), systemImage: "clock")
                }
                .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            PriorityBadge(priority: task.priority)
            if showDelete {
                Button { withAnimation { store.delete(task) } } label: {
                    Image(systemName: "trash").foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
    }
}

struct PillTabs: View {
    @Binding var selection: TaskFilter
    let counts: [TaskFilter: Int]
    var showIcons = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(TaskFilter.allCases) { f in
                Button { selection = f } label: {
                    HStack(spacing: 6) {
                        if showIcons { Image(systemName: f.icon) }
                        Text(f.rawValue)
                        if let c = counts[f] { Text("\(c)").font(.caption2).foregroundColor(.gray) }
                    }
                    .font(.footnote.weight(selection == f ? .semibold : .regular))
                    .foregroundColor(selection == f ? Theme.accent : .primary)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(selection == f ? Theme.accentSoft : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Inicio

struct FocusSummaryCard: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: FocusTimer
    
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "scope")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sesión de enfoque").font(.headline)
                    Text("Un paso a la vez.").font(.caption).opacity(0.6)
                }
                Spacer()
                Text("PLUS")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.4)))
            }
            Text(timer.display)
                .font(.system(size: 52, weight: .medium, design: .rounded))
                .monospacedDigit()
            ProgressView(value: timer.progress).tint(.white)
            Button { timer.toggle() } label: {
                Label(timer.running ? "Pausar" : "Iniciar", systemImage: timer.running ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.dark)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .foregroundColor(.white)
        .padding(20)
        .background(Theme.dark)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Mis tareas



// MARK: - Plan


struct SessionBlock: View {
    let session: StudySession
    var body: some View {
        let color = subjectColors[session.subject] ?? Theme.accent
        VStack(alignment: .leading, spacing: 3) {
            Text(session.time).font(.system(size: 8)).foregroundColor(.gray)
            Text(session.subject).font(.caption.weight(.bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(session.topic).font(.system(size: 10)).foregroundColor(.gray)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.14))
        .overlay(Rectangle().fill(color).frame(width: 3), alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Ajustes



struct AddTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subject = "Historia"
    @State private var priority: Priority = .media
    @State private var due = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tarea") {
                    TextField("¿Qué necesitas hacer?", text: $title)
                    Picker("Materia", selection: $subject) {
                        ForEach(subjects, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Detalles") {
                    Picker("Prioridad", selection: $priority) {
                        ForEach(Priority.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Entrega", selection: $due)
                }
            }
            .navigationTitle("Nueva tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.add(title: title, subject: subject, due: due, priority: priority)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

