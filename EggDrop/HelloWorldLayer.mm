//
//  HelloWorldLayer.mm
//  EggDrop
//
//  Created by Alec Thomson on 4/17/11.
//  Copyright Massachusetts Institute of Technology 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "EggNail.h"
#import "EggHinge.h"
#import "EggCompoundBlock.h"
#import "WindRayCastCallback.h"
#import "WindDisaster.h"
#import "QuakeDisaster.h"
#import "ResourceManager.h"
#import "BreakablePhysicalObject.h"
#import "CloudEggBlock.h"
#import <math.h>
#import "CDAudioManager.h"

// enums that will be used as tags
enum {
	kTagTileMap = 1,
	kTagBatchNode = 1,
	kTagAnimation1 = 1,
};



// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize windy;
@synthesize windStrength;

@synthesize quakeVelocity;
@synthesize quakeFrequency;
@synthesize quakeFloor;
@synthesize quake;

@synthesize timeSinceLastDisaster;

@synthesize objectsToRetain;
@synthesize myClouds;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

//this let's us receive single touches.
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
		// enable touches
		self.isTouchEnabled = YES;
		
		// enable accelerometer
		self.isAccelerometerEnabled = YES;
		
		
		
		// Debug Draw functions
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );
		
		uint32 flags = 0;
//		flags += b2DebugDraw::e_shapeBit;
//		flags += b2DebugDraw::e_jointBit;
//		flags += b2DebugDraw::e_aabbBit;
//		flags += b2DebugDraw::e_pairBit;
//		flags += b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);		
		
        //set up our UI
        /*
         CCMenuItem *starMenuItem = [CCMenuItemImage 
         itemFromNormalImage:@"ButtonStar.png" selectedImage:@"ButtonStarSel.png" 
         target:self selector:@selector(starButtonTapped:)];
         starMenuItem.position = ccp(60, 60);
         CCMenu *starMenu = [CCMenu menuWithItems:starMenuItem, nil];
         starMenu.position = CGPointZero;
         [self addChild:starMenu];
         */
        resetButton = [CCMenuItemImage 
                                  itemFromNormalImage:@"reset_button.png" selectedImage:@"reset_button.png" 
                                  target:self selector:@selector(resetButtonPressed: )];
        resetButton.position = ccp(screenSize.width-25, 25);
        
        nextLevelButton = [CCMenuItemImage 
                                       itemFromNormalImage:@"play_button.png" selectedImage:@"play_button.png"
                                       target:self selector:@selector(nextLevelButtonPressed: )];
        nextLevelButton.position = ccp(screenSize.width/2, screenSize.height/2);
        
        nextTutorialButton = [CCMenuItemImage 
                              itemFromNormalImage:@"play_button.png" selectedImage:@"play_button.png"
                              target:self selector:@selector(nextTutorialButtonPressed: )];
        nextTutorialButton.position = ccp(screenSize.width-25, 25);
        
        myUI = [[CCMenu menuWithItems:resetButton, nextLevelButton, nextTutorialButton, nil] retain];
        myUI.position = CGPointZero;

        myParser = [[LevelParser alloc] init];
        
        currentLevelIndex = 0;
        currentTutorialIndex = 0;
        levelString = [[ResourceManager xmlLevelList] objectAtIndex:currentLevelIndex];
        
        if ([levelString isEqualToString:@"Tutorial"]) {
            currentTutorial = [[ResourceManager tutorialList] objectAtIndex:currentTutorialIndex];
            currentTutorialIndex++;
            
            //load our initial tutorial
            [self loadFromTutorial:currentTutorial];
        }
        else{
            [myParser loadDataFromXML:levelString];
            currentLevel = myParser.level;
            
            //now here is where we load our initial level 
            [self loadFromLevel:currentLevel]; 
        }
        
	}
	return self;
}


-(void) playButtonPressed:(id)sender
{
    NSLog(@"PLAY BUTTON PRESSED: ");
}

