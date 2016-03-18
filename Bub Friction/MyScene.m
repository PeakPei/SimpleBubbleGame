//
//  MyScene.m
//  Bub Friction
//
//  Created by Jose Norberto Hidalgo Romero on 28/06/14.
//  Copyright (c) 2014 Dynambi. All rights reserved.
//

#import "MyScene.h"
#import "SplashScene.h"
#import <AVFoundation/AVFoundation.h>

// Categories Names
static NSString* ballCategoryName = @"ball";
static NSString* cannonCategoryName = @"cannon";
static NSString* bottomCategoryName = @"bottom";

// Categories Mask
static const uint32_t ballLaunchedCategory   = 0x1 << 0;         // 00000000000000000000000000000001
static const uint32_t ballCategory           = 0x1 << 1;         // 00000000000000000000000000000010
static const uint32_t bottomCategory         = 0x1 << 2;         // 00000000000000000000000000000100

// Views
SKSpriteNode* background;
SKLabelNode *scoreLabel;
SKLabelNode *highScoreLabel;
SKSpriteNode* musicSwitch;
SKNode *cannonAnchorPoint;
SKShapeNode *cannon;
SKNode *cannonShootPoint;
SKSpriteNode *bubble;
SKNode *bottom;
SKShapeNode *uiLineBottom;

// Sounds
SKAction *music;
SKAction *bubbleCollision;
SKAction *bubblePop;
SKAction *bubbleExplode;
AVAudioPlayer *musicPlayer;

// Vars
float xImpulse;
BOOL canShoot;
BOOL endGame;
BOOL musicOn;
int score;
int highScore;

// Vars for detect direction movement
BOOL isMovingRight;
float lastXSaved;

// Constants
static const float maxLeftAngle = 1.0f;
static const float maxRightAngle = -1.0f;
static const float bottomHeight = 50.0f;
static const float UIHeight = 50.0f;

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        
        // Background settings
        background = [SKSpriteNode spriteNodeWithImageNamed:@"bg.png"];
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:background];
        self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        
        // No gravity
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        
        // Creation methods
        [self createBorderNode];
        [self createBottomNode];
        [self createCannon];
        
        // Apply rotation to cannon
        [self cannonMove:YES];
        
        // Score
        [self addUI];
        
        // Bitmask
        bottom.physicsBody.categoryBitMask = bottomCategory;
        
        // Init direction detection var
        lastXSaved = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x;
        
        // Contact delegate
        self.physicsWorld.contactDelegate = self;
        
        // Preload sounds
        music = [SKAction playSoundFileNamed:@"BubFriction.mp3" waitForCompletion:NO];
        bubbleCollision = [SKAction playSoundFileNamed:@"bubbleCollision.wav" waitForCompletion:NO];
        bubblePop = [SKAction playSoundFileNamed:@"bubblePop.wav" waitForCompletion:NO];
        bubbleExplode = [SKAction playSoundFileNamed:@"bubbleExplode.wav" waitForCompletion:NO];
        
        [self playMusic:@"BubFriction.mp3"];
        
        endGame = NO;
        musicOn = YES;
        
    }
    
    return self;
    
}

#pragma mark -
#pragma mark Creation Methods
#pragma mark -


-(void)createBorderNode {
    
    CGRect gameBorder = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height-UIHeight);
    SKPhysicsBody* borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:gameBorder];
    self.physicsBody = borderBody;
    self.physicsBody.friction = 0.0f;
    
}

-(void)createBottomNode {

    CGRect bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, bottomHeight);
    bottom = [SKNode node];
    bottom.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:bottomRect];
    bottom.physicsBody.categoryBitMask = bottomCategory;
    bottom.physicsBody.contactTestBitMask = ballCategory;
    
    [self addChild:bottom];
    
}

-(void)createCannon {

    CGRect box = CGRectMake(-15, -40, 30.0, 80);
    cannon = [[SKShapeNode alloc] init];
    cannon.path = [UIBezierPath bezierPathWithRect:box].CGPath;
    cannon.fillColor = SKColor.blackColor;
    cannon.strokeColor = SKColor.orangeColor;
    cannon.name = cannonCategoryName;
    cannon.zPosition = 10;

    cannonAnchorPoint = [SKNode node];
    cannonAnchorPoint.position = CGPointMake(self.frame.size.width/2, 0);
    
    cannonShootPoint = [SKNode node];
    cannonShootPoint.position = CGPointMake((cannon.frame.size.width/2)-15, 80);
    
    [cannon addChild:cannonShootPoint];
    [cannonAnchorPoint addChild:cannon];
    [self addChild:cannonAnchorPoint];
    
}

