//
//  CKNSStringPropertyCellController.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-01.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//


#import "CKNSStringPropertyCellController.h"
#import "CKObjectProperty.h"
#import "CKNSObject+bindings.h"
#import "CKLocalization.h"
#import "CKTableViewCellNextResponder.h"
#import "CKNSValueTransformer+Additions.h"

#import "CKSheetController.h"


@implementation CKNSStringPropertyCellController
@synthesize textField = _textField;

-(void)dealloc{
	[NSObject removeAllBindingsForContext:[NSValue valueWithNonretainedObject:self]];
	[_textField release];
	[super dealloc];
}

//pas utiliser load cell mais initCell pour application des styles ...
- (void)initTableViewCell:(UITableViewCell*)cell{
	[super initTableViewCell:cell];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    if(_textField == nil){
        UITextField *txtField = [[[UITextField alloc] initWithFrame:cell.contentView.bounds] autorelease];
        self.textField = txtField;
    }
	_textField.tag = 50000;
	_textField.borderStyle = UITextBorderStyleNone;
	_textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	_textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	_textField.delegate = self;
	_textField.textAlignment = UITextAlignmentLeft;
	_textField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    if(self.cellStyle == CKTableViewCellStylePropertyGrid){
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            _textField.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
        }  
        else{
            _textField.textColor = [UIColor blackColor];
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
        }
    }  
    
    if(self.cellStyle == CKTableViewCellStyleValue3
       || self.cellStyle == CKTableViewCellStylePropertyGrid){
        _textField.autoresizingMask = UIViewAutoresizingNone;
    }
}

- (id)performStandardLayout:(CKNSStringPropertyCellController*)controller{
	[super performStandardLayout:controller];
    UITableViewCell* cell = controller.tableViewCell;
	UITextField *textField = controller.textField;
	if(textField){
        if(controller.cellStyle == CKTableViewCellStyleValue3
           || controller.cellStyle == CKTableViewCellStylePropertyGrid){
            
            textField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            BOOL isIphone = ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
            CGFloat y = isIphone ? ((cell.contentView.frame.size.height / 2.0) - ((textField.font.lineHeight + 10) / 2.0)) : self.contentInsets.top;
            
            CGFloat realWidth = cell.contentView.frame.size.width;
            CGFloat textFieldWidth = realWidth - (realWidth * self.componentsRatio + self.componentsSpace) - self.contentInsets.right;
            CGFloat textFieldX = realWidth - self.contentInsets.right - textFieldWidth;
            if(![cell.textLabel.text isKindOfClass:[NSString class]] || [cell.textLabel.text length] <= 0){
                textFieldWidth = realWidth - (self.contentInsets.left + self.contentInsets.right);
                textFieldX = self.contentInsets.left;
            }
			textField.frame = CGRectIntegral(CGRectMake(textFieldX,y,textFieldWidth,(textField.font.lineHeight + 10)));
        }
    }
    return (id)nil;
}

- (void)textFieldChanged:(id)value{
    [self setValueInObjectProperty:value];
}

