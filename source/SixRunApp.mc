using Toybox.Application;

class SixRunApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new SixRunField()]; }
}
