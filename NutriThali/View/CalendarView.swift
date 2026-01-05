import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let daysWithMeals: Set<DateComponents>
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var datesInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = monthFirstWeek.start

        while dates.count < 42 { // 6 weeks max
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    func hasMeals(for date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return daysWithMeals.contains(components)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header with Navigation
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")

                Spacer()

                Text(monthYearString)
                    .font(Theme.Typography.roundedFont(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
            }
            .padding(.horizontal, 8)

            // Day Headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(Theme.Typography.roundedFont(.caption, weight: .semibold))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }

            // Date Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(datesInMonth, id: \.self) { date in
                    DateCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isInMonth: isInCurrentMonth(date),
                        hasMeals: hasMeals(for: date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        #endif
                    }
                }
            }
        }
        // Removed internal padding and background to let parent handle it
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isInMonth: Bool
    let hasMeals: Bool

    private let calendar = Calendar.current

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(Theme.Typography.roundedFont(.subheadline, weight: isToday ? .bold : .regular))
                .foregroundStyle(isInMonth ? (isSelected ? .black : .white) : .gray.opacity(0.5))

            if hasMeals && isInMonth {
                Circle()
                    .fill(isSelected ? .black : Theme.primary)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Theme.primary : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? Theme.primary : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayNumber), \(hasMeals ? "has meals" : "no meals")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
