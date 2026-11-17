import SwiftUI
import UIKit

// MARK: - Tema

private func dynamicColor(light: UIColor, dark: UIColor) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

enum Theme {
    static let accent = Color(red: 0.49, green: 0.38, blue: 0.78)
    static let accentSoft = dynamicColor(
        light: UIColor(red: 0.93, green: 0.91, blue: 0.99, alpha: 1),
        dark: UIColor(red: 0.25, green: 0.21, blue: 0.38, alpha: 1))
    static let dark = Color(red: 0.17, green: 0.14, blue: 0.23)
    static let background = dynamicColor(
        light: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1))
    static let card = dynamicColor(
        light: .white,
        dark: UIColor(red: 0.12, green: 0.11, blue: 0.16, alpha: 1))
    static let muted = Color.gray.opacity(0.8)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

// MARK: - Modelos

enum Priority: String, CaseIterable, Identifiable, Codable {
    case alta = "Alta", media = "Media", baja = "Baja"
    var id: String { rawValue }
    var rank: Int {
        switch self {
        case .alta: return 0
        case .media: return 1
        case .baja: return 2
        }
    }
    var fg: Color {
        switch self {
        case .alta: return Color(red: 0.80, green: 0.30, blue: 0.35)
        case .media: return Color(red: 0.75, green: 0.50, blue: 0.15)
        case .baja: return Color(red: 0.25, green: 0.60, blue: 0.40)
        }
    }
    var bg: Color { fg.opacity(0.14) }
}

struct TaskItem: Identifiable, Codable {
    var id = UUID()
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

enum FocusMode: String, CaseIterable, Identifiable {
    case pomodoro, extremo, personalizado
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .extremo: return "Modo extremo"
        case .personalizado: return "Personalizado"
        }
    }
}

struct StudySession: Identifiable {
    let id = UUID()
    let dayOffset: Int      // 0 = primer día de la semana mostrada
    let time: String
    let minutes: Int
    let subject: String
    let topic: String
}

let subjectColors: [String: Color] = [
    "Matemáticas": Color(red: 0.49, green: 0.38, blue: 0.78),
    "Historia": Color(red: 0.80, green: 0.40, blue: 0.45),
    "Ciencias": Color(red: 0.85, green: 0.60, blue: 0.25),
    "Literatura": Color(red: 0.25, green: 0.65, blue: 0.45),
    "General": Color(red: 0.45, green: 0.50, blue: 0.60)
]
let subjects = ["General", "Historia", "Matemáticas", "Ciencias", "Literatura"]

// MARK: - Estado

final class AppStore: ObservableObject {
    // Persistencia sencilla con UserDefaults
    private static func bool(_ k: String, _ def: Bool) -> Bool {
        UserDefaults.standard.object(forKey: "oto." + k) as? Bool ?? def
    }
    private static func int(_ k: String, _ def: Int) -> Int {
        UserDefaults.standard.object(forKey: "oto." + k) as? Int ?? def
    }
    private static func string(_ k: String, _ def: String) -> String {
        UserDefaults.standard.string(forKey: "oto." + k) ?? def
    }
    private func save(_ value: Any, _ k: String) {
        UserDefaults.standard.set(value, forKey: "oto." + k)
    }

    @Published var tasks: [TaskItem] {
        didSet {
            if let data = try? JSONEncoder().encode(tasks) { save(data, "tasks") }
        }
    }
    @Published var showAdd = false
    @Published var query = ""

    @Published var isPlus = AppStore.bool("isPlus", false) {
        didSet { save(isPlus, "isPlus") }
    }
    @Published var darkMode = AppStore.bool("darkMode", false) {
        didSet { save(darkMode, "darkMode") }
    }
    @Published var weekStartsMonday = AppStore.bool("weekStartsMonday", true) {
        didSet { save(weekStartsMonday, "weekStartsMonday") }
    }
    @Published var defaultFocus = AppStore.int("defaultFocus", 30) {
        didSet { save(defaultFocus, "defaultFocus") }
    }
    @Published var firstName = AppStore.string("firstName", "Laura") {
        didSet { save(firstName, "firstName") }
    }
    @Published var lastName = AppStore.string("lastName", "Martínez") {
        didSet { save(lastName, "lastName") }
    }
    @Published var email = AppStore.string("email", "laura@correo.com") {
        didSet { save(email, "email") }
    }
    @Published var timeZone = AppStore.string(
        "timeZone",
        TimeZone.current.localizedName(for: .standard, locale: Locale(identifier: "es_ES"))
        ?? TimeZone.current.identifier
    ) {
        didSet { save(timeZone, "timeZone") }
    }

    // Aún sin función real (se muestran como "Próximamente")
    @Published var dailySummary = false
    @Published var focusSounds = false
    @Published var syncCalendar = false
    @Published private(set) var focusHistory: [FocusSession] = FocusHistoryStorage.load()

