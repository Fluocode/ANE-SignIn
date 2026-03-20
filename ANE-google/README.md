# 🔐 Google Sign-In — Adobe AIR ANE

A **Adobe Native Extension (ANE)** that adds **Google Sign-In** to your AIR app on **Android** and **iOS**. Sign-in runs in the native Google UI; your code listens for **`StatusEvent.STATUS`** and can read a JSON user payload from the event or from helper methods.

**Extension ID:** `com.fluocode.ane.signin.google`

---

## ✨ What you get

| | |
|---|---|
| 🤖 **Android** | Transparent helper activity + Google Play services–based sign-in |
| 🍏 **iOS** | Google Sign-In SDK with OAuth **client ID** and URL scheme handling |
| 📨 **Events** | Success/error (and sign-out) delivered as `StatusEvent` with string payloads |
| 🔄 **Android resume** | Optional `checkPendingResult()` when the app returns to foreground |

---

## 1. Add the ANE to your app

Declare the extension in your **application descriptor**:

```xml
<extensions>
    <extensionID>com.fluocode.ane.signin.google</extensionID>
</extensions>
```

Include the ANE’s **SWC** in your project so `GoogleSignInExtension` resolves at compile time.

**Google Play services:** your final APK must ship compatible **Google Play services** artifacts (often already pulled in by other ANEs or your packaging). If sign-in fails with developer/configuration errors, verify Play services and OAuth setup below.

---

## 2. ActionScript API — snippets

Import:

```actionscript
import com.fluocode.ane.signin.google.GoogleSignInExtension;
import flash.events.StatusEvent;
import flash.events.Event;
```

### 🔹 `GoogleSignInExtension.getInstance()`

```actionscript
var g:GoogleSignInExtension = GoogleSignInExtension.getInstance();
```

### 🔹 `isAvailable` (getter)

```actionscript
if (!g.isAvailable) {
    trace("ANE not linked");
    return;
}
```

### 🔹 `initializeGoogleSignIn(clientId:String = null):Boolean`

- **iOS:** pass your **OAuth 2.0 Client ID** (iOS type) from Google Cloud. Required for a working iOS flow.
- **Android:** call is safe; native side treats it as a no-op for initialization, but you should still call it once for a consistent startup sequence.

```actionscript
// iOS — use your iOS OAuth client ID string
g.initializeGoogleSignIn("YOUR_IOS_CLIENT_ID.apps.googleusercontent.com");

// Android — optional null / omit
g.initializeGoogleSignIn(null);
```

### 🔹 `signInWithGoogle(serverClientId:String = null):Boolean`

Starts sign-in. Pass a **server (web) client ID** only if you need an **ID token** (or related tokens) validated by your backend.

```actionscript
g.addEventListener(StatusEvent.STATUS, onGoogleStatus);
g.signInWithGoogle(); // or: g.signInWithGoogle("YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com");
```

### 🔹 `signOutGoogle():void`

```actionscript
g.signOutGoogle();
```

### 🔹 `isGoogleSignedIn():Boolean`

```actionscript
var signedIn:Boolean = g.isGoogleSignedIn();
```

### 🔹 `getGoogleSignedInUser():String`

Returns a **JSON string** (or `""` if none). Parse with `JSON.parse`.

```actionscript
var json:String = g.getGoogleSignedInUser();
if (json.length > 0) {
    var user:Object = JSON.parse(json);
}
```

### 🔹 `checkPendingResult():Boolean` (especially Android)

If the sign-in flow finishes while your app is backgrounded, stored results may be flushed when you resume. Call from a **foreground** / **activate** handler:

```actionscript
stage.addEventListener(Event.ACTIVATE, onActivate);

function onActivate(e:Event):void {
    if (g.isAvailable) {
        g.checkPendingResult();
    }
}
```

### 🔹 `dispose():void`

```actionscript
g.removeEventListener(StatusEvent.STATUS, onGoogleStatus);
g.dispose();
```

