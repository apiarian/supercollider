s.boot;

(
MIDIIn.connectAll;
s.scope;
s.freqscope;
)

(
var window = Window("Minimoog Controls", 800@900);

var configsFilename = "~/Desktop/minimoog-configs.scd".standardizePath;
var configs = if(File.exists(configsFilename)) { this.executeFile(configsFilename) } { (
	note: 60, bend: 0, amp: 1.0, gate: 0, glideOn: 0, glideTime: 0.01,
	mod: 0, osc3FilterEG: 0, noiseLFO: 0, modMix: 0.5, lfoRate: 0.05, lfoSelection: 0,
	oscModOn: 0,
	osc1Volume: 0, osc1Range: 3, osc1Selection: 0, tuneOffset: 0, osc1On: 0,
	osc2Volume: 0, osc2Range: 3, osc2Selection: 0, osc2NoteOffset: 0, osc2On: 0,
	osc3Volume: 0, osc3Range: 3, osc3Selection: 0, osc3NoteOffset: 0, osc3On: 0, osc3Control: 1,
	noiseVolume: 0, noiseSelection: 0, noiseOn: 0,
	extVolume: 0, extOn: 0,
	decayOn: 0,
	filterCutoff: 0, filterEmphasis: 0, filterKeyboard1: 0, filterKeyboard2: 0, filterContour: 0, filterModOn: 0, filterAttack: 0.1, filterDecay: 0.1, filterSustain: 0,
	soundAttack: 0.1, soundDecay: 0.1, soundSustain: 1,
)};

var minimoogSynth;

var updateConfig = { | control, value |
	configs.put(control, value);
	minimoogSynth.set(control, configs.at(control));
};

var lastControl = \note;
var controls = ();

var makeKnob = { | control, spec |
	controls.put(
		control,
		EZKnob(
			window,
			80@100,
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
var makePopup = { | control, bounds, items |
	var menu = PopUpMenu(window, bounds);
	menu.items = items;
	menu.action = { | menu | updateConfig.value(control, menu.value) };
	menu.value = configs.at(control);
	controls.put(control, menu);
};
var makeButton = { | control, states, bounds = (50@30) |
	var button = Button(window, bounds);
	button.states = states;
	button.action = { | button | updateConfig.value(control, button.value) };
	button.value = configs.at(control);
	controls.put(control, button);
};

var bumpControl = { | control, delta |
	var ctrl = controls.at(control);
	var spec = ctrl.controlSpec;
	ctrl.value = spec.map(spec.unmap(ctrl.value) + delta);
	ctrl.action.value(ctrl);
};

var setControl = { | control, value |
	var ctrl = controls.at(control);
	var spec = ctrl.controlSpec;
	ctrl.value = spec.map(value);
	ctrl.action.value(ctrl);
};

var setButton = { | control, value |
	var ctrl = controls.at(control);
	ctrl.value = value;
	ctrl.action.value(ctrl);
};

var noteOn;
var noteOff;
var cc;
var bend;
var shift = 0;
var meta = 0;

var notesOn = SortedList.new;

SynthDef(\minimoog, { |
	out=0,
	note=60, bend = 0, amp=1, gate=0, glideOn = 0, glideTime = 0.01,
	mod = 0, osc3FilterEG = 0, noiseLFO = 0, modMix = 0.5, lfoRate = 0.05, lfoSelection = 0,
	oscModOn = 0,
	osc1Volume = 0, osc1Range = 3, osc1Selection = 0, tuneOffset = 0, osc1On = 0, osc3Control = 1,
	osc2Volume = 0, osc2Range = 3, osc2Selection = 0, osc2NoteOffset = 0, osc2On = 0,
	osc3Volume = 0, osc3Range = 3, osc3Selection = 0, osc3NoteOffset = 0, osc3On = 0,
	noiseVolume = 0, noiseSelection = 0, noiseOn = 0,
	extVolume = 0, extOn = 0,
	decayOn = 0,
	filterCutoff = 0, filterEmphasis = 0.0, filterKeyboard1 = 0, filterKeyboard2 = 0, filterContour = 0,  filterModOn = 0,
	filterAttack = 0.1, filterDecay = 0.1, filterSustain = 0,
	soundAttack = 0.1, soundDecay = 0.1, soundSustain = 0
	|
	var extBus = Bus.audio;

	var smoothedNote = Select.kr(glideOn, [
		note + bend,
		VarLag.kr(note + bend, glideTime, warp: \lin),
	]);

	var lfo = Select.kr(lfoSelection, [
		LFTri.kr(lfoRate, mul: 0.5, add: 0.5),
		LFPulse.kr(lfoRate),
	]);

	var audioNoise = Select.ar(noiseSelection, [
		WhiteNoise.ar,
		PinkNoise.ar,
	]);

	var modNoise = Select.kr(noiseSelection, [
		PinkNoise.kr(mul: 0.5, add: 0.5),
		BrownNoise.kr(add: 0.5, mul: 0.5),
	]);

	var filterEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: filterAttack,
			decayTime: filterDecay,
			sustainLevel: filterSustain,
			releaseTime: decayOn * filterDecay,
			peakLevel: 10.0,
		),
		gate: gate
	);


	var osc3note = (smoothedNote * osc3Control) + (12 * osc3Range) + osc3NoteOffset;
	var osc3Freq = osc3note.midicps;

	var modComponent0 = Select.kr(osc3FilterEG, [
		(Select.kr(osc3Selection, [
			LFTri.kr(osc3Freq, mul: 0.5, add: 0.5),
			LFSaw.kr(osc3Freq, mul: -0.5, add: 0.5),
			LFSaw.kr(osc3Freq, mul: 0.5, add: 0.5),
			LFPulse.kr(osc3Freq, width: 0.5),
			LFPulse.kr(osc3Freq, width: 0.25),
			LFPulse.kr(osc3Freq, width: 0.05),
		]) * 0.5) + 0.5,
		filterEnv,
	]);
	var modComponent1 = Select.kr(noiseLFO, [
		modNoise,
		lfo,
	]);

	var modSignal = mod * LinSelectX.kr(modMix, [modComponent0, modComponent1]);

	var osc1note = smoothedNote + (12 * osc1Range) + (oscModOn * modSignal * 12);
	var osc1Freq = osc1note.midicps;

	var osc2note = smoothedNote + (12 * osc2Range) + osc2NoteOffset + (oscModOn * modSignal * 12);
	var osc2Freq = osc2note.midicps;

	var osc3noteAudio = ((smoothedNote * osc3Control) + (oscModOn * modSignal * 12)) + (12 * osc3Range) + osc3NoteOffset;
	var osc3FreqAudio = osc3noteAudio.midicps;

	var osc1 = Select.ar(osc1Selection, [
		LFTri.ar(osc1Freq),
		(LFTri.ar(osc1Freq) * LFPulse.ar(osc1Freq * 2)) + (LFSaw.ar(osc1Freq, iphase: 1, mul: -1) * LFPulse.ar(osc1Freq * 2, iphase: 0.5)),
		Saw.ar(osc1Freq),
		Pulse.ar(osc1Freq, width: 0.5),
		Pulse.ar(osc1Freq, width: 0.25),
		Pulse.ar(osc1Freq, width: 0.05),
	]);
	var osc2 = Select.ar(osc2Selection, [
		LFTri.ar(osc2Freq),
		(LFTri.ar(osc2Freq) * LFPulse.ar(osc2Freq * 2)) + (LFSaw.ar(osc2Freq, iphase: 1, mul: -1) * LFPulse.ar(osc2Freq * 2, iphase: 0.5)),
		LFSaw.ar(osc2Freq),
		Pulse.ar(osc2Freq, width: 0.5),
		Pulse.ar(osc2Freq, width: 0.25),
		Pulse.ar(osc2Freq, width: 0.05),
	]);
	var osc3 = Select.ar(osc3Selection, [
		LFTri.ar(osc3FreqAudio),
		LFSaw.ar(osc3FreqAudio, mul: -1),
		LFSaw.ar(osc3FreqAudio),
		Pulse.ar(osc3FreqAudio, width: 0.5),
		Pulse.ar(osc3FreqAudio, width: 0.25),
		Pulse.ar(osc3FreqAudio, width: 0.05),
	]);

	var sound = Mix([
		osc1Volume * LPF.ar(osc1, 10000) * osc1On,
		osc2Volume * LPF.ar(osc2, 10000) * osc2On,
		osc3Volume * LPF.ar(osc3, 10000) * osc3On,
		noiseVolume * audioNoise * noiseOn,
		1 * extVolume * InFeedback.ar(extBus, 1) * extOn,
		WhiteNoise.ar(mul:0.01),
	]);

	var soundEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: soundAttack,
			decayTime: soundDecay,
			sustainLevel: soundSustain,
			releaseTime: decayOn * soundDecay,
		),
		gate: gate
	);

	var filterNote = (filterCutoff * 14.4 + 79) + (((filterKeyboard1 * 1/3) + (filterKeyboard2 * 2/3)) * (smoothedNote-12)) + (((filterEnv * 1.6) + 0.1) * filterContour);

	sound = MoogFF.ar(
		in: sound,
		freq: filterNote.midicps,
		gain: filterEmphasis.linlin(0, 1, 0, 4),
	);

	sound = sound * soundEnv;

	Out.ar(extBus, sound);

	sound = Pan2.ar(amp * sound, 0);
	Out.ar(out, sound);
}).add;

