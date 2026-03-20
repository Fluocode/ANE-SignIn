package com.fluocode.ane.signin.google
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	/**
	 * Native extension wrapper for Google Sign-In on Android and iOS.
	 *
	 * <p>This class communicates with the native ANE identified by
	 * <code>com.fluocode.ane.signin.google</code> via <code>ExtensionContext</code>.
	 * It redispatches <code>StatusEvent.STATUS</code> events from the native side so
	 * application code can listen on this dispatcher.</p>
	 *
	 * <p><b>Platform support</b></p>
	 * <ul>
	 *   <li>Android: supported</li>
	 *   <li>iOS: supported</li>
	 * </ul>
	 *
	 * <p><b>Status event codes</b> (on <code>StatusEvent.STATUS</code>, property <code>code</code>):</p>
	 * <ul>
	 *   <li><code>GOOGLE_SIGN_IN_SUCCESS</code> — success; <code>level</code> contains JSON with user data</li>
	 *   <li><code>GOOGLE_SIGN_IN_ERROR</code> — failure; <code>level</code> contains an error message</li>
	 * </ul>
	 *
	 * @see flash.external.ExtensionContext
	 * @see flash.events.StatusEvent
	 *
	 * @eventType flash.events.StatusEvent STATUS Dispatched when the native layer reports sign-in progress or result.
	 * The <code>code</code> and <code>level</code> fields carry the native payload (see class description).
	 *
	 * @langversion 3.0
	 * @playerversion Flash 10.2
	 * @playerversion AIR 2.6
	 */
	public class GoogleSignInExtension extends EventDispatcher
	{
		/** @private */
		private static const EXTENSION_ID:String = "com.fluocode.ane.signin.google";
		/** @private */
		private var _context:ExtensionContext;
		/** @private */
		private var _isAvailable:Boolean = false;
		
		/** @private */
		private static var _instance:GoogleSignInExtension;
		
		/**
		 * Returns the singleton instance of the extension.
		 *
		 * @return The shared <code>GoogleSignInExtension</code> instance.
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
		 * Whether the native extension context was created successfully and the ANE can be used.
		 *
		 * @return <code>true</code> if the extension is linked and the context exists; otherwise <code>false</code>.
		 */
		public function get isAvailable():Boolean
		{
			return _isAvailable;
		}
		
		/**
		 * Creates the extension instance and, if possible, registers a listener for native status events.
		 *
		 * <p>Use <code>getInstance()</code> instead of calling this constructor directly.</p>
		 *
		 * @throws Error If a second instance is constructed; this class is a singleton.
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
		 * Initializes Google Sign-In on the native side.
		 *
		 * <p>On Android this call is effectively a no-op; the SDK initializes when needed.
		 * On iOS, pass the OAuth client ID string expected by the native implementation.</p>
		 *
		 * @param clientId OAuth client ID for iOS; ignored on Android. Omit or pass an empty string for legacy native behavior.
		 *
		 * @return <code>true</code> if initialization succeeded; <code>false</code> if unavailable or an error occurred.
		 */
		public function initializeGoogleSignIn(clientId:String = null):Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
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
		 * Starts the Google Sign-In flow.
		 *
		 * <p>Listen for <code>StatusEvent.STATUS</code> on this instance to receive
		 * <code>GOOGLE_SIGN_IN_SUCCESS</code> or <code>GOOGLE_SIGN_IN_ERROR</code> (see class description).</p>
		 *
		 * @param serverClientId Optional Google OAuth server client ID used to obtain an ID token or server-side tokens for your backend.
		 *
		 * @return <code>true</code> if the native sign-in request was started; <code>false</code> otherwise.
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
		 * Signs the user out of Google on the native side.
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
		 * Indicates whether a user is currently signed in with Google according to the native SDK.
		 *
		 * @return <code>true</code> if signed in; <code>false</code> if not signed in, unavailable, or on error.
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
		 * Returns a JSON string describing the currently signed-in user, if any.
		 *
		 * <p>Typical fields include identifiers, email, display name, photo URL, ID token, and server auth code,
		 * depending on platform and configuration. Parse with <code>JSON.parse()</code> if you need an object.
		 * Successful sign-in also delivers similar data in <code>StatusEvent</code> <code>level</code> text.</p>
		 *
		 * @return JSON string, or an empty string if not signed in or on error.
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
		 * @deprecated Use <code>getGoogleSignedInUser()</code> instead.
		 *
		 * @return Same value as <code>getGoogleSignedInUser()</code>.
		 */
		public function getGoogleUserInfo():String
		{
			return getGoogleSignedInUser();
		}
		
		/**
		 * Polls the native layer for sign-in results that were deferred while the app was in the background (for example on Android).
		 *
		 * <p>Call when the application returns to the foreground if you use flows that can complete while backgrounded.</p>
		 *
		 * @return <code>true</code> if the native check ran; <code>false</code> if unavailable or on error.
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
		 * Forwards native <code>StatusEvent</code> instances to listeners of this dispatcher.
		 *
		 * @param event The status event raised by <code>ExtensionContext</code>.
		 *
		 * @private
		 */
		private function onStatus(event:StatusEvent):void
		{
			this.dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, event.code, event.level));
		}
		
		/**
		 * Releases the extension context, removes listeners, and clears internal state.
		 *
		 * <p>Call when the extension is no longer needed (for example on application exit).</p>
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
