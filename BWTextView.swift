//
//  BWTextView.swift
//  SwiftDemo
//
//  Created by 熊本丸 on 2019/11/14.
//  Copyright © 2019 xiongbenwan. All rights reserved.
//

import UIKit

@objc protocol BWTextViewDelegate {
    
    @objc optional func bwTextViewDidChanged(textView: BWTextView) -> Void
    
    @objc optional func bwTextViewShouldBeginEditing(textView: BWTextView) -> Bool
    
    @objc optional func bwTextViewShouldEndEditing(textView: BWTextView) -> Bool
    
    @objc optional func bwTextViewDidBeginEditing(textView: BWTextView) -> Void
    
    @objc optional func bwTextViewDidEndEditing(textView: BWTextView) -> Void
    
    @objc optional func bwTextView(textView: BWTextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
}

class BWTextView: BWBaseTextView {
    //输入字数限制
    var tvLimitNumber: Int = 0
    //是否进制系统表情输入
    var shouldForbidSystemEmoji: Bool = false
    //return键点击是否收回键盘
    var shouldRetunKeyDone: Bool = false
    //弹出框选项
    var menuOptions: BWTextMenuOptions = [.copy, .selectAll, .select, .paste]
    //代理
    var tvDelegate: BWTextViewDelegate?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.delegate = self
        self.shouldRetunKeyDone = false
        self.shouldForbidSystemEmoji = false
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

extension BWTextView: UITextViewDelegate {
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return self.tvDelegate?.bwTextViewShouldEndEditing?(textView: self) ?? true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.tvDelegate?.bwTextViewShouldBeginEditing?(textView: self) ?? true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.tvDelegate?.bwTextViewDidBeginEditing?(textView: self)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.tvDelegate?.bwTextViewDidEndEditing?(textView: self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //点击return键是否收回键盘
        if text == "\n" {
            if self.shouldRetunKeyDone == true {
                textView.resignFirstResponder()
                return false;
            }
        }
        //是否支持输入系统表情
        if textView.textInputMode?.primaryLanguage == nil || textView.textInputMode?.primaryLanguage == "emoji" {
            if self.shouldForbidSystemEmoji {
                return false
            }
        }
        //最大限制数量<=0  则不做输入限制
        if self.tvLimitNumber <= 0 {
            return self.tvDelegate?.bwTextView?(textView: self, shouldChangeTextInRange: range, replacementText: text) ?? true
        }
        //获取高亮部分 //如果有高亮且当前字数开始位置小于最大限制时允许输入
        if let markedRange: UITextRange = textView.markedTextRange {
            if textView.position(from: markedRange.start, offset: 0) != nil {
                let startOffset: Int = textView.offset(from: textView.beginningOfDocument, to: markedRange.start)
                let endOffet: Int = textView.offset(from: textView.beginningOfDocument, to: markedRange.end)
                let offetRange: NSRange = NSRange(location: startOffset, length: endOffet - startOffset)
                if offetRange.location < self.tvLimitNumber {
                    return true
                } else {
                    return false
                }
            }
        }
        return self.tvDelegate?.bwTextView?(textView: self, shouldChangeTextInRange: range, replacementText: text) ?? true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if self.tvLimitNumber <= 0 {
            self.tvDelegate?.bwTextViewDidChanged?(textView: self)
            return
        }
        let lang: String = UITextInputMode.activeInputModes.first!.primaryLanguage ?? ""
        let text : String = textView.text
        //存在高亮则不计算字符长度
        if let range = self.markedTextRange {
            //计算当前高亮长度
            let selectedLength: Int = self .offset(from: range.start, to: range.end)
            if selectedLength != 0 {
                return
            }
        }
        if lang == "zh-Hans" {
            if textView.markedTextRange == nil {
                if text.count >= self.tvLimitNumber {
                    let endIndex = text.index(text.startIndex, offsetBy: self.tvLimitNumber)
                    textView.text = String(text[text.startIndex..<endIndex])
                }
            }
        } else {
            if text.count >= self.tvLimitNumber {
                let endIndex = text.index(text.startIndex, offsetBy: self.tvLimitNumber)
                textView.text = String(text[text.startIndex..<endIndex])
            }
        }
        self.tvDelegate?.bwTextViewDidChanged?(textView: self)
    }
}

// MARK: - UITextView添加占位文字
//extension UITextView {
//    private struct placeholderRuntimeKey {
//        static let placeholderLabelKey = UnsafeRawPointer.init(bitPattern: "placeholderLabelKey".hashValue)
//    }
//    
//    override open func layoutSubviews() {
//        super.layoutSubviews()
//        self.layoutIfNeeded()
//        self.placeholderLabel.frame = CGRect.init(x: 0, y: 5, width: self.frame.width, height: 20)
//    }
//    
//    //占位文字
//    @IBInspectable public var placeholder: String {
//        get {
//            return self.placeholderLabel.text ?? ""
//        }
//        set {
//            self.placeholderLabel.text = newValue
//        }
//    }
//    //占位文字
//    @IBInspectable public var attributePlaceholder: NSAttributedString {
//        get {
//            return self.placeholderLabel.attributedText ?? NSAttributedString.init()
//        }
//        set {
//            self.placeholderLabel.attributedText = newValue
//        }
//    }
//    //占位颜色
//    @IBInspectable public var placeholderColor: UIColor {
//        get {
//            return self.placeholderLabel.textColor
//        }
//        set {
//            self.placeholderLabel.textColor = newValue
//        }
//    }
//    
//    private var placeholderLabel: UILabel  {
//        get {
//            var label = objc_getAssociatedObject(self, UITextView.placeholderRuntimeKey.placeholderLabelKey!) as? UILabel
//            if label == nil {
//                if self.font == nil {
//                    self.font = UIFont.systemFont(ofSize: 14)
//                }
//                label = UILabel.init(frame: CGRect.init(x: 0, y: 5, width: self.frame.width, height: 20))
//                label?.numberOfLines = 0
//                label?.font = self.font
//                label?.textColor = UIColor.init(hexColorString: "#999999")
//                self.addSubview(label!)
//                objc_setAssociatedObject(self, UITextView.placeholderRuntimeKey.placeholderLabelKey!, label!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                self.sendSubviewToBack(label!)
//            }
//            return label!
//        }
//        set {
//            objc_setAssociatedObject(self, UITextView.placeholderRuntimeKey.placeholderLabelKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    func updataPlaceholderLabel() {
//        
//    }
//}
