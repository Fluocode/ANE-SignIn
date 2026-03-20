# ANE Sign-In Test (AIR iOS)

App de prueba para verificar los ANEs de:
- Google: `com.fluocode.ane.signin.google`
- Apple: `com.fluocode.ane.signin.apple`

Tiene 2 botones: **Sign in Google** y **Sign in Apple**. Muestra en pantalla todo lo que llegue vía `StatusEvent.STATUS`.

## Estructura
- `app.xml` — descriptor AIR (declara ambos `<extensions><extensionID>...`)
- `src/Main.as` — UI + listeners

## Requisitos
- Adobe AIR SDK + `adt` (para empaquetar)
- Un SWF compilado (ej. `TestSignIn.swf`)
- Los ANEs empaquetados (`.ane`) para iOS:
  - `ANE-google/ANE/google.ane` (ya existe en tu repo)
  - `AppleSignIn.ane` (todavía no existe en el repo en este momento; hay que empaquetarlo)

## Empaquetar (ejemplo con `adt`)
> El comando exacto depende de tu instalación de AIR/ADT y de cómo compiles el SWF.
> La idea general es:
> 1) empaquetar el `.ipa` del app incluyendo ambos ANEs
> 2) incluir en el paquete `app.xml` y el `TestSignIn.swf`

```bash
adt -package -target ipa \
  -storetype pkcs12 -keystore <TU_CERT>.p12 -storepass <PASS> \
  -provisioning-profile <TU_PROFILE>.mobileprovision \
  -C build TestSignIn.swf \
  -extdir <RUTA_A_LAS_ANES> \
  -platform iPhone-ARM -C . .
```

## Nota sobre AppleSignIn.ane
El ANE de Apple requiere un `.a` (generado) y también un `swc` (generado con Flex/AIR compiler).
En el repo ya dejé el `.a` dentro de:
- `ANE-apple/ANE/iPhone-ARM/AppleSignInExtension.a`
- `ANE-apple/ANE/iPhone-x86/AppleSignInExtension.a`

Pero todavía falta empaquetar `AppleSignIn.ane` (compilar el SWC y correr `adt -package -target ane`).

## Próximo paso
Si me confirmas qué versión de AIR/ADT usas (y si ya tienes `AppleSignIn.ane` empaquetado), te preparo el comando exacto de `adt` para que genere el `.ipa`.

## Google iOS Client ID (`GOOGLE_IOS_CLIENT_ID`)

Para que el ANE de Google funcione en iOS, el test AIR llama a:
`initializeGoogleSignIn(clientId)`

Ese valor se obtiene en Google Cloud Console:
1. Ve a **Google Cloud Console**
2. Abre tu proyecto
3. En el menú: **APIs y servicios → Credenciales**
4. Busca/crea una credencial del tipo **OAuth 2.0 Client ID**
5. Selecciona **Application type: iOS** y configura el **bundle id** de tu app
6. Copia el valor del **Client ID** (algo como):
   `1234567890-abc123def456.apps.googleusercontent.com`

Después pega ese valor en el test:
`test-air/src/Main.as` en la constante `GOOGLE_IOS_CLIENT_ID`.

## Provisioning + Reversed Client ID (Google iOS)

Para que el build iOS funcione correctamente:

- El provisioning profile debe corresponder al bundle id de la app (por ejemplo `com.fluocode.findcard`).
- Si usas Apple Sign-In, el provisioning debe incluir `com.apple.developer.applesignin`.
- Para Google Sign-In, en `Main-app.xml` (dentro de `InfoAdditions`) debes configurar:
  `CFBundleURLTypes -> CFBundleURLSchemes` con el **Reversed Client ID** de Google.
  - Ejemplo: `com.googleusercontent.apps.1234567890-abc123def456`
  - **No** pongas aquí el bundle id (`com.fluocode.findcard`) ni una API key (`AIza...`).

