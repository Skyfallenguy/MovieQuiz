import UIKit
import Foundation

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var yesButton: UIButton!
    @IBOutlet weak private var noButton: UIButton!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    
    private var correctAnswers = 0
    
    private var currentQuestionIndex: Int = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private lazy var resultAlertPresenter = ResultAlertPresenter(viewController: self)
    private var statisticService: StatisticServiceProtocol = StatisticService()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        
        alertPresenter = AlertPresenter(viewController: self)
        
        let questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        self.questionFactory = questionFactory
        
        
        
        showLoadingIndicator()
        questionFactory.loadData()
        //questionFactory.requestNextQuestion()
        
        let statisticService = StatisticService()
        self.statisticService = statisticService
    }
    
    // MARK: - QuestionFactoryDelegate

    func didRecieveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
                return
            }

        currentQuestion = question
        let quizModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
                self?.show(quiz: quizModel)
            }
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
            questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alertPresenter?.show(in: self, model: model)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepModel {
        return QuizStepModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
     private func show(quiz step: QuizStepModel) {
      imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
                correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.imageView.layer.borderWidth = 0
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
            if currentQuestionIndex == questionsAmount - 1 {
                statisticService.store(correct: correctAnswers, total: questionsAmount)
                let currentResult  = "Текущий результат: \(correctAnswers)/\(questionsAmount)"
                let gamesAmount    = "Количество сыгранных квизов за всё время: \(statisticService.gamesCount)"
                let best         = statisticService.bestGame
                let record   = "Лучший результат!: \(best.correct)/\(best.total) (\(best.date.dateTimeString))"
                let accuracy     = String(format: "%.2f", statisticService.totalAccuracy)
                let accuracyPercentage = "Средняя точность: \(accuracy)%"
                let listOfData = [currentResult, gamesAmount, record, accuracyPercentage].joined(separator: "\n")
                let alertModel = AlertModel(title: "Этот раунд окончен!", message: listOfData, buttonText: "Сыграть ещё раз") { [weak self] in
                    
                guard let self = self else {
                    return
                }
                    
                self.currentQuestionIndex = 0
                self.correctAnswers       = 0
                self.questionFactory?.requestNextQuestion()
                }
                resultAlertPresenter.showAlert(model: alertModel)
            } else {
                currentQuestionIndex += 1
                questionFactory?.requestNextQuestion()
            }
        }
    
    private func show(quiz result: QuizResultsModel) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func nobuttonTapped(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.noButton.isEnabled = true
            self.yesButton.isEnabled = true
        }
    }
    
    @IBAction private func yesButtonTapped(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        yesButton.isEnabled = false
        noButton.isEnabled = false
            
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        }
    }
}


