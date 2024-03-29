//
//  NoteDocument.m
//  CloudNotes
//
//  Created by Deen Na on 2/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "NoteDocument.h"

@implementation NoteDocument
@synthesize documentText = __documentText;
@synthesize delegate = __delegate;

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	NSString *text = nil;
	if ([contents length] > 0) {
		text = [[NSString alloc] initWithBytes:[contents bytes] length:[contents length] encoding:NSUTF8StringEncoding];
	} else {
		text = @"";
	}
	[self setDocumentText:text];
	
	if ([[self delegate] respondsToSelector:@selector(noteDocumentContentsUpdated:)]) {
		[[self delegate] noteDocumentContentsUpdated:self];
	}
	return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	if ([[self documentText] length] == 0) {
		[self setDocumentText:@"New note"];
	}
	return [NSData dataWithBytes:[[self documentText] UTF8String] length:[[self documentText] length]];
}

@end
