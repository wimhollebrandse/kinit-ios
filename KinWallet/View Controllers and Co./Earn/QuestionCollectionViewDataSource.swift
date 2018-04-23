//
//  QuestionCollectionViewDataSource.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import UIKit

enum QuestionnaireSections: Int, AutoCases {
    case question = 0
    case answers
}

class QuestionCollectionViewDataSource: NSObject {
    private struct Constants {
        static let imageQuestionCellSize = CGSize(width: 134, height: 124)
        static let questionCellHeight: CGFloat = 140
        static let textAnswerCellHeight: CGFloat = 46
        static let compactHeight: CGFloat = 568
        static let textMultipleAnswerCellHeight: CGFloat = 60
        static let textMultipleAnswerCellHeightCompact: CGFloat = 44
        static let collectionViewMinimumSpacing: CGFloat = 15
        static let numberOfColumns: CGFloat = 2
    }

    let question: Question
    let collectionView: UICollectionView

    weak var questionViewController: QuestionViewController?
    var selectedAnswerIds = Set<String>()
    var recognizedCell: SurveyAnswerCollectionViewCell?
    fileprivate(set) var animationIndex = 0
    var answersCount: Int {
        return question.results.count
    }

    init(question: Question, collectionView: UICollectionView) {
        self.question = question
        self.collectionView = collectionView

        super.init()

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func questionCell(_ collectionView: UICollectionView,
                      indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as SurveyQuestionCollectionViewCell
        SurveyCellFactory.drawCell(cell, for: question)

        return cell
    }

    func answerCell(_ collectionView: UICollectionView,
                    indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SurveyAnswerCollectionViewCell = {
            switch question.type {
            case .text, .textEmoji:
                return collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    as SurveyTextAnswerCollectionViewCell
            case .multipleText:
                return collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    as SurveyMultipleTextAnswerCollectionViewCell
            case .textAndImage:
                return collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    as SurveyTextImageAnswerCollectionViewCell
            }
        }()

        let answer = question.results[indexPath.item]
        cell.indexPath = indexPath
        cell.delegate = self
        SurveyCellFactory.drawCell(cell, for: answer, questionType: question.type)
        cell.applySelectedLook(selectedAnswerIds.contains(answer.identifier))

        return cell
    }

    func incrementAnimationIndex() -> Bool {
        if answersCount == animationIndex {
            return false
        }

        animationIndex += 1

        return true
    }

    func answer(at index: Int, didSelect selected: Bool) {
        guard let viewController = questionViewController else {
            fatalError("QuestionCollectionViewDataSource has no questionViewController assigned.")
        }

        let answer = question.results[index]
        let aId = answer.identifier

        if selected {
            selectedAnswerIds.insert(aId)
        } else {
            selectedAnswerIds.remove(aId)
        }

        viewController.dataSource(didChange: selectedAnswerIds)
    }
}

extension QuestionCollectionViewDataSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return QuestionnaireSections.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if section == QuestionnaireSections.question.rawValue {
            return 1
        } else if section == QuestionnaireSections.answers.rawValue {
            return animationIndex
        } else {
            fatalError("Section \(section) shouldn't exist.")
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == QuestionnaireSections.question.rawValue {
            return questionCell(collectionView, indexPath: indexPath)
        } else if indexPath.section == QuestionnaireSections.answers.rawValue {
            return answerCell(collectionView, indexPath: indexPath)
        } else {
            fatalError("Section \(indexPath.section) shouldn't exist.")
        }
    }
}

extension QuestionCollectionViewDataSource: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let widthWithLateralInset = width - Constants.collectionViewMinimumSpacing * 2

        if indexPath.section == QuestionnaireSections.question.rawValue {
            return CGSize(width: widthWithLateralInset, height: Constants.questionCellHeight)
        } else if indexPath.section == QuestionnaireSections.answers.rawValue {
            switch question.type {
            case .text, .textEmoji:
                return CGSize(width: widthWithLateralInset, height: Constants.textAnswerCellHeight)
            case .multipleText:
                let height = UIApplication.shared.keyWindow!.frame.height <= Constants.compactHeight
                    ? Constants.textMultipleAnswerCellHeightCompact
                    : Constants.textMultipleAnswerCellHeight

                return CGSize(width: width, height: height)
            case .textAndImage:
                return Constants.imageQuestionCellSize
            }
        } else {
            fatalError("Section \(indexPath.section) shouldn't exist.")
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == QuestionnaireSections.question.rawValue || question.type == .text {
            return .zero
        }

        if question.allowsMultipleSelection {
            return .zero
        }

        let widthInsets = question.type == .textAndImage
            ? spacing(for: collectionView)
            : Constants.collectionViewMinimumSpacing

        return UIEdgeInsets(top: 0,
                            left: widthInsets,
                            bottom: 0,
                            right: widthInsets)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == QuestionnaireSections.question.rawValue || question.type == .text {
            return Constants.collectionViewMinimumSpacing
        }

        if question.allowsMultipleSelection {
            return 0
        }

        return spacing(for: collectionView)
    }

    private func spacing(for collectionView: UICollectionView) -> CGFloat {
        let width = collectionView.frame.width
        let emptySpace = width - Constants.numberOfColumns * Constants.imageQuestionCellSize.width
        return emptySpace/(Constants.numberOfColumns + 1)
    }
}

extension QuestionCollectionViewDataSource: SurveyAnswerDelegate {
    func surveyAnswerCellDidSelect(_ cell: SurveyAnswerCollectionViewCell) {
        answer(at: cell.indexPath.item, didSelect: true)
    }

    func surveyAnswerCellDidDeselect(_ cell: SurveyAnswerCollectionViewCell) {
        answer(at: cell.indexPath.item, didSelect: false)
    }

    func surveyAnswerCellDidStartSelecting(_ cell: SurveyAnswerCollectionViewCell) {
        guard let viewController = questionViewController else {
            KLogWarn("QuestionCollectionViewDataSource has no questionViewController assigned.")
            return
        }

        viewController.surveyAnswerCellDidStartSelecting(cell)
    }

    func surveyAnswerCellDidCancelSelecting(_ cell: SurveyAnswerCollectionViewCell) {
        guard let viewController = questionViewController else {
            KLogWarn("QuestionCollectionViewDataSource has no questionViewController assigned.")
            return
        }

        viewController.surveyAnswerCellDidCancelSelecting(cell)
    }
}