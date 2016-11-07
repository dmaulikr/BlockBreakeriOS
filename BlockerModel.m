//
//  BlockerModel.m
//  BlockBreaker
//
//  Created by Smart Home on 11/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "BlockerModel.h"

#define NUM_COLS 5
#define NUM_ROWS 4
#define DEFAULT_SCREEN_SIZE 320
#define DEFAULT_SCREEN_HEIGHT 460
#define BLOCK_PCNT 0.2
#define TOP_OFFSET 20
#define BOTTOM_OFFSET 80
#define BALL_START_OFFSET 160
#define VELOCITY 200
#define SIDE_DOWN_RATIO 0.2

@interface BlockerModel()



@property CGPoint ballVelocity;
@property CFTimeInterval lastTime;
@property CGFloat sideDownOffset;


@end

@implementation BlockerModel

-(instancetype) init
{
    return [self initWithScreenWidth:DEFAULT_SCREEN_SIZE andHeight:DEFAULT_SCREEN_HEIGHT];
}

-(instancetype) initWithScreenWidth:(CGFloat)width andHeight:(CGFloat)height
{
    self = [super init];
    
    if (self)
    {
        self.screenWidth = width;
        self.screenHeight = height;
        [self initializeGame];
    }
    
    return self;
}

-(void) initializeGame
{
    CGFloat blockSize = self.screenWidth/NUM_COLS;
    
    CGFloat blockHeight = BLOCK_PCNT*self.screenHeight/NUM_ROWS;
    self.sideDownOffset = SIDE_DOWN_RATIO*blockHeight;
    //Create NSMutableArray of blockViews
    self.blocks = [[NSMutableArray alloc] init];
    for (int column = 0; column < NUM_COLS; column++)
    {
        self.blocks[column] = [[NSMutableArray alloc] init];
        for (int row = 0; row < NUM_ROWS; row++)
        {
            [self.blocks[column] addObject:[[BlockView alloc] initWithFrame:CGRectMake(column*blockSize, row*blockHeight+TOP_OFFSET, blockSize, blockHeight) andColor:row]];
        }
    }
    
    UIImage* paddleImage = [UIImage imageNamed:@"paddle.png"];
    CGSize paddleSize = [paddleImage size];
    self.paddleRect = CGRectMake(self.screenWidth/2, self.screenHeight-BOTTOM_OFFSET,
                                 paddleSize.width, paddleSize.height);
    
    UIImage* ballImage = [UIImage imageNamed:@"ball.png"];
    CGSize ballSize = [ballImage size];
    self.ballRect = CGRectMake(self.screenWidth/2, self.screenHeight-BALL_START_OFFSET,
                               ballSize.width, ballSize.height);
    
    self.ballVelocity = CGPointMake(VELOCITY, -1*VELOCITY);
    self.lastTime = 0;
    self.brokenBlocks = [[NSMutableArray alloc] init];
}

-(void)updateModelAtTime:(CFTimeInterval)timestamp
     withCompletionBlock:(dispatch_block_t)completionHandler;
{
    CGFloat newX = self.ballRect.origin.x, newY = self.ballRect.origin.y;
    if(self.lastTime)
    {
       newX += (self.ballVelocity.x*(timestamp-self.lastTime));
       newY += (self.ballVelocity.y*(timestamp-self.lastTime));
    }
    self.lastTime = timestamp;
    
    self.ballRect = CGRectMake(newX, newY,
                               self.ballRect.size.width, self.ballRect.size.height);
    [self adjustIfBallHitEdge];
    [self checkIfHitBlock];
    [self checkIfHitPaddle];
    if (completionHandler)
    {
        completionHandler();
    }
    //NSLog(@"New rect is origin: (%.2f, %.2f) size (%.2f, %.2f)",self.ballRect.origin.x, self.ballRect.origin.y, self.ballRect.size.width, self.ballRect.size.height);
}

-(void) adjustIfBallHitEdge
{
    if (self.ballRect.origin.x + self.ballRect.size.width >= self.screenWidth)
    {
        self.ballRect = CGRectMake(self.screenWidth-self.ballRect.size.width, self.ballRect.origin.y,
                                   self.ballRect.size.width, self.ballRect.size.height);
        self.ballVelocity = CGPointMake(-1*self.ballVelocity.x, self.ballVelocity.y);
    }
    else if(self.ballRect.origin.x <= 0)
    {
        self.ballRect = CGRectMake(0, self.ballRect.origin.y,
                                   self.ballRect.size.width, self.ballRect.size.height);
        self.ballVelocity = CGPointMake(-1*self.ballVelocity.x, self.ballVelocity.y);
    }
    else if (self.ballRect.origin.y + self.ballRect.size.width >= self.screenHeight)
    {
        self.ballRect = CGRectMake(self.screenWidth/2, self.screenHeight-BALL_START_OFFSET,
                                   self.ballRect.size.width, self.ballRect.size.height);
        self.ballVelocity = CGPointMake(self.ballVelocity.x, -1*self.ballVelocity.y);
    }
    else if(self.ballRect.origin.y <= TOP_OFFSET)
    {
        self.ballRect = CGRectMake(self.ballRect.origin.x, TOP_OFFSET,
                                   self.ballRect.size.width, self.ballRect.size.height);
        self.ballVelocity = CGPointMake(self.ballVelocity.x, -1*self.ballVelocity.y);
    }
}

-(void) checkIfHitBlock
{
    BOOL sideImpact = NO;
    
    for (NSMutableArray *nextCol in self.blocks)
    {
        CGRect blockRect = [[nextCol lastObject] frame];
        if ([nextCol count] && CGRectIntersectsRect(blockRect, self.ballRect))
        {
            if (self.ballRect.origin.y + self.ballRect.size.height < blockRect.origin.y + blockRect.size.height - self.sideDownOffset)
            {
                sideImpact = YES;
            }
            [self.brokenBlocks addObject:[nextCol lastObject]];
            [nextCol removeLastObject];
        }
    }
    if([self.brokenBlocks count])
    {
        if(sideImpact)
        {
            self.ballVelocity = CGPointMake(-1*self.ballVelocity.x, self.ballVelocity.y);
        }
        else
        {
            self.ballVelocity = CGPointMake(self.ballVelocity.x, -1*self.ballVelocity.y);
        }
    }
}

-(void) checkIfHitPaddle
{
    if (CGRectIntersectsRect(self.paddleRect, self.ballRect))
    {
        self.ballRect = CGRectMake(self.ballRect.origin.x, self.ballRect.origin.y - self.paddleRect.size.height,
                                   self.ballRect.size.width, self.ballRect.size.height);
        self.ballVelocity = CGPointMake(self.ballVelocity.x, -1*self.ballVelocity.y);
    }
}

-(BOOL) didGameEnd
{
    NSUInteger numBlocks = 0;
    
    for (NSMutableArray *nextCol in self.blocks)
    {
        numBlocks += [nextCol count];
    }
    
    if (numBlocks)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
