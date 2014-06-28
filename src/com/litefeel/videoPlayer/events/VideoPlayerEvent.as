package com.litefeel.videoPlayer.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author lite3
	 */
	public class VideoPlayerEvent extends Event 
	{
		
		static public const PLAY_NEXT:String = "playNext";
		
		static public const PLAY_PREV:String = "playPrev";
		
		static public const PLAY:String = "play";
		
		static public const PAUSE:String = "pause";
		
		static public const RESUME:String = "resume";
		
		static public const CHANGE_VOLUME:String = "changeVolume";
		
		public var volume:int;
		public var playTime:Number;
		
		public function VideoPlayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, playTime:Number = -1, volume:int = -1) 
		{ 
			super(type, bubbles, cancelable);
			this.playTime = playTime;
			this.volume = volume;
		} 
		
		public override function clone():Event 
		{ 
			return new VideoPlayerEvent(type, bubbles, cancelable, playTime, volume);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("VideoPlayerEvent", "type", "bubbles", "cancelable", "eventPhase", "playTime", "volume"); 
		}
		
	}
	
}