using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;
using Toybox.Math as Math;
using Toybox.System as System;

enum {
	paused,
	playing,
	repeating,
	gameover
}

//Actions that should run after a blink event is done
enum {
	AfterBlink_NoAction,
	AfterBlink_AddNumberToSequence,
	AfterBlink_SwitchToRepeat
}

//Fonts
var SCORE_FONT = Gfx.FONT_TINY;
var SOUND_STATUS_FONT = Gfx.FONT_MEDIUM;

var TIMES_TO_BLINK_GAME_OVER = 3;

//Timings
var BLINK_COLOR_MS = 250;
var PLAY_SEQUENCE_MS = 600;
var GAME_OVER_SEQUENCE_MS = BLINK_COLOR_MS + 120;

var SOUND_STATUS_MARGIN = 30;

class ColorMemoryGameView extends Ui.View {
	var sequenceTimer, blinkTimer, gameOverTimer;
	var colorsOn = [Gfx.COLOR_GREEN, Gfx.COLOR_RED, Gfx.COLOR_BLUE, Gfx.COLOR_ORANGE];
	var colorsOff = [Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_RED, Gfx.COLOR_DK_BLUE, Gfx.COLOR_YELLOW];
	var sounds;
	var toneFailed;
	var colorsToRender = [];
	var sequence = [];
	var sequenceIx = 0;
	var blinkIx = 0;
	var state = paused;
	var afterBlinkAction = AfterBlink_NoAction;
	var blinking = false;
	var playSounds = false;
	var lastScore = -1, highScore = -1;
	var dcCenterX = 0, dcCenterY = 0;
	var innerCircleRad;
	var scoreHeight;
	var gameOverBlinkedTimes = 0;
	var soundStatusVPos = 0, soundStatusDim = [0, 0];
	
    function initialize() {
        if (supportsSound) {
    		sounds = [Attention.TONE_KEY, Attention.TONE_ERROR, Attention.TONE_MSG, Attention.TONE_LOUD_BEEP];
    		toneFailed = Attention.TONE_FAILURE;
    	}
		var savedHighScore = App.getApp().getProperty("highScore");
		if (savedHighScore) {
			highScore = savedHighScore;
		}    
    	for (var i=0; i < colorsOff.size(); ++i) {
    		colorsToRender.add(colorsOff[i]);
    	}
        sequenceTimer = new Timer.Timer();
        blinkTimer = new Timer.Timer();
        gameOverTimer = new Timer.Timer();
        
    	Math.srand(System.getTimer());    	
    	
        View.initialize();
    }

	function onKeyPressed(keyIndex) {
		if (state == repeating && !blinking) {
			if (sequence[sequenceIx] == keyIndex) {
				blinkColor(sequence[sequenceIx]);
				++sequenceIx;
				if (sequenceIx >= sequence.size()) {
					afterBlinkAction = AfterBlink_AddNumberToSequence;
				}
			}
			else {
				gameOver();
			}
		}
		else if (state == paused) {
			if (keyIndex == 2) {
				Ui.popView(Ui.SLIDE_IMMEDIATE);
			}
			else if (keyIndex == 1) {
				newGame();
			}
			else if (keyIndex == 3) {
				changeSoundStatus();
			}
		}
	}
	
	function onScreenTap(coords) {
		var x = coords[0];
		var y = coords[1];
		if (state == repeating) {
			var colorIndex;
			if (x < dcCenterX) {
				if (y < dcCenterY) {
					colorIndex = 0;
				}
				else {
					colorIndex = 3;
				}
			} else {
				if (y < dcCenterY) {
					colorIndex = 1;
				}
				else {
					colorIndex = 2;
				}
			}
			onKeyPressed(colorIndex);
		} else if (state == paused) {
			if (supportsSound && 
				y > soundStatusVPos - soundStatusDim[1] && y < soundStatusVPos + soundStatusDim[1] &&
				x > dcCenterX - soundStatusDim[0] && x < dcCenterX + soundStatusDim[0]) {
				changeSoundStatus();
			}
			else {
				newGame();
			}
		}
	}
	
	function changeSoundStatus() {
		playSounds = !playSounds;
		Ui.requestUpdate();
	}
	
    function onLayout(dc) {
    	dcCenterX = dc.getWidth() / 2;
    	dcCenterY = dc.getHeight() / 2;
    	
        var txtDim = dc.getTextDimensions("Score: 10000", SCORE_FONT);
        innerCircleRad = txtDim[0] / 2 - 2;
        scoreHeight = txtDim[1] / 2;
        
        soundStatusDim = dc.getTextDimensions("Sound Off", SOUND_STATUS_FONT);
        soundStatusVPos = dc.getHeight() - soundStatusDim[1] - SOUND_STATUS_MARGIN;
    }
	
	function newGame() {
		sequence = [];
		sequence.add(getRandomColor());
		playSequence();
		Ui.requestUpdate();
	}
	
	function gameOver() {
		lastScore = sequence.size() - 1;
		if (lastScore > highScore) {
			highScore = lastScore;
			App.getApp().setProperty("highScore", highScore);
		}
		if (playSounds && supportsSound) {
			Attention.playTone(toneFailed);
		}
		state = gameover;
		gameOverBlinkedTimes = 0;
		gameOverTimerCallback();
		gameOverTimer.start( method(:gameOverTimerCallback), GAME_OVER_SEQUENCE_MS, true );
	}
	