-(void)addUI {
    
    // init score
    score = 0;
    highScore = [[NSUserDefaults standardUserDefaults] integerForKey: @"highScore"];
    
    scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GeezaPro"];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %d",score];
    scoreLabel.fontSize = 14;
    scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    scoreLabel.position = CGPointMake(10, self.frame.size.height - 40);
    [self addChild:scoreLabel];

    highScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GeezaPro"];
    highScoreLabel.text = [NSString stringWithFormat:@"Highscore: %d",highScore];
    highScoreLabel.fontSize = 14;
    highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    highScoreLabel.position = CGPointMake(self.frame.size.width - highScoreLabel.frame.size.width - 20 , self.frame.size.height - 40);
    [self addChild:highScoreLabel];
    
    // Music switch
    musicSwitch = [SKSpriteNode spriteNodeWithImageNamed:@"musicOn"];
    musicSwitch.name = @"musicSwitch";
    musicSwitch.position = CGPointMake((self.frame.size.width)/2, self.frame.size.height - 35);
    [self addChild:musicSwitch];


    // UI Top Separator
    SKShapeNode *uiLineTop = [SKShapeNode node];
    CGMutablePathRef pathToDrawTop = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDrawTop, NULL, 0.0, self.frame.size.height - UIHeight);
    CGPathAddLineToPoint(pathToDrawTop, NULL, self.frame.size.width, self.frame.size.height - UIHeight);
    uiLineTop.path = pathToDrawTop;
    [uiLineTop setStrokeColor:[UIColor whiteColor]];
    [self addChild:uiLineTop];
    
    // UI Bottom Separator
    uiLineBottom = [SKShapeNode node];
    CGMutablePathRef pathToDrawBottom = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDrawBottom, NULL, 0.0, 50.0);
    CGPathAddLineToPoint(pathToDrawBottom, NULL, self.frame.size.width, 50.0);
    uiLineBottom.path = pathToDrawBottom;
    [uiLineBottom setStrokeColor:[UIColor whiteColor]];
    [self addChild:uiLineBottom];
    
}

- (void)playMusic:(NSString *)filename
{
	NSError *error;
	NSURL *musicURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
	musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:&error];
	musicPlayer.numberOfLoops = -1;
	musicPlayer.volume = 0.40f;
	[musicPlayer prepareToPlay];
	[musicPlayer play];
}


#pragma mark -
#pragma mark Loop Methods
#pragma mark -

-(void)update:(CFTimeInterval)currentTime {

    // If cannon is in movement
    if (abs([cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x-lastXSaved)>0) {
        isMovingRight = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x-lastXSaved>0 ? YES : NO;
        lastXSaved = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x;
    }
    
    // If bubble is upon bottom line then reactivate bottom area to detect lose-game event
    if (bubble.frame.origin.y > 50) {
        
        CGRect bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, bottomHeight);
        bottom.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:bottomRect];
        bottom.physicsBody.categoryBitMask = bottomCategory;
        bottom.physicsBody.contactTestBitMask = ballCategory;
        
    }
    
    // If bubble velocity is less than 10 then reactivate cannon move and scale current bubble
    if (abs(bubble.physicsBody.velocity.dx) < 10 && abs(bubble.physicsBody.velocity.dy) < 10 && !endGame) {
        
        SKAction *scaleBubble = [SKAction scaleTo:0.7f duration:1.0];
        [bubble runAction:scaleBubble];
        bubble.physicsBody.categoryBitMask = ballCategory;
        bubble.physicsBody.contactTestBitMask = bottomCategory;
        
        bubble = nil;

        canShoot = YES;
        [self cannonMove:YES];
        
    }
    
}

-(void)cannonMove:(BOOL)canMove {
    
    if (canMove) {
        
        if (![cannon hasActions]) {
            
            float dx = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x - [cannonAnchorPoint convertPoint:self.frame.origin toNode:self.scene].x ;
            float dy = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].y - [cannonAnchorPoint convertPoint:self.frame.origin toNode:self.scene].y ;
            float tmpAngle = atan2(dy,dx)-1.570796f;
            
            if (isMovingRight) {
                
                SKAction *rotateToRightOnce = [SKAction rotateToAngle:(maxRightAngle) duration:(tmpAngle-maxRightAngle)];
                [cannon runAction:rotateToRightOnce completion:^{
                
                    SKAction *rotateToLeft = [SKAction rotateToAngle:(maxLeftAngle) duration:1.5];
                    SKAction *rotateToRight = [SKAction rotateToAngle:(maxRightAngle) duration:1.5];
                    SKAction *cannonSequence = [SKAction sequence:@[rotateToLeft,rotateToRight]];
                    [cannon runAction:[SKAction repeatActionForever:cannonSequence] withKey:@"cannonMove"];
                
                }];
                
            } else {

                SKAction *rotateToLeftOnce = [SKAction rotateToAngle:(maxLeftAngle) duration:(maxLeftAngle-tmpAngle)];
                [cannon runAction:rotateToLeftOnce completion:^{
                    
                    SKAction *rotateToRight = [SKAction rotateToAngle:(maxRightAngle) duration:1.5];
                    SKAction *rotateToLeft = [SKAction rotateToAngle:(maxLeftAngle) duration:1.5];
                    SKAction *cannonSequence = [SKAction sequence:@[rotateToRight,rotateToLeft]];
                    [cannon runAction:[SKAction repeatActionForever:cannonSequence] withKey:@"cannonMove"];
                    
                }];
                
            }
            
        }

    } else {
        
        [cannon removeAllActions];
        
    }
    
}

