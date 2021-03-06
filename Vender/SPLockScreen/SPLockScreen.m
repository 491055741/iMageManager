//
//  SPLockScreen.m
//  SuQian
//
//  Created by Suraj on 24/9/12.
//  Copyright (c) 2012 Suraj. All rights reserved.
//

#import "SPLockScreen.h"
#import "NormalCircle.h"
#import "SPLockOverlay.h"

#define kSeed								23
#define kAlterOne							1234
#define kAlterTwo							4321
#define kTagIdentifier                      22222
#define kCircleRadius   30.0

@interface SPLockScreen()
@property (nonatomic, strong) NormalCircle *selectedCell;
@property (nonatomic, strong) SPLockOverlay *overLay;
@property (nonatomic) NSInteger oldCellIndex,currentCellIndex;
@property (nonatomic, strong) NSMutableDictionary *drawnLines;
@property (nonatomic, strong) NSMutableArray *finalLines, *cellsInOrder;

- (void)resetScreen;
+ (CGFloat)calcHeight:(CGFloat)width;
@end

@implementation SPLockScreen

- (id)init
{
    self = [super init];
	if (self) {

	}
	return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview != nil) {
        [self setNeedsDisplay];
        [self setUpTheScreen];
        [self addGestureRecognizer];
    }
}

- (id)initWithDelegate:(id<LockScreenDelegate>)lockDelegate
{
	self = [self init];
	self.delegate = lockDelegate;
	
	return self;
}

+ (CGFloat)calcHeight:(CGFloat)width
{
    CGFloat radius = kCircleRadius;
    CGFloat gap = (width - 6 * radius )/4;
    return 6 * radius + 2 * gap;
}

- (void)setUpTheScreen
{
	CGFloat radius = 30.0;
	CGFloat gap = (self.frame.size.width - 6 * radius )/4;
	CGFloat topOffset = radius;
	
	for (int i=0; i < 9; i++) {
		NormalCircle *circle = [[NormalCircle alloc]initwithRadius:radius];
		int column =  i % 3;
		int row    = i / 3;
		CGFloat x = (gap + radius) + (gap + 2*radius)*column;
		CGFloat y = (row * gap + row * 2 * radius) + topOffset;
		circle.center = CGPointMake(x, y);
		circle.tag = (row+kSeed)*kTagIdentifier + (column + kSeed);
		[self addSubview:circle];
	}
	self.drawnLines = [[NSMutableDictionary alloc]init];
	self.finalLines = [[NSMutableArray alloc]init];
	self.cellsInOrder = [[NSMutableArray alloc]init];
	// Add an overlay view
	self.overLay = [[SPLockOverlay alloc]init];
    self.overLay.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	[self.overLay setUserInteractionEnabled:NO];
	[self addSubview:self.overLay];
	// set selected cell indexes to be invalid
	self.currentCellIndex = -1;
	self.oldCellIndex = self.currentCellIndex;
}

#pragma - helper methods

- (NSInteger )indexForPoint:(CGPoint)point
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[NormalCircle class]])
		{
			if(CGRectContainsPoint(view.frame, point)){
				NormalCircle *cell = (NormalCircle *)view;
				
				if(cell.selected == NO)	{
					[cell highlightCell];
					self.currentCellIndex = [self indexForCell:cell];
					self.selectedCell = cell;
				}
				
				else if (cell.selected == YES && self.allowClosedPattern == YES) {
					self.currentCellIndex = [self indexForCell:cell];
					self.selectedCell = cell;
				}
				
				int row = view.tag/kTagIdentifier - kSeed;
				int column = view.tag % kTagIdentifier - kSeed;
				return row * 3 + column;
			}
		}
	}
	return -1;
}

- (NSInteger) indexForCell:(NormalCircle *)cell
{
	if([cell isKindOfClass:[NormalCircle class]] == NO || [cell.superview isEqual:self] == NO) return -1;
	else
		return (cell.tag/kTagIdentifier - kSeed)*3 + (cell.tag % kTagIdentifier - kSeed);
}

- (NormalCircle *)cellAtIndex:(NSInteger)index
{
	if(index<0 || index > 8) return nil;
	return (NormalCircle *)[self viewWithTag:((index/3+kSeed)*kTagIdentifier + index % 3 + kSeed)];
}

