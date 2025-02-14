//
//  UIView+Snapshot.swift
//  SnapshotKit
//
//  Created by York on 2018/9/9.
//

import UIKit

private var SnapshotKit_IsShoting: String = "SnapshotKit_AssoKey_isShoting"

private var SnapshotKit_ProgressBlock: String = "SnapshotKit_ProgressBlock"

extension UIView: SnapshotKitProtocol {
    
    var isShoting:Bool! {
        get {
            let num = objc_getAssociatedObject(self, &SnapshotKit_IsShoting)
            if num == nil {
                return false
            }
            
            if let numObj = num as? NSNumber {
                return numObj.boolValue
            }else {
                return false
            }
        }
        set(newValue) {
            let num = NSNumber(value: newValue as Bool)
            objc_setAssociatedObject(self, &SnapshotKit_IsShoting, num, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var progressBlock: ((Int, Int) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &SnapshotKit_ProgressBlock) as? ((Int, Int) -> Void)
        }
        set(newValue) {
            objc_setAssociatedObject(self, &SnapshotKit_ProgressBlock, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc
    public func takeSnapshotOfVisibleContent() -> UIImage? {
        return self.takeSnapshotOfFullContent(for: self.bounds)
    }

    @objc
    public func takeSnapshotOfFullContent() -> UIImage? {
        return self.takeSnapshotOfFullContent(for: self.bounds)
    }

    @objc
    public func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            let image = self.takeSnapshotOfFullContent()
            completion(image)
        }
    }

    public func takeSnapshotOfFullContent(for croppingRect: CGRect) -> UIImage? {
        // floor(x): 如果参数是小数，则求最大的整数但不大于本身，如floor(3.001)=3.0
        // 由于 croppingView（要裁剪的子视图）的实际size，可能比获取到的size小（double精度问题导致这种差异），所以使用floor对获取到的size进行一次处理，使获取到的size不大于实际的size，以避免生成的图片底部会出现1px左右的黑线
        var backgroundColor = self.backgroundColor ?? UIColor.white
        // 若View为非透明且无圆角，则创建非透明的画布
        // 非透明的画布渲染速度比透明的画布要快
        let opaqueCanvas = (self.isOpaque && self.layer.cornerRadius == 0)
        // 对于透明的画布，使用白色作为底色
        if opaqueCanvas == false {
            backgroundColor = UIColor.white
        }
        let contentSize = CGSize.init(width: floor(croppingRect.size.width), height: floor(croppingRect.size.height))
        UIGraphicsBeginImageContextWithOptions(contentSize, opaqueCanvas, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.saveGState()
        context.clear(croppingRect)
        context.setFillColor(backgroundColor.cgColor)
        context.fill(croppingRect)
        context.translateBy(x: -croppingRect.origin.x, y: -croppingRect.origin.y)
        self.layer.render(in: context)
        context.restoreGState()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}


