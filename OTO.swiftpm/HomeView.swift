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

