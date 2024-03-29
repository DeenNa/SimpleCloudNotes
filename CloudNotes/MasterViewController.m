//
//  MasterViewController.m
//  CloudNotes
//
//  Created by Deen Na on 2/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController ()
@property (strong, readwrite) NSMetadataQuery *metadataQuery;
@property (strong, readwrite) NSMutableArray *fileList;
@property (weak, readwrite) NoteDocument *currentDocument;

- (NSURL*)localDocumentsDirectoryURL;
- (NSURL*)ubiquitousDocumentsDirectoryURL;
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize metadataQuery = _metadataQuery;
@synthesize fileList = _fileList;
@synthesize currentDocument = _currentDocument;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Master", @"Master");
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		    self.clearsSelectionOnViewWillAppear = NO;
		    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}
		UIBarButtonItem *newDocumentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createDocument)];
		[[self navigationItem] setRightBarButtonItem:newDocumentButton];
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    //[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	
	[self setFileList:[NSMutableArray array]];

	[self setMetadataQuery:[[NSMetadataQuery alloc] init]];
	[[self metadataQuery] setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
	[[self metadataQuery] setPredicate:[NSPredicate predicateWithFormat:@"%K ENDSWITH '.txt'", NSMetadataItemFSNameKey]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileListReceived) name:NSMetadataQueryDidFinishGatheringNotification object:[self metadataQuery]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileListReceived) name:NSMetadataQueryDidUpdateNotification object:[self metadataQuery]];
	[[self metadataQuery] startQuery];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self fileList] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

	// Configure the cell.
    NoteDocument *document = [[self fileList] objectAtIndex:indexPath.row];
	cell.textLabel.text = [[document fileURL] lastPathComponent];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
	    }
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }
    
    // Close the current document
    if (!([[self currentDocument] documentState] & UIDocumentStateClosed)) {
        [[self currentDocument] closeWithCompletionHandler:^(BOOL success) {
            
        }];
    }
    
    // Get the new document
    NoteDocument *document = [[self fileList] objectAtIndex:indexPath.row];
    [self setCurrentDocument:document];
    if ([document documentState] & UIDocumentStateClosed) {
        // Open if needed
        [[self currentDocument] openWithCompletionHandler:^(BOOL success) {
            [[self detailViewController] setDocument:document];
        }];
    } else {
        [[self detailViewController] setDocument:document];
    }
}

#pragma mark - File creation
- (void)createDocument
{
	UIAlertView *simpleCreateDialog = [[UIAlertView alloc] initWithTitle:@"Create Document"
																 message:@"Enter the document title"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"OK", nil];
	[simpleCreateDialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
	[simpleCreateDialog show];
}

- (void)createFileNamed:(NSString *)filename
{
	NSURL *localFileURL = [[self localDocumentsDirectoryURL] URLByAppendingPathComponent:filename];
	NSLog(@"Local file URL: %@", localFileURL);
	
	NoteDocument *newDocument = [[NoteDocument alloc] initWithFileURL:localFileURL];
    // Should really check to see if a file exists with the name
	[newDocument saveToURL:localFileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
		if (success) {
			[[self fileList] addObject:newDocument];
			[[self tableView] reloadData];
			NSIndexPath *newDocumentPath = [NSIndexPath indexPathForRow:([[self fileList] count]-1) inSection:0];
			[[self tableView] selectRowAtIndexPath:newDocumentPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [[self detailViewController] setDocument:newDocument];
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Move the new document to the cloud.
                // Don't do this on the main thread, it might block too long.
                // From NSFileManager docs:
                // "For files located in an application’s sandbox, this involves physically removing the file from the sandbox directory."
                NSURL *destinationURL = [[self ubiquitousDocumentsDirectoryURL] URLByAppendingPathComponent:filename];
                NSError *moveToCloudError = nil;
                BOOL success = [[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:[newDocument fileURL] destinationURL:destinationURL error:&moveToCloudError];
                if (!success) {
                    NSLog(@"Error moving to iCloud: %@", moveToCloudError);
                }
            });
		}
	}];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [alertView firstOtherButtonIndex]) {
		NSString *filename = [[alertView textFieldAtIndex:0] text];
		if (![filename hasSuffix:@".txt"]) {
			filename = [filename stringByAppendingPathExtension:@"txt"];
		}
		NSLog(@"Creating file named %@", filename);
		[self createFileNamed:filename];
	}
}

