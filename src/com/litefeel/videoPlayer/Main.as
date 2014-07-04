package com.litefeel.videoPlayer
{
	import com.litefeel.debug.Debug;
	import com.litefeel.ui.MyContextMenu;
	import com.litefeel.utils.StageUtil;
	import com.litefeel.videoPlayer.core.Config;
	import com.litefeel.videoPlayer.core.StreamManager;
	import com.litefeel.videoPlayer.core.VideoStream;
	import com.litefeel.videoPlayer.events.VideoPlayerEvent;
	import com.litefeel.videoPlayer.events.VideoStreamEvent;
	import com.litefeel.videoPlayer.ui.AdPanel;
	import com.litefeel.videoPlayer.ui.AdType;
	import com.litefeel.videoPlayer.ui.ControlBar;
	import com.litefeel.videoPlayer.ui.Loading;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.Video;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author lite3
	 */
	public class Main extends Sprite 
	{
		private const configURL:String = "config.xml";
		
		private var config:Config;
		
		private var streamManager:StreamManager;
		
		private var vs:VideoStream;
		private var controlBar:ControlBar;
		private var adPanel:AdPanel;
		private var loading:Loading;
		
		private var video:Video;
		
		private var timer:Timer;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			StageUtil.setNoScaleAndTopLeft(stage);
			contextMenu = MyContextMenu.getMyContextNenu();
			initUI();
			
			loadConfig(null);
			
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler(null);
		}
		
		public function loadConfig(key:String):void
		{
			if (!key) key = configURL;
			video.visible = false;
			controlBar.setEnabled(false);
			controlBar.setTime(0, 0, 0);
			adPanel.clear();
			if (streamManager) streamManager.clear();
			if (timer) timer.stop();
			if (config)
			{
				config.removeEventListener(Event.COMPLETE, configHandler);
				config.removeEventListener(IOErrorEvent.IO_ERROR, configHandler);
			}
			
			showLoading();
			config = new Config();
			config.addEventListener(Event.COMPLETE, configHandler);
			config.addEventListener(IOErrorEvent.IO_ERROR, configHandler);
			config.loadConfig(key);
		}
		
		private function showLoading():void 
		{
			loading.visible = true;
			loading.play();
		}
		
		private function hideLoading():void
		{
			loading.visible = false;
			loading.stop();
		}
		
		private function configHandler(e:Event):void 
		{
			if (Event.COMPLETE == e.type)
			{
				Debug.showObjectProps(config.configData, "configData");
				
				if (config.configData.startAd)
				{
					adPanel.visible = true;
					adPanel.showAd(config.configData.startAd, AdType.BEGIN, config.configData.startAdTime);
				}
				
				streamManager = new StreamManager();
				streamManager.initList(config.configData.moveList, config.configData.virtualClips);
				streamManager.addEventListener(VideoStreamEvent.INIT, streamManagerHandler);
				streamManager.addEventListener(VideoStreamEvent.BUFFER_BEGIN, streamManagerHandler);
				streamManager.addEventListener(VideoStreamEvent.BUFFER_END, streamManagerHandler);
				streamManager.addEventListener(VideoStreamEvent.STREAM_CHANGE, streamManagerHandler);
				streamManager.addEventListener(VideoStreamEvent.PLAY_COMPLETE, streamManagerHandler);
				streamManager.addEventListener(VideoStreamEvent.STREAM_NOT_FOUND, streamManagerHandler);
				
				if(!timer) timer = new Timer(200);
				timer.addEventListener(TimerEvent.TIMER, handler);
				timer.start();
				
				controlBar.setPrevNext(Boolean(config.configData.prevConfig), Boolean(config.configData.nextConfig));
			}else
			{
				trace("load config error");
			}
		}
		
		private function streamManagerHandler(e:Event):void 
		{
			switch(e.type)
			{
				case VideoStreamEvent.INIT :
				video.width = StreamManager.videoWidth;
				video.height = StreamManager.videoHeight;
				resizeHandler(null);
				if (adPanel.visible)
				{
					streamManager.pause();
				}else
				{
					controlBar.setEnabled(true);
				}
				video.attachNetStream(streamManager.getCurStream().getNetStream());
				break;
				
				case VideoStreamEvent.PLAY_COMPLETE :
				// 连续剧
				if (config.configData.nextConfig)
				{
					loadConfig(config.configData.nextConfig);
				}else
				{
					controlBar.setPlaying(false);
					controlBar.setTime(0, streamManager.totalTime, streamManager.loadedTime);
					if (config.configData.endAdTime)
					{
						adPanel.showAd(config.configData.endAd, AdType.END, config.configData.endAdTime);
						controlBar.setEnabled(false);
					}
				}
				//video.attachNetStream(streamManager.getCurStream().getNetStream());
				break;
				
				case VideoStreamEvent.STREAM_CHANGE :
				video.attachNetStream(streamManager.getCurStream().getNetStream());
				break;
				
				case VideoStreamEvent.BUFFER_BEGIN :
				if (!loading.visible)
				{
					loading.play();
					loading.visible = true;
				}
				break;
				
				case VideoStreamEvent.BUFFER_END :
				loading.stop();
				if (loading.visible)
				{
					loading.stop();
					loading.visible = false;
				}
				break;
				
				case VideoStreamEvent.STREAM_NOT_FOUND :
				break;
			}
		}
		
		private function initUI():void 
		{
			adPanel = new AdPanel();
			adPanel.addEventListener(Event.COMPLETE, adPanelCompleteHandler);
			video = new Video();
			video.visible = false;
			loading = new Loading();
			loading.stop();
			loading.visible = false;
			
			controlBar = new ControlBar();
			controlBar.addEventListener(VideoPlayerEvent.RESUME, controlBarHandler);
			controlBar.addEventListener(VideoPlayerEvent.PAUSE, controlBarHandler);
			controlBar.addEventListener(VideoPlayerEvent.PLAY, controlBarHandler);
			controlBar.addEventListener(VideoPlayerEvent.PLAY_PREV, controlBarHandler);
			controlBar.addEventListener(VideoPlayerEvent.PLAY_NEXT, controlBarHandler);
			controlBar.addEventListener(VideoPlayerEvent.CHANGE_VOLUME, controlBarHandler);
			
			addChild(video);
			addChild(controlBar);
			addChild(loading);
			addChild(adPanel);
		}
		
		private function controlBarHandler(e:VideoPlayerEvent):void 
		{
			trace(e);
			switch(e.type)
			{
				case VideoPlayerEvent.PLAY :
				streamManager.play(e.playTime);
				controlBar.setPlaying(streamManager.isPlaying);
				video.attachNetStream(streamManager.getCurStream().getNetStream());
				adPanel.clear();
				break;
				
				case VideoPlayerEvent.PAUSE :
				streamManager.pause();
				controlBar.setPlaying(streamManager.isPlaying);
				if (!streamManager.isPlaying && config.configData.midAd)
				{
					adPanel.showAd(config.configData.midAd, AdType.MIDDLE);
				}
				break;
				
				case VideoPlayerEvent.RESUME :
				streamManager.resume();
				controlBar.setPlaying(streamManager.isPlaying);
				if(streamManager.isPlaying) adPanel.clear();
				break;
				
				case VideoPlayerEvent.CHANGE_VOLUME :
				streamManager.volume = e.volume;
				break;
				
				case VideoPlayerEvent.PLAY_PREV :
				if (!config.configData.prevConfig) break;
				loadConfig(config.configData.prevConfig);
				break;
				case VideoPlayerEvent.PLAY_NEXT :
				if (!config.configData.nextConfig) break;
				loadConfig(config.configData.nextConfig);
				break;
			}
		}
		
		private function adPanelCompleteHandler(e:Event):void 
		{
			adPanel.visible = false;
			video.visible = true;
			resizeHandler(null);
			
			trace("adPanelCompleterHandler", streamManager.initialized, streamManager.isPlaying, streamManager.isStreamComplete);
			
			switch(adPanel.type)
			{
				case AdType.BEGIN :
				streamManager.resume();
				if (streamManager.initialized) controlBar.setEnabled(true);
				break;
				
				case AdType.END :
				controlBar.setEnabled(true);
				controlBar.setPrevNext(Boolean(config.configData.prevConfig), Boolean(config.configData.nextConfig));
				controlBar.setTime(0, streamManager.totalTime, streamManager.loadedTime);
				video.attachNetStream(streamManager.getCurStream().getNetStream());
				break;
				
				case AdType.MIDDLE :
				break
			}
		}
		
		private function resizeHandler(e:Event):void 
		{
			drawBg();
			
			var viewW:Number = stage.stageWidth;
			var viewH:Number = stage.stageHeight - controlBar.height;
			
			loading.x = viewW >> 1;
			loading.y = viewH >> 1;
			controlBar.width = viewW;
			controlBar.y = viewH;
			adPanel.setSize(viewW, viewH);
			
			
			var rate:Number = StreamManager.videoWidth / StreamManager.videoHeight;
			if (viewW / viewH > rate)
			{
				video.height = viewH;
				video.width = viewH * rate;
			}else
			{
				video.width = viewW;
				video.height = viewW / rate;
			}
			
			video.x = (viewW - video.width) / 2;
			video.y = (viewH - video.height) / 2;
		}
		
		private function drawBg():void
		{
			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		private function handler(e:Event):void 
		{
			//trace("ns.time = ", vs.currTime);
			
			var loadTime:Number = 0;
			//if (vs.bytesTotal > 0) loadTime = vs.bytesLoaded / vs.totalTime * vs.totalTime;
			//trace(streamManager.loadedTime, streamManager.totalTime, streamManager.currTime);
			controlBar.setTime(streamManager.curTime, streamManager.totalTime, streamManager.loadedTime);
		}
		
	}
	
}