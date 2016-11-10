//
//  ViewController.m
//  BlockBreaker
//
//  Created by Smart Home on 11/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "ViewController.h"
#import "BlockerModel.h"
#import "BlockView.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_Y_JERK 1
#define MAX_TAP_OFFSET 0.3


@interface ViewController ()
@property BlockerModel *myModel;
@property CADisplayLink *gameCLock;
@property UIImageView *ballView;
@property UIImageView *paddleView;
@property BOOL respondToTouch;
@property CGPoint startPoint;
@property CGFloat tapOffset;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.myModel = [[BlockerModel alloc] initWithScreenWidth:self.view.bounds.size.width
                                                   andHeight:self.view.bounds.size.height];
    self.tapOffset =  MAX_TAP_OFFSET*self.view.bounds.size.height;
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self initializeGameView];
    
    self.gameCLock = [CADisplayLink displayLinkWithTarget:self
                                                 selector:@selector(updateDisplay:)];
    
    [self.gameCLock addToRunLoop:[NSRunLoop currentRunLoop]
                         forMode:NSDefaultRunLoopMode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"Changed interface orientation from %ld to %ld",(long)fromInterfaceOrientation,(long)[[UIApplication sharedApplication] statusBarOrientation]);
    self.myModel.screenWidth = self.view.bounds.size.width;
    self.myModel.screenHeight = self.view.bounds.size.height;
    NSLog(@"New frame of view is %@",NSStringFromCGRect(self.view.frame));
    NSLog(@"New bounds of view is %@",NSStringFromCGRect(self.view.bounds));
    NSLog(@"New frame of paddle view is %@",NSStringFromCGRect(self.paddleView.frame));
    NSLog(@"New bounds of paddle view is %@",NSStringFromCGRect(self.paddleView.bounds));
}

-(void) initializeGameView
{
    for (NSMutableArray *nextColumn in self.myModel.blocks)
    {
        for (BlockView *nextBlock in nextColumn)
        {
            nextBlock.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:nextBlock];
        }
    }
    
    //Add the image view for the paddle
    if (nil == self.paddleView)
    {
        self.paddleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paddle"]];
        self.paddleView.backgroundColor = [UIColor clearColor];
        self.paddleView.opaque = NO;
        self.paddleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:self.paddleView];
    }
    [self.paddleView setFrame:self.myModel.paddleRect];

    
    //Add the image view for the ball
    if (nil == self.ballView)
    {
        self.ballView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ball"]];
        self.ballView.backgroundColor = [UIColor clearColor];
        self.ballView.opaque = NO;
        self.ballView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:self.ballView];
    }
    [self.ballView setFrame:self.myModel.ballRect];
}

-(void) updateDisplay:(CADisplayLink *)sender
{
    //NSLog(@"Received display link at time %.2f",sender.timestamp);
    [self.myModel updateModelAtTime:sender.timestamp];
    if([self.myModel didGameEnd])
    {
        self.gameCLock.paused = YES;
        
        [self showAlertWithText:@"Congratulations:  You have broken all the blocks!"
                            andTitle:@"Game Over"
                andCompletionHandler:^{
                    [self.myModel initializeGame];
                    //[self.paddleView removeFromSuperview];
                    //[self.ballView removeFromSuperview];
                    [self initializeGameView];
                    self.gameCLock.paused = NO;
                }];
    }
    else
    {
        [self.ballView setFrame:self.myModel.ballRect];
        [self.paddleView setFrame:self.myModel.paddleRect];
    }
    
}

- (void) showAlertWithText:(NSString *)alertText
                  andTitle:(NSString *)alertTitle
      andCompletionHandler:(dispatch_block_t)compBlock
{
    if ([UIAlertController class])
    {
        // use UIAlertController
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertText
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Start New Game"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                             if(compBlock)
                                                             {
                                                                 compBlock();
                                                             }}];
        [alert addAction:cancelAction];
        [self presentViewController:alert
                           animated:YES
                         completion:nil] ;
    }
    else
    {
        // use UIAlertView
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertText
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil]
         show];
        
    }
}

