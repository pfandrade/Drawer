//
//  DrawerViewController.swift
//  Drawer
//
//  Created by Paulo Andrade on 05/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit

public class DrawerViewController: UIViewController, UIGestureRecognizerDelegate {

    @objc public private(set) var mainViewController: UIViewController
    @objc public private(set) var drawerContentViewController: UIViewController
    
    @objc public init(mainViewController: UIViewController, drawerContentViewController: UIViewController) {
        self.mainViewController = mainViewController
        self.drawerContentViewController = drawerContentViewController
        super.init(nibName: nil, bundle: nil)
        // establish the parent/child relationships
        addChildViewController(mainViewController)
        mainViewController.didMove(toParentViewController: self)
        addChildViewController(drawerContentViewController)
        drawerContentViewController.didMove(toParentViewController: self)
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
    
    open override func loadView() {
        let view = UIView()
        
        // add the main view controller
        let mainView = mainViewController.view!
        view.addSubview(mainView)
        setupConstraintsToFill(view: view, with: mainView)
        
        // add the drawer content
        let drawerContainer = drawerContainerView
        let drawerMask = drawerMaskingView
        let drawerContent = drawerContentViewController.view!
        drawerContainer.addSubview(drawerMask)
        drawerMask.addSubview(drawerContent)
        setupConstraintsToFill(view: drawerContainer, with: drawerMask)
        setupConstraintsToFill(view: drawerMask, with: drawerContent)
        
        // setup drawer container constraints
        view.addSubview(drawerContainer)
        drawerContainer.translatesAutoresizingMaskIntoConstraints = false
        drawerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        drawerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        drawerContainer.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        drawerContainerHeightConstraint = drawerContainer.heightAnchor.constraint(equalTo: view.heightAnchor)
        drawerContainerHeightConstraint?.isActive = true
        
        // add the gesture recognizer
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
    
    override open func updateViewConstraints() {
        drawerContainerHeightConstraint?.constant = bottowOverflowHeight - minTopOffset;
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let path = UIBezierPath(roundedRect: drawerContainerView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii:CGSize(width: drawerCornerRadius, height: drawerCornerRadius)).cgPath
        drawerContainerView.layer.shadowPath = path
        (drawerMaskingView.layer.mask as! CAShapeLayer).path = path
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        moveDrawerToClosestAnchor()
    }
    
    open override var navigationItem: UINavigationItem {
        return mainViewController.navigationItem
    }

    // MARK:- Configuration
    
    @objc public var minTopOffset: CGFloat = 60.0 {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
                if !draggingDrawer {
                    moveDrawerToClosestAnchor()
                }
            }
        }
    }
    
    @objc public var drawerAnchors: [CGFloat] = [64.0, 250.0, CGFloat.greatestFiniteMagnitude] {
        didSet {
            if isViewLoaded && !draggingDrawer {
                moveDrawerToClosestAnchor()
            }
        }
    }
    
    @objc public var bottowOverflowHeight: CGFloat = 20 {
        didSet {
            if isViewLoaded {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
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
    
    
    // MARK: - Handling pan gesture
    private var touchBeganOnDrawer = false
    private var startingOffset: CGFloat = 0
    private var draggingDrawer = false
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let hitView = view.hitTest(touch.location(in: self.view), with: nil) {
            touchBeganOnDrawer = hitView.isDescendant(of: self.drawerContainerView)
        } else {
            touchBeganOnDrawer = false
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if  let panGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer,
            let otherView = otherGestureRecognizer.view as? UIScrollView,
            otherView.isDescendant(of: self.drawerContainerView) {
            panGestureRecognizer.removeTarget(self, action: nil)
            panGestureRecognizer.addTarget(self, action: #selector(handlePanGestureInsideDrawer(_:)))
        }
        return !touchBeganOnDrawer
    }
    
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        switch gestureRecognizer.state {
        case .possible: break
        case .began:
            startingOffset = currentDrawerOffset
            if touchBeganOnDrawer {
                draggingDrawer = true
            }
        case .changed:
            if touchBeganOnDrawer {
                moveDrawer(to: startingOffset - gestureRecognizer.translation(in: self.view).y)
            }
            else {
                let currentTouchOffset = self.view.frame.height - gestureRecognizer.location(in: self.view).y
                if currentTouchOffset < startingOffset {
                    moveDrawer(to: currentTouchOffset)
                    draggingDrawer = true
                }
                else {
                    if currentDrawerOffset != startingOffset {
                        moveDrawer(to: startingOffset)
                    }
                    draggingDrawer = false
                }
            }
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            if touchBeganOnDrawer || draggingDrawer || !cappedDrawerAnchors.contains(currentDrawerOffset) {
                moveDrawerToClosestAnchor(animated: true, velocity: gestureRecognizer.velocity(in: self.view).y)
            }
            draggingDrawer = false
        }
    }
    
    private var internalScrollViewBounces = true
    @objc private func handlePanGestureInsideDrawer(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let scrollView = gestureRecognizer.view as? UIScrollView else {
            return
        }

        let handleGesture = { () -> Void in
            let translation = gestureRecognizer.translation(in: scrollView)
            let isScrollingDown = translation.y > 0
            let shouldScrollingDownTriggerGestureRecognizer = isScrollingDown && scrollView.contentOffset.y <= 0
            let shouldScrollingUpTriggerGestureRecognizer = !isScrollingDown && self.currentDrawerOffset < (self.cappedDrawerAnchors.max() ?? 0.0)
            
            if shouldScrollingDownTriggerGestureRecognizer || shouldScrollingUpTriggerGestureRecognizer {
                scrollView.bounces = false
                self.handlePanGesture(gestureRecognizer)
            } else {
                scrollView.bounces = self.internalScrollViewBounces
            }
        }
        
        switch gestureRecognizer.state {
        case .possible: break
        case .began:
            // save off the current "bounces" state so we can reset once the gesture is finished
            internalScrollViewBounces = scrollView.bounces
            fallthrough
        case .changed:
            handleGesture()
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            handleGesture()
            scrollView.bounces = internalScrollViewBounces
            gestureRecognizer.removeTarget(self, action: nil)
            break
        }
    }
    
    // MARK: aux
    var animating = false
    private var currentDrawerOffset: CGFloat {
        if let presentationLayer = drawerContainerView.layer.presentation(), animating {
            return presentationLayer.transform.m24
        } else {
            return -drawerContainerView.transform.ty
        }
        
    }
    private func moveDrawerToClosestAnchor(animated animate: Bool = false, velocity: CGFloat? = nil) {
        let anchor = targetAnchor(for: currentDrawerOffset, at: velocity)
        moveDrawer(to: anchor, animated: animate, velocity: velocity ?? 0.0)
    }
    
    private func moveDrawer(to offset: CGFloat, animated animate: Bool = false, velocity: CGFloat = 0.0) {
        let offset = min(offset, self.view.bounds.height-minTopOffset)
        
        let updateTransformBlock = { () -> Void in
            self.drawerContainerView.transform = CGAffineTransform(translationX: 0, y: -offset)
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
            })
        }
        else {
            updateTransformBlock()
        }

        
    }
    
    private var cappedDrawerAnchors: [CGFloat] {
        let maxOffet = self.view.bounds.height - minTopOffset
        return drawerAnchors.map { min($0, maxOffet) }
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
    
}
