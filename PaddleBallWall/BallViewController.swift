//
//  BallViewController.swift
//  BallA5
//
//  Created by iMac21.5 on 5/24/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class BallViewController: UIViewController {

    @IBOutlet weak var gameView: UIView!
    
    let breakout = BreakoutBehavior()
    lazy var animator: UIDynamicAnimator = { UIDynamicAnimator(referenceView: self.gameView) }()
    var ballColor: CGColor = {
        if let bc = NSUserDefaults.standardUserDefaults().stringForKey("Ball.Color") {
            return CGColor.colorFor(bc)
        } else { return UIColor.whiteColor().CGColor }
    }()
    lazy var paddleColor: CGColor = {
        if let pc = NSUserDefaults.standardUserDefaults().stringForKey("Paddle.Color") {
            return CGColor.colorFor(pc)
        } else { return UIColor.whiteColor().CGColor }
    }()
    lazy var courtColor: CGColor = {
        if let cc = NSUserDefaults.standardUserDefaults().stringForKey("Court.Color") {
            return CGColor.colorFor(cc)
        } else { return UIColor.blackColor().CGColor }
    }()
    lazy var uid: String = {
        if let login = NSUserDefaults.standardUserDefaults().stringForKey("User.Login") {
            return login
        } else { return "" }
        }()
    lazy var soundOn: Bool = { return NSUserDefaults.standardUserDefaults().boolForKey("Sound.F/X")
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakout)
        gameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushBall:"))
        gameView.layer.backgroundColor = courtColor
        //The pan gesture handles most movement. However in the heat of the game it might be necessary to move faster-that’s what the left and right swipe gestures r4
        gameView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "panPaddle:"))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "swipePaddleLeft:")
        swipeLeft.direction = .Left
        gameView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "swipePaddleRight:")
        swipeRight.direction = .Right
        gameView.addGestureRecognizer(swipeRight)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let bc = NSUserDefaults.standardUserDefaults().stringForKey("Ball.Color") {
            ballColor = CGColor.colorFor(bc)
        }
        if let pc = NSUserDefaults.standardUserDefaults().stringForKey("Paddle.Color") {
            paddleColor = CGColor.colorFor(pc)
        }
        if let cc = NSUserDefaults.standardUserDefaults().stringForKey("Court.Color") {
            courtColor = CGColor.colorFor(cc)
        }
        if let login = NSUserDefaults.standardUserDefaults().stringForKey("User.Login") {
            uid = login
        }
        if NSUserDefaults.standardUserDefaults().boolForKey("Sound.F/X") == true {
            soundOn = true
        } else { soundOn = false }
    }
    func createBall() -> UIView {
        let ballSize = CGSize(width: Constants.BallSize, height: Constants.BallSize)
        let ball = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: ballSize))
        //ball.backgroundColor = ballColor
        ball.layer.backgroundColor = ballColor
        if let loggedInUser = User.login(uid, password: "foo") {
            ball.layer.contents = loggedInUser.image!.CGImage
            ball.layer.contentsGravity = kCAGravityCenter
            ball.layer.contentsScale = 2.0
        }
        ball.layer.cornerRadius = Constants.BallSize / 2.0
        ball.layer.borderColor = UIColor.blackColor().CGColor
        ball.layer.borderWidth = 2.0
        ball.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        ball.layer.shadowOpacity = 0.5
        return ball
    }
    func placeBall(ball: UIView) {
        //ball.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)  //ball only game
        var center = paddle.center
        center.y -= Constants.PaddleSize.height / 2 + Constants.BallSize/2
        ball.center = center
    }
    func pushBall(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            if breakout.balls.count == 0 {
                let ball = createBall()
                placeBall(ball)
                breakout.addBall(ball)
            }
            breakout.pushBall(breakout.balls.last!)
        }
    }
    struct Constants {
        static let BallSize: CGFloat = 40.0
        //static let BallColor = UIColor.yellowColor()
        static let BoxPathName = "Box"
        static let PaddlePathName = "Paddle"
        static let PaddleSize = CGSize(width: 80.0, height: 20.0)
        static let PaddleCornerRadius: CGFloat = 5.0
        //static let PaddleColor = UIColor.greenColor()
    }
    
    lazy var paddle: UIView = {
        let paddle = UIView(frame: CGRect(origin: CGPoint(x: self.gameView.bounds.maxX / 2 - Constants.PaddleSize.width / 2 , y: self.gameView.bounds.maxY - Constants.PaddleSize.height), size: Constants.PaddleSize))
        paddle.layer.backgroundColor = self.paddleColor
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.layer.borderColor = UIColor.blackColor().CGColor
        paddle.layer.borderWidth = 2.0
        paddle.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        paddle.layer.shadowOpacity = 0.5
        
        self.gameView.addSubview(paddle)
        return paddle
        }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var rect = gameView.bounds
        rect.size.height *= 2
        breakout.addBarrier(UIBezierPath(rect: rect), named: Constants.BoxPathName)
        //Its not nice if the player looses a ball because the device has been rotated accidentally. In such cases put the ball back on screen:
        for ball in breakout.balls {
            if !CGRectContainsRect(gameView.bounds, ball.frame) {
                placeBall(ball)
                animator.updateItemUsingCurrentState(ball)
            }
        }
        //When the paddle is outside the game view (at the beginning and possibly after device roatation), reset its position:
        resetPaddle()
