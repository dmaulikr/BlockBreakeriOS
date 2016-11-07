//
//  BlockView.m
//  BlockBreaker
//
//  Created by Smart Home on 11/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "BlockView.h"
#define RED 0
#define BLUE 1
#define GREEN 2


@interface BlockView()
@property int color;
@end

@implementation BlockView

-(instancetype) initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andColor:RED];
}

-(instancetype) initWithFrame:(CGRect)frame andColor:(int) color
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.color = color;
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    NSLog(@"Subview location w.r.t superview %.2f, %.2f size = %.2f, %.2f", self.frame.origin.x,self.frame.origin.y,self.frame.size.width,self.frame.size.height);
//    //Using this statement to create the BezierPaths only shows the first block
//        //UIBezierPath *block = [UIBezierPath bezierPathWithRect:self.frameRect];
//    
//    //Using this sequence, results in displaying all blocks
//    CGRect blockRect = CGRectMake(0, 0,  self.bounds.size.width, self.bounds.size.height);
//    UIBezierPath *block = [UIBezierPath bezierPathWithRect:blockRect];
//
//        switch (self.color)
//        {
//            case RED:
//                [[UIColor redColor] setFill];
//                break;
//            case BLUE:
//                [[UIColor blueColor] setFill];
//                break;
//            case GREEN:
//                [[UIColor greenColor] setFill];
//                break;
//            default:
//                break;
//        }
//        [block fill];
//}

- (void)drawRect:(CGRect)rect
{
    float viewWidth, viewHeight;
    viewWidth = self.bounds.size.width;
    viewHeight = self.bounds.size.height;
    
    //	Get the drawing context
    CGContextRef context =  UIGraphicsGetCurrentContext ();
    
    // Define a rect in the shape of the block
    CGRect blockRect = CGRectMake(0, 0,  viewWidth, viewHeight);
    
    // Define a path using the rect
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:blockRect];
    
    // Set the line width of the path
    path.lineWidth = 2.0;
    
    //	Define a gradient to use to fill the blocks
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient;
    int num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    CGFloat components[8] = { 0.0, 0.0, 0.0, 1.0,  // Start color
        1.0, 1.0, 1.0, 1.0 }; // End color
    
    // Determine gradient color based on color property
    switch (self.color) {
        case RED:
            // Red Block
            components[0] = 1.0;
            break;
        case GREEN:
            // Green Block
            components[1] = 1.0;
            break;
        case BLUE:
            // Blue Block
            components[2] = 1.0;
            break;
        default:
            break;
    }
    
    myGradient = CGGradientCreateWithColorComponents (colorSpace, components,
                                                      locations, num_locations);
    
    CGContextDrawLinearGradient (context, myGradient, CGPointMake(0, 0),
                                 CGPointMake(viewWidth, 0), 0);
    
    //	Clean up the color space & gradient
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(myGradient);
    
    // Stroke the path
    [path stroke];

}

@end
