//
//  CKTableViewController.h
//  CloudKit
//
//  Created by Fred Brunel on 10-02-15.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//
//  Initial code created by Jonathan Wight on 2/25/09.
//  Copyright 2009 toxicsoftware.com. All rights reserved.

#import "CKTableViewController.h"


@interface CKTableViewController ()
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@end


@implementation CKTableViewController

@synthesize backgroundView = _backgroundView;
@synthesize tableView = _tableView;
@synthesize style = _style;
@synthesize stickySelection = _stickySelection;
@synthesize selectedIndexPath = _selectedIndexPath;

- (id)init {
	if (self = [super initWithNibName:nil bundle:nil]) {
		self.style = UITableViewStylePlain;
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style { 
	[self init];
	self.style = style;
	return self;
}

- (void)dealloc {
	self.selectedIndexPath = nil;
	self.backgroundView = nil;
	self.tableView = nil;
	[super dealloc];
}

#pragma mark View Management

- (void)loadView {
	[super loadView];

	if (self.view == nil) {
		CGRect theViewFrame = [[UIScreen mainScreen] applicationFrame];
		UIView *theView = [[[UITableView alloc] initWithFrame:theViewFrame] autorelease];
		theView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.view = theView;
	}

	if (self.tableView == nil) {
		if ([self.view isKindOfClass:[UITableView class]]) {
			// TODO: Assert - Should not be allowed
			self.tableView = (UITableView *)self.view;
		} else {
			CGRect theViewFrame = self.view.bounds;
			UITableView *theTableView = [[[UITableView alloc] initWithFrame:theViewFrame style:self.style] autorelease];
			theTableView.delegate = self;
			theTableView.dataSource = self;
			theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			[self.view addSubview:theTableView];
			self.tableView = theTableView;
		}
	}
}

- (void)viewDidUnload {
	self.tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	if (self.stickySelection == NO) [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	else if (self.selectedIndexPath) [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:animated scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.tableView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.stickySelection == NO) [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	else self.selectedIndexPath = [self.tableView indexPathForSelectedRow];
}

#pragma mark Selection

- (void)clearSelection:(BOOL)animated {
	if (self.selectedIndexPath) [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:animated];
	self.selectedIndexPath = nil;
}

- (void)reload {
	[self.tableView reloadData];
	if (self.stickySelection == YES && self.selectedIndexPath) [self.tableView selectRowAtIndexPath:_selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark Setters

- (void)setEditing:(BOOL)inEditing animated:(BOOL)animated {
	[self.tableView setEditing:inEditing animated:animated];
}

- (void)setBackgroundView:(UIView *)backgroundView {
	[_backgroundView removeFromSuperview];
	[_backgroundView release];
	if (backgroundView) {
		_backgroundView = [backgroundView retain];
		[self.view insertSubview:backgroundView belowSubview:self.tableView];
		self.tableView.backgroundColor = [UIColor clearColor];
	}
	else _backgroundView = nil;
}

#pragma mark UITableView Delegate

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.selectedIndexPath = indexPath;
}

@end