-(void) resetButtonPressed:(id)sender
{
    //stop all the sound effects when we press the reset button
    [[[CDAudioManager sharedManager] soundEngine] stopAllSounds];
    [self clearLevel];
    [self loadFromLevel:currentLevel]; 
}

-(void) nextLevelButtonPressed:(id)sender
{
    //try to load the next level of the game. 
    if(currentLevelIndex+1 < [[ResourceManager xmlLevelList] count])
    {
        currentLevelIndex++;
        levelString = [[ResourceManager xmlLevelList] objectAtIndex:currentLevelIndex];
        if ([levelString isEqualToString:@"Tutorial"]) {
            currentTutorial = [[ResourceManager tutorialList] objectAtIndex:currentTutorialIndex];
            currentTutorialIndex++;
            
            [self clearLevel];
            [self loadFromTutorial:currentTutorial];
        }
        else{
            [myParser loadDataFromXML:levelString];
            currentLevel = myParser.level;
            
            [self clearLevel];
            [self loadFromLevel:currentLevel]; 
        }
    }
    else
    {
        NSLog(@"Out of levels!");
    }
    
    NSLog(@"NEXT LEVEL!!!");
}

-(void) nextTutorialButtonPressed:(id)sender
{
    //try to load the next level of the game. 
    if(currentSceneIndex+1 < [scenes count])
    {
        currentSceneIndex++;
        if (self != nil) {
            CGSize screenSize = [CCDirector sharedDirector].winSize;
            
            //load the first scene
            
            NSString* curScene = [scenes objectAtIndex:currentSceneIndex];
            
            CCSprite *background = [CCSprite spriteWithFile:curScene];
            
            NSLog(@"background: %@", background);
            
            //place the image in the center of the screen
            background.position = ccp(screenSize.width/2, screenSize.height/2);
            
            //add the sprite object to the layer
            [self addChild:background];
        }
    }
    else
    {
        NSLog(@"Out of Screens!");
        [self nextLevelButtonPressed:sender];
    }
    
    NSLog(@"NEXT SCREEN!!!");
}

-(void) applyWind
{
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    //Okay, we've got simulated wind through raycasting right here
    //basically we cast several horizontal rays and apply wind to the 
    //first object they hit. 
    
    //increase numRays to increase wind density
    int numRays = 22;
    float rayInterval = (screenSize.height-20)/(float)numRays;
    //more complex raycast callback
    for(int i = 0; i <= numRays; i++)
    {
        float y = i*rayInterval+10;
        WindRayCastCallback myCallback(windStrength);
        b2Vec2 point1(1, y/PTM_RATIO);
        b2Vec2 point2(screenSize.width/PTM_RATIO, y/PTM_RATIO - 0.1);
        world->RayCast(&myCallback, point1, point2);
    }
    
}


-(void) applyQuake
{
    //we need to shake the quakefloor back and forth for the quake. 
    //using the timeSinceLastDisaster as a reference for the frequency.
    float dir = sinf(M_PI*2*quakeFrequency*timeSinceLastDisaster);
    quakeFloor->body->SetLinearVelocity(b2Vec2(dir*quakeVelocity, 0));
}


-(void) draw
{
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

}

