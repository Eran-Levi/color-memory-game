using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class ColorMemoryGameDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();        
    }

    function onMenu() {
        return true;
    }
    
    function onBack() {
    	if (!isTouchScreen) {
        	return true;
        }
        return false;
    }

    function onKeyPressed(evt) {
    	var keyIndex = -1;
    	var evtKey = evt.getKey(); 
    	if (evtKey == KEY_ENTER) {
    		keyIndex = 1;
		}
    	else if (evtKey == KEY_ESC && !isTouchScreen) {
    		keyIndex = 2;
    	}
    	else if (evtKey == KEY_UP) {
    		keyIndex = 0;
    	}
    	else if (evtKey == KEY_DOWN) {
    		keyIndex = 3;
    	}
    	if (keyIndex >= 0) {
	        App.getApp().mainView.onKeyPressed(keyIndex);
        	return true;
    	}
    	return false;
    }

    // Handle touchscreen taps
    function onTap(evt) {
        if (Ui.CLICK_TYPE_TAP == evt.getType()) {
            var coords = evt.getCoordinates();
            App.getApp().mainView.onScreenTap(coords);
        }
        return true;
    }

	function tapCoordinatesToIndex() {
	}
}