package com.litefeel.videoPlayer.core 
{
	/**
	 * ...
	 * @author lite3
	 */
	public class ConfigData
	{
		public var logo:String = null;
		public var startAd:String = null;
		public var startAdTime:int = 0;
		public var midAd:String = null;
		public var midAdTime:int = 0;
		public var endAd:String = null;
		public var endAdTime:int = 0;
		
		public var prevConfig:String;
		public var nextConfig:String;
		public var moveList:Vector.<String>;
		
		public function ConfigData() 
		{
			
		}
		
	}

}