-(void) tick: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	if(state == paused || state == levelWon || state == eggBroken || state == tut)
        return;
    
    int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);

	if(windy)
        [self applyWind];
    if(quake)
        [self applyQuake];
    //create our list of guys to remove
    NSMutableArray *objectsToDestroy = [[NSMutableArray array] retain];
    
	//Iterate over the bodies in the physics world. This is where we call the updatePhysics function. 
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL && [((id)b->GetUserData()) conformsToProtocol:@protocol(PhysicalObject) ]) {
            id <PhysicalObject> myObject = (id <PhysicalObject>)b->GetUserData();
            [myObject updatePhysics];
            //now check for breakable objects
            if([myObject conformsToProtocol:@protocol(BreakablePhysicalObject)])
            {
                id <BreakablePhysicalObject> breakableObject = (id <BreakablePhysicalObject>)myObject;
                if([breakableObject shouldRemoveFromPhysics])
                    [objectsToDestroy addObject:breakableObject];
            }
		}	
	}
    for (b2Joint* j = world->GetJointList(); j; j=j->GetNext())
    {
        if(j->GetUserData() != NULL && [((id)j->GetUserData()) conformsToProtocol:@protocol(PhysicalObject)]) {
            id <PhysicalObject> myObject = (id <PhysicalObject>)j->GetUserData();
            [myObject updatePhysics];
            if([myObject conformsToProtocol:@protocol(BreakablePhysicalObject)])
            {
                id <BreakablePhysicalObject> breakableObject = (id <BreakablePhysicalObject>)myObject;
                if([breakableObject shouldRemoveFromPhysics])
                    [objectsToDestroy addObject:breakableObject];
            }
        }
    }
    //now destroy our breakable objects. 
    for(CCNode <BreakablePhysicalObject> *objectToDestroy in objectsToDestroy)
    {
        [self removeChild:objectToDestroy cleanup:YES];
        [objectToDestroy removeFromPhysicsWorld:world];
    }
    [objectsToDestroy release];
    
    if(myEgg.broken && !eggAlreadyBroken)
    {
        [eggLabel setString:@"Egg Broken!!"];
        eggLabel.visible = YES;
        [self reorderChild:eggLabel z:10];
        eggAlreadyBroken = YES;
        state = eggBroken;
    }
    

    //handle placing disasters
    if(state == runningDisasters)
    {
        timeSinceLastDisaster+=dt;
        if(currentDisaster == nil && [disasters count] != 0)
        {
            EggDisaster *nextDisaster = [disasters objectAtIndex:0];
            float timeToNextDisaster = nextDisaster.delay-timeSinceLastDisaster;
            [stateLabel setString:[NSString stringWithFormat:@"Next Disaster in: %d", (int)roundf(timeToNextDisaster)]];
            if(timeToNextDisaster <= 0)
            {
                currentDisaster = [nextDisaster retain];
                [disasters removeObjectAtIndex:0];
                timeSinceLastDisaster = 0;
                [currentDisaster addDisasterToGame:self withWorld:world];
                [stateLabel setString:[currentDisaster disasterDescription:self]];
            }

        }
        else if(currentDisaster != nil)
        {
            [stateLabel setString:[currentDisaster disasterDescription:self]];
            if(![currentDisaster isDisasterActive:self withWorld:world])
            {
                [currentDisaster removeDisasterFromGame:self withWorld:world];
                timeSinceLastDisaster = 0;
                [currentDisaster release];
                currentDisaster = nil;
            }
        }
        else if([disasters count] == 0)
        {
            [stateLabel setString:@"Level Complete!"];
            state = levelWon;
            [nextLevelButton setIsEnabled:YES];
            nextLevelButton.visible = YES;
        }
    }
    
    
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"HELLO");
    if(objectToPlace != nil || [objectsToPlace count] == 0 || state != placingObjects)
        return NO;
    
    //first, remove this object from the "next" preview
    [self removeChild:nextObjectToPlace cleanup:YES];
    
    //go ahead and add this object
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    objectToPlace = [objectsToPlace objectAtIndex:0];
    objectToPlace.position = ccp(location.x, location.y);
    [objectToPlace beginAddToWorld:location];
    
    [self addChild:objectToPlace z:objectToPlace.desiredZ];
    
    if([objectsToPlace count] > 1)
    {
        nextObjectToPlace = [objectsToPlace objectAtIndex:1];
        //nextObjectToPlace.position = ccp(440, 270);
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        [nextObjectToPlace resetToPosition:screenSize atPoint:ccp(440, 270)];
        [self addChild:nextObjectToPlace];
    }
    
    NSLog(@"HELLO AGAIN");
    return YES;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(objectToPlace == nil)
        return;
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    //objectToPlace.position = ccp(location.x, location.y);
    [objectToPlace updateAddToWorld:location];
    
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(objectToPlace == nil)
        return;

    //reset the egg's base impulse here to avoid breaking the egg due to messing with the physics world
    myEgg->baseImpulse = -1;
    if([objectToPlace addToPhysicsWorld:world])
        [objectsToPlace removeObject:objectToPlace];
    else
    {
        [self removeChild:objectToPlace cleanup:YES];
        [self removeChild:nextObjectToPlace cleanup:YES];
        nextObjectToPlace = objectToPlace;
        //nextObjectToPlace.position = ccp(440, 270);
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        [nextObjectToPlace resetToPosition:screenSize atPoint:ccp(440, 270)];
        [self addChild:nextObjectToPlace];
    }
    objectToPlace = nil;
    if([objectsToPlace count] == 0 && state != eggBroken)
    {
        [stateLabel setString:@"No more objects. Begin disasters!"];
        state = runningDisasters;
        timeSinceLastDisaster = 0;
    }
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(objectToPlace == nil)
        return;
    [self removeChild:objectToPlace cleanup:YES];
    [self removeChild:nextObjectToPlace cleanup:YES];
    nextObjectToPlace = objectToPlace;
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    [nextObjectToPlace resetToPosition:screenSize atPoint:ccp(440, 270)];
    [self addChild:nextObjectToPlace];

    objectToPlace = nil;
}


