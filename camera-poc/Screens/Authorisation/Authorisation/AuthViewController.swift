//
//  AuthViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 30.07.2021.
//

import UIKit

class AuthViewController: UIViewController {
    @IBOutlet private weak var nameTextField: UITextField! {
        didSet {
            nameTextField.delegate = self
        }
    }
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var authButton: UIButton!

    @IBAction private func authButtonPressed(_ button: UIButton) {
        let userName = nameTextField.text ?? ""
        viewModel.change(userName: userName)
    }

    var viewModel: AuthVM! {
        didSet {
            viewModel.error.bind { [unowned self] error in
                self.errorLabel.text = error
                self.errorLabel.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initBackgroundGestures()
        subscribeToNotifications()
    }

    func initBackgroundGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTop = view.frame.height - keyboardFrame.height
        self.view.frame.origin.y = -1 * max(authButton.frame.maxY - keyboardTop + 16, 0)
    }

    @objc func hideKeyboard(_ sender: Any?) {
        self.nameTextField.endEditing(true)
        self.view.frame.origin.y = 0
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        errorLabel.text = ""
        errorLabel.isHidden = true
        return true
    }
}
