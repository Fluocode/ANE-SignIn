package com.fluocode.ane.signin.apple
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	/**
	 * Apple Sign-In Extension for iOS only
	 * 
	 * Reverse Domain: com.fluocode.ane.signin.apple
	 * 
	 * Platform Support:
	 * - iOS: ✓ (iOS 13.0+)
	 * - Android: Not supported
	 */
	public class AppleSignInExtension extends EventDispatcher
	{
		private static const EXTENSION_ID:String = "com.fluocode.ane.signin.apple";
		private var _context:ExtensionContext;
		private var _isAvailable:Boolean = false;
		
		private static var _instance:AppleSignInExtension;
		
		/**
		 * Singleton instance
		 */
		public static function getInstance():AppleSignInExtension
		{
			if (!_instance)
			{
				_instance = new AppleSignInExtension();
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
		public function AppleSignInExtension()
		{
			if (_instance)
			{
				throw new Error("AppleSignInExtension is a singleton. Use getInstance() instead.");
			}
			
			try
			{
				_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
				_isAvailable = (_context != null);
				
				if (!_isAvailable)
				{
					trace("[AppleSignInExtension] Extension context could not be created. Make sure the ANE is included in your app descriptor.");
				}
				else
				{
					// Listen for StatusEvent.STATUS from native code
					_context.addEventListener(StatusEvent.STATUS, onStatus);
				}
			}
			catch (e:Error)
			{
				trace("[AppleSignInExtension] Error creating extension context: " + e.message);
				_isAvailable = false;
				_context = null;
			}
		}
		
		/**
		 * Initialize Sign-in with Apple (iOS only)
		 * @return true if initialization was successful
		 * 
		 * Platform support:
		 * - iOS: Supported (iOS 13.0+)
		 * - Android: Not supported (returns false)
		 */
		public function initializeAppleSignIn():Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				return _context.call("initializeAppleSignIn") as Boolean;
			}
			catch (e:Error)
			{
				trace("[AppleSignInExtension] Error initializing Apple Sign-In: " + e.message);
				return false;
			}
		}
		
		/**
		 * Sign in with Apple (iOS only)
		 * @return true if sign-in process was initiated
		 * 
		 * Platform support:
		 * - iOS: Supported (iOS 13.0+)
		 * - Android: Not supported (returns false)
		 * 
		 * NOTE: This method initiates the sign-in process. Listen for StatusEvent.STATUS events:
		 * - APPLE_SIGN_IN_SUCCESS: Sign-in successful (event.level contains JSON with user info)
		 * - APPLE_SIGN_IN_ERROR: Sign-in failed (event.level contains error message)
		 */
		public function signInWithApple():Boolean
		{
			if (!_isAvailable || !_context) return false;
			try
			{
				return _context.call("signInWithApple") as Boolean;
			}
			catch (e:Error)
			{
				trace("[AppleSignInExtension] Error signing in with Apple: " + e.message);
				return false;
			}
		}
		
		/**
		 * Get Apple user information (iOS only)
		 * @return Object with user info (userId, email, fullName) or null
		 * 
		 * Platform support:
		 * - iOS: Supported
		 * - Android: Not supported (returns null)
		 */
		public function getAppleUserInfo():Object
		{
			if (!_isAvailable || !_context) return null;
			try
			{
				return _context.call("getAppleUserInfo") as Object;
			}
			catch (e:Error)
			{
				trace("[AppleSignInExtension] Error getting Apple user info: " + e.message);
				return null;
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