/*
//in case we ever want to actually use the accelerometer, I'm leaving this function in here. 
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
	static float prevX=0, prevY=0;
	
	//#define kFilterFactor 0.05f
#define kFilterFactor 1.0f	// don't use filter. the code is here just as an example
	
	float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
	float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
	
	prevX = accelX;
	prevY = accelY;
	
	// accelerometer values are in "Portrait" mode. Change them to Landscape left
	// multiply the gravity by 10
	b2Vec2 gravity( -accelY * 10, accelX * 10);
	
	world->SetGravity( gravity );
}
*/

-(void) clearLevel
{
    if(world != NULL)
    {
        delete world;
        world = NULL;
    }
    
    if ([levelString isEqualToString:@"Tutorial"]){
        [scenes release];
    }
    else{
        [objectsToRetain release];
        [myClouds release];
        [objectsToPlace release];
        [disasters release];
        
        
    }
    
    [self removeAllChildrenWithCleanup:YES];
    [self unscheduleAllSelectors];
    
    currentDisaster = nil;
    objectToPlace = nil;
    
}

-(void) loadFromLevel:(EggLevel *)level
{
    
    if (self != nil) {
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        //load the image files
        CCSprite *background = [CCSprite spriteWithFile:@"background.png"];
        
        NSLog(@"background: %@", background);
        
        //place the image in the center of the screen
        background.position = ccp(screenSize.width/2, screenSize.height/2);
        
        //add the sprite object to the layer
        [self addChild:background];
    }

    objectsToRetain = [[NSMutableArray array] retain];
    myClouds = [[NSMutableArray array] retain];

    
    nextLevelButton.visible = NO;
    [nextLevelButton setIsEnabled:NO];
    
    resetButton.visible = YES;
    [resetButton setIsEnabled:YES];
    
    nextTutorialButton.visible = NO;
    [nextTutorialButton setIsEnabled:NO];
    
    //first set up the physics again. 
    
    timeSinceLastDisaster = 0;
    eggAlreadyBroken = NO;
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
    
    // Define the gravity vector.
    b2Vec2 gravity;
    gravity.Set(0.0f, -10.0f);
    
    // Do we want to let bodies sleep?
    // This will speed up the physics simulation
    bool doSleep = true;
    
    // Construct a world object, which will hold and simulate the rigid bodies.
    world = new b2World(gravity, doSleep);
    
    //Alec: I believe this should avoid the problem of tunneling, but decrease performance. Something to keep in min. 
    world->SetContinuousPhysics(true);
    world->SetDebugDraw(m_debugDraw);
    
    //Here is where we create the boundaries of the world
    // Define the ground body.
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0); // bottom-left corner
    
    // Call the body factory which allocates memory for the ground body
    // from a pool and creates the ground box shape (also from a pool).
    // The body is also added to the world.
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    
    // Define the ground box shape.
    b2PolygonShape groundBox;		
    
    // bottom
    groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&groundBox,0);
    
    //LOL: no more top for the meteors to come through. 
    // top
    //groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO));
    //groundBody->CreateFixture(&groundBox,0);
    
    // left
    groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
    groundBody->CreateFixture(&groundBox,0);
    
    // right
    groundBox.SetAsEdge(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&groundBox,0);
    
    //Set up the floor for the quakes
    quakeFloor = [[[EggBlock alloc] initWithRect:CGRectMake(screenSize.width/2, 15, 400, 30)] autorelease];
    [self addChild:quakeFloor];
    [quakeFloor addToPhysicsWorld:world];
    quakeFloor->body->SetType(b2_staticBody);
    quake = NO;

    
    //WIND
    windy = NO;
    windStrength = 2;
    
    //stateLabel = [CCLabelTTF labelWithString:@"place objects" fontName:@"Arial" fontSize:22];
    stateLabel = [CCLabelTTF labelWithString:@"place objects" dimensions:CGSizeMake(screenSize.width, 30) alignment:UITextAlignmentCenter fontName:@"Action Man" fontSize:24];
    
    [self addChild:stateLabel z:0];
    [stateLabel setColor:ccc3(50,50,50)];
    stateLabel.position = ccp( screenSize.width/2, screenSize.height-60);
    
    eggLabel = [CCLabelTTF labelWithString:@"Egg Status: Okay!" fontName:@"Arial" fontSize:18];
    eggLabel = [CCLabelTTF labelWithString:@"Egg Status: Okay!" dimensions:CGSizeMake(screenSize.width, 30) alignment:UITextAlignmentLeft fontName:@"Action Man" fontSize:36];
    [self addChild:eggLabel z:0];
    [eggLabel setColor:ccc3(50, 50, 50)];
    eggLabel.position = ccp(screenSize.width/2 + 100, screenSize.height/2);
    eggLabel.visible = NO;
    
    nextLabel = [CCLabelTTF labelWithString:@"Next:" dimensions:CGSizeMake(100, 30) alignment:UITextAlignmentLeft fontName:@"Action Man" fontSize:18];
    [self addChild:nextLabel z:0];
    [nextLabel setColor:ccc3(50, 50, 50)];
    nextLabel.position = ccp(460, 290);
    
        
    //now load our level relevant stuff
    objectsToPlace = [[NSMutableArray array] retain];
    for(PlaceableNode * p in level.objectsToPlace)
    {
        PlaceableNode * clone = [[p copy] autorelease];
        [objectsToPlace addObject:clone ];
        if([clone class] == [CloudEggBlock class])
            [myClouds addObject:clone];
    }
    disasters = [[NSMutableArray array] retain];
    for(EggDisaster * d in level.disasters)
        [disasters addObject:[[d copy] autorelease]];
    
    NSMutableString* disastersString = [[NSMutableString alloc] initWithString:@"Disasters: "];
    int n;
     
    for(n = 0; n < [disasters count]; n++){
        EggDisaster *disaster = [disasters objectAtIndex:n];
        [disastersString appendString:(disaster.disasterName)];
        
        if(n < [disasters count] - 1){
            [disastersString appendString:@", "];
        }

    }
    
    
    disasterLabel = [CCLabelTTF labelWithString:disastersString dimensions:CGSizeMake(screenSize.width, 30) alignment:UITextAlignmentLeft fontName:@"Action Man" fontSize:18]; 
    [disastersString release];
    
    [self addChild:disasterLabel z:0];
    [disasterLabel setColor:ccc3(50, 50, 50)];
    disasterLabel.position = ccp(screenSize.width/2, screenSize.height-30);
    
    for(CCNode <PhysicalObject> * p in level.objectsInPlace)
    {
        CCNode <PhysicalObject> * clone = [[p copy] autorelease];
        [self addChild:clone];
        [clone addToPhysicsWorld:world];
        //a little bit sloppy here, but this seemed like the easiest way to accomplish this
        if([clone class] == [CloudEggBlock class])
            [myClouds addObject:clone];
    }
    
    myEgg = [[level myEgg] copy];
    [self addChild:myEgg];
    [myEgg addToPhysicsWorld:world];
    
    nextObjectToPlace = [objectsToPlace objectAtIndex:0];
    
    //nextObjectToPlace.position = ccp(440, 270);
    [nextObjectToPlace resetToPosition:screenSize atPoint:ccp(440, 270)];
    [self addChild:nextObjectToPlace];
    
    //and load up our menu again
    [self addChild:myUI z:2];
    
    state = placingObjects;
    
    [self schedule: @selector(tick:) interval:.01];
}

