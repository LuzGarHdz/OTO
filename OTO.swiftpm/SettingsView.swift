import SwiftUI

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
