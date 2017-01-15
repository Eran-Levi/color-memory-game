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
        return true;
    }

    function onKeyPressed(evt) {
    	var keyIndex = -1;
    	var evtKey = evt.getKey(); 
    	if (evtKey == KEY_ENTER) {
    		keyIndex = 1;
		}
    	else if (evtKey == KEY_ESC) {
    		keyIndex = 2;
    	}
    	else if (evtKey == KEY_UP) {
    		keyIndex = 0;
    	}
    	else if (evtKey == KEY_DOWN) {
    		keyIndex = 3;
    	}
    	if (keyIndex >= 0) {
	        var app = App.getApp();
	        app.mainView.onKeyPressed(keyIndex);
    	}
        return true;
    }

}