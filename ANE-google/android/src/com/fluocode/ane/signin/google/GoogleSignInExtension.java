package com.fluocode.ane.signin.google;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREWrongThreadException;
import com.adobe.air.AndroidActivityWrapper;

import java.util.HashMap;
import java.util.Map;

public class GoogleSignInExtension implements FREExtension {
    private static final String TAG = "GoogleSignInExt";
    public static GoogleSignInExtensionContext extensionContext;

    @Override
    public void initialize() {
        Log.d(TAG, "Extension initialized");
    }

    @Override
    public FREContext createContext(String contextType) {
        extensionContext = new GoogleSignInExtensionContext();
        return extensionContext;
    }

    @Override
    public void dispose() {
        if (extensionContext != null) {
            extensionContext.dispose();
        }
        extensionContext = null;
    }

    public static void resetGoogleSignInProgress() {
        if (extensionContext != null) {
            extensionContext.resetGoogleSignInProgressFlag();
        }
    }

    public static GoogleSignInExtensionContext getExtensionContext() {
        return extensionContext;
    }

    public static class GoogleSignInExtensionContext extends FREContext {

        private boolean googleSignInInProgress = false;
        private AndroidActivityWrapper activityWrapper;

        public void resetGoogleSignInProgressFlag() {
            googleSignInInProgress = false;
        }

        public GoogleSignInExtensionContext() {
            activityWrapper = AndroidActivityWrapper.GetAndroidActivityWrapper();
            checkAndDispatchPendingResult();
        }
        
