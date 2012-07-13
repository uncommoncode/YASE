window.SM2_DEFER = true;
requirejs.config({
  shim: {
    "backbone": {
      deps: [ "underscore", "zepto" ],
      exports: function () {
        return this.Backbone.noConflict();
      }
    },
    "underscore": {
      exports: function () {
        return this._.noConflict();
      }
    },
    "zepto": {
      exports: "Zepto"
    },
    "soundcloud": {
      deps: [ "soundmanager" ],
      exports: "SC"
    }
  },
  baseUrl: "../",
  paths: {
    "text":         "lib/text",
    "embr":         "lib/embr/src/embr",
    "glmatrix":     "lib/gl-matrix",
    "backbone":     "lib/backbone",
    "underscore":   "lib/underscore",
    "zepto":        "lib/zepto",
    "soundmanager": "lib/soundmanager/soundmanager2-nodebug",
    "soundcloud":   "http://connect.soundcloud.com/sdk"
  }
});
require([ "src/models/Toy", "src/views/ToyView", "glmatrix" ], function (Toy, ToyView) {
  window.toyview = new ToyView({ model: window.toy = new Toy() });
});