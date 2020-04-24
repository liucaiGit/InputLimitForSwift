//
//  BWTextField.swift
//  SwiftDemo
//
//  Created by 熊本丸 on 2019/11/13.
//  Copyright © 2019 xiongbenwan. All rights reserved.
//

import UIKit

//输入框弹出选项
struct BWTextMenuOptions: OptionSet {
    let rawValue: UInt

    static let none = BWTextMenuOptions(rawValue: 1 << 0)
    static let copy = BWTextMenuOptions(rawValue: 1 << 1)
    static let select = BWTextMenuOptions(rawValue: 1 << 2)
    static let selectAll = BWTextMenuOptions(rawValue: 1 << 3)
    static let paste = BWTextMenuOptions(rawValue: 1 << 4)
}

@objc protocol BWTextFieldDelegate: NSObjectProtocol {
    
    @objc optional func bwTextFieldShouldBeginEditing(textField: BWTextField) -> Bool
    
    @objc optional func bwTextFieldDidBeginEditing(textField: BWTextField) -> Void
    
    @objc optional func bwTextFieldShouldEndEditing(textField: BWTextField) -> Bool
    
    @objc optional func bwTextFieldDidEndEditing(textField: BWTextField) -> Void
    
    @objc optional func bwTextField(textField: BWTextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    
    @objc optional func bwTextFieldShouldClear(textField: BWTextField) -> Bool
    
    @objc optional func bwTextFieldShouldReturn(textField: BWTextField) -> Bool
    
    @objc optional func bwTextFieldDidChanged(textFiled: BWTextField) -> Void
}

class BWTextField: BWBaseTextField {
    //最大输入字数
    var tfLimitNumber: Int = 0
    //是否进制系统表情输入
    var shouldForbidSystemEmoji: Bool = true
    //return键点击是否收回键盘
    var shouldRetunKeyDone: Bool = true
    //弹出框选项
    var menuOptions: BWTextMenuOptions = [.copy, .selectAll, .select, .paste]
    //代理
    weak var tfDelegate: BWTextFieldDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.shouldForbidSystemEmoji = false
        self.shouldRetunKeyDone = false
        self.addEditingChanged()
    }
    
    //弹出菜单栏
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if menuOptions.contains(.none) {
            return false
        }
        if self.text?.count ?? 0 <= 0 {
            if action == #selector(paste(_:)) && menuOptions.contains(.paste) {
                return true
            }
            return false
        }
        if (action == #selector(select(_:)) && menuOptions.contains(.select)) ||
            (action == #selector(selectAll(_:)) && menuOptions.contains(.selectAll)) ||
            (action == #selector(copy(_:)) && menuOptions.contains(.copy)) ||
            (action == #selector(paste(_:)) && menuOptions.contains(.paste)) {
            return true;
        }
        return false;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BWTextField: UITextFieldDelegate {

    func addEditingChanged() {
        self.addTarget(self, action: #selector(textFieldDidChanged(textField:)), for: UIControl.Event.editingChanged)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.tfDelegate?.bwTextFieldShouldBeginEditing?(textField: self) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.tfDelegate?.bwTextFieldDidEndEditing?(textField: self)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.tfDelegate?.bwTextFieldShouldEndEditing?(textField: self) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tfDelegate?.bwTextFieldDidBeginEditing?(textField: self)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.shouldRetunKeyDone == true {
            self.tfDelegate?.bwTextFieldShouldReturn?(textField: self)
            textField.resignFirstResponder()
            return false
        }
        return self.tfDelegate?.bwTextFieldShouldReturn?(textField: self) ?? true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //点击return键事件处理
        if string == "\n" {
            if self.shouldRetunKeyDone == true {
                textField.resignFirstResponder()
                return false                
            }
        }
        //禁止系统表情输入
        if textField.textInputMode?.primaryLanguage == nil || textField.textInputMode?.primaryLanguage == "emoji" {
            if self.shouldForbidSystemEmoji {
                return false
            }
        }
        //最大限制数量<=0  则不做输入限制
        if self.tfLimitNumber <= 0 {
            return true
        }
        //获取高亮部分 //如果有高亮且当前字数开始位置小于最大限制时允许输入
        if let markedRange: UITextRange = textField.markedTextRange {
            if textField.position(from: markedRange.start, offset: 0) != nil {
                let startOffset: Int = textField.offset(from: textField.beginningOfDocument, to: markedRange.start)
                let endOffet: Int = textField.offset(from: textField.beginningOfDocument, to: markedRange.end)
                let offetRange: NSRange = NSRange(location: startOffset, length: endOffet - startOffset)
                if offetRange.location < self.tfLimitNumber {
                    return true
                } else {
                    return false
                }
            }
        }
        return self.tfDelegate?.bwTextField?(textField: self, shouldChangeCharactersInRange: range, replacementString: string) ?? true
    }
    
    @objc func textFieldDidChanged(textField: BWTextField) {
        if self.tfLimitNumber <= 0 {
            self.bwTextFieldDidChanged(textFiled: textField)
            return
        }
        let lang: String = UITextInputMode.activeInputModes.first!.primaryLanguage ?? ""
        let text : String = textField.text ?? ""
        //存在高亮则不计算字符长度
        if let range = self.markedTextRange {
            //计算当前高亮长度
            let selectedLength: Int = self .offset(from: range.start, to: range.end)
            if selectedLength != 0 {
                return
            }
        }
        if lang == "zh-Hans" {
            if textField.markedTextRange == nil {
                if text.count >= self.tfLimitNumber {
                    let endIndex = text.index(text.startIndex, offsetBy: self.tfLimitNumber)
                    textField.text = String(text[text.startIndex..<endIndex])
                }
            }
        } else {
            if text.count >= self.tfLimitNumber {
                let endIndex = text.index(text.startIndex, offsetBy: self.tfLimitNumber)
                textField.text = String(text[text.startIndex..<endIndex])
            }
        }
        self .bwTextFieldDidChanged(textFiled: textField)
    }
    
    func bwTextFieldDidChanged(textFiled: BWTextField) -> Void {
        self.tfDelegate?.bwTextFieldDidChanged?(textFiled: textFiled)
    }
}
