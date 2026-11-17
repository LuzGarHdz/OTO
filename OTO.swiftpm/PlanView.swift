import SwiftUI

struct PlanView: View {
    @EnvironmentObject var store: AppStore
    @State private var weekOffset = 0
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = store.weekStartsMonday ? 2 : 1
        return cal
    }
    private var weekStart: Date {
        let cal = calendar
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: start) ?? start
    }
    private func day(_ i: Int) -> Date {
        calendar.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
    }
    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: weekStart).capitalized
    }
    private func dayLabel(_ i: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEE d"
        return f.string(from: day(i)).uppercased().replacingOccurrences(of: ".", with: "")
    }
    private var sessions: [StudySession] { store.plan(weekStart: weekStart) }
    
    var body: some View {
        let sessions = self.sessions
        let totalMinutes = sessions.reduce(0) { $0 + $1.minutes }
        
        Screen {
            VStack(alignment: .leading, spacing: 6) {
                Text("Plan de estudio").font(.system(size: 34, weight: .semibold))
                Text("Un plan realista según tus tareas y tiempo disponible.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Semana anterior")
                    Spacer()
                    Text(monthTitle).font(.headline)
                    Spacer()
                    Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }
                        .accessibilityLabel("Semana siguiente")
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
                                ForEach(sessions.filter { $0.dayOffset == i }) { s in
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
            .background(Theme.card)
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
                    Text(sessions.isEmpty
                         ? "Sin sesiones esta semana"
                         : "\(sessions.count) sesion\(sessions.count == 1 ? "" : "es") planificada\(sessions.count == 1 ? "" : "s")")
                    .font(.caption).foregroundColor(Theme.muted)
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
