package com.fluocode.ane.signin.apple
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	/**
	 * Native extension wrapper for Sign in with Apple on iOS.
	 *
	 * <p>This class communicates with the native ANE identified by
	 * <code>com.fluocode.ane.signin.apple</code> via <code>ExtensionContext</code>.
	 * It redispatches <code>StatusEvent.STATUS</code> events from the native side so
	 * application code can listen on this dispatcher.</p>
	 *
	 * <p><b>Platform support</b></p>
	 * <ul>
	 *   <li>iOS 13.0 and later: supported</li>
	 *   <li>Android: not supported</li>
	 * </ul>
	 *
	 * <p><b>Status event codes</b> (on <code>StatusEvent.STATUS</code>, property <code>code</code>):</p>
	 * <ul>
	 *   <li><code>APPLE_SIGN_IN_SUCCESS</code> — success; <code>level</code> contains JSON with user data</li>
	 *   <li><code>APPLE_SIGN_IN_ERROR</code> — failure; <code>level</code> contains an error message</li>
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
	public class AppleSignInExtension extends EventDispatcher
	{
		/** @private */
		private static const EXTENSION_ID:String = "com.fluocode.ane.signin.apple";
		/** @private */
		private var _context:ExtensionContext;
		/** @private */
		private var _isAvailable:Boolean = false;
		
		/** @private */
		private static var _instance:AppleSignInExtension;
		
		/**
		 * Returns the singleton instance of the extension.
		 *
		 * @return The shared <code>AppleSignInExtension</code> instance.
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
		 * Initializes Sign in with Apple on the native side (iOS only).
		 *
		 * @return <code>true</code> if initialization succeeded; <code>false</code> if unavailable, not supported, or an error occurred.
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
		 * Starts the Sign in with Apple user interface and flow (iOS only).
		 *
		 * <p>Listen for <code>StatusEvent.STATUS</code> on this instance to receive
		 * <code>APPLE_SIGN_IN_SUCCESS</code> or <code>APPLE_SIGN_IN_ERROR</code> (see class description).</p>
		 *
		 * @return <code>true</code> if the native sign-in request was started; <code>false</code> otherwise.
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
		 * Retrieves Apple user information from the native layer (iOS only).
		 *
		 * @return An object with fields such as user id, email, and full name, or <code>null</code> on failure or unsupported platforms.
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
