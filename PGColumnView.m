/* Copyright © 2007-2008, The Sequential Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the the Sequential Project nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE Sequential Project ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE Sequential Project BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "PGColumnView.h"

// Views
#import "PGClipView.h"

@implementation PGColumnView

#pragma mark Instance Methods

- (unsigned)numberOfColumns
{
	return [_views count];
}
- (NSArray *)views
{
	return [[_views copy] autorelease];
}
- (id)lastView
{
	return [_views lastObject];
}
- (id)viewAtIndex:(unsigned)index
{
	return [_views objectAtIndex:index];
}

#pragma mark -

- (void)addColumnWithView:(NSView *)aView
{
	[self insertColumnWithView:aView atIndex:[_views count]];
}
- (void)insertColumnWithView:(NSView *)aView
        atIndex:(unsigned)index
{
	NSParameterAssert(aView);
	NSParameterAssert([_views indexOfObjectIdenticalTo:aView] == NSNotFound);
	PGClipView *const clip = [[[PGClipView alloc] init] autorelease];
	[_clipViews insertObject:clip atIndex:index];
	[_views insertObject:aView atIndex:index];
	[_view addSubview:clip];
	[clip setDelegate:self];
	[clip setBackgroundColor:nil];
	[clip setShowsBorder:NO];
	[clip setDocumentView:aView];
	[self layout];
	[aView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[aView setFrameSize:NSMakeSize(NSWidth([clip bounds]), NSHeight([aView frame]))];
	[self scrollToTopOfColumnWithView:aView];
}
- (void)removeColumnsAfterView:(NSView *)aView
{
	unsigned const i = aView ? [_views indexOfObject:aView] : 0;
	NSParameterAssert(NSNotFound != i);
	if([_views count] <= i + 1) return;
	while([_views count] > i + 1) {
		PGClipView *const clip = [_clipViews lastObject];
		[clip setDocumentView:nil];
		[clip removeFromSuperview];
		[_clipViews removeLastObject];
		[_views removeLastObject];
	}
	[self layout];
	return;
}

#pragma mark -

- (float)columnWidth
{
	return _columnWidth;
}
- (void)setColumnWidth:(float)width
{
	_columnWidth = roundf(width);
	[self layout];
}

#pragma mark -

- (void)scrollToTopOfColumnWithView:(NSView *)aView
{
	[[_clipViews objectAtIndex:[_views indexOfObjectIdenticalTo:aView]]  scrollToEdge:PGMaxYEdgeMask animation:PGAllowAnimation];
}
- (void)scrollToLastColumnAnimate:(BOOL)flag
{
	[_clipView scrollToEdge:PGMaxXEdgeMask animation:(flag ? PGPreferAnimation : PGNoAnimation)];
}

#pragma mark -

- (void)layout
{
	NSRect const b = [self bounds];
	[_view setFrameSize:NSMakeSize(MAX(_columnWidth * [_views count], NSWidth(b)), NSHeight(b))];
	NSRect const vb = [_view bounds];
	unsigned i = 0;
	unsigned const count = [_clipViews count];
	for(; i < count; i++) [[_clipViews objectAtIndex:i] setFrame:NSMakeRect(NSMinX(vb) + _columnWidth * i, NSMinY(vb), _columnWidth, NSHeight(vb))];
	[self setNeedsDisplay:YES];
}

#pragma mark PGClipViewDelegate Protocol

- (BOOL)clipView:(PGClipView *)sender
        handleMouseEvent:(NSEvent *)anEvent
        first:(BOOL)flag
{
	unsigned const i = [_clipViews indexOfObjectIdenticalTo:sender];
	if(NSNotFound == i) return NO;
	[[_views objectAtIndex:i] mouseDown:anEvent];
	return YES;
}

#pragma mark NSView

- (id)initWithFrame:(NSRect)aRect
{
	if((self = [super initWithFrame:aRect])) {
		_clipView = [[PGClipView alloc] initWithFrame:[self bounds]];
		[_clipView setBackgroundColor:nil];
		[_clipView setShowsBorder:NO];
		[_clipView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_clipView setPinLocation:PGMinXEdgeMask];
		[self addSubview:_clipView];
		_view = [[NSView alloc] initWithFrame:NSZeroRect];
		[_clipView setDocumentView:_view];
		_clipViews = [[NSMutableArray alloc] init];
		_views = [[NSMutableArray alloc] init];
		_columnWidth = 128.0f + 12.0f;
	}
	return self;
}
- (void)setFrameSize:(NSSize)aSize
{
	if(NSEqualSizes([self frame].size, aSize)) return;
	[super setFrameSize:aSize];
	[self layout];
}

#pragma mark NSObject

- (id)init
{
	return [self initWithFrame:NSZeroRect];
}
- (void)dealloc
{
	[_clipView release];
	[_view release];
	[_clipViews release];
	[_views release];
	[super dealloc];
}

@end
