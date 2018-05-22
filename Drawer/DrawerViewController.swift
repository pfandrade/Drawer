//
//  DrawerViewController.swift
//  Drawer
//
//  Created by Paulo Andrade on 05/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit

private class DrawerContainerView: UIView {
    
    lazy var drawerMaskingView: UIView = { () -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.black.cgColor
        shapeLayer.path = path?.cgPath
        view.layer.mask = shapeLayer
        return view
    }()
    
    var path: UIBezierPath? {
        didSet {
            layer.shadowPath = path?.cgPath
            (drawerMaskingView.layer.mask as! CAShapeLayer).path = path?.cgPath
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let path = path else {
            return super.point(inside: point, with: event)
        }
        return path.contains(point)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: UIViewNoIntrinsicMetric)
    }
}

public class DrawerViewController: UIViewController, UIGestureRecognizerDelegate {

    @objc public private(set) var mainViewController: UIViewController? {
        willSet {
            if let mainVC = mainViewController {
                prepareViewControllerForRemoval(mainVC)
                mainVC.willMove(toParentViewController: nil)
                mainVC.removeFromParentViewController()
            }
        }
        didSet {
            if let mainVC = mainViewController {
                mainVC.willMove(toParentViewController: self)
                self.addChildViewController(mainVC)
                if isViewLoaded {
                    addView(from: mainVC, asSubviewOf: self.view)
                }
            }
        }
    }
    @objc public var drawerContentViewController: UIViewController? {
        willSet {
            if let drawerContent = drawerContentViewController {
                prepareViewControllerForRemoval(drawerContent)
                drawerContent.willMove(toParentViewController: nil)
                drawerContent.removeFromParentViewController()
            }
        }
        didSet {
            if let drawerContent = drawerContentViewController {
                drawerContent.willMove(toParentViewController: self)
                self.addChildViewController(drawerContent)
                if isViewLoaded {
                    addView(from: drawerContent, asSubviewOf: self.drawerMaskingView)
                }
            }
        }
    }
    
    @objc public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc public convenience init(mainViewController: UIViewController) {
        self.init()
        self.mainViewController = mainViewController
        mainViewController.willMove(toParentViewController: self)
        self.addChildViewController(mainViewController)

    }
    