        private void checkAndDispatchPendingResult() {
            try {
                Activity activity = getActivityFromWrapper();
                if (activity != null) {
                    SharedPreferences prefs = activity.getSharedPreferences("GoogleSignInPrefs", Activity.MODE_PRIVATE);
                    String pendingResultType = prefs.getString("pending_result_type", null);
                    String pendingResult = prefs.getString("pending_result", null);
                    
                    if (pendingResultType != null && pendingResult != null) {
                        Log.d(TAG, "checkAndDispatchPendingResult: Found pending result: " + pendingResultType);
                        dispatchStatusEventAsync(pendingResultType, pendingResult);
                        
                        // Drop persisted keys so the same result is not dispatched again.
                        SharedPreferences.Editor editor = prefs.edit();
                        editor.remove("pending_result");
                        editor.remove("pending_result_type");
                        editor.apply();
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "checkAndDispatchPendingResult: Error", e);
            }
        }

        @Override
        public void dispose() {
            activityWrapper = null;
        }

        @Override
        public Map<String, FREFunction> getFunctions() {
            Map<String, FREFunction> functionMap = new HashMap<>();
            functionMap.put("initializeGoogleSignIn", new InitializeGoogleSignInFunction());
            functionMap.put("signInWithGoogle", new SignInWithGoogleFunction());
            functionMap.put("signOutGoogle", new SignOutGoogleFunction());
            functionMap.put("isGoogleSignedIn", new IsGoogleSignedInFunction());
            functionMap.put("getGoogleSignedInUser", new GetGoogleSignedInUserFunction());
            functionMap.put("checkPendingResult", new CheckPendingResultFunction());
            return functionMap;
        }

        private Activity getActivityFromWrapper() {
            if (activityWrapper != null) {
                return activityWrapper.getActivity();
            }
            return null;
        }

        private class InitializeGoogleSignInFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "initializeGoogleSignIn: called");
                    // Deliver any sign-in outcome stored while the host Activity was unavailable.
                    checkAndDispatchPendingResult();
                    return FREObject.newObject(true);
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "initializeGoogleSignIn: FREWrongThreadException", e);
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "initializeGoogleSignIn: Error", e);
                    return null;
                }
            }
        }

        private class SignInWithGoogleFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "signInWithGoogle: called");

                    if (googleSignInInProgress) {
                        Log.w(TAG, "signInWithGoogle: Already in progress");
                        try {
                            return FREObject.newObject(false);
                        } catch (FREWrongThreadException e) {
                            Log.e(TAG, "signInWithGoogle: FREWrongThreadException", e);
                            return null;
                        }
                    }

                    Activity activity = getActivityFromWrapper();
                    if (activity == null) {
                        Log.e(TAG, "signInWithGoogle: Activity is null");
                        return null;
                    }

                    String serverClientId = null;
                    if (args.length > 0 && args[0] != null) {
                        try {
                            serverClientId = args[0].getAsString();
                        } catch (FREWrongThreadException e) {
                            Log.e(TAG, "signInWithGoogle: FREWrongThreadException getting serverClientId", e);
                            return null;
                        }
                    }

                    googleSignInInProgress = true;

                    Intent intent = new Intent(activity, GoogleSignInActivity.class);
                    if (serverClientId != null && !serverClientId.isEmpty()) {
                        intent.putExtra("SERVER_CLIENT_ID", serverClientId);
                    }
                    activity.startActivity(intent);

                    Log.d(TAG, "signInWithGoogle: Started GoogleSignInActivity");
                    return FREObject.newObject(true);
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "signInWithGoogle: FREWrongThreadException", e);
                    googleSignInInProgress = false;
                    dispatchStatusEventAsync("GOOGLE_SIGN_IN_ERROR", "Thread error: " + e.getMessage());
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "signInWithGoogle: Error", e);
                    googleSignInInProgress = false;
                    dispatchStatusEventAsync("GOOGLE_SIGN_IN_ERROR", "Error starting Google Sign-In: " + e.getMessage());
                    try {
                        return FREObject.newObject(false);
                    } catch (FREWrongThreadException ex) {
                        Log.e(TAG, "signInWithGoogle: FREWrongThreadException in catch", ex);
                        return null;
                    }
                }
            }
        }

        private class SignOutGoogleFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "signOutGoogle: called");
                    Activity activity = getActivityFromWrapper();
                    if (activity == null) {
                        Log.e(TAG, "signOutGoogle: Activity is null");
                        return null;
                    }
                    GoogleSignInActivity.signOut(activity);
                    return FREObject.newObject(true);
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "signOutGoogle: FREWrongThreadException", e);
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "signOutGoogle: Error", e);
                    try {
                        return FREObject.newObject(false);
                    } catch (FREWrongThreadException ex) {
                        Log.e(TAG, "signOutGoogle: FREWrongThreadException in catch", ex);
                        return null;
                    }
                }
            }
        }

        private class IsGoogleSignedInFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "isGoogleSignedIn: called");
                    Activity activity = getActivityFromWrapper();
                    if (activity == null) {
                        Log.e(TAG, "isGoogleSignedIn: Activity is null");
                        try {
                            return FREObject.newObject(false);
                        } catch (FREWrongThreadException e) {
                            Log.e(TAG, "isGoogleSignedIn: FREWrongThreadException", e);
                            return null;
                        }
                    }
                    return FREObject.newObject(GoogleSignInActivity.isSignedIn(activity));
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "isGoogleSignedIn: FREWrongThreadException", e);
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "isGoogleSignedIn: Error", e);
                    try {
                        return FREObject.newObject(false);
                    } catch (FREWrongThreadException ex) {
                        Log.e(TAG, "isGoogleSignedIn: FREWrongThreadException in catch", ex);
                        return null;
                    }
                }
            }
        }

        private class GetGoogleSignedInUserFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "getGoogleSignedInUser: called");
                    Activity activity = getActivityFromWrapper();
                    if (activity == null) {
                        Log.e(TAG, "getGoogleSignedInUser: Activity is null");
                        return null;
                    }
                    String userJson = GoogleSignInActivity.getSignedInUser(activity);
                    if (userJson == null) {
                        try {
                            return FREObject.newObject("");
                        } catch (FREWrongThreadException e) {
                            Log.e(TAG, "getGoogleSignedInUser: FREWrongThreadException (empty string)", e);
                            return null;
                        }
                    }
                    return FREObject.newObject(userJson);
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "getGoogleSignedInUser: FREWrongThreadException", e);
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "getGoogleSignedInUser: Error", e);
                    return null;
                }
            }
        }
        
        private class CheckPendingResultFunction implements FREFunction {
            @Override
            public FREObject call(FREContext context, FREObject[] args) {
                try {
                    Log.d(TAG, "checkPendingResult: called");
                    checkAndDispatchPendingResult();
                    return FREObject.newObject(true);
                } catch (FREWrongThreadException e) {
                    Log.e(TAG, "checkPendingResult: FREWrongThreadException", e);
                    return null;
                } catch (Exception e) {
                    Log.e(TAG, "checkPendingResult: Error", e);
                    try {
                        return FREObject.newObject(false);
                    } catch (FREWrongThreadException ex) {
                        return null;
                    }
                }
            }
        }
    }
}