    init() {
        if let data = UserDefaults.standard.data(forKey: "oto.tasks"),
           let saved = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = saved
        } else {
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
    }

    var pending: [TaskItem] { tasks.filter { !$0.done }.sorted { $0.due < $1.due } }
    var completed: [TaskItem] { tasks.filter { $0.done } }

    /// Aplica el texto de búsqueda (si lo hay) a una lista de tareas.
    func filtered(_ list: [TaskItem]) -> [TaskItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.title.localizedCaseInsensitiveContains(q) || $0.subject.localizedCaseInsensitiveContains(q)
        }
    }

    func add(title: String, subject: String = "General", due: Date? = nil, priority: Priority = .media) {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
        tasks.append(TaskItem(title: t, subject: subject, due: due ?? endOfToday, priority: priority))
    }
    func toggle(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i].done.toggle() }
    }
    func delete(_ task: TaskItem) { tasks.removeAll { $0.id == task.id } }

    func recordFocusSession(id: UUID, mode: String, minutes: Int, taskTitle: String?) {
        guard !focusHistory.contains(where: { $0.id == id }) else { return }
        let entry = FocusSession(id: id, completedAt: Date(), mode: mode,
                                 minutes: minutes, taskTitle: taskTitle)
        focusHistory.insert(entry, at: 0)
        FocusHistoryStorage.save(focusHistory)
    }

    /// Genera el plan de la semana a partir de las tareas pendientes:
    /// una sesión el día anterior a la entrega (o hoy si ya es tarde).
    func plan(weekStart: Date) -> [StudySession] {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: weekStart)
        let todayIdx = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: Date())).day ?? 0
        var load: [Int: Int] = [:]
        var result: [StudySession] = []

        for t in pending {
            let dueIdx = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: t.due)).day ?? 0
            var idx = max(dueIdx - 1, todayIdx)
            if idx < 0 && dueIdx >= 0 { idx = 0 }
            guard (0..<7).contains(idx) else { continue }

            let n = load[idx, default: 0]
            load[idx] = n + 1
            let minutes: Int
            switch t.priority {
            case .alta: minutes = 60
            case .media: minutes = 45
            case .baja: minutes = 30
            }
            let hour = min(16 + n, 22)
            result.append(StudySession(
                dayOffset: idx,
                time: String(format: "%02d:00 · %d MIN", hour, minutes),
                minutes: minutes,
                subject: t.subject,
                topic: t.title))
        }
        return result
    }
}

@MainActor
final class FocusTimer: ObservableObject {
    @Published private(set) var total = 25 * 60
    @Published private(set) var remaining = 25 * 60
    @Published private(set) var running = false
    @Published var mode: FocusMode = .pomodoro
    @Published var customMinutes: Double = Double(UserDefaults.standard.object(forKey: "oto.defaultFocus") as? Int ?? 30)
    @Published private(set) var hasStarted = false
    @Published private(set) var completionPending = false

    private var timer: Timer?
    private var endDate: Date?
    private let storageKey = "oto.focus.timer.v1"
    private var sessionID = UUID()
    @Published private(set) var selectedTaskTitle: String? = nil
    @Published private(set) var selectedTaskID: UUID? = nil

    private struct SavedState: Codable {
        let total: Int
        let remaining: Int
        let running: Bool
        let endDate: Date?
        let hasStarted: Bool?
        let completionPending: Bool?
        let sessionID: UUID?
        let selectedTaskTitle: String?
        let selectedTaskID: UUID?
    }

    init() { restore() }

