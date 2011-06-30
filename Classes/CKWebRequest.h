//
//  CKWebRequest.h
//  CloudKit
//
//  Created by Fred Brunel on 09-11-09.
//  Copyright 2009 WhereCloud Inc. All rights reserved.
//

// TODO: How to solve the problem of establishing a "session" with credentials and
// how to allow client classes to customize the behavior for non-standard authentication
// TODO: the CKWebRequest should be initialized with a "session" (i.e. CKWebService)

#import <Foundation/Foundation.h>

@protocol CKWebRequestDelegate;
@protocol CKWebResponseTransformer;

@class ASIHTTPRequest;


/** TODO
 */
@interface CKWebRequest : NSObject {
	NSURL *_url;
	NSDictionary *_headers;
	
	id<CKWebRequestDelegate> _delegate;
	id<CKWebResponseTransformer> _transformer;
	id _valueTarget;
	NSString *_valueTargetKeyPath;
	id _userInfo;
	
	// FIXME: Username & password should be in a "authentication class"
	NSString *_username;
	NSString *_password;
	
	ASIHTTPRequest *_httpRequest; // Weak reference
}

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, retain, readwrite) NSDictionary *headers;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, assign) id<CKWebRequestDelegate> delegate;
@property (nonatomic, assign) id<CKWebResponseTransformer> transformer; // FIXME: assign or retain?

// Create a request from a URL string
// <url> is an URL as a string with an optional base path (e.g., http://google.com/search)
// <params> is the query as a key/value NSDictionary; it will be appended as a query string to the URL (e.g., <url>?q="example")

+ (CKWebRequest *)requestWithURL:(NSURL *)url;
+ (CKWebRequest *)requestWithURLString:(NSString *)url params:(NSDictionary *)params;
+ (CKWebRequest *)requestWithURLString:(NSString *)url params:(NSDictionary *)params delegate:(id)delegate;

- (id)setValueTarget:(id)target forKeyPath:(NSString *)keyPath;
- (void)setBasicAuthWithUsername:(NSString *)username password:(NSString *)password;

- (void)start;
- (void)cancel;

@end

//

/** TODO
 */
@protocol CKWebRequestDelegate <NSObject> @optional
- (void)request:(id)request didReceiveData:(NSData *)data withResponseHeaders:(NSDictionary *)headers;
- (void)request:(id)request didReceiveValue:(id)value;
//- (void)request:(id)request didReceiveError:(NSError *)error withResponseHeaders:(NSDictionary *)headers; // TODO: FOR HTTP ERRORS
- (void)request:(id)request didFailWithError:(NSError *)error;
@end

//

/** TODO
 */
@protocol CKWebResponseTransformer <NSObject>
- (id)request:(CKWebRequest *)request transformContent:(id)content;
@end

//