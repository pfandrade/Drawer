//
//  DrawerViewController.swift
//  Drawer
//
//  Created by Paulo Andrade on 05/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit

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
    
    public private(set) lazy var drawerContainerView: UIView = { () -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -1)
        view.layer.shadowOpacity = 0.2
        return view
    }()
    
    private lazy var drawerMaskingView: UIView = { () -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.black.cgColor
        view.layer.mask = shapeLayer
        return view
    }()
    
    private var drawerContainerHeightConstraint: NSLayoutConstraint?
    private var drawerContainerLeftConstraint: NSLayoutConstraint?
    private var drawerContainerRightConstraint: NSLayoutConstraint?
    
    open override func loadView() {
        let view = UIView()
        
        // add the drawer container
        let drawerContainer = drawerContainerView
        let drawerMask = drawerMaskingView
        drawerContainer.addSubview(drawerMask)
        setupConstraintsToFill(view: drawerContainer, with: drawerMask)
        
        // setup drawer container constraints
        view.addSubview(drawerContainer)
        drawerContainer.translatesAutoresizingMaskIntoConstraints = false
        drawerContainer.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        drawerContainerLeftConstraint = drawerContainer.leftAnchor.constraint(equalTo: view.leftAnchor)
        drawerContainerRightConstraint = drawerContainer.rightAnchor.constraint(equalTo: view.rightAnchor)
        drawerContainerHeightConstraint = drawerContainer.heightAnchor.constraint(equalTo: view.heightAnchor)
        drawerContainerLeftConstraint?.isActive = true
        drawerContainerRightConstraint?.isActive = true
        drawerContainerHeightConstraint?.isActive = true
        
        // add the panning gesture recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delaysTouchesBegan = false
        panGestureRecognizer.delaysTouchesEnded = false
        view.addGestureRecognizer(panGestureRecognizer)
        
        self.drawerContainerView = drawerContainer
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
    }
    
    override open func updateViewConstraints() {
        drawerContainerHeightConstraint?.constant = bottowOverflowHeight - drawerInsets.top;
        drawerContainerRightConstraint?.constant = -drawerInsets.right
        drawerContainerLeftConstraint?.constant = drawerInsets.left
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // when we layout we must update the drawer container mask and shadow path
        let path = UIBezierPath(roundedRect: drawerContainerView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii:CGSize(width: drawerCornerRadius, height: drawerCornerRadius)).cgPath
        drawerContainerView.layer.shadowPath = path
        (drawerMaskingView.layer.mask as! CAShapeLayer).path = path
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
    // the bottom value is ignored
    @objc public var drawerInsets: UIEdgeInsets = UIEdgeInsetsMake(60.0, 0, 0, 0) {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
                if !draggingDrawer {
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
            if isViewLoaded && !draggingDrawer {
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
    
    // MARK:- Public API
    
    @objc(moveDrawerToLowestAnchorAnimated:)
    open func moveDrawerToLowestAnchor(animated: Bool) {
        moveDrawer(to: cappedDrawerAnchors.min() ?? 0.0, animated: animated)
    }
    @objc(moveDrawerToHighestAnchorAnimated:)
    open func moveDrawerToHighestAnchor(animated: Bool) {
        moveDrawer(to: cappedDrawerAnchors.max() ?? CGFloat.greatestFiniteMagnitude, animated: animated)
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
    
    // MARK: - Handling pan gesture
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
        
        // if a scrollview panning gesture recognizer is about to start inside our drawer we want to add ourselves as one of its targets
        if  let panGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer,
            let otherView = otherGestureRecognizer.view as? UIScrollView,
            otherView.isDescendant(of: self.drawerContainerView) {
            panGestureRecognizer.removeTarget(self, action: nil)
            panGestureRecognizer.addTarget(self, action: #selector(handleInternalScrollViewPanGesture(_:)))
        }
        
        // prevent our panning gesture recognizer from doing anything if the gesture starts inside the drawer
        return !touchBeganOnDrawer
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
                draggingDrawer = true
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
                    draggingDrawer = true
                }
                else {
                    if currentDrawerOffset != drawerOffsetAtDragStart {
                        moveDrawer(to: drawerOffsetAtDragStart)
                    }
                    draggingDrawer = false
                }
            }
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            if !cappedDrawerAnchors.contains(currentDrawerOffset) {
                moveDrawerToClosestAnchor(animated: true, velocity: gestureRecognizer.velocity(in: self.view).y)
            }
            draggingDrawer = false
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
        case .began: break
        case .changed:
            let translation = gestureRecognizer.translation(in: scrollView)
            let isScrollingDown = gestureRecognizer.velocity(in: scrollView).y > 0
            let shouldScrollDownDragDrawer = isScrollingDown && scrollView.contentOffset.y <= 0
            let shouldScrollUpDragDrawer = !isScrollingDown && self.currentDrawerOffset < (self.cappedDrawerAnchors.max() ?? 0.0)
            
            if shouldScrollDownDragDrawer || shouldScrollUpDragDrawer {
                if !draggingDrawer {
                    drawerOffsetAtDragStart = currentDrawerOffset
                    translationAtDragStart = translation
                    scrollViewOffsetAtDragStart = scrollView.contentOffset
                }
                draggingDrawer = true
                
                let scrolledAmount = translation.y - translationAtDragStart.y
                self.moveDrawer(to: drawerOffsetAtDragStart - scrolledAmount)
                scrollView.contentOffset = scrollViewOffsetAtDragStart
                scrollView.showsVerticalScrollIndicator = false
            }
            else {
                draggingDrawer = false
                scrollView.showsVerticalScrollIndicator = true
            }
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            gestureRecognizer.removeTarget(self, action: nil)
            
            if !cappedDrawerAnchors.contains(currentDrawerOffset) {
                moveDrawerToClosestAnchor(animated: true, velocity: gestureRecognizer.velocity(in: scrollView).y)
            }
            draggingDrawer = false
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
    
    private var cappedDrawerAnchors: [CGFloat] {
        return drawerAnchors.map { min($0, maxDrawerOffset) }
    }
    
    private func moveDrawerToClosestAnchor(animated animate: Bool = false, velocity: CGFloat? = nil) {
        let anchor = targetAnchor(for: currentDrawerOffset, at: velocity)
        moveDrawer(to: anchor, animated: animate, velocity: velocity ?? 0.0)
    }
    
    private func moveDrawer(to offset: CGFloat, animated animate: Bool = false, velocity: CGFloat = 0.0) {
        let offset = min(offset, maxDrawerOffset)
        
        let updateTransformBlock = { () -> Void in
            self.drawerContainerView.transform = CGAffineTransform(translationX: 0, y: -offset)
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
        let distances = cappedDrawerAnchors.map { ($0, $0 - offset) }
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
}