forkIfNeeded {
	s.sync;
	minimoogSynth = Synth(\minimoog, configs.asPairs);
};

window.view.decorator = FlowLayout(window.view.bounds);
window.view.decorator.gap = 5@2;

makeKnob.value(\lfoRate, ControlSpec(0.05, 200, warp: \exp, units: "Hz"));
makePopup.value(\lfoSelection, 80@30, ["Triangle", "Square"]);
makeButton.value(\decayOn, [["Decay Off"], ["Decay On"]], bounds: 80@30);
makeButton.value(\glideOn, [["Glide Off"], ["Glide On"]], bounds: 80@30);
makeKnob.value(\glideTime, ControlSpec(0.01, 10, warp: \exp, units: "s"));

window.view.decorator.nextLine;

makeKnob.value(\mod, ControlSpec(0, 1, units: "u"));
makeButton.value(\osc3FilterEG, [["[OSC3] Filter EG"], ["OSC3 [FilterEG]"]], bounds: 120@30);
makeKnob.value(\modMix, ControlSpec(0, 1, units: "%"));
makeButton.value(\noiseLFO, [["[Noise] LFO"], ["Noise [LFO]"]], bounds: 120@30);
makeButton.value(\oscModOn, [["OSC Mod Off"], ["OSC Mod On"]], bounds: 100@30);

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("OSC 1:").align_(\right);
makePopup.value(\osc1Range, 50@30, ["LO", "32'", "16'", "8'", "4'", "2'"]);
makePopup.value(\osc1Selection, 100@30, ["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"]);
makeKnob.value(\tuneOffset, ControlSpec(-2.5, 2.5, units: "st"));
makeKnob.value(\osc1Volume, ControlSpec(0, 1, units: "u"));
makeButton.value(\osc1On, [["off"], ["on"]]);

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("OSC 2:").align_(\right);
makePopup.value(\osc2Range, 50@30, ["LO", "32'", "16'", "8'", "4'", "2'"]);
makePopup.value(\osc2Selection, 100@30, ["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"]);
makeKnob.value(\osc2NoteOffset, ControlSpec(-8, 8, units: "st"));
makeKnob.value(\osc2Volume, ControlSpec(0, 1, units: "u"));
makeButton.value(\osc2On, [["off"], ["on"]]);


