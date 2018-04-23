//
//  Questionnaire.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import Foundation

struct Task: Codable {
    let author: Author
    let identifier: String
    let kinReward: UInt
    let minutesToComplete: Float
    let questions: [Question]
    let startAt: TimeInterval
    let subtitle: String
    let tags: [String]
    let title: String

    enum CodingKeys: CodingKey, String {
        case author = "provider"
        case identifier = "id"
        case kinReward = "price"
        case minutesToComplete = "min_to_complete"
        case questions = "items"
        case startAt = "start_date"
        case subtitle = "desc"
        case tags
        case title
    }
}

extension Task {
    var startDate: Date {
        return Date(timeIntervalSince1970: startAt)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    func prefetchImages() {
        let urls = questions
            .filter { $0.type == .textAndImage }
            .flatMap { $0.results }
            .compactMap { $0.imageURL?.kinImagePathAdjustedForDevice() }

        urls.forEach(ResourceDownloader.shared.requestResource)
    }

    func daysToUnlock() -> UInt {
        let now = Date()

        if now > startDate {
            return 0
        }

        let midnight = now.endOfDay().timeIntervalSince1970
        return UInt(1 + (startDate - midnight).timeIntervalSince1970 / secondsInADay)
    }

    func nextAvailableDay() -> String {
        let toUnlock = daysToUnlock()
        guard toUnlock > 0 else {
            assertionFailure("nextAvailableDay should never be called in a Task whose daysToUnlock equals to 0")
            return "Now"
        }

        if toUnlock == 1 {
            return "tomorrow"
        }

        let unlockDate = Date().addingTimeInterval(TimeInterval(toUnlock) * secondsInADay)
        return "on \(Task.dateFormatter.string(from: unlockDate))"
    }
}

extension Task: Equatable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}