#pragma mark -
#pragma mark Touch Methods
#pragma mark -

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    SKNode *touchedNode = [self nodeAtPoint:touchLocation];
    
    if ([touchedNode.name isEqualToString:@"restart"]) {
        
        CGSize newSceneSize = self.view.bounds.size;
        SKTransition *trans = [SKTransition crossFadeWithDuration:1.00];
        MyScene *anotherScene = [[MyScene alloc] initWithSize:newSceneSize];
        [self.scene.view presentScene:anotherScene transition:trans];
        
    }

    if ([touchedNode.name isEqualToString:@"musicSwitch"]) {
        
        musicOn = !musicOn;
        
        if (musicOn) {
            
            musicSwitch.texture = [SKTexture textureWithImageNamed:@"musicOn"];
            [musicPlayer play];
        
        } else {

            musicSwitch.texture = [SKTexture textureWithImageNamed:@"musicOff"];
            [musicPlayer pause];
            
        }
        
    } else {

        bottom.physicsBody = nil;
    
        if (canShoot) {
        
            // block futher shoots
            canShoot = NO;
        
            // Stop cannon
            [self cannonMove:NO];
        
            SKAction *boom1 = [SKAction scaleXTo:1.2f duration:0.1];
            SKAction *boom2 = [SKAction scaleXTo:1.0f duration:0.1];
            SKAction *boom3 = [SKAction scaleXTo:1.1f duration:0.1];
            SKAction *boom4 = [SKAction scaleXTo:1.0f duration:0.1];
            SKAction *boomSequence = [SKAction sequence:@[boom1,boom2,boom3,boom4]];
            [cannon runAction:boomSequence];
        
            [self addBubble];
        
            [self runAction:bubblePop];
    
        }
        
    }
    
}

-(void)addBubble {
    
    // Generate Bubble Random Range (max-min)+min
    int randNum;
    if (score < 15) {
        randNum = rand() % (5 - 2) + 2;
    } else if (score < 30) {
        randNum = rand() % (6 - 2) + 2;
    } else if (score < 45) {
        randNum = rand() % (7 - 2) + 2;
    } else if (score < 60) {
        randNum = rand() % (8 - 2) + 2;
    } else if (score < 75) {
        randNum = rand() % (9 - 2) + 2;
    } else if (score < 90) {
        randNum = rand() % (10 - 2) + 2;
    } else if (score < 105) {
        randNum = rand() % (11 - 2) + 2;
    } else if (score < 120) {
        randNum = rand() % (12 - 2) + 2;
    } else if (score < 135) {
        randNum = rand() % (13 - 2) + 2;
    } else {
        randNum = rand() % (15 - 2) + 2;
    }
    
    float dx = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].x - [cannonAnchorPoint convertPoint:self.frame.origin toNode:self.scene].x;
    float dy = [cannonShootPoint convertPoint:self.frame.origin toNode:self.scene].y - [cannonAnchorPoint convertPoint:self.frame.origin toNode:self.scene].y;
    
    NSString *bubblePng = [NSString stringWithFormat:@"bubble%d.png",randNum];
    bubble = [SKSpriteNode spriteNodeWithImageNamed:bubblePng];
    bubble.xScale = 0.25;
    bubble.yScale = 0.25;
    
    SKAction *scaleOut = [SKAction scaleBy:1.3f duration:0.15];
    SKAction *scaleIn = [SKAction scaleBy:0.8f duration:0.15];
    SKAction *sequence = [SKAction sequence:@[scaleOut,scaleIn]];
    [bubble runAction:[SKAction repeatAction:sequence count:2]];
    
    bubble.position = CGPointMake(((self.frame.size.width)/2)+(dx/5), 2);
    
    // Physics!
    bubble.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:bubble.frame.size.height/2];
    bubble.physicsBody.dynamic = YES;
    bubble.physicsBody.affectedByGravity = NO;
    bubble.physicsBody.allowsRotation = NO;
    bubble.physicsBody.friction = 0.0f;
    bubble.physicsBody.restitution = 0.9f;
    bubble.physicsBody.linearDamping = 1.0f;
    
    // create label
    SKLabelNode *text = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    text.name = @"number";
    text.text = [NSString stringWithFormat:@"%i", randNum];
    text.fontSize = 20;
    text.position = CGPointMake(0, -5);
    
    // Add tag
    bubble.name = [NSString stringWithFormat:@"bubble-%i", randNum];
    
    // Category
    bubble.physicsBody.categoryBitMask = ballLaunchedCategory;
    bubble.physicsBody.contactTestBitMask = ballCategory;
    
    [bubble addChild:text];
    [self addChild:bubble];
    
    // Impulse
    
    [bubble.physicsBody applyImpulse:CGVectorMake(dx/7, dy/7)];
    
}

