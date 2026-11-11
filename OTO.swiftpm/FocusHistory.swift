import Foundation

// Historial independiente de las sesiones programadas en Plan.
struct FocusSession: Identifiable, Codable {
    let id: UUID
    let completedAt: Date
    let mode: String
    let minutes: Int
    let taskTitle: String?

    var modeTitle: String {
        switch mode {
        case "pomodoro": return "Pomodoro"
        case "extremo": return "Modo extremo"
        case "personalizado": return "Personalizado"
        default: return "Enfoque"
        }
    }
}

enum FocusHistoryStorage {
    private static let key = "oto.focus.history.v1"

    static func load() -> [FocusSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sessions = try? JSONDecoder().decode([FocusSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.completedAt > $1.completedAt }
    }

    static func save(_ sessions: [FocusSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
