(
var window;
var configsFilename = "~/Desktop/configs.scd".standardizePath;
var configs = if(File.exists(configsFilename)) { this.executeFile(configsFilename) } {
	(
		freq: 500,
		freq2: 600,
	)
};

var updateConfig = { | control, value |
	configs.put(control, value);
	configs.at(control).postln;
};

var lastControl = \freq;

var controls = ();

var makeKnob = { | control, spec |
	controls.put(
		control,
		EZKnob(
			window,
			100@120,
			label: control,
			controlSpec: spec,
			initVal: configs.at(control),
			layout: \vert2,
			margin: 5@5,
			unitWidth: 20,
			initAction: true,
			action: { | knob |
				lastControl = control;
				updateConfig.value(control, knob.value);
			}
		)
	);
};

var bumpControl = { | control, delta |
	var ctrl = controls.at(control);
	var spec = ctrl.controlSpec;
	ctrl.value = spec.map(spec.unmap(ctrl.value) + delta);
	ctrl.action.value(ctrl);
};

window = Window("control-test");
window.view.decorator = FlowLayout(window.view.bounds);
window.view.decorator.gap = 2@2;

makeKnob.value(\freq, \freq);
makeKnob.value(\freq2, \freq);

Button(window, Rect(120, 100, 20, 20))
.string_("-")
.action_({ | button |
	bumpControl.value(lastControl, -0.01);
});
Button(window, Rect(150, 100, 20, 20))
.string_("+")
.action_({ | button |
	bumpControl.value(lastControl, 0.01);
});

window.onClose_({
	var configFile = File(configsFilename, "w");
	configFile.write(configs.asCompileString);
	configFile.close;
});

window.front;

CmdPeriod.add({window.close});
)