// This method is straight out of the docs...
- (BOOL)downloadFileIfNotAvailable:(NSURL*)file {
    NSNumber*  isIniCloud = nil;
    
    if ([file getResourceValue:&isIniCloud forKey:NSURLIsUbiquitousItemKey error:nil]) {
        // If the item is in iCloud, see if it is downloaded.
        if ([isIniCloud boolValue]) {
            NSNumber*  isDownloaded = nil;
            if ([file getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:nil]) {
                if ([isDownloaded boolValue])
                    return YES;
				
                // Download the file.
                NSFileManager*  fm = [NSFileManager defaultManager];
                [fm startDownloadingUbiquitousItemAtURL:file error:nil];
                return NO;
            }
        }
    }
    
    // Return YES as long as an explicit download was not started.
    return YES;
}

#pragma mark - NSMetadataQuery lookup
- (void)fileListReceived
{
	// Get currently selected file and save it
	NSString *selectedFileName = nil;
    NSIndexPath *selectedRowIndex = [[self tableView] indexPathForSelectedRow];
    NSInteger selectedRow = NSNotFound;
    if (selectedRowIndex != nil) {
        selectedRow = [selectedRowIndex row];
        if (selectedRow != NSNotFound) {
            selectedFileName = [[[[self fileList] objectAtIndex:selectedRow] fileURL] lastPathComponent];
        }
    }
	
	// Build the new file list
	[[self fileList] removeAllObjects];
	NSArray *queryResults = [[self metadataQuery] results];
	for (NSMetadataItem *result in queryResults) {
		NSString *filename = [result valueForAttribute:NSMetadataItemFSNameKey];
		if ((selectedFileName != nil) && ([selectedFileName isEqualToString:filename])) {
			selectedRow = [[self fileList] count];
		}
        NSURL *documentURL = [result valueForAttribute:NSMetadataItemURLKey];
        NoteDocument *document = [[NoteDocument alloc] initWithFileURL:documentURL];
		[[self fileList] addObject:document];
        [self downloadFileIfNotAvailable:documentURL];
	}
	
	[[self tableView] reloadData];
	if (selectedRow != NSNotFound) {
		NSIndexPath *selectionPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
		[[self tableView] selectRowAtIndexPath:selectionPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

#pragma mark - Misc utility
- (NSURL*)localDocumentsDirectoryURL
{
    static NSURL *localDocumentsDirectoryURL = nil;
    if (localDocumentsDirectoryURL == nil) {
        NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
																				NSUserDomainMask, YES ) objectAtIndex:0];
        localDocumentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectoryPath];
    }
    return localDocumentsDirectoryURL;
}

- (NSURL*)ubiquitousContainerURL
{
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (NSURL*)ubiquitousDocumentsDirectoryURL
{
    NSURL *ubiquitousDocumentsURL = [[self ubiquitousContainerURL] URLByAppendingPathComponent:@"Documents"];
    if (ubiquitousDocumentsURL != nil) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[ubiquitousDocumentsURL path]]) {
            NSError *createDirectoryError = nil;
            BOOL created = [[NSFileManager defaultManager] createDirectoryAtURL:ubiquitousDocumentsURL withIntermediateDirectories:NO attributes:0 error:&createDirectoryError];
            if (!created) {
                NSLog(@"Error creating directory at %@: %@", ubiquitousDocumentsURL, createDirectoryError);
            }
        }
    } else {
        NSLog(@"Error getting ubiquitous container URL");
    }
    return ubiquitousDocumentsURL;
}

@end
