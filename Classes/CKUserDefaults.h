//
//  CKUserDefaults.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-07-15.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import "CKModelObject.h"


/** 
 A CKUserDefaults contains properties that will get synched automatically with the [NSUserDefaults standardUserDefaults] system provided by Apple.
 This allow to easilly specify typed properties with default values in a plist named YourClassUserDefaults.plist or in the postInit selector.
 It also provides all the helpers from CKModelObject : auto init, auto dealloc, copy, serialization and more ...
 
 CKUserDefaults objects are sharedInstance for an easy access. It will get initialized the first time you access the shared instance of your specific class.
        
           @interface MyUserDefaults : CKUserDefaults{}
                    @property (nonatomic,assign) BOOL theBool;
                    @property (nonatomic,assign) CGFloat theFloat;
                    @property (nonatomic,copy) NSString* theString;
           @end
 
           @implementation MyUserDefaults
                    @syntesize theBool,theFloat,theString
           @end
 
 
 In the previous example, we provides a user setting containing 3 properties. each time you will set one of these, the NSUserDefaults standardUserDefaults object will get automatically updated and synchronized. The properties for this object will get stored with the following keys in the NSUserDefaults :
 
           MyUserDefaults_theBool
           MyUserDefaults_theFloat
           MyUserDefaults_theString
           
 If we do not find some of those keys at init, the default values could be sepecified either in your postInit selector or in a plist named MyUserDefaults.plist located in the mainBundle.
 
 @see CKModelObject
 */
@interface CKUserDefaults : CKModelObject {
}

///-----------------------------------
/// @name Getting the Shared Instanceß
///-----------------------------------

/** 
 Returns the shared defaults object.
 @return The shared defaults object.
 */
+ (id)sharedInstance;

@end
