//
//  ViewController.swift
//  project28
//
//  Created by Павел Петров on 16.07.2023.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var secret: UITextView!
    var doneButton: UIBarButtonItem! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
        navigationItem.rightBarButtonItem = doneButton
        doneButton.isHidden = true
    }
    @IBAction func authenticateTappped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Indentify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        if let pinError = authenticationError as? LAError,
                           pinError.code == .userFallback {
                            self?.showPinEntry()
                        } else {
                            //error
                            let ac = UIAlertController(title: "Аутентификация не пройдена", message: "Попробуйте еще раз или введите пин-код", preferredStyle: .alert)
                            let pinButton = UIAlertAction(title: "Ввести пин-код", style: .default) { [weak self] _ in
                                self?.showPinEntry()
                            }
                            ac.addAction(UIAlertAction(title: "Повторить", style: .default))
                            ac.addAction(pinButton)
                            self?.present(ac, animated: true)
                        }
                    }
                }
            }
        } else {
            //no biometry
//            let ac = UIAlertController(title: "Биометрия не возможна", message: "Ваше устройство не поддерживает биометрическую аутентификацию.", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default))
//            present(ac, animated: true)
            showPinEntry()
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keybardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keybardScreenEnd, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        doneButton.isHidden = false
        secret.isHidden = false
        title = "Secret stuff!"
        
        
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ??
            ""
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        doneButton.isHidden = true
        title = "Nothing to see here"
    }
    
    func showPinEntry() {
        let ac = UIAlertController(title: "Введите пин-код", message: nil, preferredStyle: .alert)
        ac.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.keyboardType = .numberPad
            textField.addTarget(self, action: #selector(self.pinTextFieldDidChange(_:)), for: .editingChanged)
        }
        let cencelAction = UIAlertAction(title: "Отмена", style: .cancel)
        let okAction = UIAlertAction(title: "Подтвердить", style: .default) { [ weak self ] _ in
            if let pin = ac.textFields?.first?.text, pin.count == 5 {
                self?.checkPin(pin)
            } else {
                self?.showPinEntryError()
            }
        }
        okAction.isEnabled = false
        
        ac.addAction(cencelAction)
        ac.addAction(okAction)
        
        present(ac, animated: true)
    }
    
    @objc func pinTextFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            let okAction = (presentedViewController as? UIAlertController)?.actions.last
            okAction?.isEnabled = text.count == 5
        }
    }
    
    func checkPin(_ pin: String) {
        if pin == "12345" {
            unlockSecretMessage()
        } else {
            showPinEntryError()
        }
    }
    
    func showPinEntryError() {
        let ac = UIAlertController(title: "Неверный пин-код", message: "Повторите ввод", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

}

