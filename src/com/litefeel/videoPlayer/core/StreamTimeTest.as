package com.litefeel.videoPlayer.core 
{
	import com.litefeel.videoPlayer.core.VideoStream;
	import com.litefeel.videoPlayer.events.VideoStreamEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	
	[Event(name = "complete", type = "flash.events.Event")]
	[Event(name = "streamNotFound", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	/**
	 * ...
	 * @author lite3
	 */
	public class StreamTimeTest extends EventDispatcher
	{
		
		public var videoWidth:int;
		public var videoHeight:int;
		
		private var _totalTime:Number;
		// 每一个元素都表示一个stream的总时间
		private var _timeList:Vector.<Number>;
		private var streamList:Vector.<VideoStream>;
		
		public function StreamTimeTest(urlList:Vector.<String>) 
		{
			var len:int = urlList.length;
			trace("len = ", len);
			_timeList = new Vector.<Number>(len);
			streamList = new Vector.<VideoStream>(len);
			for (var i:int = 0; i < len; i++)
			{
				_timeList[i] = 0;
				streamList[i] = new VideoStream(urlList[i]);
				streamList[i].addEventListener(VideoStreamEvent.INIT, streamInitHandler);
				streamList[i].addEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamNotFoundHandler);
			}
		}
		
		public function dispose():void
		{
			var len:int = streamList.length;
			for (var i:int = 0; i < len; i++)
			{
				streamList[i].stop();
				streamList[i].removeEventListener(VideoStreamEvent.INIT, streamInitHandler);
				streamList[i].removeEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamNotFoundHandler);
			}
			streamList.length = 0;
			
		}
		
		private function streamNotFoundHandler(e:VideoStreamEvent):void 
		{
			dispose();
			dispatchEvent(e.clone());
		}
		
		private function streamInitHandler(e:VideoStreamEvent):void 
		{
			_totalTime = 0;
			var len:int = streamList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (streamList[i].initialized)
				{
					_totalTime += streamList[i].totalTime;
					_timeList[i] = streamList[i].totalTime;
				}
				else return;
			}
			
			videoWidth = streamList[0].videoWidth;
			videoHeight = streamList[0].videoHeight;
			dispose();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get totalTime():Number 
		{
			return _totalTime;
		}
		
		public function get timeList():Vector.<Number> 
		{
			return _timeList;
		}
		
		
		
	}

}