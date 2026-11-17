import SwiftUI

// MARK: - Enfoque (Premium)

struct FocusView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var timer: FocusTimer
    @AppStorage("oto.focus.mode")
    private var savedMode = FocusMode.pomodoro.rawValue

    @AppStorage("oto.focus.customMinutes")
    private var customMinutes = 30.0

    private var mode: FocusMode {
        FocusMode(rawValue: savedMode) ?? .pomodoro
    }
    @State private var showPaywall = false
    @AppStorage("oto.focus.extremeMinutes") private var extremeMinutes = 50.0
    @AppStorage("oto.focus.pomodoroCount") private var pomodoroCount = 0
    // focus, breakReady, shortBreak, longBreak
    @AppStorage("oto.focus.pomodoroPhase") private var pomodoroPhase = "focus"
    @State private var showExtremeScreen = false
    @State private var showDiscardConfirmation = false
    @State private var pendingMode: FocusMode?
    @State private var showModeConfirmation = false

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Elige cómo avanzar").font(.system(size: 34, weight: .semibold))
                Text("Protege este tiempo. El resto puede esperar.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            }

            modeCard(.pomodoro, icon: "clock", title: "Pomodoro",
                     detail: "25 min de enfoque, 5 min de descanso; pausa larga cada 4 bloques.",
                     tag: "RECOMENDADO", dark: false)
            modeCard(.extremo, icon: "viewfinder", title: "Modo extremo",
                     detail: "Pantalla negra de concentración con duración configurable.",
                     tag: "OTO PLUS", dark: true)
            modeCard(.personalizado, icon: "gearshape", title: "Personalizado",
                     detail: "Adapta el bloque a tu energía y disponibilidad.",
                     tag: "1–90 MIN", dark: false)

            if mode == .pomodoro {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CICLO POMODORO").font(.caption.weight(.semibold)).foregroundColor(Theme.accent)
                    Text("Bloques completados en el ciclo: \(pomodoroCount % 4) de 4")
                        .font(.subheadline)
                    if pomodoroPhase == "breakReady" {
                        Text(pomodoroCount % 4 == 0 ? "Toca un descanso largo de 15 minutos." : "Toca un descanso corto de 5 minutos.")
                        Button("Comenzar descanso") { startBreak() }
                            .buttonStyle(.borderedProminent)
                        Button("Omitir descanso") { finishBreak() }
                            .font(.caption)
                    } else if isBreak {
                        Text(pomodoroPhase == "longBreak" ? "Descanso largo" : "Descanso corto")
                            .font(.headline)
                        Text("Los descansos no se guardan como tiempo de estudio.")
                            .font(.caption).foregroundColor(Theme.muted)
                        Button("Omitir descanso") { finishBreak() }
                            .font(.caption)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).card()
            }

            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("SESIÓN ACTUAL").font(.system(size: 10, weight: .semibold)).tracking(1)
                        .foregroundColor(Theme.accent)
                    Text(isBreak ? "Descanso Pomodoro" : (timer.selectedTaskTitle ?? "Sesión libre"))
                        .font(.headline)
                    if !timer.hasStarted && !timer.completionPending && !isBreak && pomodoroPhase != "breakReady" {
                        Menu {
                            Button("Sesión libre") { timer.selectTask(nil) }
                            ForEach(store.pending) { task in
                                Button(task.title) { timer.selectTask(task) }
                            }
                        } label: {
                            Label("Elegir tarea", systemImage: "list.bullet")
                                .font(.subheadline)
                        }
                        Text("Elige una tarea pendiente o estudia sin asociar una tarea.")
                            .font(.caption).foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("La tarea queda fijada durante esta sesión.")
                            .font(.caption).foregroundColor(Theme.muted)
                    }
                }
                Text(timer.display)
                    .font(.system(size: 60, weight: .medium, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: timer.progress)
                    .accessibilityLabel("Progreso de la sesión")
                if timer.completionPending {
                    Text(isBreak ? "¡Descanso terminado!" : "¡Tiempo cumplido! Confirma tu sesión para guardarla.")
                        .font(.subheadline).foregroundColor(Theme.accent)
                        .multilineTextAlignment(.center)
                    Button {
                        if isBreak {
                            finishBreak()
                        } else if let result = timer.confirmCompletion() {
                            store.recordFocusSession(id: result.id, mode: mode.rawValue, minutes: result.minutes, taskTitle: result.taskTitle)
                            if mode == .pomodoro {
                                pomodoroCount += 1
                                pomodoroPhase = "breakReady"
                            }
                        }
                    } label: {
                        Label(isBreak ? "Terminar descanso" : "Finalizar sesión", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button(isBreak ? "Omitir descanso" : "Descartar sesión") {
                        if isBreak { finishBreak() }
                        else { showDiscardConfirmation = true }
                    }
                    .font(.caption)
                }
                if !timer.completionPending && pomodoroPhase != "breakReady" {
                    HStack(spacing: 12) {
                        Button {
                            if timer.hasStarted { showDiscardConfirmation = true }
                            else { timer.reset() }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 52, height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3)))
                        }
                        .accessibilityLabel("Reiniciar sesión")
                        Button {
                            timer.toggle()
                            if mode == .extremo && timer.running { showExtremeScreen = true }
                        } label: {
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
            }
            .frame(maxWidth: .infinity)
            .card()

            VStack(alignment: .leading, spacing: 12) {
                Text("Historial de enfoque").font(.title3.weight(.semibold))
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(store.focusHistory.count)").font(.title2.bold())
                        Text("Sesiones").font(.caption).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(store.focusHistory.reduce(0) { $0 + $1.minutes }) min")
                            .font(.title2.bold())
                        Text("Tiempo completado").font(.caption).foregroundColor(Theme.muted)
                    }
                }
                Divider()
                if store.focusHistory.isEmpty {
                    Text("Aún no hay sesiones confirmadas.")
                        .font(.subheadline).foregroundColor(Theme.muted)
                } else {
                    ForEach(store.focusHistory.prefix(5)) { session in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                if let title = session.taskTitle {
                                    Text(title).font(.subheadline.weight(.semibold))
                                }
                                Text("\(session.modeTitle) · \(session.minutes) min").font(.subheadline.weight(.medium))
                                Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundColor(Theme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .confirmationDialog("¿Descartar esta sesión?", isPresented: $showDiscardConfirmation) {
            Button("Descartar y reiniciar", role: .destructive) {
                if isBreak { finishBreak() }
                else { timer.discardSession() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El progreso actual no se guardará en el historial.")
        }
        .confirmationDialog("¿Cambiar de modo?", isPresented: $showModeConfirmation) {
            Button("Descartar sesión y cambiar", role: .destructive) {
                if let requested = pendingMode {
                    timer.discardSession()
                    pomodoroPhase = "focus"
                    applyMode(requested)
                }
                pendingMode = nil
            }
            Button("Cancelar", role: .cancel) { pendingMode = nil }
        } message: {
            Text("Se perderá el progreso de la sesión actual.")
        }
        .alert("Oto Plus", isPresented: $showPaywall) {
            Button("Probar OTO Plus (demo)") { store.isPlus = true; select(.extremo) }
            Button("Ahora no", role: .cancel) {}
        } message: {
            Text("OTO Plus es una demostración sin pagos. El modo extremo usa una pantalla negra, pero no bloquea notificaciones ni otras aplicaciones.")
        }
        .fullScreenCover(isPresented: $showExtremeScreen) {
            extremeScreen
                .interactiveDismissDisabled()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                timer.refresh()
                if mode == .extremo && timer.hasStarted { showExtremeScreen = true }
            }
        }
        .onAppear {
            timer.mode = mode
            timer.refresh()
            if mode == .extremo && timer.hasStarted { showExtremeScreen = true }
        }
    }

    private var extremeScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("OTO · MODO EXTREMO")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundColor(.gray)
                Text(timer.selectedTaskTitle ?? "Sesión libre")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Text(timer.display)
                    .font(.system(size: 78, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                ProgressView(value: timer.progress)
                    .tint(.white)
                    .padding(.horizontal, 32)
                Text(timer.completionPending ? "Tiempo cumplido" : "Concéntrate en lo importante")
                    .foregroundColor(.gray)
                Spacer()
                if timer.completionPending {
                    Button("Finalizar sesión") {
                        if let result = timer.confirmCompletion() {
                            store.recordFocusSession(id: result.id, mode: mode.rawValue,
                                                     minutes: result.minutes, taskTitle: result.taskTitle)
                            showExtremeScreen = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(.black)
                } else {
                    Button(timer.running ? "Pausar" : "Reanudar") { timer.toggle() }
                        .foregroundColor(.white)
                }
                Button("Salir del modo extremo") { showExtremeScreen = false }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                Text("Salir de esta pantalla no cancela el temporizador.")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(32)
        }
        .preferredColorScheme(.dark)
        .onAppear { timer.refresh() }
    }

    private var isBreak: Bool {
        mode == .pomodoro && (pomodoroPhase == "shortBreak" || pomodoroPhase == "longBreak")
    }

    private func startBreak() {
        guard mode == .pomodoro, pomodoroPhase == "breakReady" else { return }
        let long = pomodoroCount % 4 == 0
        pomodoroPhase = long ? "longBreak" : "shortBreak"
        timer.setMinutes(long ? 15 : 5)
        timer.start()
    }

    private func finishBreak() {
        timer.discardSession()
        pomodoroPhase = "focus"
        timer.setMinutes(25)
    }

    private func select(_ m: FocusMode) {
        guard m != .extremo || store.isPlus else { return }

        if !timer.canChangeMode {
            pendingMode = m
            showModeConfirmation = true
            return
        }
        applyMode(m)
    }

    private func applyMode(_ m: FocusMode) {
        pomodoroPhase = "focus"
        savedMode = m.rawValue
        timer.mode = m
        switch m {
        case .pomodoro:
            timer.setMinutes(25)

        case .extremo:
            timer.setMinutes(Int(extremeMinutes))

        case .personalizado:
            timer.setMinutes(Int(customMinutes))
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

            if m == .extremo && mode == .extremo {
                Divider()
                Text("Duración extrema: \(Int(extremeMinutes)) min")
                    .font(.subheadline.weight(.medium))
                Slider(value: $extremeMinutes, in: 1...90, step: 1)
                    .onChange(of: extremeMinutes) { _, value in
                        if timer.canChangeMode { timer.setMinutes(Int(value)) }
                    }
                    .disabled(!timer.canChangeMode)
                Text("Al iniciar, OTO mostrará únicamente el tiempo restante sobre una pantalla negra. No bloquea notificaciones ni otras aplicaciones.")
                    .font(.caption)

            }

            if m == .personalizado && mode == .personalizado {
                Divider()
                Text("Duración: \(Int(customMinutes)) min")
                    .font(.subheadline.weight(.medium))
                Slider(value: $customMinutes, in: 1...90, step: 1)
                    .onChange(of: customMinutes) { _, minutes in
                        if timer.canChangeMode { timer.setMinutes(Int(minutes)) }
                    }
                    .disabled(!timer.canChangeMode)
                    .accessibilityLabel("Duración personalizada en minutos")
                if !timer.canChangeMode {
                    Text("Reinicia o finaliza la sesión para cambiar la duración.")
                        .font(.caption).foregroundColor(Theme.muted)
                }
                HStack {
                    Text("1 min")
                    Spacer()
                    Text("90 min")
                }
                .font(.caption).foregroundColor(Theme.muted)
            }
        }
        .foregroundColor(dark ? .white : .primary)
        .padding(20)
        .background(dark ? Theme.dark : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(mode == m ? Theme.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}

