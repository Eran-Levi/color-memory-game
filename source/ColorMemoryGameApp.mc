using Toybox.Application as App;
using Toybox.WatchUi as Ui;

var isTouchScreen = false;
var supportsSound = false;
class ColorMemoryGameApp extends App.AppBase {
	var mainView;
	var mainDelegate;
	
    function initialize() {
        AppBase.initialize();
		isTouchScreen = System.getDeviceSettings().isTouchScreen;
    	supportsSound = Attention has :playTone;
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	mainView = new ColorMemoryGameView();
    	mainDelegate = new ColorMemoryGameDelegate();
        return [ mainView, mainDelegate ];
    }

}
