import SwiftUI

// MARK: - Enfoque (Premium)

private enum FocusMode: String, CaseIterable, Identifiable {
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
                     detail: "50 minutos de concentración para avanzar sin interrupciones.",
                     tag: "OTO PLUS", dark: true)
            modeCard(.personalizado, icon: "gearshape", title: "Personalizado",
                     detail: "Adapta el bloque a tu energía y disponibilidad.",
                     tag: "15–90 MIN", dark: false)

            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("SESIÓN ACTUAL").font(.system(size: 10, weight: .semibold)).tracking(1)
                        .foregroundColor(Theme.accent)
                    Text(store.pending.first?.title ?? "Sin tarea seleccionada")
                        .font(.headline)
                    if let t = store.pending.first {
                        Text("\(t.subject) · Entrega \(dueLabel(t.due).lowercased())")
                            .font(.caption).foregroundColor(Theme.muted)
                    } else {
                        Text("Puedes iniciar una sesión libre o añadir una tarea con +.")
                            .font(.caption).foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                }
                Text(timer.display)
                    .font(.system(size: 60, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: timer.progress)
                    .accessibilityLabel("Progreso de la sesión")
                if timer.remaining == 0 {
                    Text("Sesión completada. Reinicia para comenzar de nuevo.")
                        .font(.subheadline).foregroundColor(Theme.accent)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 12) {
                    Button { timer.reset() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 52, height: 52)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3)))
                    }
                    .accessibilityLabel("Reiniciar sesión")
                    Button { timer.toggle() } label: {
                        Label(timer.running ? "Pausar" : "Iniciar",
                              systemImage: timer.running ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(timer.remaining == 0)
                    .opacity(timer.remaining == 0 ? 0.5 : 1)
                }
            }
            .frame(maxWidth: .infinity)
            .card()
        }
        .alert("Oto Plus", isPresented: $showPaywall) {
            Button("Probar OTO Plus (demo)") { store.isPlus = true; select(.extremo) }
            Button("Ahora no", role: .cancel) {}
        } message: {
            Text("El modo extremo ofrece sesiones de 50 minutos con OTO Plus. Puedes desbloquearlo en esta demo sin realizar pagos. Esta versión no bloquea notificaciones.")
        }
    }

    private func select(_ m: FocusMode) {
        guard m != .extremo || store.isPlus else { return }
        mode = m
        switch m {
        case .pomodoro: timer.setMinutes(25)
        case .extremo: timer.setMinutes(50)
        case .personalizado: timer.setMinutes(Int(customMinutes))
        }
    }

    private func modeCard(_ m: FocusMode, icon: String, title: String, detail: String, tag: String, dark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                if m == .extremo && !store.isPlus { showPaywall = true } else { select(m) }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(dark ? .white : Theme.accent)
                            .frame(width: 46, height: 46)
                            .background(dark ? Color.white.opacity(0.12) : Theme.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                        if mode == m {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(dark ? .white : Theme.accent)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.bottom, 8)
                    Text(title).font(.headline)
                    Text(detail).font(.caption).opacity(0.7).multilineTextAlignment(.leading)
                    Text(tag).font(.system(size: 10, weight: .bold))
                        .foregroundColor(dark ? Color(red: 0.75, green: 0.70, blue: 1) : Theme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(mode == m ? [.isSelected] : [])

            if m == .personalizado && mode == .personalizado {
                Divider()
                Text("Duración: \(Int(customMinutes)) min")
                    .font(.subheadline.weight(.medium))
                Slider(value: $customMinutes, in: 15...90, step: 1)
                    .onChange(of: customMinutes) { _, minutes in
                        timer.setMinutes(Int(minutes))
                    }
                    .accessibilityLabel("Duración personalizada en minutos")
                HStack {
                    Text("15 min")
                    Spacer()
                    Text("90 min")
                }
                .font(.caption).foregroundColor(Theme.muted)
            }
        }
        .foregroundColor(dark ? .white : .primary)
        .padding(20)
        .background(dark ? Theme.dark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(mode == m ? Theme.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}