	function playSequence() {
		state = playing;
		sequenceIx = 0;
        sequenceTimer.start( method(:sequenceTimerCallback), PLAY_SEQUENCE_MS, true );        
	}
	
	function sequenceTimerCallback() {
		blinkColor(sequence[sequenceIx]);
		if (sequenceIx >= sequence.size() - 1) {
			afterBlinkAction = AfterBlink_SwitchToRepeat;
			sequenceTimer.stop();
		}
		else {
			++sequenceIx;
		}
	}
	
	function gameOverTimerCallback() {
		++gameOverBlinkedTimes;
		if (gameOverBlinkedTimes > TIMES_TO_BLINK_GAME_OVER) {
			gameOverTimer.stop();
			state = paused;
			Ui.requestUpdate();
		}
		else {
			blinkColor(sequence[sequenceIx]);
		}
	}
	
	function blinkColor(index) {
		blinking = true;
		if (playSounds && state != gameover) {		
        	Attention.playTone(sounds[index]);
        }
		blinkIx = index;
		colorsToRender[blinkIx] = colorsOn[blinkIx];
        Ui.requestUpdate();
		blinkTimer.start(method(:blinkTimerCallback), BLINK_COLOR_MS, false);
	}
	
	function blinkTimerCallback() {
		var colorIx = blinkIx;
		colorsToRender[colorIx] = colorsOff[colorIx];
        Ui.requestUpdate();
		blinking = false;
        if (afterBlinkAction == AfterBlink_AddNumberToSequence) {
			afterBlinkAction = AfterBlink_NoAction;
			sequence.add(getRandomColor());
			playSequence();
		}
        else if (afterBlinkAction == AfterBlink_SwitchToRepeat) {
			afterBlinkAction = AfterBlink_NoAction;
			state = repeating;
			sequenceIx = 0;
			Ui.requestUpdate();
		}
	}
	
	function getRandomColor() {
		return Math.rand() % (colorsOn.size());
	}
	
    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
     	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_BLUE);
        
		drawMainBoard(dc);
		
     	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillCircle(dcCenterX, dcCenterY, innerCircleRad);
        var rectSize = 8;
        dc.fillRectangle(dcCenterX - rectSize / 2, 0, rectSize, dc.getHeight());
        dc.fillRectangle(0, dcCenterY - rectSize / 2, dc.getWidth(), rectSize);
        
        dc.setPenWidth(1);
        if (state != paused) {
        	drawInnerCircleData(dc);
        }
        else {
        	drawPauseScreenData(dc);
        }
    }

    function drawMainBoard(dc) {
        var x = 0, y = 0;
        var dcWidth = dc.getWidth();
        var dcHeight = dc.getHeight();
        for(var i = 0; i < colorsToRender.size(); ++i) {
            dc.setColor(colorsToRender[i], colorsToRender[i]);
            dc.fillRectangle(x, y, dcCenterX, dcCenterY);
            if (x >= dcCenterX) {
            	if (y == 0) {
					y += dcCenterY;
            	}
            	else {
            		x = 0;
            	}
            }
            else {
            	x+= dcCenterX;
            }
        }
    }
	
	function drawInnerCircleData(dc) {
     	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
     	var scoreTxt = "Score: " + (sequence.size() - 1);
        var scoreYPos = dcCenterY - scoreHeight - 10;
        dc.drawText(dcCenterX, scoreYPos, 
        	Gfx.FONT_TINY, scoreTxt, Gfx.TEXT_JUSTIFY_CENTER);
		
     	var txt;
		if (state == playing) {
	     	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
	     	txt = "Listen";
		}
		else if (state == repeating || state == gameover) {
	     	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
	     	txt = "Repeat";
		} 
		else {
	     	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
	     	txt = "Game Over";
		}
        var txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_TINY);
        dc.drawText(dcCenterX, scoreYPos + txt2Dim[1], 
        	Gfx.FONT_TINY, txt, Gfx.TEXT_JUSTIFY_CENTER);
	}
	
	function drawPauseScreenData(dc) {
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		var txt = isTouchScreen ? "Tap To Start" : "Press START"; 
        var txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
        dc.drawText(dcCenterX, dcCenterY - txt2Dim[1] / 2, 
        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);
        	
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		if (supportsSound) {
			txt = playSounds ? "Sound On" : "Sound Off";
	        dc.drawText(dcCenterX, soundStatusVPos, 
	        	SOUND_STATUS_FONT, txt, Gfx.TEXT_JUSTIFY_CENTER);
		}
		        
	    var vMargin = 8;
        if (lastScore >= 0) {
			txt = "Score: " + lastScore;
	        dc.drawText(dcCenterX, vMargin, 
	        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);		        			        	
        }
        
        if (highScore >= 0) {
			txt = "High Score: " + highScore;
	        txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
	        var vPos = txt2Dim[1];
	        if (lastScore >= 0) {
	        	vPos += vMargin;
	        }
	        else {
	        	vPos -= 5;
	        }
	        dc.drawText(dcCenterX, vPos, 
	        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);				        
        }
	}
	
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
