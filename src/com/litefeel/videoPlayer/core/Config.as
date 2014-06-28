package com.litefeel.videoPlayer.core 
{
	import com.litefeel.net.SimpleTextLoader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	
	/**
	 * ...
	 * @author lite3
	 */
	public class Config extends EventDispatcher
	{
		
		private var _loaded:Boolean = false;
		private var _configData:ConfigData;
		
		private var loader:SimpleTextLoader;
		public function Config() 
		{
			
		}
		
		public function loadConfig(url:String):void
		{
			trace("load config ", url);
			_loaded = false;
			_configData = null;
			loader = new SimpleTextLoader(url, loaderHandler);
		}
		
		private function loaderHandler(loader:SimpleTextLoader):void 
		{
			if (loader != this.loader) return;
			
			if (loader.success)
			{
				conveteXML(loader.data);
				_loaded = true;
				dispatchEvent(new Event(Event.COMPLETE));
			}else
			{
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
			}
			
			loader = null;
		}
		
		private function conveteXML(data:String):void 
		{
			var xml:XML = new XML(data);
			
			if (!_configData) _configData = new ConfigData();
			_configData.logo = xml.logo;
			_configData.startAd = xml.start_ad.url;
			if (_configData.startAd) _configData.startAd = encodeURI(_configData.startAd);
			_configData.startAdTime = xml.start_ad.time;
			_configData.midAd = xml.mid_ad.url;
			if (_configData.midAd) _configData.midAd = encodeURI(_configData.midAd);
			_configData.midAdTime = xml.mid_ad.time;
			_configData.endAd = xml.end_ad.url;
			if (_configData.endAd) _configData.endAd = encodeURI(_configData.endAd);
			_configData.endAdTime = xml.end_ad.time;
			_configData.prevConfig = xml.up_mv;
			_configData.nextConfig = xml.next_mv;
			var len:int = xml.mv.item.length();
			_configData.moveList = new Vector.<String>(len);
			for (var i:int = 0; i < len; i++)
			{
				_configData.moveList[i] = xml.mv.item[i];
				if (_configData.moveList[i]) _configData.moveList[i] = encodeURI(_configData.moveList[i]);
			}
		}
		
		public function get loaded():Boolean { return _loaded; }
		public function get configData():ConfigData { return _configData; }
	}

}