-(void) loadFromTutorial:(EggTutorial *)tutorial
{
    
    currentSceneIndex = 0;
    
    scenes = [[NSMutableArray array] retain];
    for(NSString* s in tutorial.scenes)
        [scenes addObject:[[s copy] autorelease]];
    
    if (self != nil) {
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        //load the first scene
        
        NSString* curScene = [scenes objectAtIndex:currentSceneIndex];
        
        CCSprite *background = [CCSprite spriteWithFile:curScene];
        
        NSLog(@"background: %@", background);
        
        //place the image in the center of the screen
        background.position = ccp(screenSize.width/2, screenSize.height/2);
        
        //add the sprite object to the layer
        [self addChild:background];
    }
    
    //first set up the physics again. 
    
    timeSinceLastDisaster = 0;
    eggAlreadyBroken = NO;
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
    
    // Define the gravity vector.
    b2Vec2 gravity;
    gravity.Set(0.0f, -10.0f);
    
    // Do we want to let bodies sleep?
    // This will speed up the physics simulation
    bool doSleep = true;
    
    // Construct a world object, which will hold and simulate the rigid bodies.
    world = new b2World(gravity, doSleep);
    
    //Alec: I believe this should avoid the problem of tunneling, but decrease performance. Something to keep in min. 
    world->SetContinuousPhysics(true);
    world->SetDebugDraw(m_debugDraw);
    
    //Here is where we create the boundaries of the world
    // Define the ground body.
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0); // bottom-left corner
    
    // Call the body factory which allocates memory for the ground body
    // from a pool and creates the ground box shape (also from a pool).
    // The body is also added to the world.
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    
    // Define the ground box shape.
    b2PolygonShape groundBox;		
    
    // bottom
    groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&groundBox,0);
    
    // top
    //groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO));
    //groundBody->CreateFixture(&groundBox,0);
    
    // left
    groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
    groundBody->CreateFixture(&groundBox,0);
    
    // right
    groundBox.SetAsEdge(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&groundBox,0);
    
    
    nextLevelButton.visible = NO;
    [nextLevelButton setIsEnabled:NO];
    
    resetButton.visible = NO;
    [resetButton setIsEnabled:NO];
    
    nextTutorialButton.visible = YES;
    [nextTutorialButton setIsEnabled:YES];

    
    //and load up our menu again
    [self addChild:myUI z:2];
    
    state = tut;
    
    [self schedule: @selector(tick:) interval:.01];
}
 
// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	delete world;
	world = NULL;
	
	delete m_debugDraw;
    [objectsToRetain release];
    [myClouds release];
    [objectsToPlace release];
    [disasters release];
    [scenes release];
    [myUI release];
    [myParser release];
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
