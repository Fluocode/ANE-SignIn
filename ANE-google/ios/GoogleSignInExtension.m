//
//  GoogleSignInExtension.m
//  GoogleSignInExtension
//
//  Created for com.fluocode.ane.signin.google
//

#import "GoogleSignInExtension.h"
#import "FlashRuntimeExtensions.h"
#import <GoogleSignIn/GoogleSignIn.h>

// Context reference
static FREContext g_ctx = nil;

// Google Sign-In state
static BOOL g_googleInitialized = NO;
static NSString *g_googleClientId = nil;
static GIDGoogleUser *g_currentGoogleUser = nil;

// Function declarations
FREObject initializeGoogleSignIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject signInWithGoogle(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject signOutGoogle(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject isGoogleSignedIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject getGoogleUserInfo(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);

// Helper function to get NSString from FREObject
NSString* getStringFromFREObject(FREObject object) {
    uint32_t length;
    const uint8_t* value;
    if (FREGetObjectAsUTF8(object, &length, &value) == FRE_OK) {
        return [NSString stringWithUTF8String:(const char*)value];
    }
    return nil;
}

// Helper function to create FREObject from NSString
FREObject createFREObjectFromString(NSString* string) {
    FREObject result = nil;
    if (string) {
        const char* utf8String = [string UTF8String];
        FRENewObjectFromUTF8((uint32_t)strlen(utf8String) + 1, (const uint8_t*)utf8String, &result);
    }
    return result;
}

// Helper function to create FREObject from BOOL
FREObject createFREObjectFromBool(BOOL value) {
    FREObject result = nil;
    FRENewObjectFromBool(value ? 1 : 0, &result);
    return result;
}

// Helper function to create an Object with properties
FREObject createObjectFromDictionary(NSDictionary* dict) {
    FREObject result = nil;
    FRENewObject((const uint8_t*)"Object", 0, NULL, &result, NULL);
    
    for (NSString* key in dict) {
        id value = dict[key];
        FREObject freValue = nil;
        
        if ([value isKindOfClass:[NSString class]]) {
            freValue = createFREObjectFromString((NSString*)value);
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber* num = (NSNumber*)value;
            if (CFBooleanGetTypeID() == CFGetTypeID((__bridge CFTypeRef)value)) {
                FRENewObjectFromBool([num boolValue] ? 1 : 0, &freValue);
            } else {
                FRENewObjectFromDouble([num doubleValue], &freValue);
            }
        }
        
        if (freValue) {
            const char* keyStr = [key UTF8String];
            FRESetObjectProperty(result, (const uint8_t*)keyStr, freValue, NULL);
        }
    }
    
    return result;
}

// Serializes profile fields from GIDGoogleUser to JSON and dispatches GOOGLE_SIGN_IN_SUCCESS to ActionScript.
static void dispatchUserSuccess(GIDGoogleUser *user) {
    g_currentGoogleUser = user;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (user.userID) {
        userInfo[@"id"] = user.userID;
    }
    if (user.profile.email) {
        userInfo[@"email"] = user.profile.email;
    }
    if (user.profile.name) {
        userInfo[@"displayName"] = user.profile.name;
    }
    if (user.profile.hasImage) {
        NSURL *photoURL = [user.profile imageURLWithDimension:128];
        if (photoURL) {
            userInfo[@"photoUrl"] = [photoURL absoluteString];
        }
    }
    if (user.idToken) {
        userInfo[@"idToken"] = user.idToken.tokenString;
    }
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&jsonError];
    if (!jsonError && jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"GOOGLE_SIGN_IN_SUCCESS", (const uint8_t*)[jsonString UTF8String]);
    } else {
        FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"GOOGLE_SIGN_IN_SUCCESS", (const uint8_t*)"{}");
    }
}

// Native function implementations
FREObject initializeGoogleSignIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (argc < 1) {
        return createFREObjectFromBool(NO);
    }
    
    NSString *clientId = getStringFromFREObject(argv[0]);
    if (!clientId) {
        return createFREObjectFromBool(NO);
    }
    
    g_googleClientId = clientId;
    
    // Configure Google Sign-In (8.x: no delegate, use completion handlers)
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];
    [GIDSignIn sharedInstance].configuration = config;
    
    g_googleInitialized = YES;
    
    return createFREObjectFromBool(YES);
}

