//
//  IngredientsFullTableViewCell.swift
//  FoodViewer
//
//  Created by arnaud on 24/02/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import UIKit

protocol IngredientsFullCellDelegate: class {
    
    func ingredientsFullTableViewCell(_ sender: IngredientsFullTableViewCell, receivedActionOn textView:UITextView)
    
    func ingredientsFullTableViewCell(_ sender: IngredientsFullTableViewCell, receivedTapOn button:UIButton)

}


class IngredientsFullTableViewCell: UITableViewCell {

    private struct Constants {
        static let NoIngredientsText = TranslatableStrings.NoIngredients
        static let UnbalancedWarning = TranslatableStrings.UnbalancedWarning
    }

    @IBOutlet weak var textView: UITextView! {
        didSet {
            setupTextView()
        }
    }
    
    @IBOutlet weak var clearTextViewButton: UIButton! {
        didSet {
            setTextViewClearButton()
        }
    }
    
    @IBAction func clearTextViewButtonTapped(_ sender: UIButton) {
        ingredients = ""
    }
    @IBOutlet weak var toggleViewModeButton: UIButton! {
        didSet {
            toggleViewModeButton?.isHidden = true
        }
    }
    @IBAction func toggleViewModeButtonTapped(_ sender: UIButton) {
        delegate?.ingredientsFullTableViewCell(self, receivedTapOn: toggleViewModeButton)
    }
    
    private func setTextViewClearButton() {
        clearTextViewButton?.isHidden = !editMode
    }

    private func setupTextView() {
        // the textView might not be initialised
        guard textView != nil else { return }

        
        textView?.layer.borderWidth = 0.5
        textView?.delegate = delegate as? UITextViewDelegate
        textView?.tag = textViewTag
        textView?.isEditable = editMode

        if editMode {
            textView?.backgroundColor = UIColor.groupTableViewBackground
            textView?.layer.cornerRadius = 5
            textView?.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            textView?.clipsToBounds = true
            textView?.isScrollEnabled = true
            toggleViewModeButton?.isHidden = true
        } else {
            setButtonOrDoubletap(buttonNotDoubleTap)
            textView?.backgroundColor = UIColor.white
            textView?.layer.borderColor = UIColor.white.cgColor
            textView?.isScrollEnabled = false
            toggleViewModeButton?.isHidden = !isMultilingual
        }
        
        if editMode {
            if unAttributedIngredients.count > 0 {
                // needed to reset the color of the text. It is not actually shown.
                textView?.attributedText = NSMutableAttributedString(string: "fake text", attributes: [NSAttributedString.Key.foregroundColor : UIColor.black,  NSAttributedString.Key.font: UIFont.systemFont(ofSize: (textView.font?.pointSize)!)])
                textView?.text = unAttributedIngredients
            } else {
                textView?.text = ""
            }
            // print(textView?.text, self.frame.size, textView.frame.size)
            // let fixedWidth = self.frame.size.width - 20.0 - 32.0
            // let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            // textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
            // print(textView?.text, self.frame.size, textView.frame.size)
            // textView?.sizeToFit() this allows for incompatible widths
            // textView?.removeGestureRecognizer(tapGestureRecognizer)
        } else {
            if attributedIngredients.length > 0 {
                textView?.attributedText = attributedIngredients
            } else {
                textView?.text = Constants.NoIngredientsText
            }
            textView?.sizeToFit()
        }
        // self.frame.size.height = textView.frame.size.height
    }
    
    var editMode: Bool = false {
        didSet {
            setupTextView()
            setTextViewClearButton()
        }
    }

    var delegate: IngredientsFullCellDelegate? = nil {
        didSet {
            if delegate != nil && delegate! is UITextViewDelegate {
                textView.delegate = delegate as? UITextViewDelegate
            }
        }
    }
    
    var textViewTag: Int = 0
    
    var isMultilingual = false {
        didSet {
            toggleViewModeButton?.isHidden = !isMultilingual
        }
    }
    
    var buttonNotDoubleTap: Bool = true

    var ingredients: String? = nil {
        didSet {
            if let text = ingredients {
                if !text.isEmpty {
                    // defined the attributes for allergen text
                    let fontSize = (textView.font?.pointSize)!
                    // let currentFont = (textView.font?.fontName)!
                    // textView.font = UIFont(name: ()!, size: fontSize)!

                    let allergenAttributes = [NSAttributedString.Key.foregroundColor : UIColor.red, NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
                    let noAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black,  NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
                    // create a attributable string
                    let myString = NSMutableAttributedString(string: "", attributes: noAttributes)
                    let components = text.components(separatedBy: "_")
                    for (index, component) in components.enumerated() {
                        // if the text starts with a "_", then there will be an empty string component
                        let (_, fraction) = modf(Double(index)/2.0)
                        if (fraction) > 0 {
                            let attributedString = NSAttributedString(string: component, attributes: allergenAttributes)
                            myString.append(attributedString)
                        } else {
                            let attributedString = NSAttributedString(string: component, attributes: noAttributes)
                            myString.append(attributedString)
                        }
                    }
                    if  (text.unbalancedDelimiters()) ||
                        (text.oddNumberOfString("_")) {
                        let attributedString = NSAttributedString(string: Constants.UnbalancedWarning, attributes: noAttributes)
                        myString.append(attributedString)
                    }
                    attributedIngredients = myString
                    unAttributedIngredients = text
                } else {
                    attributedIngredients = NSMutableAttributedString.init(string: "")
                    unAttributedIngredients = ""
                }
            } else {
                attributedIngredients = NSMutableAttributedString.init(string: "")
                unAttributedIngredients = ""
            }
            setupTextView()
        }
    }
    
    private var attributedIngredients = NSMutableAttributedString()
    
    private var unAttributedIngredients: String = ""
    
    @objc func ingredientsTapped() {
        delegate?.ingredientsFullTableViewCell(self, receivedActionOn: textView)
    }

    private func setButtonOrDoubletap(_ button:Bool?) {
        guard let validButton = button else { return }
        if validButton {
            toggleViewModeButton?.isHidden = !validButton
        } else {
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProductNameTableViewCell.nameTapped))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            doubleTapGestureRecognizer.delaysTouchesBegan = true      //Important to add
            doubleTapGestureRecognizer.cancelsTouchesInView = false
            textView?.addGestureRecognizer(doubleTapGestureRecognizer)
        }
    }
    
}

extension String {
    
    func unbalancedDelimiters() -> Bool {
        return (self.unbalanced("(", endDelimiter: ")")) ||
            (self.unbalanced("{", endDelimiter: "}")) ||
            (self.unbalanced("[", endDelimiter: "]"))
    }
    
    func unbalanced(_ startDelimiter: String, endDelimiter: String) -> Bool {
        return (self.difference(startDelimiter, endDelimiter: endDelimiter) != 0)
    }

    func difference(_ startDelimiter: String, endDelimiter: String) -> Int {
        return self.components(separatedBy: startDelimiter).count - self.components(separatedBy: endDelimiter).count
    }
    
    func oddNumberOfString(_ testString: String) -> Bool {
        let (_, fraction) = modf(Double(self.components(separatedBy: testString).count-1)/2.0)
        return (fraction > 0)
    }
}
