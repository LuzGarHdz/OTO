import SwiftUI

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

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Buenos días"
        case 12..<20: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    private var list: [TaskItem] {
        let base: [TaskItem]
        switch filter {
        case .pendientes: base = store.pending
        case .completadas: base = store.completed
        case .todas: base = store.tasks.sorted { $0.due < $1.due }
        }
        return store.filtered(base)
    }

    var body: some View {
        Screen(searchable: true) {
            let n = store.pending.count
            Header(eyebrow: dateText,
                   title: "\(greeting), \(store.firstName).",
                   subtitle: n == 0
                   ? "No tienes tareas pendientes. ¡Buen trabajo!"
                   : "Tienes \(n) tarea\(n == 1 ? "" : "s") pendiente\(n == 1 ? "" : "s"). Empecemos por una.")

            QuickAddField(placeholder: "Añade una tarea rápida…", button: "Añadir")

            VStack(alignment: .leading, spacing: 8) {
                Text("Mis tareas").font(.title3.weight(.medium))
                Text("\(n) pendiente\(n == 1 ? "" : "s")")
                    .font(.caption).foregroundColor(Theme.muted)
                PillTabs(selection: $filter,
                         counts: [.pendientes: store.pending.count,
                                  .completadas: store.completed.count,
                                  .todas: store.tasks.count])
                .padding(.top, 4)
                Divider()
                let items = list
                ForEach(items) { t in
                    TaskRow(task: t)
                    if t.id != items.last?.id { Divider() }
                }
                if items.isEmpty {
                    Text(store.query.isEmpty ? "Nada por aquí por ahora." : "Sin resultados para “\(store.query)”.")
                        .font(.footnote).foregroundColor(.gray).padding(.vertical, 12)
                }
            }
            .card()

            FocusSummaryCard()
        }
    }
}
