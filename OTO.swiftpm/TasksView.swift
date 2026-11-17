import SwiftUI

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
        base = store.filtered(base)
        if sortByPriority {
            base.sort {
                if $0.priority.rank != $1.priority.rank { return $0.priority.rank < $1.priority.rank }
                return $0.due < $1.due
            }
        }
        return base
    }

    var body: some View {
        Screen(searchable: true) {
            Header(eyebrow: "Organiza tu día", title: "Mis tareas",
                   subtitle: "Captura, prioriza y termina una cosa a la vez.")
            QuickAddField(placeholder: "¿Qué necesitas hacer?", button: "Crear tarea")

            ScrollView(.horizontal, showsIndicators: false) {
                PillTabs(selection: $filter,
                         counts: [.pendientes: store.pending.count,
                                  .completadas: store.completed.count,
                                  .todas: store.tasks.count],
                         showIcons: true)
            }
            .padding(10).background(Theme.card)
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
                        Label("Ordenar", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25)))
                    }
                }
                let items = list
                ForEach(items) { t in
                    Divider()
                    TaskRow(task: t, showDelete: true)
                }
                if items.isEmpty {
                    Text(store.query.isEmpty ? "No hay tareas en esta vista." : "Sin resultados para “\(store.query)”.")
                        .font(.footnote).foregroundColor(.gray).padding(.vertical, 20)
                }
            }
            .card()
        }
    }
}
