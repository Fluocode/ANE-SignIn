package
{
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import com.fluocode.ane.signin.google.GoogleSignInExtension;
	import com.fluocode.ane.signin.apple.AppleSignInExtension;
	
	/**
	 * AIR test app (iOS) with 2 buttons:
	 * - Google sign-in via ANE
	 * - Apple sign-in via ANE
	 *
	 * Shows all StatusEvent.STATUS events on screen.
	 */
	public class Main extends Sprite
	{
		private var log:TextField;
		
		private var google:GoogleSignInExtension;
		private var apple:AppleSignInExtension;

		// iOS only: GoogleSignInExtension native implementation requires an iOS OAuth Client ID.
		// It usually looks like: 1234567890-abc123def456.apps.googleusercontent.com
		// Paste it here (DO NOT paste an API key that starts with "AIza...").
		private static const GOOGLE_IOS_CLIENT_ID:String = "1047023546747-pcubsnbc83pueirek46p4r5pe9jqvae7.apps.googleusercontent.com";
		
		public function Main()
		{
			stage ? initUI() : addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:flash.events.Event):void
		{
			removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
			initUI();
		}
		
		private function initUI():void
		{
			// Log area
			log = new TextField();
			log.x = 20;
			log.y = 170;
			log.width = stage.stageWidth - 40;
			log.height = stage.stageHeight - 190;
			log.multiline = true;
			log.wordWrap = true;
			log.selectable = false;
			log.defaultTextFormat = new TextFormat("_sans", 12, 0x333333);
			addChild(log);
			
			var googleBtn:Sprite = makeButton("Sign in Google", 0x2D7EF7);
			googleBtn.x = 20;
			googleBtn.y = 80;
			googleBtn.addEventListener(MouseEvent.CLICK, onGoogleClick);
			addChild(googleBtn);
			
			var appleBtn:Sprite = makeButton("Sign in Apple", 0x111111);
			appleBtn.x = 20;
			appleBtn.y = 130;
			appleBtn.addEventListener(MouseEvent.CLICK, onAppleClick);
			addChild(appleBtn);
			
			google = GoogleSignInExtension.getInstance();
			apple = AppleSignInExtension.getInstance();
			
			// Listen for native extension events BEFORE clicking buttons
			google.addEventListener(StatusEvent.STATUS, onGoogleStatus);
			apple.addEventListener(StatusEvent.STATUS, onAppleStatus);
			
			append("Google available: " + google.isAvailable);
			append("Apple available: " + apple.isAvailable);
			append("Tap a button to start sign-in.");
		}
		
		private function makeButton(label:String, color:uint):Sprite
		{
			var w:Number = 260;
			var h:Number = 40;
			var radius:Number = 10;
			
			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;
			g.beginFill(color);
			g.drawRoundRect(0, 0, w, h, radius);
			g.endFill();
			
			var tf:TextField = new TextField();
			tf.mouseEnabled = false;
			tf.selectable = false;
			tf.defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFF, true);
			tf.text = label;
			tf.width = w;
			tf.height = h;
			tf.y = 8;
			s.addChild(tf);
			
			return s;
		}
		
		private function onGoogleClick(e:MouseEvent):void
		{
			append("[GOOGLE] Button clicked");
			if (!google.isAvailable)
			{
				append("[GOOGLE] Not available. Check that com.fluocode.ane.signin.google is declared in app.xml and packaged in ANE.");
				return;
			}
			
			// Required on iOS (no-op on Android)
			var clientIdIsNull:Boolean = (GOOGLE_IOS_CLIENT_ID == null);
			var clientIdLen:int = clientIdIsNull ? 0 : GOOGLE_IOS_CLIENT_ID.length;
			var looksLikeApiKey:Boolean = (!clientIdIsNull && clientIdLen >= 4 && GOOGLE_IOS_CLIENT_ID.indexOf("AIza") == 0);
			
			append("[GOOGLE] clientId len=" + clientIdLen + " isNull=" + clientIdIsNull + " looksLikeApiKey=" + looksLikeApiKey);
			
			if (clientIdIsNull || clientIdLen == 0)
			{
				append("[GOOGLE] Missing GOOGLE_IOS_CLIENT_ID. Paste your iOS OAuth Client ID (ends with .apps.googleusercontent.com) and rebuild.");
				return;
			}
			
			if (looksLikeApiKey)
			{
				append("[GOOGLE] This looks like an API key (AIza...). Paste the OAuth Client ID for iOS instead (123...apps.googleusercontent.com) and rebuild.");
				return;
			}
			
			var initOk:Boolean = google.initializeGoogleSignIn(GOOGLE_IOS_CLIENT_ID);
			append("[GOOGLE] initializeGoogleSignIn => " + initOk);
			var startOk:Boolean = google.signInWithGoogle();
			append("[GOOGLE] signInWithGoogle => " + startOk);
		}
		
		private function onAppleClick(e:MouseEvent):void
		{
			append("[APPLE] Button clicked");
			if (!apple.isAvailable)
			{
				append("[APPLE] Not available. Check that com.fluocode.ane.signin.apple is declared in app.xml and packaged in ANE.");
				return;
			}
			
			var initOk:Boolean = apple.initializeAppleSignIn();
			append("[APPLE] initializeAppleSignIn => " + initOk);
			var startOk:Boolean = apple.signInWithApple();
			append("[APPLE] signInWithApple => " + startOk);
		}
		
		private function onGoogleStatus(event:StatusEvent):void
		{
			append("[GOOGLE] " + event.code + " -> " + String(event.level));
		}
		
		private function onAppleStatus(event:StatusEvent):void
		{
			append("[APPLE] " + event.code + " -> " + String(event.level));
		}
		
		private function append(msg:String):void
		{
			trace(msg);
			if (!log) return;
			log.appendText(msg + "\n");
		}
	}
}