    @objc public convenience init(mainViewController: UIViewController, drawerContentViewController: UIViewController) {
        self.init(mainViewController: mainViewController)
        self.drawerContentViewController = drawerContentViewController
        drawerContentViewController.willMove(toParentViewController: self)
        self.addChildViewController(drawerContentViewController)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public var drawerContainerView: UIView {
        return _drawerContainerView
    }
    
    @objc public private(set) lazy var dimmingView: UIView = { () -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGR)
        return view
    }()
    
    
    private lazy var _drawerContainerView: DrawerContainerView = { () -> DrawerContainerView in
        let view = DrawerContainerView()
        view.backgroundColor = UIColor.clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -1)
        view.layer.shadowOpacity = 0.2
        return view
    }()
    
    private var drawerMaskingView: UIView {
        return _drawerContainerView.drawerMaskingView
    }
    
    private var drawerContainerHeightConstraint: NSLayoutConstraint?
    private var drawerContainerLeftConstraint: NSLayoutConstraint?
    private var drawerContainerRightConstraint: NSLayoutConstraint?
    private var drawerContainerMaxWidthConstraint: NSLayoutConstraint?
    
    open override func loadView() {
        let view = UIView()
        
        // add the dimming view
        view.addSubview(dimmingView)
        setupConstraintsToFill(view: view, with: dimmingView)
        
        // add the drawer container
        let drawerContainer = drawerContainerView
        let drawerMask = drawerMaskingView
        drawerContainer.addSubview(drawerMask)
        setupConstraintsToFill(view: drawerContainer, with: drawerMask)
        
        // setup drawer container constraints
        view.addSubview(drawerContainer)
        drawerContainer.translatesAutoresizingMaskIntoConstraints = false
        drawerContainer.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        let centerConstraint = drawerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        centerConstraint.priority = .defaultLow
        centerConstraint.isActive = true
        
        drawerContainerLeftConstraint = drawerContainer.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor)
        drawerContainerRightConstraint = drawerContainer.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor)
        drawerContainerHeightConstraint = drawerContainer.heightAnchor.constraint(equalTo: view.heightAnchor)
        drawerContainerHeightConstraint?.priority = UILayoutPriority(rawValue: 900)
        drawerContainerMaxWidthConstraint = drawerContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxDrawerWidth)
        
        drawerContainerLeftConstraint?.isActive = true
        drawerContainerRightConstraint?.isActive = true
        drawerContainerHeightConstraint?.isActive = true
        drawerContainerMaxWidthConstraint?.isActive = true
        
        // add the panning gesture recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delaysTouchesBegan = false
        panGestureRecognizer.delaysTouchesEnded = false
        view.addGestureRecognizer(panGestureRecognizer)
        
        self.view = view
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if let mainVC = mainViewController {
            addView(from: mainVC, asSubviewOf: self.view)
        }
        
        if let drawerContent = drawerContentViewController {
            addView(from: drawerContent, asSubviewOf: self.drawerMaskingView)
        }
        else {
            moveDrawerOffscreen(animated: false)
        }
        updateDimmingView(for: currentDrawerOffset)
    }
    
    override open func updateViewConstraints() {
        drawerContainerHeightConstraint?.constant = max(-view.frame.height, bottowOverflowHeight - drawerInsets.top);
        drawerContainerRightConstraint?.constant = -drawerInsets.right
        drawerContainerLeftConstraint?.constant = drawerInsets.left
        drawerContainerMaxWidthConstraint?.constant = maxDrawerWidth
        
        if pinDrawerToEdge.contains([.left]) {
            updateConstraintsToPinDrawerLeft()
        } else if pinDrawerToEdge.contains([.right]) {
            updateConstraintsToPinDrawerRight()
        } else {
            updateConstraintsToCenterDrawer()
        }
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // when we layout we must update the drawer container mask and shadow path
        
        let clippingPath: UIBezierPath
        if let drawerContent = drawerContentProvider,
            let path = drawerContent.clippingPathForDrawer?(self, in: drawerContainerView.bounds) {
            clippingPath = path
        }
        else {
            clippingPath = UIBezierPath(roundedRect: drawerContainerView.bounds,
                                        byRoundingCorners: [.topLeft, .topRight],
                                        cornerRadii:CGSize(width: drawerCornerRadius, height: drawerCornerRadius))
        }

        _drawerContainerView.path = clippingPath
        
        updateDimmingView(for: currentDrawerOffset)
    }
    
    @available(iOS 11.0, *)
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        invalidateDrawerAnchors()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        drawerContentProvider?.updateDrawer?(self, for: size)
        if !draggingDrawer {
            coordinator.animate(alongsideTransition: { (context) in
                self.moveDrawerToClosestAnchor()
            }, completion: nil)
            
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isDrawerOffscreen {
            moveDrawerToClosestAnchor(animated: animated)
        }
    }
    
    
    // forward our navigation item to the main view controller
    open override var navigationItem: UINavigationItem {
        return mainViewController?.navigationItem  ?? super.navigationItem
    }

    // MARK:- Configuration
    
    // the minimum distance the drawer should keep to the left, right & top margins
    // the bottom value is ignored, instead the first value of drawerAnchors is used
    @objc public var drawerInsets: UIEdgeInsets = UIEdgeInsetsMake(60.0, 0, 0, 0) {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
                if !draggingDrawer && !isDrawerOffscreen {
                    moveDrawerToClosestAnchor()
                }
            }
        }
    }
    
    // the drawer anchor positions measured from the bottom in points
    // all positions will be capped to the maximum drawer offset given by the this controller's view height and the top drawerInset
    // you can use a large value such as CGFloat.greatestFiniteMagnitude specify an anchor at the heighest possible value
    @objc public var drawerAnchors: [CGFloat] = [64.0, 250.0, CGFloat.greatestFiniteMagnitude] {
        didSet {
            guard drawerAnchors.count > 0 else {
                fatalError("There must be at least one anchor value")
            }
            if isViewLoaded && !draggingDrawer && !isDrawerOffscreen {
                moveDrawerToClosestAnchor()
            }
        }
    }
    
    // this value is added to the height of the drawer to make sure
    // this view controller's view doesn't show behind the drawer when animating with a spring effect
    @objc public var bottowOverflowHeight: CGFloat = 20 {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    // the corner radius given to the top/left and top/right corners of the view container the drawer content
    @objc public var drawerCornerRadius: CGFloat = 14.0 {
        didSet {
            if isViewLoaded {
                self.view.setNeedsLayout()
            }
        }
    }
    
    @objc public var dimBackgroundStartingAtOffset: CGFloat = 250 {
        didSet {
            updateDimmingView(for: currentDrawerOffset)
        }
    }
    
    @objc public var maxDrawerWidth: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    // only left,right allowed
    @objc public var pinDrawerToEdge: UIRectEdge = UIRectEdge.left {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    // MARK:- Public API
    
    @objc(moveDrawerToLowestAnchorAnimated:)
    open func moveDrawerToLowestAnchor(animated: Bool) {
        moveDrawer(to: effectiveDrawerAnchors.min() ?? 0.0, animated: animated)
    }
    @objc(moveDrawerToHighestAnchorAnimated:)
    open func moveDrawerToHighestAnchor(animated: Bool) {
        moveDrawer(to: effectiveDrawerAnchors.max() ?? CGFloat.greatestFiniteMagnitude, animated: animated)
    }
    
    @objc open func moveDrawerToAnchor(at offset: CGFloat, animated: Bool) {
        let target = targetAnchor(for: offset)
        moveDrawer(to: target, animated: animated)
    }
    
    @objc(moveDrawerOffscreeAnimated:)
    open func moveDrawerOffscreen(animated: Bool) {
        moveDrawer(to: offscreenDrawerOffset, animated: animated)
    }
    
    @objc public var isDrawerOffscreen: Bool {
        return currentDrawerOffset < 0
    }
    
    @objc public func invalidateDrawerAnchors() {
        if !draggingDrawer && !isDrawerOffscreen && isViewLoaded {
            moveDrawerToClosestAnchor(animated: self.view.window != nil)
        }
    }
    
    // MARK: - Gestures
    
    // MARK: tap
    
    @objc private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard !isDrawerOffscreen else {
            return
        }
        
        if gestureRecognizer.state == .ended {
            let target = effectiveDrawerAnchors.sorted().reversed().first { $0 <= dimBackgroundStartingAtOffset } ?? 0.0
            moveDrawerToAnchor(at: target, animated: true)
        }
    }
    
    // MARK: pan
    @objc public private(set) var draggingDrawer = false
    private var drawerOffsetAtDragStart: CGFloat = 0
    private var touchBeganOnDrawer = false
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard !isDrawerOffscreen  else {
            return false
        }
        
        if let hitView = view.hitTest(touch.location(in: self.view), with: nil) {
            touchBeganOnDrawer = hitView.isDescendant(of: self.drawerContainerView)
        } else {
            touchBeganOnDrawer = false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // if a scrollview panning gesture recognizer is about to start inside our drawer we want to add ourselves as one of its targets
        if  let panGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer,
            let otherView = otherGestureRecognizer.view as? UIScrollView,
            otherView.isDescendant(of: self.drawerContainerView) {
            panGestureRecognizer.removeTarget(self, action: nil)
            panGestureRecognizer.addTarget(self, action: #selector(handleInternalScrollViewPanGesture(_:)))
        }
        
        // require any GR inside the drawer to fail before we can recognize
        return touchBeganOnDrawer
    }
    
    // handle our panning gesture recognizer
    // this is responsible for:
    // - gestures that start on the drawer and don't have another gesture recognizer contending with it. For example, if you touch down on the drawer handle.
    // - moving the drawer out of the way for gestures that start over our mainViewController's view and move over the drawer
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .possible: break
        case .began:
            drawerOffsetAtDragStart = currentDrawerOffset
            if touchBeganOnDrawer {
                if !draggingDrawer {
                    draggingDrawer = true
                    drawerContentProvider?.drawerDidBeginDragging?(self)
                }
            }
        case .changed:
            if touchBeganOnDrawer {
                let newOffset = drawerOffsetAtDragStart - gestureRecognizer.translation(in: self.view).y
                moveDrawer(to: newOffset)
            }
            else {
                let currentTouchOffset = self.view.frame.height - gestureRecognizer.location(in: self.view).y
                if currentTouchOffset < drawerOffsetAtDragStart {
                    moveDrawer(to: currentTouchOffset)
                    if !draggingDrawer {
                        draggingDrawer = true
                        drawerContentProvider?.drawerDidBeginDragging?(self)
                    }
                }
                else {
                    if currentDrawerOffset != drawerOffsetAtDragStart {
                        moveDrawer(to: drawerOffsetAtDragStart)
                    }
                    if draggingDrawer {
                        draggingDrawer = false
                        drawerContentProvider?.drawerDidEndDragging?(self, at: drawerOffsetAtDragStart)
                    }
                    
                }
            }
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            var target: CGFloat?
            if !effectiveDrawerAnchors.contains(currentDrawerOffset) {
                let velocity = gestureRecognizer.velocity(in: self.view).y
                target = targetAnchor(for: currentDrawerOffset, at: velocity)
                moveDrawer(to: target!, animated: true, velocity: velocity)
            }
            
            if draggingDrawer {
                if let anchor = target {
                    drawerContentProvider?.drawerDidEndDragging?(self, willAnimateTo: anchor)
                }
                else {
                    drawerContentProvider?.drawerDidEndDragging?(self, at: currentDrawerOffset)
                }
                draggingDrawer = false
            }
            
        }
    }
    
    
    private var scrollViewOffsetAtDragStart: CGPoint = .zero
    private var translationAtDragStart: CGPoint = .zero
    
    // when panning over a scrollview inside our drawer we might want to move the drawer up or down
    // depending on the current scrollview offset
    @objc private func handleInternalScrollViewPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let scrollView = gestureRecognizer.view as? UIScrollView else {
            return
        }

        switch gestureRecognizer.state {
        case .possible: break
        case .began: fallthrough
        case .changed:
            let translation = gestureRecognizer.translation(in: scrollView)
            let isScrollingDown = gestureRecognizer.velocity(in: scrollView).y > 0
            let shouldScrollDownDragDrawer = isScrollingDown && scrollView.contentOffset.y <= 0
            let shouldScrollUpDragDrawer = !isScrollingDown && self.currentDrawerOffset < (self.effectiveDrawerAnchors.max() ?? 0.0)
            
            if shouldScrollDownDragDrawer || shouldScrollUpDragDrawer {
                if !draggingDrawer {
                    drawerOffsetAtDragStart = currentDrawerOffset
                    translationAtDragStart = translation
                    scrollViewOffsetAtDragStart = scrollView.contentOffset
                    
                    draggingDrawer = true
                    drawerContentProvider?.drawerDidBeginDragging?(self)
                }
                
                
                let scrolledAmount = translation.y - translationAtDragStart.y
                self.moveDrawer(to: drawerOffsetAtDragStart - scrolledAmount)
                scrollView.contentOffset = scrollViewOffsetAtDragStart
                scrollView.showsVerticalScrollIndicator = false
            }
            else {
                if draggingDrawer {
                    drawerContentProvider?.drawerDidEndDragging?(self, at: currentDrawerOffset)
                    draggingDrawer = false
                }
                
                scrollView.showsVerticalScrollIndicator = true
            }
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            gestureRecognizer.removeTarget(self, action: nil)
            var target: CGFloat?
            
            if !effectiveDrawerAnchors.contains(currentDrawerOffset) {
                let velocity = gestureRecognizer.velocity(in: self.view).y
                target = targetAnchor(for: currentDrawerOffset, at: velocity)
                moveDrawer(to: target!, animated: true, velocity: velocity)
            }
            
            if draggingDrawer {
                if let anchor = target {
                    drawerContentProvider?.drawerDidEndDragging?(self, willAnimateTo: anchor)
                }
                else {
                    drawerContentProvider?.drawerDidEndDragging?(self, at: currentDrawerOffset)
                }
                draggingDrawer = false
            }
            
            scrollViewOffsetAtDragStart = .zero
            translationAtDragStart = .zero
        }
    }
    
    // MARK: aux
    var animating = false
    private var currentDrawerOffset: CGFloat {
        return -drawerContainerView.transform.ty
    }
    
    private var maxDrawerOffset: CGFloat {
        let viewHeight: CGFloat = self.isViewLoaded ? self.view.bounds.height : 480
        return viewHeight-drawerInsets.top
    }
    
    private let offscreenDrawerOffset: CGFloat = -50
    
    private var effectiveDrawerAnchors: [CGFloat] {
        var anchors = drawerAnchors
        if let dc = drawerContentProvider {
            let safeAreaInsets: UIEdgeInsets
            if #available(iOS 11.0, *) {
                safeAreaInsets = self.view.safeAreaInsets
            } else {
                safeAreaInsets = .zero
            }
            
            if let dcAnchors = dc.anchorsForDrawer?(self, consideringSafeAreaInsets: safeAreaInsets) {
                anchors = dcAnchors
            }
        }
        return anchors.map { min($0, maxDrawerOffset) }
    }
    
    private func moveDrawerToClosestAnchor(animated animate: Bool = false, velocity: CGFloat? = nil) {
        let anchor = targetAnchor(for: currentDrawerOffset, at: velocity)
        moveDrawer(to: anchor, animated: animate, velocity: velocity ?? 0.0)
    }
    
    private func moveDrawer(to offset: CGFloat, animated animate: Bool = false, velocity: CGFloat = 0.0) {
        let offset = min(offset, maxDrawerOffset)
        
        let updateTransformBlock = { () -> Void in
            self.drawerContainerView.transform = CGAffineTransform(translationX: 0, y: -offset)
            self.updateDimmingView(for: offset)
        }

        let finish = { (finished: Bool) -> Void in
            if finished && self.currentDrawerOffset < 0 {
                self.drawerContainerView.isHidden = true
            }
        }
        
        if offset >= 0 {
            self.drawerContainerView.isHidden = false
        }
        
        if (animate) {
            let distance = abs(currentDrawerOffset - offset)
            let initialVelocity = velocity / distance
            animating = true
            let duration = max(0.25, TimeInterval(0.25 * (distance/250)))
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: initialVelocity,
                           options: [.beginFromCurrentState],
                           animations: {
                            updateTransformBlock()
            }, completion: { finished -> Void in
                self.animating = false
                finish(finished)
            })
        }
        else {
            updateTransformBlock()
            finish(true)
        }
    
    }
    
    private func targetAnchor(for offset: CGFloat, at velocity: CGFloat? = nil) -> CGFloat {
        var offset = offset
        if var v = velocity {
            // if we consider an anchor is only able to "grab" the drawer if it's crusing at no more than
            // X p/s we can calculate where the drawer would be if it decelerated at Y rate
            // X and Y were chosen to feel "natural"
            let x: CGFloat = 1000
            let y: CGFloat = 0.1
            while abs(v) > x {
                v *= y
                offset -= v
            }
        }
        let distances = effectiveDrawerAnchors.map { ($0, $0 - offset) }
        return distances.min { (a, b) -> Bool in return abs(a.1) < abs(b.1) }?.0 ?? 0.0
    }
    
    private func setupConstraintsToFill(view: UIView, with subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        subview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func prepareViewControllerForRemoval(_ viewController: UIViewController) {
        guard childViewControllers.contains(viewController) else {
            return
        }
        if isViewLoaded && viewController.isViewLoaded && viewController.view.superview == self.view {
            let shouldPerformAppearanceTransition = self.view.window != nil
            if shouldPerformAppearanceTransition {
                viewController.beginAppearanceTransition(false, animated: false)
            }
            viewController.view.removeFromSuperview()
            if shouldPerformAppearanceTransition {
                viewController.endAppearanceTransition()
            }
        }
    }
    
    private func addView(from viewController: UIViewController, asSubviewOf parentView: UIView) {
        guard let view = viewController.view else {
            return
        }
        let shouldPerformAppearanceTransition = parentView.window != nil
        if shouldPerformAppearanceTransition {
            viewController.beginAppearanceTransition(true, animated: false)
        }
        parentView.insertSubview(view, at: 0)
        setupConstraintsToFill(view: parentView, with: view)
        if shouldPerformAppearanceTransition {
            viewController.endAppearanceTransition()
        }
    }
    
    private func updateDimmingView(for offset: CGFloat) {
        let delta = max(offset, 0)-dimBackgroundStartingAtOffset
        let maxDelta = max(maxDrawerOffset-dimBackgroundStartingAtOffset, 0)
        if maxDelta > 0 {
            let ratio = delta/maxDelta
            dimmingView.alpha = min(max(ratio, 0), 1)
        }
        else {
            dimmingView.alpha = 0.0
        }
    }
    
    
    private func updateConstraintsToPinDrawerLeft() {
        if drawerContainerLeftConstraint?.relation != NSLayoutRelation.equal {
            drawerContainerLeftConstraint?.isActive = false
            drawerContainerLeftConstraint = drawerContainerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: drawerInsets.left)
            drawerContainerLeftConstraint?.isActive = true
        }
        if drawerContainerRightConstraint?.relation != NSLayoutRelation.lessThanOrEqual {
            drawerContainerRightConstraint?.isActive = false
            drawerContainerRightConstraint = drawerContainerView.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -drawerInsets.right)
            drawerContainerRightConstraint?.isActive = true
        }
    }
    
    private func updateConstraintsToPinDrawerRight() {
        if drawerContainerRightConstraint?.relation != NSLayoutRelation.equal {
            drawerContainerRightConstraint?.isActive = false
            drawerContainerRightConstraint = drawerContainerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -drawerInsets.right)
            drawerContainerRightConstraint?.isActive = true
        }
        if drawerContainerLeftConstraint?.relation != NSLayoutRelation.greaterThanOrEqual {
            drawerContainerLeftConstraint?.isActive = false
            drawerContainerLeftConstraint = drawerContainerView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: drawerInsets.left)
            drawerContainerLeftConstraint?.isActive = true
        }
    }
    
    private func updateConstraintsToCenterDrawer() {
        if drawerContainerLeftConstraint?.relation != NSLayoutRelation.greaterThanOrEqual {
            drawerContainerLeftConstraint?.isActive = false
            drawerContainerLeftConstraint = drawerContainerView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: drawerInsets.left)
            drawerContainerLeftConstraint?.isActive = true
        }
        if drawerContainerRightConstraint?.relation != NSLayoutRelation.lessThanOrEqual {
            drawerContainerRightConstraint?.isActive = false
            drawerContainerRightConstraint = drawerContainerView.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -drawerInsets.right)
            drawerContainerRightConstraint?.isActive = true
        }
    }
    
    private var drawerContentProvider: DrawerContentProvider? {
        return drawerContentViewController as? DrawerContentProvider
    }
}
