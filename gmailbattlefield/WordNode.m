//
//  WordNode.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import "WordNode.h"
#import "cocos2d.h"
@implementation WordNode
@synthesize word;

- (id)initWithWord:(NSString*)w{
    self = [super init];
    if (self) {
        word = w;
        CCSprite* sprite = [CCSprite spriteWithFile:@"round.png"];
        sprite.position=CGPointMake(50,50);
        label = [CCLabelTTF labelWithString:word fontName:@"Marker Felt" fontSize:24];
        label.position=CGPointMake(50, 50);
        [self addChild:sprite];
        [self addChild:label];
        [self setContentSize:CGSizeMake(100, 100)];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
    return self;    
}

-(void)setWord:(NSString *)w{
    self.word = w;
    [label setString:word];
}
-(void)dealloc{
    self.word=nil;
    [label release];
    [super dealloc];
}

@end
