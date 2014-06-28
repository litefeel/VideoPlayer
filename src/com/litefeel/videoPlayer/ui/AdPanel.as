package com.litefeel.videoPlayer.ui 
{
	import com.litefeel.videoPlayer.core.VideoStream;
	import com.litefeel.videoPlayer.events.VideoStreamEvent;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.media.Video;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import org.bytearray.gif.events.GIFPlayerEvent;
	import org.bytearray.gif.player.GIFPlayer;
	
	/**
	 * ...
	 * @author lite3
	 */
	public class AdPanel extends AdPanelUI
	{
		
		private var rectW:int;
		private var rectH:int;
		
		private var beginTime:int;
		private var showTime:int;
		private var timer:Timer;
		public var type:String;
		
		private var video:Video;
		private var vs:VideoStream;
		private var gifPlayer:GIFPlayer;
		private var image:Loader
		private var timeTxt:TextField;
		
		public function AdPanel() 
		{
			timeTxt = adTime.getChildByName("timeTxt") as TextField;
			video = new Video();
			adTime.visible = false;
			closeBtn.visible = false;
			closeBtn.addEventListener(MouseEvent.CLICK, closeHandler);
		}
		
		private function closeHandler(e:MouseEvent):void 
		{
			clear();
			visible = false;
			//dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function setSize(w:int, h:int):void
		{
			rectW = w;
			rectH = h;
			adTime.x = rectW - adTime.width - 10;
			adTime.y = 10;
			initHandler(null);
		}
		
		/**
		 * 显示广告
		 * @param	url
		 * @param	type
		 * @param	time
		 */
		public function showAd(url:String, type:String, time:int = -1):void
		{
			clear();
			this.type = type;
			adTime.visible = time > 0;
			closeBtn.visible = false;
			showTime = time * 1000;
			visible = true;
			if (time > 0)
			{
				timeTxt.text = time + "";
				beginTime = getTimer();
				if (!timer) timer = new Timer(1000);
				timer.addEventListener(TimerEvent.TIMER, timerHandler);
				timer.start();
			}
			switch(getFileType(url))
			{
				case "image" :
				image = new Loader();
				image.load(new URLRequest(url));
				image.contentLoaderInfo.addEventListener(Event.INIT, initHandler);
				addChildAt(image, 0);
				break;
				
				case "gif" :
				gifPlayer = new GIFPlayer();
				gifPlayer.addEventListener(GIFPlayerEvent.COMPLETE, initHandler);
				gifPlayer.load(new URLRequest(url));
				addChildAt(gifPlayer, 0);
				break;
				case "flv" :
				vs = new VideoStream(url, true);
				vs.addEventListener(VideoStreamEvent.INIT, initHandler);
				video.attachNetStream(vs.getNetStream());
				addChildAt(video, 0);
				break;
			}
		}
		
		private function initHandler(e:Event):void 
		{
			trace("complte", e);
			var display:DisplayObject = null;
			if (image)
			{
				display = image;
			}else if (gifPlayer)
			{
				display = gifPlayer;
			}else if (vs)
			{
				video.width = vs.videoWidth;
				video.height = vs.videoHeight;
				display = video;
			}
			if (display)
			{
				display.x = (rectW - display.width) / 2;
				display.y = (rectH - display.height) / 2;
				closeBtn.visible = AdType.MIDDLE == type;
				closeBtn.x = display.x + display.width - closeBtn.width;
				closeBtn.y = display.y;
			}
			
			
		}
		
		public function clear():void
		{
			visible = false;
			if (vs)
			{
				vs.stop()
				vs.removeEventListener(VideoStreamEvent.INIT, initHandler);
				vs = null;
				
				video.attachNetStream(null);
				if (video.parent) video.parent.removeChild(video);
			}
			if (gifPlayer)
			{
				gifPlayer.stop();
				gifPlayer.dispose();
				gifPlayer.removeEventListener(GIFPlayerEvent.COMPLETE, initHandler);
				if (gifPlayer.parent) gifPlayer.parent.removeChild(gifPlayer);
				gifPlayer = null;
			}
			if (image)
			{
				if (image.parent) image.parent.removeChild(image);
				image.contentLoaderInfo.removeEventListener(Event.INIT, initHandler);
				image = null;
			}
		}
		
		private function timerHandler(e:TimerEvent):void 
		{
			var remnantTime:int = showTime - getTimer() + beginTime;
			if (remnantTime < 0) remnantTime = 0;
			
			timeTxt.text = int(remnantTime/1000) + "";
			
			if (0 == remnantTime)
			{
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				trace("adPanel complte");
				clear();
				dispatchEvent(new Event(Event.COMPLETE));
			}
			
		}
		
		private function getFileType(url:String):String
		{
			if (/^.+\.((jpg)|(gif)|(jpeg)|(png))/i.test(url)) return "image";
			else if (/^.+\.((gif))/i.test(url)) return "gif";
			else if (/^.+\.((flv)|(f4v)|(mp4)|(m4v)|(m4a)|(mov)|(3gp))/i.test(url)) return "flv";
			return null;
		}
		
	}

}