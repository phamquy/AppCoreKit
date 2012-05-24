//
//  CKWebRequest.m
//  CloudKit
//
//  Created by Fred Brunel on 11-01-05.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKNSString+URIQuery.h"
#import "CKWebRequest+Initialization.h"
#import "CKWebRequest.h"
#import "CKWebRequestManager.h"
#import "CKWebDataConverter.h"

NSString * const CKWebRequestHTTPErrorDomain = @"CKWebRequestHTTPErrorDomain";

@interface CKWebRequest () <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSHTTPURLResponse *response;

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSFileHandle *handle;
@property (nonatomic, retain, readwrite) NSString *downloadPath;

@property (nonatomic, assign, readwrite) CGFloat progress;
@property (nonatomic, assign) NSUInteger retriesCount;

@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (nonatomic, assign) dispatch_group_t operationsGroup;

@end

@implementation CKWebRequest

@synthesize connection, request, response, cancelled, operationsGroup;
@synthesize completionBlock, transformBlock, cancelBlock;
@synthesize data, handle, downloadPath;
@synthesize delegate, progress, retriesCount;

- (void)dealloc {
    self.connection = nil;
    self.request = nil;
    self.response = nil;
    self.data = nil;
    self.handle = nil;
    self.downloadPath = nil;
    self.completionBlock = nil;
    self.transformBlock = nil;
    self.cancelBlock = nil;
    dispatch_release(self.operationsGroup);
    
    [super dealloc];
}

- (id)initWithURLRequest:(NSURLRequest *)aRequest parameters:(NSDictionary *)parameters transform:(id (^)(id value))transform completion:(void (^)(id, NSHTTPURLResponse *, NSError *))block {
    if (self = [super init]) {
        NSMutableURLRequest *mutableRequest = aRequest.mutableCopy;
        if (parameters) {
            NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", aRequest.URL.absoluteString, [NSString stringWithQueryDictionary:parameters]]];
            [mutableRequest setURL:newURL];
        }
                
        self.request = mutableRequest;
        [mutableRequest release];
        
        self.completionBlock = block;
        self.transformBlock = transform;
        self.data = [[[NSMutableData alloc] init] autorelease];
        self.cancelled = NO;
        self.operationsGroup = dispatch_group_create();
    }
    return self;
}

- (id)initWithURLRequest:(NSURLRequest *)aRequest parameters:(NSDictionary *)parameters downloadAtPath:(NSString *)path completion:(void (^)(id, NSHTTPURLResponse *, NSError *))block {
    if (self = [self initWithURLRequest:aRequest parameters:parameters completion:block]) {
        unsigned long long existingDataLenght = 0;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            unsigned long long existingDataLenght = [attributes fileSize];
            NSString* bytesStr = [NSString stringWithFormat:@"bytes=%qu-", existingDataLenght];
            
            NSMutableURLRequest *mutableRequest = self.request.mutableCopy;
            [mutableRequest addValue:bytesStr forHTTPHeaderField:@"Range"];
            self.request = mutableRequest;
            [mutableRequest release];
        }
        else 
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        
        self.handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [self.handle seekToFileOffset:existingDataLenght];
        
        self.downloadPath = path;
        self.retriesCount = 0;
        self.data = nil;
        self.cancelled = NO;
        self.operationsGroup = dispatch_group_create();
    }
    return self;
}

#pragma mark - LifeCycle

- (void)start {
    [self startOnRunLoop:[NSRunLoop currentRunLoop]];
}

- (void)startOnRunLoop:(NSRunLoop *)runLoop {
    NSAssert(self.connection == nil, @"Connection already started");
    
    self.progress = 0.0;
    self.cancelled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
        if (cachedResponse) {
            [self connection:nil didReceiveResponse:cachedResponse.response];
            [self connection:nil didReceiveData:cachedResponse.data];
            [self connectionDidFinishLoading:nil];
        }
        else {
            self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
            
            [self.connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
            [self.connection start];  
        }
    });
}

- (void)cancel {
    [self.connection cancel];
    self.cancelled = YES;
    
    dispatch_group_wait(self.operationsGroup, DISPATCH_TIME_FOREVER);
    
    if (self.cancelBlock)
        self.cancelBlock();
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)aResponse {
    if (!self.isCancelled) {
        self.response = aResponse;
        
        if ([aResponse statusCode] >= 400) {
            self.handle = nil;
            self.data = [NSMutableData data];
            [[NSFileManager defaultManager] removeItemAtPath:self.downloadPath error:nil];
        }
        
        if ([self.delegate respondsToSelector:@selector(connection:didReceiveResponse:)])
            [self.delegate connection:aConnection didReceiveResponse:aResponse];  
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)someData {
    if (!self.isCancelled) {
        if (self.handle) {
            self.progress = self.handle.offsetInFile / self.response.expectedContentLength;
            [self.handle writeData:someData];
        }
        else {
            self.progress = self.data.length / self.response.expectedContentLength;
            [self.data appendData:someData];
        }
        
        if ([self.delegate respondsToSelector:@selector(connection:didReceiveData:)]) 
            [self.delegate connection:aConnection didReceiveData:someData];  
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    self.progress = 1.0;
    
    dispatch_group_async(self.operationsGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        id object = self.isCancelled ? nil : [CKWebDataConverter convertData:self.data fromResponse:self.response];
        
        if (self.transformBlock && !self.isCancelled) {
            id transformedObject = transformBlock(object);
            if (transformedObject)
                object = transformedObject;
        }
        
        if (!self.isCancelled) {
            dispatch_group_async(self.operationsGroup, dispatch_get_main_queue(), ^(void) {
                if (self.completionBlock && !self.isCancelled)
                    self.completionBlock(object, self.response, nil);
                
                if ([self.delegate respondsToSelector:@selector(connectionDidFinishLoading:)] && !self.isCancelled)
                    [self.delegate connectionDidFinishLoading:aConnection];
            });  
        }
    });
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSCachedURLResponse *onDiskCachedResponse = [[[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data] autorelease];
    [[NSURLCache sharedURLCache] storeCachedResponse:onDiskCachedResponse forRequest:self.request];
        
     return nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    if (!([error code] == NSURLErrorTimedOut && [self retry] && self.handle)) {
        dispatch_group_async(self.operationsGroup, dispatch_get_main_queue(), ^(void) {
            if (self.completionBlock && !self.isCancelled)
                self.completionBlock(nil, self.response, error);
            
            if ([self.delegate respondsToSelector:@selector(connection:didFailWithError:)] && !self.isCancelled)
                [self.delegate connection:aConnection didFailWithError:error];
        });
    }
}

#pragma mark - Getters

- (BOOL)retry {
    if (self.retriesCount++ == 3)
        return NO;
    else {
      	[self cancel];
        self.connection = nil;
        [self start];
        return YES;  
    }
}

- (NSURL *)URL {
    return self.request.URL;
}

@end
