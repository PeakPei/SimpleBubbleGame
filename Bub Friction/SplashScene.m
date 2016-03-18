//
//  SplashScene.m
//  Bub Friction
//
//  Created by Jose Norberto Hidalgo Romero on 28/06/14.
//  Copyright (c) 2014 Dynambi. All rights reserved.
//

#import "SplashScene.h"
#import "MyScene.h"

// Sounds
SKAction *startCoin;

@implementation SplashScene

SKLabelNode *startLabel;

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        
        // Background settings
        SKSpriteNode* background = [SKSpriteNode spriteNodeWithImageNamed:@"bg.png"];
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:background];
        self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        
        startLabel = [SKLabelNode labelNodeWithFontNamed:@"Thonburi-Bold"];
        startLabel.text = @"START";
        startLabel.name = @"start";
        startLabel.fontSize = 46;
        startLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:startLabel];
        
        CGRect box = CGRectMake(0, CGRectGetMidY(self.frame)-startLabel.frame.size.height/2, self.frame.size.width, startLabel.frame.size.height*2);
        SKShapeNode *panel = [[SKShapeNode alloc] init];
        panel.path = [UIBezierPath bezierPathWithRect:box].CGPath;
        panel.strokeColor = SKColor.clearColor;
        panel.name = @"panel";
        panel.zPosition = 10;
        [self addChild:panel];
        
        SKSpriteNode *bubble = [SKSpriteNode spriteNodeWithImageNamed:@"bubble2"];
        bubble.name = @"bubble";
        SKAction *scaleOut = [SKAction scaleTo:1.2f duration:1.0];
        SKAction *scaleIn = [SKAction scaleTo:0.8f duration:1.0];
        SKAction *sequence = [SKAction sequence:@[scaleOut,scaleIn]];
        [bubble runAction:[SKAction repeatActionForever:sequence]];
        bubble.position = CGPointMake(((self.frame.size.width)/2), ((self.frame.size.height)/2)+startLabel.frame.size.height+100);
        [self addChild:bubble];
        
        // Preload sounds
        startCoin = [SKAction playSoundFileNamed:@"bubbleStart.wav" waitForCompletion:NO];
        
    }
    
    return self;
    
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    NSLog(@"Node: %@",node.name);
    
    if ([node.name isEqualToString:@"panel"] ||
        [node.name isEqualToString:@"bubble"] ) {
        
        [self runAction:startCoin];

        startLabel.fontColor = SKColor.greenColor;
        
        SKAction *wait = [SKAction waitForDuration:0.25f];
        
        [startLabel runAction:wait completion:^{
           
            CGSize newSceneSize = self.view.bounds.size;
            SKTransition *trans = [SKTransition pushWithDirection:SKTransitionDirectionUp duration:1.25];
            MyScene *anotherScene = [[MyScene alloc] initWithSize:newSceneSize];
            [self.scene.view presentScene:anotherScene transition:trans];

            
        }];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
