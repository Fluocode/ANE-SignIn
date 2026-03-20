//
//  GoogleSignInExtension.h
//  GoogleSignInExtension
//
//  Created for com.fluocode.ane.signin.google
//

#ifndef GoogleSignInExtension_h
#define GoogleSignInExtension_h

#import "FlashRuntimeExtensions.h"

// Extension initializer and finalizer
void GoogleSignInExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet);
void GoogleSignInExtensionFinalizer(void* extData);

// Context initializer and finalizer
void GoogleSignInExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet);
void GoogleSignInExtensionContextFinalizer(FREContext ctx);

#endif /* GoogleSignInExtension_h */

