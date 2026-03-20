//
//  AppleSignInExtension.h
//  AppleSignInExtension
//
//  Created for com.fluocode.ane.signin.apple
//

#ifndef AppleSignInExtension_h
#define AppleSignInExtension_h

#import "FlashRuntimeExtensions.h"

// Extension initializer and finalizer
void AppleSignInExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet);
void AppleSignInExtensionFinalizer(void* extData);

// Context initializer and finalizer
void AppleSignInExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet);
void AppleSignInExtensionContextFinalizer(FREContext ctx);

#endif /* AppleSignInExtension_h */

