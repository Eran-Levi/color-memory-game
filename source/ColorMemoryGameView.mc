using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;
using Toybox.Math as Math;
using Toybox.System as System;

enum {
	paused,
	playing,
	repeating
}

//Actions that should run after a blink event is done
enum {
	AfterBlink_NoAction,
	AfterBlink_AddNumberToSequence,
	AfterBlink_SwitchToRepeat
}
class ColorMemoryGameView extends Ui.View {

	var sequenceTimer;
	var blinkTimer;
	var colorsOn = [Gfx.COLOR_GREEN, Gfx.COLOR_RED, Gfx.COLOR_BLUE, Gfx.COLOR_ORANGE];
	var colorsOff = [Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_RED, Gfx.COLOR_DK_BLUE, Gfx.COLOR_YELLOW];
	var sounds = [Attention.TONE_KEY, Attention.TONE_MSG, Attention.TONE_START, Attention.TONE_LOUD_BEEP];
	var toneFailed = Attention.TONE_FAILURE;
	var colorsToRender = [];
	var sequence = [];
	var sequenceIx = 0;
	var blinkIx = 0;
	var state = paused;
	var afterBlinkAction = AfterBlink_NoAction;
	var blinking = false;
	var playSounds = false;
	var lastScore = -1;
	var highScore = -1;
	
    function initialize() {
    	for (var i=0; i < colorsOff.size(); ++i) {
    		colorsToRender.add(colorsOff[i]);
    	}
        sequenceTimer = new Timer.Timer();
        blinkTimer = new Timer.Timer();
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
				lastScore = sequence.size() - 1;
				if (lastScore > highScore) {
					highScore = lastScore;
				}
				if (playSounds) {
					Attention.playTone(toneFailed);
				}
				state = paused;
				Ui.requestUpdate();				
			}
		}
		else if (state == paused) {
			if (keyIndex == 2) {
				System.exit();
			}
			else if (keyIndex == 1) {
				newGame();
			}
			else if (keyIndex == 3) {
				playSounds = !playSounds;
				Ui.requestUpdate();
			}
		}
	}
	
    function onLayout(dc) {        
    }
	
	function newGame() {
		sequence = [];
		sequence.add(getRandomColor());
		playSequence();
		Ui.requestUpdate();
	}
	
	function playSequence() {
		state = playing;
		sequenceIx = 0;
        sequenceTimer.start( method(:sequenceTimerCallback), 800, true );        
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
	
	function blinkColor(index) {
		blinking = true;
		if (playSounds) {		
        	Attention.playTone(sounds[index]);
        }
		blinkIx = index;
		colorsToRender[blinkIx] = colorsOn[blinkIx];
        Ui.requestUpdate();
		blinkTimer.start(method(:blinkTimerCallback), 400, false);
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
        
		drawMainCircle(dc);
		
     	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillCircle(dc.getHeight() / 2, dc.getWidth() / 2, 40);
        var rectSize = 8;
        dc.fillRectangle(dc.getWidth() / 2 - rectSize / 2, 0, rectSize, dc.getHeight());
        dc.fillRectangle(0, dc.getHeight() / 2 - rectSize / 2, dc.getWidth(), rectSize);
        
        dc.setPenWidth(1);
        if (state != paused) {
	     	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
	     	var scoreTxt = "Score: " + (sequence.size() - 1);
	        var textDimensions = dc.getTextDimensions(scoreTxt, Gfx.FONT_TINY);
	        var scoreYPos = dc.getHeight() / 2 - textDimensions[1] / 2 - 10;
	        dc.drawText(dc.getWidth() / 2, scoreYPos, 
	        	Gfx.FONT_TINY, scoreTxt, Gfx.TEXT_JUSTIFY_CENTER);
			
	     	var txt;
			if (state == playing) {
		     	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
		     	txt = "Listen";
			}
			else if (state == repeating) {
		     	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
		     	txt = "Repeat";
			} 
			else {
		     	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
		     	txt = "Game Over";
			}
	        var txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_TINY);
	        dc.drawText(dc.getWidth() / 2, scoreYPos + txt2Dim[1], 
	        	Gfx.FONT_TINY, txt, Gfx.TEXT_JUSTIFY_CENTER);
        }
        else {
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			var txt = "Press START"; 
	        var txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
	        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - txt2Dim[1] / 2, 
	        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);
	        	
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
			txt = playSounds ? "Sound On" : "Sound Off";
	        txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
	        dc.drawText(dc.getWidth() / 2, dc.getHeight() - txt2Dim[1] - 30, 
	        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);
	        
	        if (lastScore >= 0) {
				txt = "Score: " + lastScore;
		        txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
		        var vMargin = 8;
		        dc.drawText(dc.getWidth() / 2, vMargin, 
		        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);
		        	
				txt = "High Score: " + (highScore >= lastScore ? highScore : lastScore);
		        txt2Dim = dc.getTextDimensions(txt, Gfx.FONT_MEDIUM);
		        dc.drawText(dc.getWidth() / 2, txt2Dim[1] + vMargin, 
		        	Gfx.FONT_MEDIUM, txt, Gfx.TEXT_JUSTIFY_CENTER);				        
		        	
	        }	        
        }
    }

    function drawMainCircle(dc) {
        var index = 0;
        var angle = ( Math.PI * 2 ) / colorsToRender.size();
        var startAngle = Math.PI * ( 3 / 2.0 ) - ( angle);

        // draw the wheel
        for(var i = 0; i < colorsToRender.size(); ++i) {
            if(index == colorsToRender.size()) {
                index = 0;
            }

            dc.setColor(colorsToRender[index], colorsToRender[index]);
            drawArc(dc, dc.getHeight()/2, dc.getWidth()/2, 4, (i * angle) + startAngle, ((i + 1 ) * angle) + startAngle, true);
            ++index;
        }

        // highlight the selected one
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        drawArc(dc, dc.getHeight()/2, dc.getWidth()/2, dc.getHeight() / 2, startAngle, startAngle + angle, false);
    }
	
    function drawArc(dc, centerX, centerY, radius, startAngle, endAngle, fill) {
        var points = new [30];
        var halfHeight = dc.getHeight() / 2;
        var halfWidth = dc.getWidth() / 2;
        var radius = ( halfHeight > halfWidth ) ? halfWidth : halfHeight;
        var arcSize = points.size() - 2;
        for(var i = arcSize; i >= 0; --i) {
            var angle = ( i / arcSize.toFloat() ) * ( endAngle - startAngle ) + startAngle;
            points[i] = [halfWidth + radius * Math.cos(angle), halfHeight + radius * Math.sin(angle)];
        }
        points[points.size() - 1] = [halfWidth, halfHeight];

        if(fill) {
            dc.fillPolygon(points);
        }
        else {
            for(var i = 0; i < points.size() - 1; ++i) {
                dc.drawLine(points[i][0], points[i][1], points[i+1][0], points[i+1][1]);
            }
            dc.drawLine(points[points.size()-1][0], points[points.size()-1][1], points[0][0], points[0][1]);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
