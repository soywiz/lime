package lime._backend.html5;


import haxe.Timer;
import js.html.CanvasElement;
import js.html.DivElement;
#if (haxe_ver >= "3.2")
import js.html.Element;
#else
import js.html.HtmlElement;
#end
import js.html.FocusEvent;
import js.html.InputElement;
import js.html.InputEvent;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.Browser;
import lime.app.Application;
import lime.graphics.Image;
import lime.system.Display;
import lime.system.System;
import lime.ui.Window;


class HTML5Window {
	
	
	private static var textInput:InputElement;
	
	public var canvas:CanvasElement;
	public var div:DivElement;
	public var element:#if (haxe_ver >= "3.2") Element #else HtmlElement #end;
	#if stats
	public var stats:Dynamic;
	#end
	
	private var enableTextEvents:Bool;
	private var parent:Window;
	private var setHeight:Int;
	private var setWidth:Int;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
		if (parent.config != null && Reflect.hasField (parent.config, "element")) {
			
			element = parent.config.element;
			
		}
		
	}
	
	
	public function close ():Void {
		
		
		
	}
	
	
	public function create (application:Application):Void {
		
		setWidth = parent.width;
		setHeight = parent.height;
		
		if (Std.is (element, CanvasElement)) {
			
			canvas = cast element;
			
		} else {
			
			#if dom
			div = cast Browser.document.createElement ("div");
			#else
			canvas = cast Browser.document.createElement ("canvas");
			#end
			
		}
		
		if (canvas != null) {
			
			var style = canvas.style;
			style.setProperty ("-webkit-transform", "translateZ(0)", null);
			style.setProperty ("transform", "translateZ(0)", null);
			
		} else if (div != null) {
			
			var style = div.style;
			style.setProperty ("-webkit-transform", "translate3D(0,0,0)", null);
			style.setProperty ("transform", "translate3D(0,0,0)", null);
			//style.setProperty ("-webkit-transform-style", "preserve-3d", null);
			//style.setProperty ("transform-style", "preserve-3d", null);
			style.position = "relative";
			style.overflow = "hidden";
			style.setProperty ("-webkit-user-select", "none", null);
			style.setProperty ("-moz-user-select", "none", null);
			style.setProperty ("-ms-user-select", "none", null);
			style.setProperty ("-o-user-select", "none", null);
			
		}
		
		if (parent.width == 0 && parent.height == 0) {
			
			if (element != null) {
				
				parent.width = element.clientWidth;
				parent.height = element.clientHeight;
				
			} else {
				
				parent.width = Browser.window.innerWidth;
				parent.height = Browser.window.innerHeight;
				
			}
			
			parent.fullscreen = true;
			
		}
		
		if (canvas != null) {
			
			canvas.width = parent.width;
			canvas.height = parent.height;
			
		} else {
			
			div.style.width = parent.width + "px";
			div.style.height = parent.height + "px";
			
		}
		
		handleResize ();
		
		if (element != null) {
			
			if (canvas != null) {
				
				if (element != cast canvas) {
					
					element.appendChild (canvas);
					
				}
				
			} else {
				
				element.appendChild (div);
				
			}
			
			var events = [ "mousedown", "mouseenter", "mouseleave", "mousemove", "mouseup", "wheel" ];
			
			for (event in events) {
				
				element.addEventListener (event, handleMouseEvent, true);
				
			}
			
			// Disable image drag on Firefox
			Browser.document.addEventListener ("dragstart", function (e) {
				if (e.target.nodeName.toLowerCase () == "img") {
					e.preventDefault ();
					return false;
				}
				return true;
			}, false);
			
			element.addEventListener ("touchstart", handleTouchEvent, true);
			element.addEventListener ("touchmove", handleTouchEvent, true);
			element.addEventListener ("touchend", handleTouchEvent, true);
			
		}
		
	}
	
	
	public function getDisplay ():Display {
		
		return System.getDisplay (0);
		
	}
	
	
	public function getEnableTextEvents ():Bool {
		
		return enableTextEvents;
		
	}
	
	
	private function handleFocusEvent (event:FocusEvent):Void {
		
		if (enableTextEvents) {
			
			Timer.delay (function () { textInput.focus (); }, 20);
			
		}
		
	}
	
	
	private function handleInputEvent (event:InputEvent):Void {
		
		if (textInput.value != "") {
			
			parent.onTextInput.dispatch (textInput.value);
			textInput.value = "";
			
		}
		
	}
	
	
	private function handleMouseEvent (event:MouseEvent):Void {
		
		var x = 0.0;
		var y = 0.0;
		
		if (event.type != "wheel") {
			
			if (element != null) {
				
				if (canvas != null) {
					
					var rect = canvas.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (parent.width / rect.width);
					y = (event.clientY - rect.top) * (parent.height / rect.height);
					
				} else if (div != null) {
					
					var rect = div.getBoundingClientRect ();
					//x = (event.clientX - rect.left) * (window.backend.div.style.width / rect.width);
					x = (event.clientX - rect.left);
					//y = (event.clientY - rect.top) * (window.backend.div.style.height / rect.height);
					y = (event.clientY - rect.top);
					
				} else {
					
					var rect = element.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (parent.width / rect.width);
					y = (event.clientY - rect.top) * (parent.height / rect.height);
					
				}
				
			} else {
				
				x = event.clientX;
				y = event.clientY;
				
			}
			
			switch (event.type) {
				
				case "mousedown":
					
					parent.onMouseDown.dispatch (x, y, event.button);
				
				case "mouseenter":
					
					parent.onWindowEnter.dispatch ();
				
				case "mouseleave":
					
					parent.onWindowLeave.dispatch ();
				
				case "mouseup":
					
					parent.onMouseUp.dispatch (x, y, event.button);
				
				case "mousemove":
					
					parent.onMouseMove.dispatch (x, y);
				
				default:
				
			}
			
		} else {
			
			parent.onMouseWheel.dispatch (untyped event.deltaX, - untyped event.deltaY);
			
		}
		
	}
	
	
	private function handleResize ():Void {
		
		var stretch = parent.fullscreen || (setWidth == 0 && setHeight == 0);
		
		if (element != null && (div == null || (div != null && stretch))) {
			
			if (stretch) {
				
				if (parent.width != element.clientWidth || parent.height != element.clientHeight) {
					
					parent.width = element.clientWidth;
					parent.height = element.clientHeight;
					
					if (canvas != null) {
						
						if (element != cast canvas) {
							
							canvas.width = element.clientWidth;
							canvas.height = element.clientHeight;
							
						}
						
					} else {
						
						div.style.width = element.clientWidth + "px";
						div.style.height = element.clientHeight + "px";
						
					}
					
				}
				
			} else {
				
				var scaleX = element.clientWidth / setWidth;
				var scaleY = element.clientHeight / setHeight;
				
				var currentRatio = scaleX / scaleY;
				var targetRatio = Math.min (scaleX, scaleY);
				
				if (canvas != null) {
					
					if (element != cast canvas) {
						
						canvas.style.width = setWidth * targetRatio + "px";
						canvas.style.height = setHeight * targetRatio + "px";
						canvas.style.marginLeft = ((element.clientWidth - (setWidth * targetRatio)) / 2) + "px";
						canvas.style.marginTop = ((element.clientHeight - (setHeight * targetRatio)) / 2) + "px";
						
					}
					
				} else {
					
					div.style.width = setWidth * targetRatio + "px";
					div.style.height = setHeight * targetRatio + "px";
					div.style.marginLeft = ((element.clientWidth - (setWidth * targetRatio)) / 2) + "px";
					div.style.marginTop = ((element.clientHeight - (setHeight * targetRatio)) / 2) + "px";
					
				}
				
			}
			
		}
		
	}
	
	
	private function handleTouchEvent (event:TouchEvent):Void {
		
		event.preventDefault ();
		
		var touch = event.changedTouches[0];
		var id = touch.identifier;
		var x = 0.0;
		var y = 0.0;
		
		if (element != null) {
			
			if (canvas != null) {
				
				var rect = canvas.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (parent.width / rect.width);
				y = (touch.clientY - rect.top) * (parent.height / rect.height);
				
			} else if (div != null) {
				
				var rect = div.getBoundingClientRect ();
				//eventInfo.x = (event.clientX - rect.left) * (window.div.style.width / rect.width);
				x = (touch.clientX - rect.left);
				//eventInfo.y = (event.clientY - rect.top) * (window.div.style.height / rect.height);
				y = (touch.clientY - rect.top);
				
			} else {
				
				var rect = element.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (parent.width / rect.width);
				y = (touch.clientY - rect.top) * (parent.height / rect.height);
				
			}
			
		} else {
			
			x = touch.clientX;
			y = touch.clientY;
			
		}
		
		switch (event.type) {
			
			case "touchstart":
				
				parent.onTouchStart.dispatch (x / setWidth, y / setHeight, id);
				parent.onMouseDown.dispatch (x, y, 0);
			
			case "touchmove":
				
				parent.onTouchMove.dispatch (x / setWidth, y / setHeight, id);
				parent.onMouseMove.dispatch (x, y);
			
			case "touchend":
				
				parent.onTouchEnd.dispatch (x / setWidth, y / setHeight, id);
				parent.onMouseUp.dispatch (x, y, 0);
			
			default:
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		
		
	}
	
	
	public function setEnableTextEvents (value:Bool):Bool {
		
		if (value) {
			
			if (textInput == null) {
				
				textInput = cast Browser.document.createElement ('input');
				textInput.type = 'text';
				textInput.style.position = 'absolute';
				textInput.style.opacity = "0";
				textInput.style.color = "transparent";
				textInput.value = "";
				
				untyped textInput.autocapitalize = "off";
				untyped textInput.autocorrect = "off";
				textInput.autocomplete = "off";
				
				// TODO: Position for mobile browsers better
				
				textInput.style.left = "0px";
				textInput.style.top = "50%";
				
				if (~/(iPad|iPhone|iPod).*OS 8_/gi.match (Browser.window.navigator.userAgent)) {
					
					textInput.style.fontSize = "0px";
					textInput.style.width = '0px';
					textInput.style.height = '0px';
					
				} else {
					
					textInput.style.width = '1px';
					textInput.style.height = '1px';
					
				}
				
				untyped (textInput.style).pointerEvents = 'none';
				textInput.style.zIndex = "-10000000";
				
				Browser.document.body.appendChild (textInput);
				
			}
			
			if (!enableTextEvents) {
				
				textInput.addEventListener ('input', handleInputEvent, true);
				textInput.addEventListener ('blur', handleFocusEvent, true);
				
			}
			
			textInput.focus ();
			
		} else {
			
			if (textInput != null) {
				
				textInput.removeEventListener ('input', handleInputEvent, true);
				textInput.removeEventListener ('blur', handleFocusEvent, true);
				
				textInput.blur ();
				
			}
			
		}
		
		return enableTextEvents = value;
		
	}
	
	
	public function setFullscreen (value:Bool):Bool {
		
		return false;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		
		
	}
	
	
	public function setMinimized (value:Bool):Bool {
		
		return false;
		
	}
	
	
	public function setTitle (value:String):String {
		
		return value;
		
	}
	
	
}