#pragma mark -
#pragma mark Contact Detection Methods
#pragma mark -

- (void)didBeginContact:(SKPhysicsContact*)contact {
    
    SKPhysicsBody* cannonBall;
    SKPhysicsBody* staticBall;
    
    BOOL ballCollision = NO;

    if (contact.bodyA.categoryBitMask == ballLaunchedCategory && contact.bodyB.categoryBitMask == ballCategory) {

        cannonBall = contact.bodyA;
        staticBall = contact.bodyB;
        ballCollision = YES;
        
    }
    
    if (contact.bodyB.categoryBitMask == ballLaunchedCategory && contact.bodyA.categoryBitMask == ballCategory) {
        
        cannonBall = contact.bodyB;
        staticBall = contact.bodyA;
        ballCollision = YES;
        
    }
    
    // Ball-Ball contact
    if (ballCollision) {

        SKLabelNode *text = (SKLabelNode *)[staticBall.node childNodeWithName:@"number"];
        
        int currentNumber = [text.text intValue];
        int newNumber = currentNumber-1;
        
        if (newNumber==0) {
            
            NSArray *myArray = [staticBall.node.name componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
            int originalValue = [myArray[1] intValue];
            score += originalValue;
            scoreLabel.text = [NSString stringWithFormat:@"Score: %d",score];
            [self runAction:bubbleExplode];
            [staticBall.node removeFromParent];
            
        } else {

            text.text = [NSString stringWithFormat:@"%d",newNumber];
            
        }
        
    }
    
    // Ball-Block contact
    if (contact.bodyA.categoryBitMask == bottomCategory || contact.bodyB.categoryBitMask == bottomCategory) {
        
        // block futher shoots
        canShoot = NO;
        endGame = YES;
        
        // Stop cannon
        [cannon removeAllActions];
        
        // Save highscore
        [self saveScore];
        
        // show new highscore
        if (score>highScore) {
            
            SKLabelNode *newHighscoreTitle = [SKLabelNode labelNodeWithFontNamed:@"GeezaPro"];
            newHighscoreTitle.name = @"newHighscoreTitle";
            newHighscoreTitle.text = @"New Highscore!";
            newHighscoreTitle.fontSize = 45;
            newHighscoreTitle.fontColor = UIColor.whiteColor;
            newHighscoreTitle.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
            newHighscoreTitle.position = CGPointMake(self.scene.frame.size.width/2, (self.scene.frame.size.height/2) + 100);
            [self.scene addChild:newHighscoreTitle];

        }
        
        // Present label
        SKLabelNode *loseTitle = [SKLabelNode labelNodeWithFontNamed:@"GeezaPro"];
        loseTitle.name = @"loseTitle";
        loseTitle.text = [NSString stringWithFormat:@"Score %d", score];
        loseTitle.fontSize = 65;
        loseTitle.fontColor = UIColor.whiteColor;
        loseTitle.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        loseTitle.position = CGPointMake(self.scene.frame.size.width/2, self.scene.frame.size.height/2);
        [self.scene addChild:loseTitle];
        
        // Restart
        SKSpriteNode *restart = [SKSpriteNode spriteNodeWithImageNamed:@"reload"];
        restart.name = @"restart";
        restart.xScale = 0.70;
        restart.yScale = 0.70;
        restart.position = CGPointMake((self.scene.frame.size.width/2), loseTitle.frame.origin.y - 80);
        [self.scene addChild:restart];
        
    }

    
}

#pragma mark -
#pragma mark -End Game Detection Methods
#pragma mark -

-(void)saveScore {
    
    if (score>highScore) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:score forKey:@"highScore"];
        [defaults synchronize];
    }
    
}

@end