    var display: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - Double(remaining) / Double(total)))
    }
    var canChangeMode: Bool { !hasStarted && !completionPending }

    func setMinutes(_ minutes: Int) {
        guard canChangeMode else { return }
        stopTicker()
        total = max(1, min(minutes, 90)) * 60
        remaining = total
        running = false
        endDate = nil
        sessionID = UUID()
        save()
    }

    func selectTask(_ task: TaskItem?) {
        guard canChangeMode else { return }
        selectedTaskID = task?.id
        selectedTaskTitle = task?.title
        save()
    }

    func toggle() { running ? pause() : start() }

    func start() {
        guard !running, remaining > 0, !completionPending else { return }
        hasStarted = true
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        running = true
        save()
        startTicker()
    }

    func pause() {
        guard running else { return }
        updateRemaining()
        guard running else { return }
        running = false
        endDate = nil
        stopTicker()
        save()
    }

    func stop() { pause() }

    func reset() {
        stopTicker()
        running = false
        endDate = nil
        remaining = total
        hasStarted = false
        completionPending = false
        sessionID = UUID()
        selectedTaskID = nil
        selectedTaskTitle = nil
        save()
    }

    func discardSession() { reset() }

    // Returns an identifier exactly once for the confirmed session.
    func confirmCompletion() -> (id: UUID, minutes: Int, taskTitle: String?)? {
        refresh()
        guard completionPending, remaining == 0 else { return nil }
        let result = (id: sessionID, minutes: total / 60, taskTitle: selectedTaskTitle)
        reset()
        return result
    }

    func refresh() {
        updateRemaining()
        if running && timer == nil { startTicker() }
    }

    private func startTicker() {
        stopTicker()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateRemaining() }
        }
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func updateRemaining() {
        guard running, let endDate else { return }
        remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        if remaining == 0 {
            running = false
            self.endDate = nil
            hasStarted = true
            completionPending = true
            stopTicker()
            save()
        }
    }

    private func save() {
        let state = SavedState(total: total, remaining: remaining, running: running,
                               endDate: endDate, hasStarted: hasStarted,
                               completionPending: completionPending, sessionID: sessionID,
                               selectedTaskTitle: selectedTaskTitle, selectedTaskID: selectedTaskID)
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        total = max(60, min(state.total, 90 * 60))
        remaining = max(0, min(state.remaining, total))
        sessionID = state.sessionID ?? UUID()
        selectedTaskTitle = state.selectedTaskTitle
        selectedTaskID = state.selectedTaskID
        hasStarted = state.hasStarted ?? (state.running || remaining < total)
        completionPending = state.completionPending ?? (hasStarted && remaining == 0)
        if completionPending {
            remaining = 0
            running = false
            endDate = nil
        } else if state.running, let savedEndDate = state.endDate {
            endDate = savedEndDate
            running = true
            hasStarted = true
            updateRemaining()
            if running { startTicker() }
        } else {
            running = false
            endDate = nil
        }
        save()
    }

    deinit { timer?.invalidate() }
}

// MARK: - Helpers de fecha

func dueLabel(_ date: Date) -> String {
    let cal = Calendar.current
    let f = DateFormatter()
    f.locale = Locale(identifier: "es_ES")
    if cal.isDateInToday(date) {
        let c = cal.dateComponents([.hour, .minute], from: date)
        if c.hour == 23 && c.minute == 59 { return "Hoy" }   // tarea sin hora específica
        f.dateFormat = "HH:mm"
        return "Hoy, \(f.string(from: date))"
    }
    if cal.isDateInTomorrow(date) { return "Mañana" }
    if cal.isDateInYesterday(date) { return "Ayer" }
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
                .preferredColorScheme(store.darkMode ? .dark : .light)
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
    var searchable = false
    @ViewBuilder var content: () -> Content
    @State private var searching = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OTO")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .tracking(2)
                Spacer()
                if searchable {
                    Button {
                        withAnimation {
                            searching.toggle()
                            if !searching { store.query = "" }
                        }
                    } label: {
                        Image(systemName: searching ? "xmark" : "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(searching ? "Cerrar búsqueda" : "Buscar tareas")
                }
                Button { store.showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityLabel("Nueva tarea")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Theme.card)

            if searchable && searching {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Buscar por título o materia", text: $store.query)
                        .focused($searchFocused)
                        .submitLabel(.search)
                }
                .padding(12)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .background(Theme.card)
                .onAppear { searchFocused = true }
            }

            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) { content() }
                    .padding(20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
        }
        .background(Theme.card.ignoresSafeArea(edges: .top))
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
        .background(Theme.card)
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
            .accessibilityLabel(task.done ? "Marcar como pendiente" : "Marcar como completada")
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
                .accessibilityLabel("Eliminar tarea")
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

// MARK: - Inicio (tarjeta de enfoque)

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
                Text(timer.mode.title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.4)))
            }
            Text(timer.display)
                .font(.system(size: 52, weight: .medium, design: .rounded))
                .monospacedDigit()
            ProgressView(value: timer.progress).tint(.white)
            Button { timer.toggle() } label: {
                Label(timer.completionPending ? "Finalizar en Enfoque" : (timer.running ? "Pausar" : "Iniciar"), systemImage: timer.running ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.dark)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(timer.remaining == 0)
            .opacity(timer.remaining == 0 ? 0.5 : 1)
        }
        .foregroundColor(.white)
        .padding(20)
        .background(Theme.dark)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Plan (bloque de sesión)

struct SessionBlock: View {
    let session: StudySession
    var body: some View {
        let color = subjectColors[session.subject] ?? Theme.accent
        VStack(alignment: .leading, spacing: 3) {
            Text(session.time).font(.system(size: 8)).foregroundColor(.gray)
            Text(session.subject).font(.caption.weight(.bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(session.topic).font(.system(size: 10)).foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.14))
        .overlay(Rectangle().fill(color).frame(width: 3), alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Nueva tarea

struct AddTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subject = "General"
    @State private var priority: Priority = .media
    @State private var due = Date()

    var body: some View {
        NavigationStack {
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

