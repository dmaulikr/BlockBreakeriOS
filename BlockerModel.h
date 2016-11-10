//
//  BlockerModel.h
//  BlockBreaker
//
//  Created by Smart Home on 11/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BlockView.h"

@interface BlockerModel : NSObject

@property CGFloat screenWidth;
@property CGFloat screenHeight;
@property CGRect paddleRect;
@property CGRect ballRect;

@property NSMutableArray <NSMutableArray <BlockView *>*> *blocks;
-(instancetype) initWithScreenWidth:(CGFloat)width andHeight:(CGFloat)height;
-(void)updateModelAtTime:(CFTimeInterval)timestamp;
-(BOOL) didGameEnd;
-(void) initializeGame;
@end
