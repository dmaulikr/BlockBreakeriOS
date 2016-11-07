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

#define MAX_Y_JERK 0.1
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

-(void) initializeGameView
{
    for (NSMutableArray *nextColumn in self.myModel.blocks)
    {
        for (BlockView *nextBlock in nextColumn)
        {
            [self.view addSubview:nextBlock];
        }
    }
    
    //Add the image view for the paddle
    self.paddleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paddle"]];
    [self.paddleView setFrame:self.myModel.paddleRect];
    [self.view addSubview:self.paddleView];
    
    //Add the image view for the ball
    self.ballView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ball"]];
    [self.ballView setFrame:self.myModel.ballRect];
    [self.view addSubview:self.ballView];
}

-(void) updateDisplay:(CADisplayLink *)sender
{
    //NSLog(@"Received display link at time %.2f",sender.timestamp);
    __weak ViewController *weakSelf = self;
    [self.myModel updateModelAtTime:sender.timestamp withCompletionBlock:^{
    
        ViewController *innerSelf = weakSelf;
        
        if([innerSelf.myModel didGameEnd])
        {
            innerSelf.gameCLock.paused = YES;
            for (BlockView *nextBlockToRemove in self.myModel.brokenBlocks)
            {
                [nextBlockToRemove removeFromSuperview];
            }
            [innerSelf.myModel.brokenBlocks removeAllObjects];
            [innerSelf.ballView removeFromSuperview];
            
            [innerSelf showAlertWithText:@"Congratulations:  You have broken all the blocks!"
                           andTitle:@"Game Over"
                    andCompletionHandler:^{
                        [innerSelf.myModel initializeGame];
                        [innerSelf.paddleView removeFromSuperview];
                        [innerSelf initializeGameView];
                        innerSelf.gameCLock.paused = NO;
                    }];
        }
        else
        {
            [innerSelf.ballView setFrame:self.myModel.ballRect];
            [innerSelf.paddleView setFrame:self.myModel.paddleRect];
            for (BlockView *nextBlockToRemove in self.myModel.brokenBlocks)
            {
                [nextBlockToRemove removeFromSuperview];
            }
            [innerSelf.myModel.brokenBlocks removeAllObjects];
        }
    }];
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
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    CGRect largePaddle = CGRectMake(self.myModel.paddleRect.origin.x - self.tapOffset,
                                    self.myModel.paddleRect.origin.y - self.tapOffset,
                                    self.myModel.paddleRect.size.width + 2*self.tapOffset,
                                    self.myModel.paddleRect.size.height + 2*self.tapOffset);
    
    NSLog(@"Touches began at point (%.1f,%.1f)",p.x,p.y) ;

    if(CGRectContainsPoint(largePaddle, p))
    {
        self.respondToTouch = YES;
        self.startPoint = p;
    }
    else
    {
        self.respondToTouch = NO;
    }
       
    }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    
    NSLog(@"Touches moved to point (%.1f,%.1f)",p.x,p.y) ;
    
    if(self.respondToTouch)
    {
        if (fabs(p.y-self.startPoint.y) < MAX_Y_JERK*self.view.bounds.size.height)
        {
            [self updatePaddleRectFromPoint:p];
            self.startPoint = p;
        }
    }
}

-(void) updatePaddleRectFromPoint:(CGPoint) p
{
    if (fabs(p.y-self.startPoint.y) < MAX_Y_JERK*self.view.bounds.size.height)
    {
        CGFloat startX = MAX(0,self.myModel.paddleRect.origin.x + p.x-self.startPoint.x);
        startX = MIN(self.view.bounds.size.width - self.myModel.paddleRect.size.width, startX);
        self.myModel.paddleRect = CGRectMake(startX,
                                             self.myModel.paddleRect.origin.y,
                                             self.myModel.paddleRect.size.width,
                                             self.myModel.paddleRect.size.height);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    
    NSLog(@"Touches ended at point (%.1f,%.1f)",p.x,p.y) ;
    
    if(self.respondToTouch)
    {
        [self updatePaddleRectFromPoint:p];
        self.startPoint = p;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

@end