#pragma mark - handling touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began at point") ;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches moved with num touches %ld",[touches count]) ;
    for (UITouch *touch in touches)
    {
        [self updatePaddleRectFromTouch:touch];
    }
}

-(void) updatePaddleRectFromTouch:(UITouch *) touch
{
    CGPoint p = [touch locationInView:self.view];
    CGPoint startPoint = [touch previousLocationInView:self.view];
    
    NSLog(@"Touches moved from (%.1f, %.1f) to (%.1f,%.1f)",startPoint.x, startPoint.y, p.x, p.y) ;
    
    CGFloat startX = MAX(0,self.myModel.paddleRect.origin.x + p.x-startPoint.x);
    startX = MIN(self.view.bounds.size.width - self.myModel.paddleRect.size.width, startX);
    self.myModel.paddleRect = CGRectMake(startX,
                                         self.myModel.paddleRect.origin.y,
                                         self.myModel.paddleRect.size.width,
                                         self.myModel.paddleRect.size.height);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    
    NSLog(@"Touches ended at point (%.1f,%.1f)",p.x,p.y) ;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    
    NSLog(@"Touches cancelled at point (%.1f,%.1f)",p.x,p.y) ;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    UITouch *touch = [touches anyObject];
//    CGPoint p = [touch locationInView:self.view];
//    CGRect largePaddle = CGRectMake(self.myModel.paddleRect.origin.x - self.tapOffset,
//                                    self.myModel.paddleRect.origin.y - self.tapOffset,
//                                    self.myModel.paddleRect.size.width + 2*self.tapOffset,
//                                    self.myModel.paddleRect.size.height + 2*self.tapOffset);
//    
//    
//    
//        NSLog(@"Touches began at point (%.1f,%.1f)",p.x,p.y) ;
//    
//        if(CGRectContainsPoint(largePaddle, p))
//        {
//            NSLog(@"Setting respond to YES");
//            self.respondToTouch = YES;
//        }
//        else
//        {
//            NSLog(@"Setting respond to NO");
//            self.respondToTouch = NO;
//        }
//}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    NSLog(@"Touches moved with num touches %ld",[touches count]) ;
//    if(self.respondToTouch)
//    {
//        for (UITouch *touch in touches)
//        {
//            [self updatePaddleRectFromTouch:touch];
//            
//        }
//    }
//}

//-(void) updatePaddleRectFromTouch:(UITouch *) touch
//{
//    CGPoint p = [touch locationInView:self.view];
//    CGPoint startPoint = [touch previousLocationInView:self.view];
//
//    
//    if (fabs(p.y-startPoint.y) < MAX_Y_JERK*self.view.bounds.size.height)
//    {
//        NSLog(@"Touches moved from (%.1f, %.1f) to (%.1f,%.1f)",startPoint.x, startPoint.y, p.x, p.y) ;
//        
//        CGFloat startX = MAX(0,self.myModel.paddleRect.origin.x + p.x-startPoint.x);
//        startX = MIN(self.view.bounds.size.width - self.myModel.paddleRect.size.width, startX);
//        self.myModel.paddleRect = CGRectMake(startX,
//                                             self.myModel.paddleRect.origin.y,
//                                             self.myModel.paddleRect.size.width,
//                                             self.myModel.paddleRect.size.height);
//    }
//    else
//    {
//         NSLog(@"Ignoring Touches moved from (%.1f, %.1f) to (%.1f,%.1f)",startPoint.x, startPoint.y, p.x, p.y) ;
//    }
//}

//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    UITouch *touch = [touches anyObject];
//    CGPoint p = [touch locationInView:self.view];
//    
//    NSLog(@"Touches ended at point (%.1f,%.1f)",p.x,p.y) ;
//    
//    self.respondToTouch = NO;
//}



@end
