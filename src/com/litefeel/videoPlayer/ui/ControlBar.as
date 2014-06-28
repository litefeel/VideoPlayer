package com.litefeel.videoPlayer.ui 
{
	import com.litefeel.controls.delegateControls.Slider;
	import com.litefeel.events.SliderEvent;
	import com.litefeel.utils.DisplayObjectUtil;
	import com.litefeel.videoPlayer.events.VideoPlayerEvent;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author lite3
	 */
	public class ControlBar extends ControlBarUI
	{
		
		private var rightList:Vector.<Number>;
		
		public var volumeBar:Slider;
		
		private var seekBar:SeekBar;
		
		public function ControlBar() 
		{
			rightList = Vector.<Number>([width - soundBtn.x, width - sliderSkin.x, width - fullScreenBtn.x]);
			bg.mouseChildren = false;
			setPlaying(true);
			addEventListener(MouseEvent.CLICK, btnClickHandler);
			volumeBar = new Slider();
			volumeBar.minimum = 0;
			volumeBar.maximum = 100;
			volumeBar.value = 50;
			volumeBar.setSkin(sliderSkin);
			volumeBar.addEventListener(SliderEvent.CHANGING, volumeChangeHandler);
			
			
			seekBar = new SeekBar();
			var seekBarH:Number = seekBar.height;
			for (var i:int = numChildren - 1; i >= 0; i--)
			{
				getChildAt(i).y += seekBarH;
			}
			addChild(seekBar);
			seekBar.addEventListener(Event.CHANGE, seekBarChangeHandler);
			
		}
		
		private function seekBarChangeHandler(e:Event):void 
		{
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.PLAY, false, false, seekBar.value));
		}
		
		private function volumeChangeHandler(e:SliderEvent):void 
		{
			setSoundEnabled(volumeBar.value > 0);
		}
		
		public function setPlaying(play:Boolean):void
		{
			playBtn.visible = !play;
			pauseBtn.visible = play;
		}
		
		public function setEnabled(value:Boolean):void
		{
			DisplayObjectUtil.setEnabled(playBtn, value);
			DisplayObjectUtil.setEnabled(pauseBtn, value);
			seekBar.setEnabled(value);
			if (!value) setPrevNext(false, false);
		}
		
		public function setTime(currTime:Number, totalTime:Number, loadedTime:Number):void 
		{
			timeTxt.text = convertTime(currTime) + "/" + convertTime(totalTime);
			seekBar.setValue(loadedTime, totalTime, currTime);
		}
		
		public function setPrevNext(prev:Boolean, next:Boolean):void 
		{
			DisplayObjectUtil.setEnabled(prevBtn, prev);
			DisplayObjectUtil.setEnabled(nextBtn, next);
		}
		
		private function btnClickHandler(e:MouseEvent):void 
		{
			switch(e.target)
			{
				case playBtn :
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.RESUME));
				break;
				
				case prevBtn :
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.PLAY_PREV));
				break;
				
				case nextBtn :
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.PLAY_NEXT));
				break;
				
				case pauseBtn :
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.PAUSE));
				break;
				
				case soundBtn :
				setSoundEnabled(false);
				break;
				
				case noSoundBtn :
				setSoundEnabled(true);
				break;
				
				case fullScreenBtn :
				stage.displayState = StageDisplayState.NORMAL == stage.displayState ? 
										StageDisplayState.FULL_SCREEN :
										StageDisplayState.NORMAL;
				break;
			}
		}
		
		private function setSoundEnabled(soundEnabled:Boolean):void 
		{
			soundBtn.visible = soundEnabled;
			noSoundBtn.visible = !soundEnabled;
			
			var volume:int = soundEnabled ? volumeBar.value : 0;
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CHANGE_VOLUME, false, false, -1, volume));
		}
		
		override public function set width(value:Number):void 
		{
			bg.width = value;
			seekBar.width = value;
			soundBtn.x = noSoundBtn.x = value-rightList[0];
			sliderSkin.x = value - rightList[1];
			fullScreenBtn.x = value - rightList[2];
		}
		
		//转换时间
		private function convertTime(second:int):String{
			var hour:int = int(second/3600);
			second = second%3600;
			var minute:int = int(second/60);
			second = second%60;
			
			var hours:String;
			if(hour < 10){
				hours = "0" + String(hour);
			} else {
				hours = String(hour);
			}
			var minutes:String;
			if(minute < 10){
				minutes = "0" + String(minute);
			} else {
				minutes = String(minute);
			}
			var seconds:String;
			if(second < 10){
				seconds = "0" + String(second);
			} else {
				seconds = String(second);
			}
			
			var time:String = hours + ":" + minutes + ":" + seconds;
			return time;
		}
	}

}