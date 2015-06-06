//
//  BreakoutBehavior.swift
//  BallA5
//
//  Created by iMac21.5 on 5/24/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class BreakoutBehavior: UIDynamicBehavior {
 
    lazy var collider: UICollisionBehavior = {
        let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.action = {
            for ball in self.balls {
                if !CGRectIntersectsRect(self.dynamicAnimator!.referenceView!.bounds, ball.frame) {
                    self.removeBall(ball)
                }
            }
        }
        return lazilyCreatedCollider
        }()
    lazy var ballBehavior: UIDynamicItemBehavior = {
        let lazilyCreatedBallBehavior = UIDynamicItemBehavior()
        lazilyCreatedBallBehavior.allowsRotation = true
        lazilyCreatedBallBehavior.elasticity = CGFloat(NSUserDefaults.standardUserDefaults().floatForKey("Ball.Elasticity"))
        lazilyCreatedBallBehavior.friction = CGFloat(NSUserDefaults.standardUserDefaults().floatForKey("Ball.Friction"))
        lazilyCreatedBallBehavior.resistance = 0.0
        return lazilyCreatedBallBehavior
        }()
    lazy var paddleBehavior: UIDynamicItemBehavior = {
        let lazilyCreatedPaddleBehavior = UIDynamicItemBehavior()
        lazilyCreatedPaddleBehavior.allowsRotation = false
        lazilyCreatedPaddleBehavior.elasticity = CGFloat(NSUserDefaults.standardUserDefaults().floatForKey("Paddle.Elasticity"))
        lazilyCreatedPaddleBehavior.friction = CGFloat(NSUserDefaults.standardUserDefaults().floatForKey("Paddle.Friction"))
        lazilyCreatedPaddleBehavior.resistance = 0.0
        return lazilyCreatedPaddleBehavior
        }()
//    func addPaddle(paddle: UIView) {
//        dynamicAnimator?.referenceView?.addSubview(paddle)
//        collider.addItem(paddle)
//        paddleBehavior.addItem(paddle)
//    }
//    func removePaddle(paddle: UIView) {
//        collider.removeItem(paddle)
//        paddleBehavior.removeItem(paddle)
//        paddle.removeFromSuperview()
//    }  see addBarrier ...at bottom
    override init() {
        super.init()
        addChildBehavior(collider)
        addChildBehavior(ballBehavior)
        addChildBehavior(paddleBehavior)
    }
    func addBall(ball: UIView) {
        dynamicAnimator?.referenceView?.addSubview(ball)
        collider.addItem(ball)
        ballBehavior.addItem(ball)
    }
    var balls:[UIView] {
        get {
            return collider.items.filter{$0 is UIView}.map{$0 as! UIView}
        }
    }
    func removeBall(ball: UIView) {
        collider.removeItem(ball)
        ballBehavior.removeItem(ball)
        ball.removeFromSuperview()
    }
    func pushBall(ball: UIView) {
        let push = UIPushBehavior(items: [ball], mode: .Instantaneous)
        push.magnitude = 1.0
        push.angle = CGFloat(Double(arc4random()) * M_PI * 2 / Double(UINT32_MAX))
//        println("radians = \(push.angle)")
        push.action = { [weak push] in
            if !push!.active {
                self.removeChildBehavior(push!)
            }
        }
        addChildBehavior(push)
    }
    func addBarrier(path: UIBezierPath, named name: String) {
        collider.removeBoundaryWithIdentifier(name)
        collider.addBoundaryWithIdentifier(name, forPath: path)
    }
}
