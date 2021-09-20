//
//  LoginViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 20.09.2021.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet private weak var emailTextField: UITextField! {
        didSet {
            emailTextField.delegate = self
        }
    }
    @IBOutlet private weak var passwordTextField: UITextField! {
        didSet {
            passwordTextField.delegate = self
        }
    }
    @IBOutlet private weak var errorLabel: UILabel! {
        didSet {
            errorLabel.text = ""
            errorLabel.isHidden = true
        }
    }

    @IBAction private func loginButtonPressed(_ button: UIButton) {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        viewModel.login(email: email, password: password)
    }

    var viewModel: LoginVM! {
        didSet {
            viewModel.error.bind { [unowned self] value in
                self.errorLabel.text = value
                self.errorLabel.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        emailTextField.text = "app@astartecosmetics.com"
        passwordTextField.text = "123456"
        #endif
        initBackgroundGestures()
        subscribeToNotifications()
    }

    private func initBackgroundGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }

    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTop = view.frame.height - keyboardFrame.height
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = -1 * max(self.errorLabel.frame.maxY - keyboardTop - 5, 0)
        }
    }

    @objc private func hideKeyboard() {
        self.emailTextField.endEditing(true)
        self.passwordTextField.endEditing(true)
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = 0
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorLabel.text = ""
        errorLabel.isHidden = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = 0
        }
        return textField.resignFirstResponder()
    }
}