// Key window for presenting UI (iOS 13+ multi-scene safe; avoids deprecated keyWindow)
static UIWindow *keyWindowForPresentation(void) {
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                // No key window; use first window in foreground scene
                UIWindow *first = windowScene.windows.firstObject;
                if (first) return first;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return app.keyWindow;
#pragma clang diagnostic pop
}

FREObject signInWithGoogle(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (!g_googleInitialized) {
        return createFREObjectFromBool(NO);
    }
    
    UIWindow *keyWindow = keyWindowForPresentation();
    UIViewController *rootViewController = keyWindow.rootViewController;
    if (!rootViewController) {
        FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"GOOGLE_SIGN_IN_ERROR", (const uint8_t*)"No root view controller for presentation.");
        return createFREObjectFromBool(NO);
    }
    
    [[GIDSignIn sharedInstance] signInWithPresentingViewController:rootViewController completion:^(GIDSignInResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"GOOGLE_SIGN_IN_ERROR", (const uint8_t*)[error.localizedDescription UTF8String]);
            return;
        }
        if (result.user) {
            dispatchUserSuccess(result.user);
        }
    }];
    
    return createFREObjectFromBool(YES);
}

FREObject signOutGoogle(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (!g_googleInitialized) {
        return NULL;
    }
    
    [[GIDSignIn sharedInstance] signOut];
    g_currentGoogleUser = nil;
    FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"GOOGLE_SIGN_OUT_SUCCESS", (const uint8_t*)"Signed out successfully.");
    
    return NULL;
}

FREObject isGoogleSignedIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    BOOL signedIn = (g_currentGoogleUser != nil) || ([[GIDSignIn sharedInstance] currentUser] != nil);
    return createFREObjectFromBool(signedIn);
}

FREObject getGoogleUserInfo(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    GIDGoogleUser *user = g_currentGoogleUser ?: [[GIDSignIn sharedInstance] currentUser];
    
    if (!user) {
        return NULL;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    if (user.userID) {
        userInfo[@"id"] = user.userID;
    }
    if (user.profile.email) {
        userInfo[@"email"] = user.profile.email;
    }
    if (user.profile.name) {
        userInfo[@"displayName"] = user.profile.name;
    }
    if (user.profile.hasImage) {
        NSURL *photoURL = [user.profile imageURLWithDimension:128];
        if (photoURL) {
            userInfo[@"photoUrl"] = [photoURL absoluteString];
        }
    }
    if (user.idToken) {
        userInfo[@"idToken"] = user.idToken.tokenString;
    }
    
    // Convert to JSON string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
    if (!error && jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return createFREObjectFromString(jsonString);
    }
    
    return NULL;
}

// Context initializer
void GoogleSignInExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet) {
    static const FRENamedFunction functionMap[] = {
        { (const uint8_t*)"initializeGoogleSignIn", NULL, &initializeGoogleSignIn },
        { (const uint8_t*)"signInWithGoogle", NULL, &signInWithGoogle },
        { (const uint8_t*)"signOutGoogle", NULL, &signOutGoogle },
        { (const uint8_t*)"isGoogleSignedIn", NULL, &isGoogleSignedIn },
        { (const uint8_t*)"getGoogleSignedInUser", NULL, &getGoogleUserInfo },
    };
    
    *numFunctionsToSet = sizeof(functionMap) / sizeof(FRENamedFunction);
    *functionsToSet = functionMap;
    
    g_ctx = ctx;
}

// Context finalizer
void GoogleSignInExtensionContextFinalizer(FREContext ctx) {
    g_ctx = nil;
    g_currentGoogleUser = nil;
}

// Extension initializer
void GoogleSignInExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &GoogleSignInExtensionContextInitializer;
    *ctxFinalizerToSet = &GoogleSignInExtensionContextFinalizer;
}

// Extension finalizer
void GoogleSignInExtensionFinalizer(void* extData) {
    /* Reserved for releasing native resources if added later. */
}

