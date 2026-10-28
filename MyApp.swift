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
        total = m * 60
        remaining = total
    }
    func toggle() { running ? stop() : start() }
    func start() {
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remaining > 0 { self.remaining -= 1 } else { self.stop() }
        }
    }
    func stop() {
        running = false
        timer?.invalidate()
        timer = nil
    }
    func reset() { stop(); remaining = total }
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

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: FocusTimer
    @State private var filter: TaskFilter = .pendientes
    
    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE, d 'de' MMMM"
        return f.string(from: Date()).uppercased()
    }
    
    var body: some View {
        Screen {
            let n = store.pending.count
            Header(eyebrow: dateText,
                   title: "Buenos días, \(store.firstName).",
                   subtitle: "Tienes \(n) tarea\(n == 1 ? "" : "s") pendiente\(n == 1 ? "" : "s"). Empecemos por una.")
            
            QuickAddField(placeholder: "Añade una tarea rápida…", button: "Añadir")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mis tareas").font(.title3.weight(.medium))
                Text("\(n) pendientes esta semana").font(.caption).foregroundColor(Theme.muted)
                PillTabs(selection: $filter,
                         counts: [.pendientes: store.pending.count, .completadas: store.completed.count])
                .padding(.top, 4)
                Divider()
                let list = filter == .completadas ? store.completed : store.pending
                ForEach(list) { t in
                    TaskRow(task: t)
                    if t.id != list.last?.id { Divider() }
                }
                if list.isEmpty {
                    Text("Nada por aquí por ahora.")
                        .font(.footnote).foregroundColor(.gray).padding(.vertical, 12)
                }
            }
            .card()
            
            FocusSummaryCard()
        }
    }
}

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

struct TasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: TaskFilter = .pendientes
    @State private var sortByPriority = false
    
    private var list: [TaskItem] {
        var base: [TaskItem]
        switch filter {
        case .pendientes: base = store.pending
        case .completadas: base = store.completed
        case .todas: base = store.tasks.sorted { $0.due < $1.due }
        }
        if sortByPriority {
            let order: [Priority] = [.alta, .media, .baja]
            base.sort { order.firstIndex(of: $0.priority)! < order.firstIndex(of: $1.priority)! }
        }
        return base
    }
    
    var body: some View {
        Screen {
            Header(eyebrow: "Organiza tu día", title: "Mis tareas",
                   subtitle: "Captura, prioriza y termina una cosa a la vez.")
            QuickAddField(placeholder: "¿Qué necesitas hacer?", button: "Crear tarea")
            
            ScrollView(.horizontal, showsIndicators: false) {
                PillTabs(selection: $filter,
                         counts: [.pendientes: store.pending.count, .completadas: store.completed.count],
                         showIcons: true)
            }
            .padding(10).background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(filter.rawValue).font(.title3.weight(.medium))
                        Text(sortByPriority ? "Ordenadas por prioridad" : "Ordenadas por fecha de entrega")
                            .font(.caption).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Menu {
                        Button("Fecha de entrega") { sortByPriority = false }
                        Button("Prioridad") { sortByPriority = true }
                    } label: {
                        Label("Filtrar", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25)))
                    }
                }
                ForEach(list) { t in
                    Divider()
                    TaskRow(task: t, showDelete: true)
                }
                if list.isEmpty {
                    Text("No hay tareas en esta vista.")
                        .font(.footnote).foregroundColor(.gray).padding(.vertical, 20)
                }
            }
            .card()
        }
    }
}

// MARK: - Plan

struct PlanView: View {
    @EnvironmentObject var store: AppStore
    @State private var weekOffset = 0
    
