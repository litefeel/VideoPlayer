package com.litefeel.videoPlayer.core 
{
	import com.litefeel.debug.Debug;
	import com.litefeel.videoPlayer.events.VideoStreamEvent;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.getTimer;
	
	
	[Event(name = "bufferBegin", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "bufferEnd", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	[Event(name = "init", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "loadComplete", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "playComplete", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	[Event(name = "streamNotFound", type = "com.litefeel.videoPlayer.events.VideoStreamEvent")]
	
	
	/**
	 * ...
	 * @author lite3
	 */
	public class VideoStream extends EventDispatcher
	{
		private var startTime:Number = 0;
		private var _totalTime:Number = 0;
		private var _videoTotalTime:Number = 0;
		private var _videoWidth:Number = 0;
		private var _videoHeight:Number = 0;
		
		private var toTime:Number = -1;
		private var _initialized:Boolean = false;
		private var _loadComplete:Boolean = false;
		
		private var autoPlay:Boolean = false;
		private var isStarted:Boolean = false;
		
		private var url:String = null;
		
		private var nc:NetConnection;
		private var ns:NetStream;
		
		public function VideoStream(url:String, autoPlay:Boolean = false, totalTime:Number = -1) 
		{
			_totalTime = totalTime;
			this.url = url;
			this.autoPlay = autoPlay;
			nc = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.inBufferSeek = true;
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.client = { onMetaData:onMetaDataHandler };
			ns.play(url);
			//trace("ns.bufferTime = ", ns.bufferTime);
		}
		
		private function netStatusHandler(e:NetStatusEvent):void 
		{
			Debug.showObjectProps(e.info, "netStatusHandler");
			trace(ns.time);
			trace("ns.bytesLoaded, ns.bytesTotal: ", ns.bytesLoaded, ns.bytesTotal)
			
			checkLoadComplete();
			var t:Number = getTimer() / 1000;
			trace("time:", t.toFixed(3));
			switch(e.info.code)
			{
				case "NetStream.Buffer.Flush" :
				break;
				
				case "NetStream.Buffer.Empty" :
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_BEGIN));
				break;
				
				case "NetStream.Buffer.Full" :
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_END));
				break;
				
				case "NetStream.Play.Stop" :
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.PLAY_COMPLETE));
				break;
				
				case "NetStream.Play.Start" :
				isStarted = true;
				if (!autoPlay) ns.pause();
				break;
				
				case "NetStream.Play.StreamNotFound" :
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.STREAM_NOT_FOUND));
				break;
			}
			
		}
		
		private function checkLoadComplete():void 
		{
			if (!_loadComplete && _initialized && ns != null && ns.bytesLoaded == ns.bytesTotal)
			{
				_loadComplete = true;
				dispatchEvent(new VideoStreamEvent(VideoStreamEvent.LOAD_COMPLETE));
			}
		}
		
		/**
		 * 开始播放
		 * @param	start 开始的时间 单位:ms
		 */
		public function play(playTime:Number):void
		{
			if (isNaN(startTime) || startTime < 0) return;
			autoPlay = true;
			if (totalTime > 0 || _initialized)
			{
				if (startTime > totalTime) return;
				
				var seekTime:Number = playTime - startTime;
				var hasTime:Number = ns.bytesTotal > 0 ? ns.bytesLoaded / ns.bytesTotal * _videoTotalTime : 0;
				
				// 播放点已经在缓存里了
				if (seekTime >= 0 && seekTime <= hasTime + 10)
				{
					
					trace("this is resume", ns.time);
					ns.seek(seekTime);
					ns.resume();
				}
				// 播放未知的位置
				else
				{
					this.startTime = playTime;
					_initialized = false;
					_loadComplete = false;
					isStarted = false;
					dispatchEvent(new VideoStreamEvent(VideoStreamEvent.BUFFER_BEGIN));
					ns.play(url + "?start=" + playTime);
					trace("play url ", url + "?start=" + playTime);
				}
			}
		}
		
		public function pause():void
		{
			if (isStarted) ns.pause();
			else autoPlay = false;
			//ns.pause();
		}
		
		public function resume():void
		{
			//if (!_initialized) return;
			
			if (isStarted) ns.resume();
			else autoPlay = true;
			//autoPlay = true;
			//ns.resume();
		}
		
		public function stop():void
		{
			ns.close();
			nc.close();
			ns = null;
			nc = null;
		}
		
		public function getNetStream():NetStream 
		{
			return ns;
		}
		
		public function get bufferTime():Number { return ns.bufferTime; }
		public function set bufferTime(value:Number):void
		{
			if (ns.bufferTime != value) ns.bufferTime = value;
		}
		
		public function get bytesLoaded():int { return ns.bytesLoaded; }
		public function get bytesTotal():int { return ns.bytesTotal; }
		
		public function get bufferLength():Number { return ns.bufferLength; }
		
		public function get videoTotalTime():Number { return _videoTotalTime; }
		
		public function get loadedTime():Number { return initialized ? startTime + ns.bytesLoaded / ns.bytesTotal * _totalTime : startTime; }
		public function get totalTime():Number { return _totalTime; }
		
		public function get videoWidth():Number { return _videoWidth; }
		
		public function get videoHeight():Number { return _videoHeight; }
		
		public function get curTime():Number { return startTime + ns.time; }
		
		public function get initialized():Boolean { return _initialized; }
		
		public function get loadComplete():Boolean { return _loadComplete; }
		
		
		private function onMetaDataHandler(o:Object):void
		{
			Debug.showObjectProps(o, "onMetaDataHandler:" + url);
			_videoTotalTime = o.duration;
			_videoWidth = o.width;
			_videoHeight = o.height;
			
			if ( -1 == totalTime)
			{
				_totalTime = _videoTotalTime;
			}
			
			startTime = _totalTime - _videoTotalTime;
			_initialized = true;
			if (!autoPlay)
			{
				//ns.pause();
				//ns.step(0);
			}else
			{
				//ns.resume();
				//ns.seek(ns.time);
			}
			
			dispatchEvent(new VideoStreamEvent(VideoStreamEvent.INIT));
			
			// 检测加载完成
			checkLoadComplete();
		}
	}

}