package com.litefeel.videoPlayer.core 
{
	import com.litefeel.videoPlayer.core.VideoStream;
	import com.litefeel.videoPlayer.events.VideoStreamEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.SoundTransform;
	
	/**
	 * 初始化完成
	 */
	[Event(name = "init", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	/**
	 * 片段切换后触发
	 */
	[Event(name = "streamChange", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	/**
	 * 播放完毕
	 */
	[Event(name = "playComplete", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	[Event(name = "bufferBegin", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "bufferEnd", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "ioError", type = "flash.events.IOErrorEvent")]
	
	/**
	 * 片段管理类
	 * @author lite3
	 */
	public class StreamManager extends EventDispatcher
	{
		
		static public var videoWidth:int = 240;
		static public var videoHeight:int = 160;
		
		
		private var _curTime:Number = 0;
		private var _totalTime:Number;
		
		private var timeTest:StreamTimeTest;
		private var curStreamIdx:int = -1;
		private var curStreamBaseTime:Number = 0;
		
		private var urlList:Vector.<String>;
		// 每一个元素都表示一个stream的总时间
		private var timeList:Vector.<Number>;
		private var streamList:Vector.<VideoStream>;
		
		private var soundTransform:SoundTransform;
		private var _initialized:Boolean;
		private var _isPlaying:Boolean = false;
		private var _isStreamComplete:Boolean = false;
		private var virtualClips:Boolean = false;
		
		
		public function getCurStream():VideoStream
		{
			if (streamList.length > 0 && curStreamIdx >= 0)
			{
				return streamList[curStreamIdx];
			}
			return null;
		}
		
		public function StreamManager() 
		{
			curStreamIdx = -1;
			timeList = new Vector.<Number>();
			streamList = new Vector.<VideoStream>();
			
			soundTransform = new SoundTransform(0.5);
		}
		
		public function initList(list:Vector.<String>, virtualClips:Boolean):void
		{
			this.virtualClips = virtualClips;
			urlList = list.concat();
			timeTest = new StreamTimeTest(list.concat());
			timeTest.addEventListener(Event.COMPLETE, timeTestCompleteHandler);
			timeTest.addEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamNotFoundHandler);
			
		}
		
		private function timeTestCompleteHandler(e:Event):void 
		{
			timeList = timeTest.timeList.concat();
			_totalTime = timeTest.totalTime;
			videoWidth = timeTest.videoWidth;
			videoHeight = timeTest.videoHeight;
			
			if (streamList)
			{
				for (var i:int = streamList.length - 1; i >= 0; i--)
				{
					if (!streamList[i]) continue;
					streamList[i].removeEventListener(VideoStreamEvent.LOAD_COMPLETE, streamHandler);
					streamList[i].removeEventListener(VideoStreamEvent.PLAY_COMPLETE, streamHandler);
					streamList[i].removeEventListener(VideoStreamEvent.BUFFER_BEGIN, streamHandler);
					streamList[i].removeEventListener(VideoStreamEvent.BUFFER_END, streamHandler);
					streamList[i] = null;
				}
			}
			trace("stream time test complete");
			_initialized = true;
			
			streamList = new Vector.<VideoStream>(urlList.length);
			play(0);
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.INIT));
		}
		
		public function play(playTime:Number):void 
		{
			if (!_initialized) return;
			if (playTime < 0) playTime = 0;
			else if (playTime > totalTime) playTime = totalTime;
			
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_END));
			
			pause();
			computeCurStream(playTime);
			streamList[curStreamIdx].play(playTime - curStreamBaseTime);
			streamList[curStreamIdx].getNetStream().soundTransform = soundTransform;
			
			_isPlaying = true;
			_isStreamComplete = false;
			
			if (getCurStream().loadComplete)
			{
				getCurStream().dispatchEvent(new VideoStreamEvent(VideoStreamEvent.LOAD_COMPLETE));
			}
		}
		
		// 计算playTime所在的影片及开始时间
		private function computeCurStream(playTime:Number):void 
		{
			var time:Number = 0;
			for (var i:int = 0; i < timeList.length; i++)
			{
				time += timeList[i];
				if (playTime < time) break;
			}
			
			// 播放到最后
			if (i == timeList.length)
			{
				curStreamIdx = timeList.length - 1;
				curStreamBaseTime = timeList[timeList.length - 1];
			}
			// 播放其他地方
			else
			{
				curStreamBaseTime = time-timeList[i];
				curStreamIdx = i;
			}
			
			initStream(curStreamIdx);
		}
		
		public function pause():void 
		{
			var s:VideoStream = getCurStream();
			if (s)
			{
				_isPlaying = false;
				s.pause();
				//if (s.initialized) s.pause();
				//else s.autoPlay = false;
			}
			trace("this is pause", s);
		}
		
		public function resume():void
		{
			var s:VideoStream = getCurStream();
			if (s)
			{
				_isPlaying = true;
				s.resume();
				//if (s.initialized) s.resume();
				//else s.autoPlay = true;
			}
		}
		
		public function clear():void 
		{
			_isPlaying = false;
			_initialized = false;
			_isStreamComplete = false;
			if (timeTest)
			{
				timeTest.dispose();
				timeTest.removeEventListener(Event.COMPLETE, timeTestCompleteHandler);
				timeTest.removeEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamNotFoundHandler);
			}
			var len:int = streamList ? streamList.length : 0;
			for (var i:int = 0; i < len; i++)
			{
				var s:VideoStream = streamList[i];
				if (!s) continue;
				s.stop();
				s.removeEventListener(VideoStreamEvent.LOAD_COMPLETE, streamHandler);
				s.removeEventListener(VideoStreamEvent.PLAY_COMPLETE, streamHandler);
				s.removeEventListener(VideoStreamEvent.BUFFER_BEGIN, streamHandler);
				s.removeEventListener(VideoStreamEvent.BUFFER_END, streamHandler);
				streamList[i] = null;
			}
		}
		
		private function streamHandler(e:VideoStreamEvent):void 
		{
			var stream:VideoStream = e.currentTarget as VideoStream;
			switch(e.type)
			{
				case VideoStreamEvent.LOAD_COMPLETE :
				for (var i:int = curStreamIdx + 1; i < streamList.length && i <= curStreamIdx+1; i++)
				{
					if (streamList[i] && !streamList[i].loadComplete) break;
					if (!streamList[i]) initStream(i);
				}
				break;
				
				case VideoStreamEvent.PLAY_COMPLETE :
				// 无效的stream
				var idx:int = streamList.indexOf(stream);
				if (idx != curStreamIdx) return;
				
				// 转到下一个stream
				nextStream();
				break;
				
				case VideoStreamEvent.BUFFER_BEGIN :
				case VideoStreamEvent.BUFFER_END :
				case VideoStreamEvent.STREAM_NOT_FOUND :
				if (streamList.indexOf(stream) == curStreamIdx) dispatchEvent(e.clone());
				break;
			}
		}
		
		private function nextStream():void 
		{
			var s:VideoStream = getCurStream();
			if (s) s.pause();
			
			// 播放完毕
			if (curStreamIdx == urlList.length - 1) 
			{
				trace("播放完毕");
				_isStreamComplete = true;
				curStreamIdx = 0;
				curStreamBaseTime = 0;
				initStream(curStreamIdx);
				getCurStream().play(0);
				getCurStream().pause();
				_isPlaying = false;
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.PLAY_COMPLETE));
				return;
			}
			curStreamIdx++;
			curStreamBaseTime = 0;
			for (var i:int = 0; i < curStreamIdx; i++)
			{
				curStreamBaseTime += timeList[i];
			}
			
			initStream(curStreamIdx);
			getCurStream().play(0);
			getCurStream().getNetStream().soundTransform = soundTransform;
			
			if (getCurStream().loadComplete)
			{
				getCurStream().dispatchEvent(new VideoStreamEvent(VideoStreamEvent.LOAD_COMPLETE));
			}
			
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.STREAM_CHANGE)); 
		}
		
		private function initStream(idx:int = -1):void 
		{
			if (!streamList[idx])
			{
				streamList[idx] = new VideoStream(urlList[idx], false, timeList[idx], virtualClips);
				streamList[idx].addEventListener(VideoStreamEvent.LOAD_COMPLETE, streamHandler);
				streamList[idx].addEventListener(VideoStreamEvent.PLAY_COMPLETE, streamHandler);
				streamList[idx].addEventListener(VideoStreamEvent.BUFFER_BEGIN, streamHandler);
				streamList[idx].addEventListener(VideoStreamEvent.BUFFER_END, streamHandler);
				streamList[idx].addEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamHandler);
			}
		}
		
		
		private function streamNotFoundHandler(e:VideoStreamEvent):void 
		{
			dispatchEvent(e.clone());
		}
		
		private function initHandler(e:VideoStreamEvent):void 
		{
			var time:Number = 0;
			var len:int = streamList.length;
			for (var i:int = 0; i < len; i++)
			{
				if (!streamList[i].initialized) return;
				
				time += streamList[i].totalTime;
				timeList[i] = time;
			}
		}
		
		public function get volume():int { return soundTransform.volume * 100; }
		public function set volume(value:int):void
		{
			soundTransform.volume = value / 100;
			var s:VideoStream = getCurStream();
			if (s) s.getNetStream().soundTransform = soundTransform;
		}
		
		public function get curTime():Number { return getCurStream() ? curStreamBaseTime + getCurStream().curTime : 0; }
		public function get totalTime():Number { return _totalTime; }
		
		public function get loadedTime():Number
		{
			if (!getCurStream()) return 0;
			
			var time:Number = curStreamBaseTime;
			for (var i:int = curStreamIdx; i < urlList.length; i++)
			{
				var s:VideoStream = streamList[i];
				if (!s) break;
				time += streamList[i].loadedTime;
				if (!streamList[i].loadComplete) break;
			}
			return time;
		}
		
		public function get initialized():Boolean { return _initialized; }
		public function get isPlaying():Boolean { return _isPlaying; }
		public function get isStreamComplete():Boolean { return _isStreamComplete; }
		
	}

}