    private var monday: Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: start) ?? start
    }
    private func day(_ i: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: i, to: monday) ?? monday
    }
    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: monday).capitalized
    }
    private func dayLabel(_ i: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEE d"
        return f.string(from: day(i)).uppercased().replacingOccurrences(of: ".", with: "")
    }
    private var totalMinutes: Int { store.sessions.reduce(0) { $0 + $1.minutes } }
    
    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Plan de estudio").font(.system(size: 34, weight: .semibold))
                Text("Un plan realista según tus tareas y tiempo disponible.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(monthTitle).font(.headline)
                    Spacer()
                    Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }
                }
                .padding(16)
                Divider()
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<7, id: \.self) { i in
                            let isToday = Calendar.current.isDateInToday(day(i))
                            VStack(spacing: 8) {
                                Text(dayLabel(i))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(isToday ? Theme.accent : .gray)
                                    .padding(.top, 12)
                                ForEach(store.sessions.filter { $0.dayOffset == i }) { s in
                                    SessionBlock(session: s)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 6)
                            .frame(width: 100, height: 360, alignment: .top)
                            .background(isToday ? Theme.accentSoft.opacity(0.5) : Color.clear)
                            Divider()
                        }
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            
            HStack(spacing: 14) {
                Image(systemName: "scope")
                    .foregroundColor(Theme.accent)
                    .frame(width: 50, height: 50)
                    .background(Theme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("OBJETIVO SEMANAL").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                    Text("\(totalMinutes / 60) h \(totalMinutes % 60) min").font(.title.weight(.medium))
                    Text("\(store.sessions.count) sesiones planificadas").font(.caption).foregroundColor(Theme.muted)
                }
                Spacer()
            }
            .card()
            
            HStack(spacing: 12) {
                Image(systemName: "sparkles").foregroundColor(Color(red: 0.75, green: 0.70, blue: 1))
                Text("Oto reorganiza tu plan cuando cambian tus tareas.")
                    .font(.subheadline).foregroundColor(.white)
                Spacer()
            }
            .padding(20)
            .background(Theme.dark)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

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

// MARK: - Enfoque (Premium)

enum FocusMode: String, CaseIterable, Identifiable {
    case pomodoro, extremo, personalizado
    var id: String { rawValue }
}

struct FocusView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: FocusTimer
    @State private var mode: FocusMode = .pomodoro
    @State private var customMinutes = 30.0
    @State private var showPaywall = false
    
    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Elige cómo avanzar").font(.system(size: 34, weight: .semibold))
                Text("Protege este tiempo. El resto puede esperar.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            }
            
            modeCard(.pomodoro, icon: "clock", title: "Pomodoro",
                     detail: "25 minutos de concentración y una pausa breve.",
                     tag: "RECOMENDADO", dark: false)
            modeCard(.extremo, icon: "viewfinder", title: "Modo extremo",
                     detail: "Bloquea distracciones durante 50 minutos.",
                     tag: "OTO PLUS", dark: true)
            modeCard(.personalizado, icon: "gearshape", title: "Personalizado",
                     detail: "Adapta el bloque a tu energía y disponibilidad.",
                     tag: "15–90 MIN", dark: false)
            
            if mode == .personalizado {
                VStack(alignment: .leading) {
                    Text("Duración: \(Int(customMinutes)) min").font(.subheadline.weight(.medium))
                    Slider(value: $customMinutes, in: 15...90, step: 5) { _ in
                        timer.setMinutes(Int(customMinutes))
                    }
                }
                .card()
            }
            
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("SESIÓN ACTUAL").font(.system(size: 10, weight: .semibold)).tracking(1)
                        .foregroundColor(Theme.accent)
                    Text(store.pending.first?.title ?? "Sin tarea seleccionada")
                        .font(.headline)
                    if let t = store.pending.first {
                        Text("\(t.subject) · Entrega \(dueLabel(t.due).lowercased())")
                            .font(.caption).foregroundColor(Theme.muted)
                    }
                }
                Text(timer.display)
                    .font(.system(size: 60, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: timer.progress)
                HStack(spacing: 12) {
                    Button { timer.reset() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 52, height: 52)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3)))
                    }
                    Button { timer.toggle() } label: {
                        Label(timer.running ? "Pausar" : "Iniciar",
                              systemImage: timer.running ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .card()
        }
        .alert("Oto Plus", isPresented: $showPaywall) {
            Button("Desbloquear") { store.isPlus = true; select(.extremo) }
            Button("Ahora no", role: .cancel) {}
        } message: {
            Text("El modo extremo bloquea distracciones y notificaciones durante 50 minutos. Disponible con Oto Plus.")
        }
    }
    
    private func select(_ m: FocusMode) {
        mode = m
        switch m {
        case .pomodoro: timer.setMinutes(25)
        case .extremo: timer.setMinutes(50)
        case .personalizado: timer.setMinutes(Int(customMinutes))
        }
    }
    
    private func modeCard(_ m: FocusMode, icon: String, title: String, detail: String, tag: String, dark: Bool) -> some View {
        Button {
            if m == .extremo && !store.isPlus { showPaywall = true } else { select(m) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 46, height: 46)
                    .background(dark ? Color.white.opacity(0.12) : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.bottom, 8)
                Text(title).font(.headline)
                Text(detail).font(.caption).opacity(0.7).multilineTextAlignment(.leading)
                Text(tag).font(.system(size: 10, weight: .bold)).foregroundColor(dark ? Color(red: 0.75, green: 0.70, blue: 1) : Theme.accent)
            }
            .foregroundColor(dark ? .white : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(dark ? Theme.dark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(mode == m ? Theme.accent : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ajustes

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var section = "Perfil"
    private let sections = ["Perfil", "Enfoque", "Calendario", "Apariencia"]
    @State private var defaultFocus = 25
    @State private var weekStartsMonday = true
    @State private var syncCalendar = false
    @State private var darkMode = false
    
    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ajustes").font(.system(size: 34, weight: .semibold))
                Text("Haz que OTO funcione a tu ritmo.").font(.subheadline).foregroundColor(Theme.muted)
            }
            
            HStack(spacing: 4) {
                ForEach(sections, id: \.self) { s in
                    Button { section = s } label: {
                        Text(s)
                            .font(.footnote.weight(section == s ? .semibold : .regular))
                            .foregroundColor(section == s ? Theme.accent : .primary)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(section == s ? Theme.accentSoft : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8).background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            VStack(alignment: .leading, spacing: 16) {
                switch section {
                case "Perfil": profile
                case "Enfoque": focus
                case "Calendario": calendar
                default: appearance
                }
            }
            .card()
        }
    }
    
    private var profile: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(String(store.firstName.prefix(1)) + String(store.lastName.prefix(1)))
                    .font(.headline).foregroundColor(Theme.accent)
                    .frame(width: 54, height: 54)
                    .background(Theme.accentSoft).clipShape(Circle())
                VStack(alignment: .leading) {
                    Text("Perfil personal").font(.headline)
                    Text("Información visible en tu cuenta.").font(.caption).foregroundColor(Theme.muted)
                }
            }
            Divider()
            field("Nombre", text: $store.firstName)
            field("Apellido", text: $store.lastName)
            field("Correo", text: $store.email, keyboard: .emailAddress)
            field("Zona horaria", text: $store.timeZone)
            Divider()
            toggleRow("Resumen diario", "Recibe tu plan cada mañana.", $store.dailySummary)
            Divider()
            toggleRow("Sonidos de enfoque", "Ruido blanco durante tus sesiones.", $store.focusSounds)
        }
    }
    
    private var focus: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enfoque").font(.headline)
            Stepper("Duración por defecto: \(defaultFocus) min", value: $defaultFocus, in: 15...90, step: 5)
            Divider()
            toggleRow("Sonidos de enfoque", "Ruido blanco durante tus sesiones.", $store.focusSounds)
            Divider()
            toggleRow("Oto Plus", "Desbloquea modo extremo y más.", $store.isPlus)
        }
    }
    
    private var calendar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendario").font(.headline)
            toggleRow("La semana empieza el lunes", "Cambia el inicio de semana en el plan.", $weekStartsMonday)
            Divider()
            toggleRow("Sincronizar calendario", "Importa tus eventos para planear mejor.", $syncCalendar)
        }
    }
    
    private var appearance: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apariencia").font(.headline)
            toggleRow("Modo oscuro", "Usa colores oscuros en la app.", $darkMode)
        }
    }
    
    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold))
            TextField(label, text: text)
                .keyboardType(keyboard)
                .padding(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25)))
        }
    }
    
    private func toggleRow(_ title: String, _ subtitle: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundColor(Theme.muted)
            }
        }
        .tint(Theme.accent)
    }
}

// MARK: - Nueva tarea

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

