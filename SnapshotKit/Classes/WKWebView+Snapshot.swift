//
//  WKWebView+Snapshot.swift
//  SnapshotKit
//
//  Created by York on 2018/9/9.
//

import UIKit
import WebKit

private var SnapshotKit_ProgressBlock: String = "SnapshotKit_ProgressBlock"

extension WKWebView {
    
    var progressBlock: ((Int, Int) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &SnapshotKit_ProgressBlock) as? ((Int, Int) -> Void)
        }
        set(newValue) {
            objc_setAssociatedObject(self, &SnapshotKit_ProgressBlock, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override
    public func takeSnapshotOfVisibleContent() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)

        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    override
    public func takeSnapshotOfFullContent() -> UIImage? {
        let renderer = WebViewPrintPageRenderer.init(formatter: self.viewPrintFormatter(), contentSize: self.scrollView.contentSize)
        let image = renderer.printContentToImage()
        return image
    }

    override
    public func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((UIImage?) -> Void)) {
        
        let originalOffset = self.scrollView.contentOffset

        // 当contentSize.height<bounds.height时，保证至少有1页的内容绘制
        var pageNum = 1
        if self.scrollView.contentSize.height > self.scrollView.bounds.height {
            pageNum = Int(floorf(Float(self.scrollView.contentSize.height / self.scrollView.bounds.height)))
        }

        self.loadPageContent(0, maxIndex: pageNum, completion: {
            self.scrollView.contentOffset = CGPoint.zero
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [unowned self] in
                let renderer = WebViewPrintPageRenderer.init(formatter: self.viewPrintFormatter(), contentSize: self.scrollView.contentSize)
                let image = renderer.printContentToImage()
                self.scrollView.contentOffset = originalOffset
                
                completion(image)
            }
        })
    }

    fileprivate func loadPageContent(_ index: Int, maxIndex: Int, completion: @escaping () -> Void) {
        self.scrollView.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * self.scrollView.frame.size.height), animated: false)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            if index < maxIndex {
                self.progressBlock?(index+1, maxIndex)
                self.loadPageContent(index + 1, maxIndex: maxIndex, completion: completion)
            }else{
                completion()
            }
        }
    }
    
    public func asyncTakeSnapshotOfFullContent(progress: @escaping ((Int, Int) -> Void), _ completion: @escaping ((UIImage?) -> Void)) {
        self.isShoting = true
        self.progressBlock = progress
        // Put a fake Cover of View
        let snapShotView = self.snapshotView(afterScreenUpdates: true)
        snapShotView?.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: (snapShotView?.frame.size.width)!, height: (snapShotView?.frame.size.height)!)
        self.superview?.addSubview(snapShotView!)
        let shadowView = UIView()
        shadowView.frame = snapShotView?.bounds ?? .zero
        shadowView.backgroundColor = .init(white: 1, alpha: 0.3)
        snapShotView?.addSubview(shadowView)
        
        let originalOffset = self.scrollView.contentOffset

        // 当contentSize.height<bounds.height时，保证至少有1页的内容绘制
        var pageNum = 1
        if self.scrollView.contentSize.height > self.scrollView.bounds.height {
            pageNum = Int(floorf(Float(self.scrollView.contentSize.height / self.scrollView.bounds.height)))
        }

        self.loadPageContent(0, maxIndex: pageNum, completion: {
            self.scrollView.contentOffset = CGPoint.zero
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [unowned self] in
                let renderer = WebViewPrintPageRenderer.init(formatter: self.viewPrintFormatter(), contentSize: self.scrollView.contentSize)
                let image = renderer.printContentToImage()
                self.scrollView.contentOffset = originalOffset
                
                shadowView.removeFromSuperview()
                snapShotView?.removeFromSuperview()
                self.isShoting = false
                
                completion(image)
            }
        })
    }
}