window.view.decorator.nextLine;

StaticText(window, 70@30).string_("OSC 3:").align_(\right);
makePopup.value(\osc3Range, 50@30, ["LO", "32'", "16'", "8'", "4'", "2'"]);
makePopup.value(\osc32election, 100@30, ["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"]);
makeKnob.value(\osc3NoteOffset, ControlSpec(-8, 8, units: "st"));
makeKnob.value(\osc3Volume, ControlSpec(0, 1, units: "u"));
makeButton.value(\osc3On, [["off"], ["on"]]);

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("Noise:").align_(\right);
makePopup.value(\noiseSelection, 100@30, ["White", "Pink"]);
makeKnob.value(\noiseVolume, ControlSpec(0, 1, units: "u"));
makeButton.value(\noiseOn, [["off"], ["on"]]);

StaticText(window, 70@30).string_("External: ").align_(\right);
makeKnob.value(\extVolume, ControlSpec(0, 1, units: "u"));
makeButton.value(\extOn, [["off"], ["on"]]);

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("Filter: ").align_(\right);
makeButton.value(\filterModOn, [["Mod off"], ["Mod on"]]);
makeButton.value(\filterKeyboard1, [["Kbd 0"], ["Kbd 1/3"]]);
makeButton.value(\filterKeyboard2, [["Kbd 0"], ["Kbd 2/3"]]);
makeKnob.value(\filterCutoff, ControlSpec(-5, 5, units: "u"));
makeKnob.value(\filterEmphasis, ControlSpec(0, 1, units: "u"));
makeKnob.value(\filterContour, ControlSpec(0, 10, units: "u"));
makeKnob.value(\filterAttack, ControlSpec(0.01, 10, \exp, units: "s"));
makeKnob.value(\filterDecay, ControlSpec(0.04, 35, \exp, units: "s"));
makeKnob.value(\filterSustain, ControlSpec(0, 1, units: "u"));

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("Loudness: ").align_(\right);
makeKnob.value(\soundAttack, ControlSpec(0.01, 10, \exp, units: "s"));
makeKnob.value(\soundDecay, ControlSpec(0.04, 35, \exp, units: "s"));
makeKnob.value(\soundSustain, ControlSpec(0, 1, units: "u"));
makeKnob.value(\amp, ControlSpec(0, 1.1, units: "u"));

