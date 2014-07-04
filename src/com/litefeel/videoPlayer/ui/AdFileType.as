package com.litefeel.videoPlayer.ui 
{
	/**
	 * ...
	 * @author lite3
	 */
	public class AdFileType 
	{
		public static const GIF:String = "gif";
		public static const IMAGE:String = "image";
		public static const VIDEO:String = "video";
		
		public static function getType(url:String):String
		{
			if (/^.+\.((jpg)|(gif)|(jpeg)|(png))/i.test(url)) return IMAGE;
			else if (/^.+\.((gif))/i.test(url)) return GIF;
			else if (/^.+\.((flv)|(f4v)|(mp4)|(m4v)|(m4a)|(mov)|(3gp))/i.test(url)) return VIDEO
			return null;
		}
	}

}