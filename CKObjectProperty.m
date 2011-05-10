//
//  CKObjectKeyValue.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-01.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKObjectProperty.h"


@implementation CKObjectProperty
@synthesize object,keyPath;

- (id)initWithObject:(id)theobject keyPath:(NSString*)thekeyPath{
	[super init];
	self.object = theobject;
	self.keyPath = thekeyPath;
	return self;
}

- (CKClassPropertyDescriptor*)descriptor{
	id subObject = object;
	
	NSArray * ar = [keyPath componentsSeparatedByString:@"."];
	for(int i=0;i<[ar count]-1;++i){
		NSString* path = [ar objectAtIndex:i];
		subObject = [subObject valueForKey:path];
	}
	if(subObject == nil){
		NSLog(subObject,@"unable to find property '%@' in '%@'",keyPath,object);
		return nil;
	}
	return [NSObject propertyDescriptor:[subObject class] forKey:[ar objectAtIndex:[ar count] -1 ]];
	//return [NSObject propertyDescriptor:[object class] forKeyPath:keyPath];
}

- (id)value{
	return [object valueForKeyPath:keyPath];
}

- (void)setValue:(id)value{
	[object setValue:value forKeyPath:keyPath];
}

- (CKDocumentCollection*)editorCollectionWithFilter:(NSString*)filter{
	id subObject = object;
	
	NSArray * ar = [keyPath componentsSeparatedByString:@"."];
	for(int i=0;i<[ar count]-1;++i){
		NSString* path = [ar objectAtIndex:i];
		subObject = [subObject valueForKey:path];
	}
	
	if(subObject == nil){
		NSLog(subObject,@"unable to find property '%@' in '%@'",keyPath,object);
		return nil;
	}
	
	CKClassPropertyDescriptor* descriptor = [NSObject propertyDescriptor:[subObject class] forKey:[ar objectAtIndex:[ar count] -1 ]];
	SEL selector = [NSObject propertyeditorCollectionSelectorForProperty:descriptor.name];
	if([subObject respondsToSelector:selector]){
		CKDocumentCollection* collection = [subObject performSelector:selector withObject:filter];
		return collection;
	}
	else{
		Class type = descriptor.type;
		if([type respondsToSelector:@selector(editorCollectionWithFilter:)]){
			CKDocumentCollection* collection = [type performSelector:@selector(editorCollectionWithFilter:) withObject:filter];
			return collection;
		}
	}
	return nil;
}


- (Class)tableViewCellControllerType{
	id subObject = object;
	
	NSArray * ar = [keyPath componentsSeparatedByString:@"."];
	for(int i=0;i<[ar count]-1;++i){
		NSString* path = [ar objectAtIndex:i];
		subObject = [subObject valueForKey:path];
	}
	
	if(subObject == nil){
		NSLog(subObject,@"unable to find property '%@' in '%@'",keyPath,object);
		return nil;
	}
	
	CKClassPropertyDescriptor* descriptor = [NSObject propertyDescriptor:[subObject class] forKey:[ar objectAtIndex:[ar count] -1 ]];
	SEL selector = [NSObject propertyTableViewCellControllerClassSelectorForProperty:descriptor.name];
	if([subObject respondsToSelector:selector]){
		Class controllerClass = [subObject performSelector:selector];
		return controllerClass;
	}
	else{
		Class type = descriptor.type;
		if([type respondsToSelector:@selector(tableViewCellControllerClass)]){
			Class controllerClass = [type performSelector:@selector(tableViewCellControllerClass)];
			return controllerClass;
		}
	}
	return nil;
}


- (CKModelObjectPropertyMetaData*)metaData{
	id subObject = object;
	
	NSArray * ar = [keyPath componentsSeparatedByString:@"."];
	for(int i=0;i<[ar count]-1;++i){
		NSString* path = [ar objectAtIndex:i];
		subObject = [subObject valueForKey:path];
	}
	
	if(subObject == nil){
		NSLog(subObject,@"unable to find property '%@' in '%@'",keyPath,object);
		return nil;
	}
	
	CKClassPropertyDescriptor* descriptor = [NSObject propertyDescriptor:[subObject class] forKey:[ar objectAtIndex:[ar count] -1 ]];
	CKModelObjectPropertyMetaData* metaData = [CKModelObjectPropertyMetaData propertyMetaDataForObject:subObject property:descriptor];
	
	return metaData;
}

- (NSString*)name{
	CKClassPropertyDescriptor* descriptor = [self descriptor];
	return descriptor.name;
}

@end