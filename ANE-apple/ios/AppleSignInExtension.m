//
//  AppleSignInExtension.m
//  AppleSignInExtension
//
//  Created for com.fluocode.ane.signin.apple
//

#import "AppleSignInExtension.h"
#import "FlashRuntimeExtensions.h"
#import <AuthenticationServices/AuthenticationServices.h>

// Context reference
static FREContext g_ctx = nil;

// Apple Sign-In state
static ASAuthorizationAppleIDProvider *g_appleIDProvider = nil;
static ASAuthorizationAppleIDCredential *g_currentAppleCredential = nil;

// Function declarations
FREObject initializeAppleSignIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject signInWithApple(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);
FREObject getAppleUserInfo(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]);

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

// Apple Sign-In Delegate
@interface AppleSignInDelegate : NSObject <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>
@end

@implementation AppleSignInDelegate

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization {
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
        g_currentAppleCredential = credential;
        
        // Create user info dictionary
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        
        if (credential.user) {
            userInfo[@"userId"] = credential.user;
        }
        if (credential.email) {
            userInfo[@"email"] = credential.email;
        }
        if (credential.fullName) {
            NSString *fullName = [NSString stringWithFormat:@"%@ %@",
                                  credential.fullName.givenName ?: @"",
                                  credential.fullName.familyName ?: @""];
            userInfo[@"fullName"] = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Convert to JSON string
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
        if (!error && jsonData) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"APPLE_SIGN_IN_SUCCESS", (const uint8_t*)[jsonString UTF8String]);
        } else {
            FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"APPLE_SIGN_IN_SUCCESS", (const uint8_t*)"{}");
        }
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    FREDispatchStatusEventAsync(g_ctx, (const uint8_t*)"APPLE_SIGN_IN_ERROR", (const uint8_t*)[error.localizedDescription UTF8String]);
}

// Key window for presentation (iOS 13+ multi-scene safe)
static UIWindow *appleSignInKeyWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) return window;
                }
                if (windowScene.windows.firstObject) return windowScene.windows.firstObject;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return app.keyWindow;
#pragma clang diagnostic pop
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    return appleSignInKeyWindow();
}

@end

static AppleSignInDelegate *g_appleSignInDelegate = nil;

// Native function implementations
FREObject initializeAppleSignIn(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (@available(iOS 13.0, *)) {
        if (!g_appleIDProvider) {
            g_appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
        }
        if (!g_appleSignInDelegate) {
            g_appleSignInDelegate = [[AppleSignInDelegate alloc] init];
        }
        return createFREObjectFromBool(YES);
    }
    return createFREObjectFromBool(NO);
}

FREObject signInWithApple(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (@available(iOS 13.0, *)) {
        if (!g_appleIDProvider) {
            return createFREObjectFromBool(NO);
        }
        
        ASAuthorizationAppleIDRequest *request = [g_appleIDProvider createRequest];
        request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        
        ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        controller.delegate = g_appleSignInDelegate;
        controller.presentationContextProvider = g_appleSignInDelegate;
        
        [controller performRequests];
        
        return createFREObjectFromBool(YES);
    }
    return createFREObjectFromBool(NO);
}

FREObject getAppleUserInfo(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[]) {
    if (@available(iOS 13.0, *)) {
        if (!g_currentAppleCredential) {
            return NULL;
        }
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        
        if (g_currentAppleCredential.user) {
            userInfo[@"userId"] = g_currentAppleCredential.user;
        }
        if (g_currentAppleCredential.email) {
            userInfo[@"email"] = g_currentAppleCredential.email;
        }
        if (g_currentAppleCredential.fullName) {
            NSString *fullName = [NSString stringWithFormat:@"%@ %@",
                                  g_currentAppleCredential.fullName.givenName ?: @"",
                                  g_currentAppleCredential.fullName.familyName ?: @""];
            userInfo[@"fullName"] = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        return createObjectFromDictionary(userInfo);
    }
    return NULL;
}

// Context initializer
void AppleSignInExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet) {
    static const FRENamedFunction functionMap[] = {
        { (const uint8_t*)"initializeAppleSignIn", NULL, &initializeAppleSignIn },
        { (const uint8_t*)"signInWithApple", NULL, &signInWithApple },
        { (const uint8_t*)"getAppleUserInfo", NULL, &getAppleUserInfo },
    };
    
    *numFunctionsToSet = sizeof(functionMap) / sizeof(FRENamedFunction);
    *functionsToSet = functionMap;
    
    g_ctx = ctx;
}

// Context finalizer
void AppleSignInExtensionContextFinalizer(FREContext ctx) {
    g_ctx = nil;
    g_currentAppleCredential = nil;
}

// Extension initializer
void AppleSignInExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AppleSignInExtensionContextInitializer;
    *ctxFinalizerToSet = &AppleSignInExtensionContextFinalizer;
}

// Extension finalizer
void AppleSignInExtensionFinalizer(void* extData) {
    /* Reserved for releasing native resources if added later. */
}