- (NSNumber *) uniqueLineIdForLineJoiningPoint:(NSInteger)A AndPoint:(NSInteger)B
{
	return @(abs(A+B)*kAlterOne + abs(A-B)*kAlterTwo);
}

- (void)handlePanAtPoint:(CGPoint)point
{
	self.oldCellIndex = self.currentCellIndex;
	NSInteger cellPos = [self indexForPoint:point];
	
	if(cellPos >=0 && cellPos != self.oldCellIndex)
		[self.cellsInOrder addObject:@(self.currentCellIndex + 1)];
	
	if(cellPos < 0 && self.oldCellIndex < 0) return;
	
	else if(cellPos < 0) {
        return;
        // not draw line while dragging
//		SPLine *aLine = [[SPLine alloc]initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center toPoint:point AndIsFullLength:NO];
//		[self.overLay.pointsToDraw removeAllObjects];
//		[self.overLay.pointsToDraw addObjectsFromArray:self.finalLines];
//		[self.overLay.pointsToDraw addObject:aLine];
//		[self.overLay setNeedsDisplay];
	}
	else if(cellPos >=0 && self.currentCellIndex == self.oldCellIndex) return;
	else if (cellPos >=0 && self.oldCellIndex == -1) return;
	else if(cellPos >= 0 && self.oldCellIndex != self.currentCellIndex)
	{
		// two situations: line already drawn, or not fully drawn yet
		NSNumber *uniqueId = [self uniqueLineIdForLineJoiningPoint:self.oldCellIndex AndPoint:self.currentCellIndex];
		
		if(![self.drawnLines objectForKey:uniqueId])
		{
			SPLine *aLine = [[SPLine alloc]initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center toPoint:self.selectedCell.center AndIsFullLength:YES];
			[self.finalLines addObject:aLine];
			[self.overLay.pointsToDraw removeAllObjects];
			[self.overLay.pointsToDraw addObjectsFromArray:self.finalLines];
			[self.overLay setNeedsDisplay];
			[self.drawnLines setObject:@(YES) forKey:uniqueId];
		}
		else return;
	}
}

- (void)endPattern
{
	if ([self.delegate respondsToSelector:@selector(lockScreen:didEndWithPattern:)])
		[self.delegate lockScreen:self didEndWithPattern:[self patternToString]];
	[self resetScreen];
}

- (NSString *)patternToString
{
    NSMutableString *patternString = [NSMutableString stringWithCapacity:10];
    for (NSNumber *num in self.cellsInOrder) {
        [patternString appendString:[num stringValue]];
    }
	NSLog(@"PATTERN: %@", patternString);
    return patternString;
}

- (NSNumber *)patternToUniqueId
{
	long finalNumber = 0;
	long thisNum;
	for(int i = self.cellsInOrder.count - 1 ; i >= 0 ; i--){
		thisNum = ([[self.cellsInOrder objectAtIndex:i] integerValue]) * pow(10, (self.cellsInOrder.count - i - 1));
		finalNumber = finalNumber + thisNum;
	}
	return @(finalNumber);
}

- (void)resetScreen
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[NormalCircle class]])
			[(NormalCircle *)view resetCell];
	}
	[self.finalLines removeAllObjects];
	[self.drawnLines removeAllObjects];
	[self.cellsInOrder removeAllObjects];
	[self.overLay.pointsToDraw removeAllObjects];
	[self.overLay setNeedsDisplay];
	self.oldCellIndex = -1;
	self.currentCellIndex = -1;
	self.selectedCell = nil;
}

#pragma - Gesture Handler

- (void)addGestureRecognizer
{
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(gestured:)];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(gestured:)];
	[self addGestureRecognizer:pan];
	[self addGestureRecognizer:tap];
}

- (void)gestured:(UIGestureRecognizer *)gesture
{
	CGPoint point = [gesture locationInView:self];
	if([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
		if(gesture.state == UIGestureRecognizerStateEnded ) {
			if(self.finalLines.count > 0)[self endPattern];
			else [self resetScreen];
		}
		else [self handlePanAtPoint:point];
	}
	else {
		NSInteger cellPos = [self indexForPoint:point];
		self.oldCellIndex = self.currentCellIndex;
		if(cellPos >=0) {
			[self.cellsInOrder addObject:@(self.currentCellIndex)];
			[self performSelector:@selector(endPattern) withObject:nil afterDelay:0.3];
		}
	}
}
@end
