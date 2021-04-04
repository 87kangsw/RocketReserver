//
//  UIViewController+Alert.swift
//  RocketReserver
//
//  Created by Kanz on 2021/04/04.
//

import UIKit

import Apollo

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func showAlertForErrors(_ errors: [GraphQLError]) {
        let message = errors
            .map { $0.localizedDescription }
            .joined(separator: "\n")
        self.showAlert(title: "GraphQL Error(s)", message: message)
    }
}


