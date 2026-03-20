# 🍎 Sign in with Apple — Adobe AIR ANE

A small **Adobe Native Extension (ANE)** that lets your AIR app use **Sign in with Apple** on **iPhone and iPad**. The native layer talks to Apple’s `AuthenticationServices` APIs; your app listens for **`StatusEvent.STATUS`** and reads user data from the event payload or from a helper call.

**Extension ID:** `com.fluocode.ane.signin.apple`

---

## ✨ What you get

| | |
|---|---|
| 📱 **Platform** | iOS **13.0+** only (not available on Android or desktop) |
| 🔐 **Flow** | System Sign in with Apple UI, then success/error via `StatusEvent` |
| 📦 **User data** | JSON with fields such as `userId`, `email`, `fullName` (when Apple provides them) |

---

## 1. Add the ANE to your app

Include the packaged `.ane` in your project and declare the extension in your **application descriptor** (`app.xml` / `application.xml`):

```xml
<extensions>
    <extensionID>com.fluocode.ane.signin.apple</extensionID>
</extensions>
```

Point your build settings at the **SWC** the ANE ships with so ActionScript can compile against `AppleSignInExtension`.

---

## 2. ActionScript API — snippets

Import:

```actionscript
import com.fluocode.ane.signin.apple.AppleSignInExtension;
import flash.events.StatusEvent;
```

### 🔹 `AppleSignInExtension.getInstance()`

Singleton accessor. Always use this instead of `new`.

```actionscript
var apple:AppleSignInExtension = AppleSignInExtension.getInstance();
```

### 🔹 `isAvailable` (getter)

`true` when the native extension context loaded (ANE linked correctly). If `false`, Sign in with Apple cannot run.

```actionscript
if (!apple.isAvailable) {
    trace("ANE not available on this build or platform");
    return;
}
```

### 🔹 `initializeAppleSignIn():Boolean`

Prepares native Sign in with Apple (`ASAuthorizationAppleIDProvider`, delegate). Call **before** starting sign-in.

```actionscript
var ok:Boolean = apple.initializeAppleSignIn();
```

### 🔹 `signInWithApple():Boolean`

Starts the system sign-in UI. Listen for **`StatusEvent.STATUS`** first; results arrive asynchronously.

```actionscript
apple.addEventListener(StatusEvent.STATUS, onAppleStatus);
var started:Boolean = apple.signInWithApple();
```

### 🔹 `getAppleUserInfo():Object`

Returns an **Object** with the last credential fields (`userId`, `email`, `fullName`, etc.), or `null` if none. Useful after a successful sign-in.

```actionscript
var info:Object = apple.getAppleUserInfo();
```

### 🔹 `dispose():void`

Removes listeners and releases the extension context when you no longer need the ANE (for example on exit).

```actionscript
apple.removeEventListener(StatusEvent.STATUS, onAppleStatus);
apple.dispose();
```

### 🔹 Handle status events

```actionscript
function onAppleStatus(event:StatusEvent):void {
    switch (event.code) {
        case "APPLE_SIGN_IN_SUCCESS":
            var user:Object = JSON.parse(event.level);
            trace("userId:", user.userId);
            break;
        case "APPLE_SIGN_IN_ERROR":
            trace("Apple Sign-In error:", event.level);
            break;
    }
}
```

---

## 3. Status event codes (`event.code`)

| Code | Meaning |
|------|--------|
| `APPLE_SIGN_IN_SUCCESS` | `event.level` is a **JSON string** with user fields |
| `APPLE_SIGN_IN_ERROR` | `event.level` is a **human-readable error message** |

---

## 4. App descriptor & Apple configuration

### 4.1 Minimum iOS version

Target **iOS 13.0 or newer** in your AIR iOS settings (`sdkVersion` / minimum OS as you usually set for your app).

### 4.2 Sign in with Apple capability (required)

In **[Apple Developer](https://developer.apple.com/)**:

1. Open your **App ID** and enable **Sign In with Apple**.
2. Regenerate / use provisioning profiles that include this capability.

Your **signed AIR iOS app** must include the **Sign in with Apple** entitlement. In the **iOS** section of your application descriptor, add an entitlements block such as:

```xml
<iPhone>
    <Entitlements>
        <![CDATA[
        <key>com.apple.developer.applesignin</key>
        <array>
            <string>Default</string>
        </array>
        ]]>
    </Entitlements>
</iPhone>
```

Adjust nesting to match your AIR version’s expected schema if your tool uses slightly different tags—the important part is the **`com.apple.developer.applesignin`** array with **`Default`**.

> Without this entitlement and a matching App ID, Sign in with Apple will fail at runtime.

---

## 5. Keys, identifiers & portal setup

There is **no separate API key** file for Sign in with Apple inside the ANE. You must:

| Step | What to do |
|------|------------|
| ✅ App ID | Enable **Sign In with Apple** for your app’s bundle ID |
| ✅ Profiles | Use development/distribution profiles that include the capability |
| ✅ Entitlements | Ship the **`com.apple.developer.applesignin`** entitlement as shown above |

Optional (for **web** or **server** verification later): create a **Services ID** and keys in the Apple Developer **Certificates, Identifiers & Profiles** area— that is separate from this ANE and only needed if **your backend** validates Apple tokens.

---

## 📌 Quick checklist

1. Extension ID `com.fluocode.ane.signin.apple` in `<extensions>`
2. ANE + SWC wired in your IDE / build
3. iOS **13+** deployment
4. **Sign In with Apple** enabled on the App ID + entitlements in the packaged app
