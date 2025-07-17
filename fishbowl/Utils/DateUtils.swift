import Foundation

class DateUtils {
    static let shared = DateUtils()
    
    private let fileNameFormatter: DateFormatter
    private let iso8601Formatter: DateFormatter
    
    private init() {
        fileNameFormatter = DateFormatter()
        fileNameFormatter.dateFormat = "EEEE MMM d yyyy"
        
        iso8601Formatter = DateFormatter()
        iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    /// Formats a date for use in file names (e.g., "TuesdayJan12025.txt")
    func formatDateForFileName(_ date: Date) -> String {
        let rawName = fileNameFormatter.string(from: date)
        return rawName.replacingOccurrences(of: " ", with: "") + ".txt"
    }
    
    /// Formats a date for use in analysis file names (e.g., "TuesdayJan12025.json")
    func formatDateForAnalysisFileName(_ date: Date) -> String {
        let rawName = fileNameFormatter.string(from: date)
        return rawName.replacingOccurrences(of: " ", with: "") + ".json"
    }
    
    /// Parses an ISO 8601 date string
    func parseISO8601Date(_ dateString: String) -> Date? {
        return iso8601Formatter.date(from: dateString)
    }
    
    /// Formats a date as ISO 8601 string
    func formatAsISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    /// Checks if two dates are on the same day
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    /// Gets the number of days between two dates
    func daysBetween(_ startDate: Date, _ endDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    /// Gets a date that is a specified number of days before the given date
    func dateBySubtractingDays(_ days: Int, from date: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
    }
    
    /// Gets the start of day for the given date
    func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    /// Gets the end of day for the given date
    func endOfDay(for date: Date) -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
} 