- (void)setupCell:(UITableViewCell *)cell {
	[super setupCell:cell];
	[self clearBindingsContext];
	
	CKObjectProperty* model = self.value;
	
	CKClassPropertyDescriptor* descriptor = [model descriptor];
    
    if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad
       || self.cellStyle != CKTableViewCellStylePropertyGrid){
        cell.textLabel.text = _(descriptor.name);
    }
	
	if(self.textField){
		[self.textField removeFromSuperview];
	}
	cell.detailTextLabel.text = nil;
	
	if([model isReadOnly] || self.readOnly){
        self.fixedSize = YES;
		[NSObject beginBindingsContext:[NSValue valueWithNonretainedObject:self] policy:CKBindingsContextPolicyRemovePreviousBindings];
		[model.object bind:model.keyPath toObject:cell.detailTextLabel withKeyPath:@"text"];
		[NSObject endBindingsContext];
	}
	else{
        if(self.cellStyle == CKTableViewCellStylePropertyGrid
           && [[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            self.fixedSize = YES;
        }
        else{
            self.fixedSize = NO;
        }
		[NSObject beginBindingsContext:[NSValue valueWithNonretainedObject:self] policy:CKBindingsContextPolicyRemovePreviousBindings];
		[model.object bind:model.keyPath toObject:self.textField withKeyPath:@"text"];
        [[NSNotificationCenter defaultCenter] bindNotificationName:UITextFieldTextDidChangeNotification object:self.textField 
                                                         withBlock:^(NSNotification *notification) {
                                                             [self textFieldChanged:self.textField.text];
                                                              }];
		[NSObject endBindingsContext];
		
		NSString* placeholerText = [NSString stringWithFormat:@"%@_Placeholder",descriptor.name];
		self.textField.placeholder = _(placeholerText);
		[cell.contentView addSubview:self.textField];
	}
}

- (void)rotateCell:(UITableViewCell*)cell withParams:(NSDictionary*)params animated:(BOOL)animated{
	[super rotateCell:cell withParams:params animated:animated];
}

+ (CKItemViewFlags)flagsForObject:(id)object withParams:(NSDictionary*)params{
	return CKItemViewFlagNone;
}

#pragma mark UITextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)next:(id)sender{
    [CKTableViewCellNextResponder activateNextResponderFromController:self];
}

- (void)done:(id)sender{
    [self.parentController.view endEditing:YES];
    [[NSNotificationCenter defaultCenter]postNotificationName:CKSheetResignNotification object:nil];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    BOOL hasNextResponder = [CKTableViewCellNextResponder needsNextKeyboard:self];
    switch(self.textField.keyboardType){
        case UIKeyboardTypeDecimalPad:{
            UIToolbar* toolbar = nil;
            if([self.textField.inputAccessoryView isKindOfClass:[UIToolbar class]]){
                toolbar = (UIToolbar*)self.textField.inputAccessoryView;
            }
            if(!toolbar){
                toolbar = [[[UIToolbar alloc]initWithFrame:CGRectMake(0,0,320,44)]autorelease];
                toolbar.barStyle = UIBarStyleBlackTranslucent;
            }
            UIBarButtonItem* button = [[[UIBarButtonItem alloc]initWithTitle:hasNextResponder ? _(@"Next") : _(@"Done") 
                                                                       style:hasNextResponder ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone 
                                                                      target:self 
                                                                      action:hasNextResponder ? @selector(next:) : @selector(done:)]autorelease];
            toolbar.items = [NSArray arrayWithObject:button];
            self.textField.inputAccessoryView = toolbar;
            break;
        }
        default:{
            self.textField.inputAccessoryView = nil;
            break;
        }
    }
    
    if(hasNextResponder){
        self.textField.returnKeyType = UIReturnKeyNext;
    }
    else{
        self.textField.returnKeyType = UIReturnKeyDone;
    }
    
	[self scrollToRow];
    
	[self didBecomeFirstResponder];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[self didResignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if([CKTableViewCellNextResponder activateNextResponderFromController:self] == NO){
		[textField resignFirstResponder];
	}
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    CKObjectPropertyMetaData* metaData = [[self objectProperty]metaData];
    NSInteger min = [metaData.options minimumLength];
    NSInteger max = [metaData.options maximumLength];
	if (range.length>0) {
        if(min >= 0 && range.location < min){
            return NO;
        }
		return YES;
	} else {
        if(max >= 0 && range.location >= max){
            return NO;
        }
        return YES;
	}
    return YES;
}

#pragma mark Keyboard

- (void)keyboardDidShow:(NSNotification *)notification {
    [self scrollToRowAfterDelay:0.3];
}


+ (BOOL)hasAccessoryResponderWithValue:(id)object{
	CKObjectProperty* model = object;// || self.readonly
	return ![model isReadOnly];
}

+ (UIResponder*)responderInView:(UIView*)view{
	UITextField *textField = (UITextField*)[view viewWithTag:50000];
	return textField;
}

@end