noteOn = MIDIFunc.noteOn({ | velocity, note, channel, something |
	format("Note % on %", note, velocity).postln;
	notesOn.add(note);

 	updateConfig.value(\note, notesOn[0]);
	updateConfig.value(\gate, 1);
});

noteOff = MIDIFunc.noteOff({| velocity, note, channel, something |
	format("Note % off", note, velocity).postln;
	notesOn.removeAt(notesOn.indexOfEqual(note));

 	if ( notesOn.size == 0 ) {
 		updateConfig.value(\gate, 0);
 	} {
 		updateConfig.value(\note, notesOn[0])
 	};
});

bend = MIDIFunc.bend({| value, channel, something |
	format("Bend %", value).postln;
	updateConfig.value(\bend, value.linlin(0, 16383, -7, 7));
});

cc = MIDIFunc.cc({| value, control, channel, something |
	AppClock.sched(0, {

		var rotaryMappings = (
			74: ["Rotary 1", \filterCutoff],
			71: ["Rotary 2", \filterEmphasis],
			76: ["Rotary 3", \filterContour],
			77: ["Rotary 4", \filterSustain],
			93: ["Rotary 5", \lfoRate],
			18: ["Rotary 6", \osc2NoteOffset],
			19: ["Rotary 7", \osc3NoteOffset],
			16: ["Rotary 8", \modMix],
		);

		var directMappings = (
			1: ["Mod", \mod],
			82: ["Slider 1", \osc1Volume],
			83: ["Slider 2", \osc2Volume],
			85: ["Slider 3", \osc3Volume],
			17: ["slider 4", \noiseVolume],
		);

		var buttonMappings = (
			109: ["Pad 1A", nil],
			111: ["Pad 2A", nil],
			113: ["Pad 3A", \osc2On],
			115: ["Pad 4A", \osc1On],
			117: ["Pad 5A", \osc2On],
			119: ["Pad 6A", \osc3On],
			121: ["Pad 7A", \noiseOn],
			123: ["Pad 8A", \extOn],
			110: ["Pad 1B", nil],
			112: ["Pad 2B", nil],
			114: ["Pad 3B", nil],
			116: ["Pad 4B", nil],
			118: ["Pad 5B", nil],
			120: ["Pad 6B", nil],
			122: ["Pad 7B", nil],
			124: ["Pad 8B", nil],
		);

		case
		{ control == 9 } {
			format("Shift = %", value).postln;
			shift = value/127;
		}
		{ control == 21 } {
			format("Knob Button = %", value).postln;
			meta = value/127;
		}
		{ control == 20 } {
			var target = \soundSustain;
			var delta = if (value > 64 ) { if (shift == 1) {0.001} {0.01} } { if (shift == 1) {-0.001} {-0.01} };

			format("Knob = %", value).postln;
			bumpControl.value(target, delta);
		}
		{ rotaryMappings[control] != nil } {
			var name = rotaryMappings[control][0];
			var target = rotaryMappings[control][1];

			var delta = if (value > 64) { if (shift == 1) {-0.001} {-0.01} } { if(shift == 1) {0.001} {0.01} };

			format("% = %", name, value).postln;
			if (target != nil ) { bumpControl.value(target, delta) } { };
		}
		{ directMappings[control] != nil } {
			var name = directMappings[control][0];
			var target = directMappings[control][1];
			format("% = %", name, value).postln;
			setControl.value(target, value.linlin(0, 127, 0, 1));
		}
		{ buttonMappings[control] != nil} {
			var name = buttonMappings[control][0];
			var target = buttonMappings[control][1];
			format("% = %", name, value).postln;
			if (target != nil) { setButton.value(target, value/127) } { };
		}
		{ true } { format("control % = %", control, value).postln };
		nil;
	});
});

window.onClose_({
	var configFile = File(configsFilename, "w");
	configFile.write(configs.asCompileString);
	configFile.close;

	minimoogSynth.free;
	noteOn.free;
	noteOff.free;
	cc.free;
	bend.free;
});

window.front;

CmdPeriod.doOnce({window.close});
)