### 🔹 Status handler example

```actionscript
function onGoogleStatus(event:StatusEvent):void {
    switch (event.code) {
        case "GOOGLE_SIGN_IN_SUCCESS":
            var user:Object = JSON.parse(event.level);
            trace("email:", user.email);
            break;
        case "GOOGLE_SIGN_IN_ERROR":
            trace("Error:", event.level);
            break;
        case "GOOGLE_SIGN_OUT_SUCCESS":
        case "GOOGLE_SIGN_OUT_ERROR":
            trace(event.code, event.level);
            break;
    }
}
```

---

## 3. Status event codes (`event.code`)

| Code | Meaning |
|------|--------|
| `GOOGLE_SIGN_IN_SUCCESS` | `event.level` = JSON user string |
| `GOOGLE_SIGN_IN_ERROR` | `event.level` = error message |
| `GOOGLE_SIGN_OUT_SUCCESS` | Sign-out completed |
| `GOOGLE_SIGN_OUT_ERROR` | Sign-out failed |

*Additional codes may appear in edge flows (for example current-user probes from native helpers).*

---

## 4. App descriptor — Android manifest

Inside `<android><manifestAdditions><![CDATA[ ... ]]></manifestAdditions></android>`, merge an **`<application>`** block that registers the ANE’s activity (transparent, not exported):

```xml
<application>
    <activity
        android:name="com.fluocode.ane.signin.google.GoogleSignInActivity"
        android:exported="false"
        android:theme="@android:style/Theme.Translucent.NoTitleBar" />
</application>
```

You do **not** declare Google’s own account-picker activities—those belong to Google Play services.

Ensure your merged manifest allows **Internet** access if your template does not already (many AIR templates do).

---

## 5. App descriptor & iOS — URL scheme

Google Sign-In on iOS needs a **URL scheme** so the OAuth redirect can return to your app. Use the **reversed client ID** from the Google Cloud **OAuth client** (iOS).

In your iOS `InfoAdditions` (or equivalent AIR iOS plist merge), add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value Google shows for your iOS client (often like `com.googleusercontent.apps.123456789-abcdef`).

Pass the matching **iOS client ID** string into `initializeGoogleSignIn(...)` as described in section 2.

---

## 6. Google Cloud & OAuth setup

Do this in **[Google Cloud Console](https://console.cloud.google.com/)** for the same project you ship in the store:

### 6.1 Create OAuth clients

| Client type | Used for |
|-------------|----------|
| **iOS** | Bundle ID + App Store workflow; supplies **client ID** + **reversed client ID** (URL scheme) |
| **Android** | Package name + **SHA-1** signing certificate fingerprint |
| **Web application** (optional) | **Server client ID** if you call `signInWithGoogle(serverClientId)` for backend token checks |

### 6.2 Android SHA-1

Add the **SHA-1** (and **SHA-256** if you use Play App Signing) of the key that signs your **release** and **debug** builds. Mismatched SHA-1 is a common cause of **error code 10** (“developer error”) during sign-in.

### 6.3 Consent screen

Configure the **OAuth consent screen** (app name, support email, scopes). For production, complete Google’s verification if you request sensitive scopes.

### 6.4 Pass the right IDs in code

- **iOS:** `initializeGoogleSignIn("…ios-client-id….apps.googleusercontent.com")` + URL scheme = **reversed** iOS client ID  
- **Backend ID tokens:** `signInWithGoogle("…web-server-client-id….apps.googleusercontent.com")`  

---

## 📌 Quick checklist

1. Extension ID `com.fluocode.ane.signin.google` in `<extensions>`
2. **Android:** `GoogleSignInActivity` in `manifestAdditions`  
3. **iOS:** URL scheme + `initializeGoogleSignIn` with iOS **client ID**  
4. **Google Cloud:** OAuth clients for Android (package + SHA-1) and iOS (bundle ID)  
5. **Android:** call `checkPendingResult()` on activate if users might background during sign-in  
