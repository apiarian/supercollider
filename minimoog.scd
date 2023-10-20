s.boot;

(
MIDIIn.connectAll;
s.scope;
s.freqscope;
)

(
var window = Window("Minimoog Controls", 600@800);

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
var makePopup = { | control, bounds, items |
	var menu = PopUpMenu(window, bounds);
	menu.items = items;
	menu.action = { | menu | updateConfig.value(control, menu.value) };
	menu.value = configs.at(control);
	controls.put(control, menu);
};
var makeButton = { | control, states |
	var button = Button(window, 50@30);
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

var noteOn;
var noteOff;
var cc;
var bend;

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
		Saw.ar(osc2Freq),
		Pulse.ar(osc2Freq, width: 0.5),
		Pulse.ar(osc2Freq, width: 0.25),
		Pulse.ar(osc2Freq, width: 0.05),
	]);
	var osc3 = Select.ar(osc3Selection, [
		LFTri.ar(osc3FreqAudio),
		LFSaw.ar(osc3FreqAudio, mul: -1),
		Saw.ar(osc3FreqAudio),
		Pulse.ar(osc3FreqAudio, width: 0.5),
		Pulse.ar(osc3FreqAudio, width: 0.25),
		Pulse.ar(osc3FreqAudio, width: 0.05),
	]);

	var sound = Mix([
		osc1Volume * osc1 * osc1On,
		osc2Volume * osc2 * osc2On,
		osc3Volume * osc3 * osc3On,
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
window.view.decorator.gap = 2@2;

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

StaticText(window, 70@30).string_("Filter: ").align_(\right);
makeButton.value(\filterModOn, [["Mod off"], ["Mod on"]]);
makeButton.value(\filterKeyboard1, [["Kbd 0"], ["Kbd 1/3"]]);
makeButton.value(\filterKeyboard2, [["Kbd 0"], ["Kbd 2/3"]]);
makeKnob.value(\filterAttack, ControlSpec(0.01, 10, \exp, units: "s"));
makeKnob.value(\filterDecay, ControlSpec(0.04, 35, \exp, units: "s"));
makeKnob.value(\filterSustain, ControlSpec(0, 1, units: "u"));

window.view.decorator.nextLine;

StaticText(window, 70@30).string_("Loudness: ").align_(\right);
makeKnob.value(\soundAttack, ControlSpec(0.01, 10, \exp, units: "s"));
makeKnob.value(\soundDecay, ControlSpec(0.04, 35, \exp, units: "s"));
makeKnob.value(\soundSustain, ControlSpec(0, 1, units: "u"));

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

// 	HLayout(
// 		Button(window).states_([["OSC Mod Off"], ["OSC Mod On"]]).action_({ | button |
// 			minimoogSynth.set(\oscModOn, button.value)
// 		}),
// 		Button(window).states_([["Decay Off"], ["Decay On"]]).action_({ | button |
// 			minimoogSynth.set(\decayOn, button.value)
// 		}),
// 		Button(window).states_([["Glide Off"], ["Glide On"]]).action_({ | button |
// 			minimoogSynth.set(\glideOn, button.value)
// 		}),
// 		EZKnob(window, 160@40, label: "Glide", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
// 			| k | minimoogSynth.set(\glideTime, k.value);
// 		}, layout: \line2).view,
// 	),
// 	HLayout(
// 		StaticText(window).string_("Mod Selection:"),
// 		Button(window).states_([["[OSC3] Filter EG"], ["OSC3 [Filter EG]"]]).action_({ | button |
// 			minimoogSynth.set(\osc3FilterEG, button.value)
// 		}),
// 		Button(window).states_([["[Noise] LFO"], ["Noise [LFO]"]]).action_({ | button |
// 			minimoogSynth.set(\noiseLFO, button.value)
// 		}),
// 	),
// );
//
// cc = MIDIFunc.cc({| value, control, channel, something |
// 	switch(control)
// 	{ 1 } {
// 		format("Mod = %", value).postln;
// 		minimoogSynth.set(\mod, value.linlin(0, 127, 0, 1));
// 	}
// 	{ 74 } {
// 		format("Rotary 1 = %", value).postln;
// 		setOSC1Volume.value(value.linlin(0, 127, 0, 1));
// 	}
// 	{ 71 } {
// 		format("Rotary 2 = %", value).postln;
// 		setOSC2Volume.value(value.linlin(0, 127, 0, 1));
// 	}
// 	{ 76 } {
// 		format("Rotary 3 = %", value).postln;
// 		setOSC3Volume.value(value.linlin(0, 127, 0, 1));
// 	}
// 	{ 77 } {
// 		format("Rotary 4 = %", value).postln;
// 		minimoogSynth.set(\noiseVolume, value.linlin(0, 127, 0, 1));
// 	}
// 	{ 93 } {
// 		format("Rotary 5 = %", value).postln;
// 		minimoogSynth.set(\lfoRate, value.linexp(0, 127, 0.05, 200));
// 	}
// 	{ 18 } {
// 		format("Rotary 6 = %", value).postln;
// 		if (value == 64) {
// 			minimoogSynth.set(\osc2NoteOffset, 0);
// 		} {
// 			minimoogSynth.set(\osc2NoteOffset, value.linlin(0, 127, -8, 8));
// 		};
// 	}
// 	{ 19 } {
// 		format("Rotary 7 = %", value).postln;
// 		if (value == 64) {
// 			minimoogSynth.set(\osc3NoteOffset, 0);
// 		} {
// 			minimoogSynth.set(\osc3NoteOffset, value.linlin(0, 127, -8, 8));
// 		};
// 	}
// 	{ 16 } {
// 		format("Rotary 8 = %", value).postln;
// 		minimoogSynth.set(\modMix, value.linlin(0, 127, 0, 1));
// 	}
// 	{ 82 } {
// 		format("Slider 1 = %", value).postln;
// 		minimoogSynth.set(\extVolume, value.linlin(0, 127, 0, 1));
// 	}
// 	{ 83 } {
// 		format("Slider 2 = %", value).postln;
// 		minimoogSynth.set(\filterCutoff, value.linlin(0, 127, -5, 5));
// 	}
// 	{ 85 } {
// 		format("Slider 3 = %", value).postln;
// 		setFilterEmphasis.value(value.linlin(0, 127, 0.0, 1.0));
// 	}
// 	{ 17 } {
// 		format("Slider 4 = %", value).postln;
// 		minimoogSynth.set(\filterContour, value.linlin(0, 127, 0, 10));
// 	}
// 	{ 109 } {
// 		format("Pad 1A = %", value).postln;
// 		minimoogSynth.set(\osc3Control, value.linlin(0, 127, 1, 0));
// 	}
// 	{ 111 } {
// 		format("Pad 2A = %", value).postln;
// 		minimoogSynth.set(\osc1On, value/127);
// 	}
// 	{ 113 } {
// 		format("Pad 3A = %", value).postln;
// 		minimoogSynth.set(\osc2On, value/127);
// 	}
// 	{ 115 } {
// 		format("Pad 4A = %", value).postln;
// 		minimoogSynth.set(\osc3On, value/127);
// 	}
// 	{ 117 } {
// 		format("Pad 5A = %", value).postln;
// 		minimoogSynth.set(\noiseOn, value/127);
// 	}
// 	{ 119 } {
// 		format("Pad 6A = %", value).postln;
// 		minimoogSynth.set(\extOn, value/127);
// 	}
// 	{ 121 } {
// 		format("Pad 7A = %", value).postln;
// 		minimoogSynth.set(\lfoSelection, value / 127);
// 	}
// 	{ 123 } {
// 		format("Pad 8A = %", value).postln;
// 		minimoogSynth.set(\noiseSelection, value / 127);
// 	}
// 	{ 110 } {
// 		format("Pad 1B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 112 } {
// 		format("Pad 2B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 114 } {
// 		format("Pad 3B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 116 } {
// 		format("Pad 4B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 118 } {
// 		format("Pad 5B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 120 } {
// 		format("Pad 6B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 122 } {
// 		format("Pad 7B = %", value).postln;
// 		// [unmapped]
// 	}
// 	{ 124 } {
// 		format("Pad 8B = %", value).postln;
// 		// [unmapped]
// 	}
//
// 	{ format("control % = %", control, value).postln };
// });

