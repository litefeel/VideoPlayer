package com.litefeel.videoPlayer.ui 
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	[Event(name = "change", type = "flash.evnets.Event")]
	
	/**
	 * ...
	 * @author lite3
	 */
	public class SeekBar extends SeekBarUI
	{
		
		private var loaded:Number;
		private var total:Number;
		private var _value:Number;
		
		private var draging:Boolean;
		
		private var lockX:Number;
		
		public function SeekBar() 
		{
			thumb.x = 0;
			
			mouseEnabled = false;
			
			buffer.width = track.width;
			buffer.mouseChildren = false;
			buffer.mouseEnabled = false;
			track.buttonMode = true;
			track.mouseChildren = false;
			
			thumb.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
			track.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
		}
		
		
		private function upHandler(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, upHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			moveHandler(null);
			_value = thumb.x / (track.width - thumb.width) * total;
			draging = false;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function downHandler(e:MouseEvent):void 
		{
			draging = true;
			lockX = mouseX - thumb.width / 2;
			thumb.x = lockX
			stage.addEventListener(MouseEvent.MOUSE_UP, upHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
		}
		
		private function moveHandler(e:MouseEvent):void 
		{
			var tx:Number = mouseX;
			var left:Number = thumb.width / 2;
			var right:Number = track.width - left;
			if (tx < left) tx = left;
			else if (tx > right) tx = right;
			thumb.x = tx - left;
		}
		
		public function setValue(loaded:Number, total:Number, value:Number):void
		{
			//trace(loaded, total, value);
			this.total = total;
			this.loaded = loaded;
			this.value = value;
			var loadedRate:Number = total > 0 ? loaded / total : 0;
			buffer.width = thumb.width + loadedRate * (track.width - thumb.width);
		}
		
		public function setEnabled(value:Boolean):void 
		{
			mouseChildren = value;
		}
		
		override public function set width(value:Number):void 
		{
			track.width = value;
			var loadedRate:Number = total > 0 ? loaded / total : 0;
			buffer.width = thumb.width + loadedRate * (value - thumb.width);
			this.value = _value;
		}
		
		public function get value():Number { return _value; }
		
		public function set value(value:Number):void 
		{
			if (value > total) value = total;
			if (value < 0) value = 0;
			
			_value = value;
			if(!draging)thumb.x = (track.width - thumb.width) * (total > 0 ? value / total : 0);
		}
	}
}