//        println("paddle = \(paddle.frame.origin)")
//        println("maxY = \(gameView.bounds)")
//            let halfPaddleWidth = Constants.PaddleSize.width / 2
//            let center = gameView.bounds.maxX / 2 - halfPaddleWidth
//            println("center = \(center)")
//            let x = center - paddle.frame.origin.x
//            println("x = \(x)")
//            placePaddle(CGPoint(x: x, y: 0))
    }
    func resetPaddle() {
        paddle.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.maxY - paddle.bounds.height)
        addPaddleBarrier()
    }
    func addPaddleBarrier() {
        breakout.addBarrier(UIBezierPath(roundedRect: paddle.frame, cornerRadius: Constants.PaddleCornerRadius), named: Constants.PaddlePathName)
    }
    //While panning change the position of the paddle according to the panned distance. For swipes move to the far left or right:
    func panPaddle(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            placePaddle(gesture.translationInView(gameView))
            gesture.setTranslation(CGPointZero, inView: gameView)
        default: break
        }
    }
    func swipePaddleLeft(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            placePaddle(CGPoint(x: -gameView.bounds.maxX, y: 0.0))
        default: break
        }
    }
    func swipePaddleRight(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            placePaddle(CGPoint(x: gameView.bounds.maxX, y: 0.0))
        default: break
        }
    }
    //To change the position of the paddle, change its origin – but take care, not to move it off screen:
    func placePaddle(translation: CGPoint) {
        var origin = paddle.frame.origin
        origin.x = origin.x + translation.x
        origin.y = gameView.bounds.maxY - Constants.PaddleSize.height
        paddle.frame.origin = origin
        addPaddleBarrier()
    }
}

private extension CGColor {
    class func colorFor(sel: String) -> CGColor {
        switch sel {
        case "G": return UIColor.greenColor().CGColor
        case "B": return UIColor.blueColor().CGColor
        case "O": return UIColor.orangeColor().CGColor
        case "R": return UIColor.redColor().CGColor
        case "P": return UIColor.purpleColor().CGColor
        case "Y": return UIColor.yellowColor().CGColor
        case "C": return UIColor.cyanColor().CGColor
        case "W": return UIColor.whiteColor().CGColor
        default: return UIColor.blackColor().CGColor
        }
    }
}

// User is our Model,
// so it can't itself have anything UI-related
// but we can add a UI-specific property
// just for us to use
// because we are the Controller
// note this extension is private
private extension User {
    var image: UIImage? {
        if let image = UIImage(named: login) {
            return image
        } else {
            return UIImage(named: "tennis")!
        }
    }
}