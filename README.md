# ANE Sign-In — Adobe AIR native extensions

This repository contains **Adobe Native Extensions (ANEs)** that integrate **Sign in with Apple** and **Google Sign-In** into **Adobe AIR** applications (ActionScript 3). Each extension exposes a small ActionScript API and forwards native results through **`StatusEvent.STATUS`**.

| Extension | Platform(s) | Purpose |
|-----------|---------------|---------|
| [**ANE-apple**](ANE-apple/) | iOS 13+ | [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/) |
| [**ANE-google**](ANE-google/) | Android & iOS | [Google Sign-In](https://developers.google.com/identity/sign-in) |

---

## 📁 Project layout

```
ANE-SignIn/
├── ANE-apple/          # Sign in with Apple (iOS only)
├── ANE-google/         # Google Sign-In (Android + iOS)
└── README.md           # This file
```

---

## 🍎 ANE-apple (`com.fluocode.ane.signin.apple`)

Native **AuthenticationServices** bridge for **Sign in with Apple** on iPhone and iPad.

- **Class:** `com.fluocode.ane.signin.apple.AppleSignInExtension`
- **Not supported:** Android, Windows, macOS desktop

👉 **Integration guide (descriptor, entitlements, ActionScript snippets):** [**ANE-apple/README.md**](ANE-apple/README.md)

---

## 🔐 ANE-google (`com.fluocode.ane.signin.google`)

Native **Google Sign-In** for **Android** (Play services) and **iOS** (Google Sign-In SDK).

- **Class:** `com.fluocode.ane.signin.google.GoogleSignInExtension`
- **Typical use:** OAuth client IDs, optional server client ID for ID tokens, manifest activity on Android, URL scheme on iOS

👉 **Integration guide (manifest, plist, Google Cloud, ActionScript snippets):** [**ANE-google/README.md**](ANE-google/README.md)

---

## 🧩 Using more than one ANE

You can reference **multiple** `<extensionID>` entries in the same AIR application descriptor if your app needs both Apple and Google sign-in on different platforms.

---

## 📎 Requirements (summary)

| | Apple ANE | Google ANE |
|---|-----------|------------|
| **AIR** | Mobile profile with iOS target | Android and/or iOS targets |
| **Portal** | Apple Developer — Sign in with Apple capability | Google Cloud — OAuth clients |
| **Min. OS** | iOS 13+ | Per Google / device (see folder README) |

For step-by-step setup, keys, and XML snippets, use the README inside each project folder.

***
If You like what I make please donate:
[![Foo](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4QBWVDKEVRL46)
*** 	
