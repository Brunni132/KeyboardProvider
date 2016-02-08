//
//  InstructionsController.m
//  KeyboardProvider
//
//  Created by Florian Bronnimann on 10.05.13.
//  Copyright (c) 2013 Brunni. All rights reserved.
//

#import "InstructionsController.h"

@interface InstructionsController ()

@end

@implementation InstructionsController
@synthesize textField;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib {
	NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Instructions" ofType:@"rtf"]];
	NSAttributedString *content = [[NSAttributedString alloc] initWithRTF:data
													   documentAttributes:NULL];
	[[self.textField textStorage] setAttributedString:content];
}

@end
