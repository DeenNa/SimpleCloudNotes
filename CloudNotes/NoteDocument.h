//
//  NoteDocument.h
//  CloudNotes
//
//  Created by Deen Na on 2/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteDocument;

@protocol NoteDocumentDeletate <NSObject>
- (void)noteDocumentContentsUpdated:(NoteDocument *)document;
@end

@interface NoteDocument : UIDocument

@property (strong, readwrite) NSString *documentText;
@property (weak, readwrite) id delegate;
@end
