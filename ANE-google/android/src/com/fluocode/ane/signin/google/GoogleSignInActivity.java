package com.fluocode.ane.signin.google;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

import org.json.JSONObject;

public class GoogleSignInActivity extends Activity {
    private static final String TAG = "GoogleSignInActivity";
    private static final int RC_SIGN_IN = 9001;
    private static final String PREFS_NAME = "GoogleSignInPrefs";
    private static final String KEY_PENDING_RESULT = "pending_result";
    private static final String KEY_PENDING_RESULT_TYPE = "pending_result_type";
    private GoogleSignInClient mGoogleSignInClient;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "onCreate: GoogleSignInActivity started");

        Intent intent = getIntent();
        if (intent == null) {
            finish();
            return;
        }

        String action = intent.getStringExtra("ACTION");
        String serverClientId = intent.getStringExtra("SERVER_CLIENT_ID");

        if ("SIGN_OUT".equals(action)) {
            handleSignOut();
            return;
        }

        if ("GET_CURRENT_USER".equals(action)) {
            handleGetCurrentUser();
            return;
        }

        GoogleSignInOptions.Builder gsoBuilder = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail();

        if (serverClientId != null && !serverClientId.isEmpty()) {
            gsoBuilder.requestIdToken(serverClientId);
            Log.d(TAG, "Using serverClientId for idToken: " + serverClientId);
        }

        GoogleSignInOptions gso = gsoBuilder.build();
        mGoogleSignInClient = GoogleSignIn.getClient(this, gso);

        Intent signInIntent = mGoogleSignInClient.getSignInIntent();
        Log.d(TAG, "onCreate: Starting Google Sign-In intent with requestCode=" + RC_SIGN_IN);
        startActivityForResult(signInIntent, RC_SIGN_IN);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Log.d(TAG, "onActivityResult: called - requestCode=" + requestCode + ", resultCode=" + resultCode + ", data=" + (data != null ? "not null" : "null"));

        if (requestCode == RC_SIGN_IN) {
            Log.d(TAG, "onActivityResult: Processing RC_SIGN_IN result");
            if (data != null) {
                Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
                handleSignInResult(task);
            } else {
                Log.e(TAG, "onActivityResult: data Intent is null");
                storePendingResult("GOOGLE_SIGN_IN_ERROR", "Sign-in result data is null");
                finish();
            }
        } else {
            Log.w(TAG, "onActivityResult: Unexpected requestCode=" + requestCode);
        }
    }

    private void handleSignInResult(Task<GoogleSignInAccount> completedTask) {
        Log.d(TAG, "handleSignInResult: called, task.isComplete()=" + completedTask.isComplete() + ", task.isSuccessful()=" + completedTask.isSuccessful());
        try {
            GoogleSignInAccount account = completedTask.getResult(ApiException.class);
            Log.d(TAG, "handleSignInResult: Got account, email=" + (account != null ? account.getEmail() : "null"));

            if (account != null) {
                JSONObject userInfo = new JSONObject();
                userInfo.put("id", account.getId());
                userInfo.put("email", account.getEmail());
                userInfo.put("displayName", account.getDisplayName());
                userInfo.put("photoUrl", account.getPhotoUrl() != null ? account.getPhotoUrl().toString() : "");
                userInfo.put("idToken", account.getIdToken());
                userInfo.put("serverAuthCode", account.getServerAuthCode());

                Log.d(TAG, "handleSignInResult: Creating userInfo JSON");
                String userInfoJson = userInfo.toString();
                Log.d(TAG, "handleSignInResult: userInfo JSON length=" + userInfoJson.length());

                GoogleSignInExtension.GoogleSignInExtensionContext context = GoogleSignInExtension.getExtensionContext();
                Log.d(TAG, "handleSignInResult: Got extension context: " + (context != null ? "not null" : "NULL"));
                // Persist so checkPendingResult can deliver after resume if the AIR context was torn down.
                storePendingResult("GOOGLE_SIGN_IN_SUCCESS", userInfoJson);
                
                // Deliver to ActionScript now when the FRE context is still active.
                if (context != null) {
                    Log.d(TAG, "handleSignInResult: Dispatching GOOGLE_SIGN_IN_SUCCESS event immediately");
                    context.dispatchStatusEventAsync("GOOGLE_SIGN_IN_SUCCESS", userInfoJson);
                } else {
                    Log.e(TAG, "GoogleSignInExtensionContext is null, cannot dispatch success event.");
                }
            } else {
                Log.e(TAG, "GoogleSignInAccount is null after successful task.");
                storePendingResult("GOOGLE_SIGN_IN_ERROR", "GoogleSignInAccount is null.");
            }
        } catch (ApiException e) {
            Log.w(TAG, "signInResult:failed code=" + e.getStatusCode() + ", message=" + e.getMessage());
            String errorMessage = "Google Sign-In failed: " + e.getStatusCode();
            if (e.getStatusCode() == 12500) {
                errorMessage += " - Sign in was cancelled";
            } else if (e.getStatusCode() == 10) {
                errorMessage += " - Developer error (check SHA1 in Google Cloud Console)";
            }
            storePendingResult("GOOGLE_SIGN_IN_ERROR", errorMessage);
        } catch (Exception e) {
            Log.e(TAG, "handleSignInResult: Error", e);
            storePendingResult("GOOGLE_SIGN_IN_ERROR", "Error processing Google Sign-In result: " + e.getMessage());
        } finally {
            GoogleSignInExtension.resetGoogleSignInProgress();
            // Defer finish() so StatusEvent dispatch can complete before this Activity is destroyed.
            new android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(new Runnable() {
                @Override
                public void run() {
                    finish();
                }
            }, 150);
        }
    }
    
    private void storePendingResult(String resultType, String result) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(KEY_PENDING_RESULT, result);
        editor.putString(KEY_PENDING_RESULT_TYPE, resultType);
        editor.apply();
        Log.d(TAG, "storePendingResult: Stored " + resultType);
        
        // Notify ActionScript immediately when the extension context is available.
        GoogleSignInExtension.GoogleSignInExtensionContext context = GoogleSignInExtension.getExtensionContext();
        if (context != null) {
            context.dispatchStatusEventAsync(resultType, result);
        }
    }

    private void handleSignOut() {
        Log.d(TAG, "handleSignOut: called");
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).build();
        GoogleSignInClient googleSignInClient = GoogleSignIn.getClient(this, gso);
        googleSignInClient.signOut()
                .addOnCompleteListener(this, task -> {
                    GoogleSignInExtension.GoogleSignInExtensionContext context = GoogleSignInExtension.getExtensionContext();
                    if (context != null) {
                        if (task.isSuccessful()) {
                            context.dispatchStatusEventAsync("GOOGLE_SIGN_OUT_SUCCESS", "Signed out successfully.");
                        } else {
                            context.dispatchStatusEventAsync("GOOGLE_SIGN_OUT_ERROR", "Sign out failed.");
                        }
                    }
                    Log.d(TAG, "Sign-out completed");
                    finish();
                });
    }

    private void handleGetCurrentUser() {
        Log.d(TAG, "handleGetCurrentUser: called");
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
        GoogleSignInExtension.GoogleSignInExtensionContext context = GoogleSignInExtension.getExtensionContext();
        if (context != null) {
            if (account != null) {
                try {
                    JSONObject userInfo = new JSONObject();
                    userInfo.put("id", account.getId());
                    userInfo.put("email", account.getEmail());
                    userInfo.put("displayName", account.getDisplayName());
                    userInfo.put("photoUrl", account.getPhotoUrl() != null ? account.getPhotoUrl().toString() : "");
                    userInfo.put("idToken", account.getIdToken());
                    userInfo.put("serverAuthCode", account.getServerAuthCode());
                    
                    context.dispatchStatusEventAsync("GOOGLE_CURRENT_USER", userInfo.toString());
                } catch (Exception e) {
                    Log.e(TAG, "Error creating user JSON", e);
                    context.dispatchStatusEventAsync("GOOGLE_CURRENT_USER", "");
                }
            } else {
                context.dispatchStatusEventAsync("GOOGLE_CURRENT_USER", "");
            }
        }
        finish();
    }

    public static void signOut(Activity activity) {
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).build();
        GoogleSignInClient googleSignInClient = GoogleSignIn.getClient(activity, gso);
        googleSignInClient.signOut()
                .addOnCompleteListener(task -> {
                    GoogleSignInExtension.GoogleSignInExtensionContext context = GoogleSignInExtension.getExtensionContext();
                    if (context != null) {
                        if (task.isSuccessful()) {
                            context.dispatchStatusEventAsync("GOOGLE_SIGN_OUT_SUCCESS", "Signed out successfully.");
                        } else {
                            context.dispatchStatusEventAsync("GOOGLE_SIGN_OUT_ERROR", "Sign out failed.");
                        }
                    }
                });
    }

    public static boolean isSignedIn(Activity activity) {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(activity);
        return account != null;
    }

    public static String getSignedInUser(Activity activity) {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(activity);
        if (account != null) {
            try {
                JSONObject userInfo = new JSONObject();
                userInfo.put("id", account.getId());
                userInfo.put("email", account.getEmail());
                userInfo.put("displayName", account.getDisplayName());
                userInfo.put("photoUrl", account.getPhotoUrl() != null ? account.getPhotoUrl().toString() : "");
                userInfo.put("idToken", account.getIdToken());
                userInfo.put("serverAuthCode", account.getServerAuthCode());
                return userInfo.toString();
            } catch (Exception e) {
                Log.e(TAG, "Error getting signed in user info", e);
            }
        }
        return null;
    }
}

