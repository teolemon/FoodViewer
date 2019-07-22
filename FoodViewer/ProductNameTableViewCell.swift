//
//  ProductNameTableViewCell.swift
//  FoodViewer
//
//  Created by arnaud on 07/09/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import UIKit

protocol ProductNameCellDelegate: class {
    
    func productNameTableViewCell(_ sender: ProductNameTableViewCell, receivedDoubleTap textView:UITextView)
    
    func productNameTableViewCell(_ sender: ProductNameTableViewCell, receivedTapOn button:UIButton)
}

class ProductNameTableViewCell: UITableViewCell {
    
    var name: String? = nil {
        didSet {
            setName()
        }
    }
    
    var editMode: Bool = false {
        didSet {
            setTextViewStyle()
            setTextViewClearButton()
            setName()
        }
    }
    
    var delegate: ProductNameCellDelegate? = nil {
        didSet {
            nameTextView?.delegate = delegate as? UITextViewDelegate
        }
    }
    
    var isMultilingual = false {
        didSet {
            toggleViewModeButton?.isHidden = !isMultilingual
        }
    }
    
    var buttonNotDoubleTap: Bool = true {
        didSet {
            setButtonOrDoubletap(buttonNotDoubleTap)
        }
    }
    
    @IBOutlet weak var nameTextView: UITextView! {
        didSet {
            setTextViewStyle()
        }
    }
    
    @IBOutlet weak var clearTextViewButton: UIButton! {
        didSet {
            setTextViewClearButton()
        }
    }
    
    @IBAction func clearTextViewButtonTapped(_ sender: UIButton) {
        name = ""
    }
    
    @IBOutlet weak var toggleViewModeButton: UIButton! {
        didSet {
            toggleViewModeButton?.isHidden = buttonNotDoubleTap
        }
    }

    @IBAction func toggleViewModeButtonTapped(_ sender: UIButton) {
        delegate?.productNameTableViewCell(self, receivedTapOn: toggleViewModeButton)
    }
    
    private func setTextViewStyle() {
        nameTextView.layer.borderWidth = 0.5
        nameTextView?.delegate = delegate as? UITextViewDelegate
        nameTextView?.tag = tag
        nameTextView?.isEditable = editMode
        nameTextView?.isScrollEnabled = editMode
        nameTextView.backgroundColor = editMode ? UIColor.groupTableViewBackground : UIColor.white
        
        if editMode {
            nameTextView?.backgroundColor = UIColor.groupTableViewBackground
            nameTextView?.layer.cornerRadius = 5
            nameTextView?.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            nameTextView?.clipsToBounds = true
            toggleViewModeButton?.isHidden = true
            // nameTextField.removeGestureRecognizer(tapGestureRecognizer)
        } else {
            setButtonOrDoubletap(buttonNotDoubleTap)
            nameTextView?.layer.borderColor = UIColor.white.cgColor
            toggleViewModeButton?.isHidden = !isMultilingual
        }
        //print ("ProductNameTableViewCell: setTextView", self.frame)
        //if nameTextView?.text != nil && !nameTextView!.text!.isEmpty {
        //    nameTextView?.sizeToFit()
        //}
    }
    
    private func setTextViewClearButton() {
        clearTextViewButton?.isHidden = !editMode
    }
    
    private func setName() {
        nameTextView.text = (name != nil) && (name!.count > 0) ? name! :  ( editMode ? "" : TranslatableStrings.NoName )
    }
    
    override var tag: Int {
        didSet {
            nameTextView?.tag = tag
        }
    }

    @objc func nameTapped() {
        delegate?.productNameTableViewCell(self, receivedDoubleTap: nameTextView)
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
            nameTextView?.addGestureRecognizer(doubleTapGestureRecognizer)
        }
    }

}
