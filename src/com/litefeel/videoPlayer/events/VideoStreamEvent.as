package com.litefeel.videoPlayer.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author lite3
	 */
	public class VideoStreamEvent extends Event 
	{
		
		static public const INIT:String = "init";
		
		static public const LOAD_COMPLETE:String = "loadComplete";
		
		static public const PLAY_COMPLETE:String = "playComplete";
		
		static public const STREAM_CHANGE:String = "streamChange";
		
		static public const BUFFER_BEGIN:String = "bufferBegin";
		
		static public const BUFFER_END:String = "bufferEnd";
		
		static public const STREAM_NOT_FOUND:String = "streamNotFound";
		
		
		public function VideoStreamEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
		} 
		
		public override function clone():Event 
		{ 
			return new VideoStreamEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("VideoStreamEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}