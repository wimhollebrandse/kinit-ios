//
//  SurveyInfoViewController.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import UIKit

final class SurveyInfoViewController: UIViewController {
    var task: Task! {
        didSet {
            if isViewLoaded {
                fillQuestionnaireInfo()
            }
        }
    }

    var alreadyStartedTask = false
    weak var surveyDelegate: SurveyViewControllerDelegate?

    @IBOutlet var separators: [UIView]! {
        didSet {
            separators.forEach {
                $0.backgroundColor = UIColor.kin.lightGray
                $0.layer.cornerRadius = 1
            }
        }
    }

    @IBOutlet weak var authorImageView: UIImageView! {
        didSet {
            authorImageView.layer.cornerRadius = 8
        }
    }

    @IBOutlet weak var authorNameLabel: UILabel! {
        didSet {
            authorNameLabel.font = FontFamily.Roboto.regular.font(size: 14)
            authorNameLabel.textColor = UIColor.kin.lightGray
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = FontFamily.Roboto.medium.font(size: 22)
            titleLabel.textColor = UIColor.kin.darkGray
        }
    }

    @IBOutlet weak var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.font = FontFamily.Roboto.regular.font(size: 16)
            subtitleLabel.textColor = UIColor.kin.gray
        }
    }

    @IBOutlet weak var rewardLabel: UILabel! {
        didSet {
            rewardLabel.font = FontFamily.Roboto.regular.font(size: 16)
            rewardLabel.textColor = UIColor.kin.gray
        }
    }

    @IBOutlet weak var averageTimeLabel: UILabel! {
        didSet {
            averageTimeLabel.font = FontFamily.Roboto.regular.font(size: 16)
            averageTimeLabel.textColor = UIColor.kin.gray
        }
    }

    @IBOutlet weak var startButton: UIButton! {
        didSet {
            startButton.makeKinButtonFilled()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        fillQuestionnaireInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureStartButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        logViewEvent()
    }

    func fillQuestionnaireInfo() {
        authorNameLabel.text = "by \(task.author.name)"
        titleLabel.text = task.title
        subtitleLabel.text = task.subtitle

        let rewardString = KinAmountFormatter().string(from: NSNumber(value: task.kinReward))
            ?? String(describing: task.kinReward)
        rewardLabel.text = "+ \(rewardString) KIN"

        averageTimeLabel.text = format(minutes: task.minutesToComplete)

        authorImageView.loadImage(url: task.author.imageURL.kinImagePathAdjustedForDevice(),
                                  placeholderColor: UIColor.kin.extraLightGray)

        configureStartButton()
    }

    func configureStartButton() {
        SimpleDatastore.loadObject(task.identifier) { (tResults: TaskResults?) in
            DispatchQueue.main.async {
                if let tResults = tResults, !tResults.results.isEmpty {
                    self.alreadyStartedTask = true
                } else {
                    self.alreadyStartedTask = false
                }

                let title = self.alreadyStartedTask ? "Continue" : "Start Earning Kin"

                self.startButton.setTitle(title, for: .normal)
            }
        }
    }

    @IBAction func startButtonTapped(_ sender: Any) {
        logStartEvents()
        task.prefetchImages()

        SimpleDatastore.loadObject(task.identifier) { (tResults: TaskResults?) in
            DispatchQueue.main.async {
                if let results = tResults,
                    results.results.count == self.task.questions.count {
                    let surveyComplete = StoryboardScene.Earn.surveyCompletedViewController.instantiate()
                    surveyComplete.task = self.task
                    surveyComplete.results = results
                    self.present(KinNavigationController(rootViewController: surveyComplete), animated: true)
                } else {
                    let surveyNavController = SurveyViewController.embeddedInNavigationController(with: self.task,
                                                        delegate: self.surveyDelegate!)
                    self.present(surveyNavController, animated: true)
                }
            }
        }
    }

    func format(minutes: Float) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]

        if #available(iOS 10.0, *) {
            formatter.unitsStyle = .brief
        } else {
            formatter.unitsStyle = .abbreviated
        }

        formatter.allowsFractionalUnits = true
        formatter.maximumUnitCount = 0

        let duration: TimeInterval = TimeInterval(minutes * 60)
        guard let formatted = formatter.string(from: duration) else {
            return "\(minutes) min."
        }

        return formatted + "."
    }
}

// MARK: Analytics
extension SurveyInfoViewController {
    func logViewEvent() {
        let event = Events.Analytics
            .ViewTaskPage(creator: task.author.name,
                          estimatedTimeToComplete: task.minutesToComplete,
                          kinReward: Int(task.kinReward),
                          taskCategory: task.tags.asString,
                          taskId: task.identifier,
                          taskTitle: task.title,
                          taskType: .questionnaire)
        Analytics.logEvent(event)
    }

    func logStartEvents() {
        let aEvent = Events.Analytics
            .ClickStartButtonOnTaskPage(alreadyStarted: alreadyStartedTask,
                                        creator: task.author.name,
                                        estimatedTimeToComplete: task.minutesToComplete,
                                        kinReward: Int(task.kinReward),
                                        taskCategory: task.tags.asString,
                                        taskId: task.identifier,
                                        taskTitle: task.title,
                                        taskType: .questionnaire)

        Analytics.logEvent(aEvent)

        if !alreadyStartedTask {
            let bEvent = Events.Business
                .EarningTaskStarted(creator: task.author.name,
                                    estimatedTimeToComplete: task.minutesToComplete,
                                    kinReward: Int(task.kinReward),
                                    taskCategory: task.tags.asString,
                                    taskId: task.identifier,
                                    taskTitle: task.title,
                                    taskType: .questionnaire)

            Analytics.logEvent(bEvent)
        }
    }
}

extension SurveyInfoViewController: StoryboardInitializable {
    static func instantiateFromStoryboard() -> SurveyInfoViewController {
        return StoryboardScene.Earn.surveyInfoViewController.instantiate()
    }
}