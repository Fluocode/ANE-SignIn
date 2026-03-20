package com.fluocode.ane.signin.google
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	/**
	 * Google Sign-In Extension for Android and iOS
	 * 
	 * Reverse Domain: com.fluocode.ane.signin.google
	 * 
	 * Platform Support:
	 * - Android: ✓
	 * - iOS: ✓
	 */
	public class GoogleSignInExtension extends EventDispatcher
	{
		private static const EXTENSION_ID:String = "com.fluocode.ane.signin.google";
		private var _context:ExtensionContext;
		private var _isAvailable:Boolean = false;
		
		private static var _instance:GoogleSignInExtension;
		
		/**
		 * Singleton instance
		 */
		public static function getInstance():GoogleSignInExtension
		{
			if (!_instance)
			{
				_instance = new GoogleSignInExtension();
			}
			return _instance;
		}
		
		/**
		 * Check if the extension is available
		 */
		public function get isAvailable():Boolean
		{
			return _isAvailable;
		}
		
		/**
		 * Constructor
		 */
		public function GoogleSignInExtension()
		{
			if (_instance)
			{
				throw new Error("GoogleSignInExtension is a singleton. Use getInstance() instead.");
			}
			
		try
		{
			_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
			_isAvailable = (_context != null);
			
			if (!_isAvailable)
			{
				trace("[GoogleSignInExtension] Extension context could not be created. Make sure the ANE is included in your app descriptor.");
			}
			else
			{
				// Listen for StatusEvent.STATUS from native code
				_context.addEventListener(StatusEvent.STATUS, onStatus);
			}
		}
		catch (e:Error)
		{
			trace("[GoogleSignInExtension] Error creating extension context: " + e.message);
			_isAvailable = false;
			_context = null;
		}
		}
		
		/**
		 * Initialize Google Sign-in (Android and iOS)
		 * NOTE: On Android, this is a no-op. Google Sign-In is initialized automatically when needed.
		 * @param clientId Ignored on Android (kept for iOS compatibility)
		 * @return true if initialization was successful
		 */
		public function initializeGoogleSignIn(clientId:String = null):Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				// iOS requires the OAuth clientId; Android is a no-op.
				// If no clientId is provided, pass no args to keep backward compatibility.
				if (clientId && clientId.length > 0)
				{
					return _context.call("initializeGoogleSignIn", clientId) as Boolean;
				}
				return _context.call("initializeGoogleSignIn") as Boolean;
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error initializing Google Sign-In: " + e.message);
				return false;
			}
		}
		
		/**
		 * Sign in with Google
		 * @param serverClientId Optional: Google OAuth server client ID for backend authentication (to get idToken)
		 * @return true if sign-in process was initiated
		 * 
		 * NOTE: This method initiates the sign-in process. Listen for StatusEvent.STATUS events:
		 * - GOOGLE_SIGN_IN_SUCCESS: Sign-in successful (event.level contains JSON with user info)
		 * - GOOGLE_SIGN_IN_ERROR: Sign-in failed (event.level contains error message)
		 */
		public function signInWithGoogle(serverClientId:String = null):Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				if (serverClientId && serverClientId.length > 0)
				{
					return _context.call("signInWithGoogle", serverClientId) as Boolean;
				}
				else
				{
					return _context.call("signInWithGoogle") as Boolean;
				}
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error signing in with Google: " + e.message);
				return false;
			}
		}
		
		/**
		 * Sign out from Google
		 */
		public function signOutGoogle():void
		{
			if (!_isAvailable || !_context) return;
			try
			{
				_context.call("signOutGoogle");
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error signing out from Google: " + e.message);
			}
		}
		
		/**
		 * Check if user is signed in with Google
		 * @return true if user is signed in
		 */
		public function isGoogleSignedIn():Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				return _context.call("isGoogleSignedIn") as Boolean;
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error checking Google sign-in status: " + e.message);
				return false;
			}
		}
		
		/**
		 * Get Google user information for currently signed-in user
		 * @return JSON string with user info (id, email, displayName, photoUrl, idToken, serverAuthCode) or empty string if not signed in
		 * 
		 * NOTE: This returns a JSON string, not an Object. Parse it with JSON.parse() if needed.
		 * Alternatively, the GOOGLE_SIGN_IN_SUCCESS event already contains this information in event.level
		 */
		public function getGoogleSignedInUser():String
		{
			if (!_isAvailable || !_context) return "";
			try
			{
				var result:String = _context.call("getGoogleSignedInUser") as String;
				return result || "";
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error getting Google signed-in user: " + e.message);
				return "";
			}
		}
		
		/**
		 * @deprecated Use getGoogleSignedInUser() instead
		 * Get Google user information (legacy method name)
		 * @return JSON string with user info or empty string
		 */
		public function getGoogleUserInfo():String
		{
			return getGoogleSignedInUser();
		}
		
		/**
		 * Check for pending sign-in results (should be called when app returns to foreground)
		 * This method checks SharedPreferences for any pending sign-in results that were stored
		 * when the app went to background during the sign-in flow.
		 * @return true if check was performed
		 */
		public function checkPendingResult():Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				return _context.call("checkPendingResult") as Boolean;
			}
			catch (e:Error)
			{
				trace("[GoogleSignInExtension] Error checking pending result: " + e.message);
				return false;
			}
		}
		
	/**
	 * Handle StatusEvent from native code and dispatch it to listeners
	 * @param event StatusEvent from ExtensionContext
	 */
	private function onStatus(event:StatusEvent):void
	{
		// Redispatch the event so listeners in the app can receive it
		this.dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, event.code, event.level));
	}
	
	/**
	 * Dispose the extension
	 */
	public function dispose():void
	{
		if (_context)
		{
			_context.removeEventListener(StatusEvent.STATUS, onStatus);
			_context.dispose();
			_context = null;
		}
	}
}
}

