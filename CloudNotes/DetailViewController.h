//
//  DetailViewController.h
//  CloudNotes
//
//  Created by Deen Na on 2/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteDocument.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, NoteDocumentDeletate, UITextViewDelegate>

@property (strong, nonatomic) NoteDocument *document;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@end
