s.boot;

(
MIDIIn.connectAll;
s.scope;
s.freqscope;
)

(
var window = Window("Minimoog Controls", 700@400);

var minimoogSynth;
var noteOn;
var noteOff;
var cc;
var bend;

var notesOn = SortedList.new;

var gate = 0;
var setGate;
var toggleGate;
var gateButton;

var note = 60;
var setNote;

var setFilterEmphasis;

var setOSC1Volume;
var setOSC2Volume;
var setOSC3Volume;

var osc1SelectionMenu;
var osc2SelectionMenu;
var osc3SelectionMenu;

var osc1RangeMenu;
var osc2RangeMenu;
var osc3RangeMenu;

SynthDef(\minimoog, { |
	out=0,
	note=60, bend = 0, amp=1, gate=0, glideOn = 0, glideTime = 0.01,
	mod = 0, osc3FilterEG = 0, noiseLFO = 0, modMix = 0.5, lfoRate = 0.05, lfoSelection = 0,
	oscModOn = 0,
	osc1Volume = 0, osc1Range = 3, osc1Selection = 0, osc1On = 0, osc3Control = 1,
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
		),
		gate: gate
	);


	var osc3note = (smoothedNote * osc3Control) + (12 * (osc3Range - 3)) + osc3NoteOffset;
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

	var osc1note = smoothedNote + (12 * (osc1Range - 3)) + (oscModOn * modSignal * 12);
	var osc1Freq = osc1note.midicps;

	var osc2note = smoothedNote + (12 * (osc2Range - 3)) + osc2NoteOffset + (oscModOn * modSignal * 12);
	var osc2Freq = osc2note.midicps;

	var osc3noteAudio = ((smoothedNote * osc3Control) + (oscModOn * modSignal * 12)) + (12 * (osc3Range - 3)) + osc3NoteOffset;
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

	var filterNote = filterCutoff + (filterEnv * filterContour) + (filterKeyboard1 * 1/3 * smoothedNote) + (filterKeyboard2 * 2/3 * smoothedNote) + (filterModOn * modSignal * 127);

	sound = MoogLadder.ar(
		in: sound,
		ffreq: filterNote.midicps,
		res: filterEmphasis,
	);

	sound = sound * soundEnv;

	Out.ar(extBus, sound);

	sound = Pan2.ar(amp * sound, 0);
	Out.ar(out, sound);
}).add;

forkIfNeeded {
	s.sync;
	minimoogSynth = Synth(\minimoog, [
		amp: 0.5,
	]);
};

setGate = { | value |
	gate = value;
	minimoogSynth.set(\gate, gate);
};
toggleGate = {
	if(gate == 0) {
		setGate.value(1);
	} {
		setGate.value(0);
	};
};

setNote = { | value |
	note = value;
	minimoogSynth.set(\note, note);
};

setFilterEmphasis = { | value |
	minimoogSynth.set(\filterEmphasis, value);
};

setOSC1Volume = { | value |
	minimoogSynth.set(\osc1Volume, value);
};
setOSC2Volume = { | value |
	minimoogSynth.set(\osc2Volume, value);
};
setOSC3Volume = { | value |
	minimoogSynth.set(\osc3Volume, value);
};

window.layout = VLayout(
	HLayout(
		StaticText(window).string_("OSC 1:"),
		osc1SelectionMenu = PopUpMenu(window)
		.items_(["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"])
		.action_({ | menu | minimoogSynth.set(\osc1Selection, menu.value) }),
		osc1RangeMenu = PopUpMenu(window)
		.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
		.action_({ | menu | minimoogSynth.set(\osc1Range, menu.value) })
		.value_(3),
	),
	HLayout(
		StaticText(window).string_("OSC 2:"),
		osc2SelectionMenu = PopUpMenu(window)
		.items_(["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"])
		.action_({ | menu | minimoogSynth.set(\osc2Selection, menu.value) }),
		osc2RangeMenu = PopUpMenu(window)
		.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
		.action_({ | menu | minimoogSynth.set(\osc2Range, menu.value) })
		.value_(3),
	),
	HLayout(
		StaticText(window).string_("OSC 3:"),
		osc3SelectionMenu = PopUpMenu(window)
		.items_(["Triangle", "Rev. Saw", "Sawtooth", "Square", "Rect", "Pulse"])
		.action_({ | menu | minimoogSynth.set(\osc3Selection, menu.value) }),
		osc3RangeMenu = PopUpMenu(window)
		.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
		.action_({ | menu | minimoogSynth.set(\osc3Range, menu.value) })
		.value_(3),
	),
	HLayout(
		Button(window).states_([["OSC Mod Off"], ["OSC Mod On"]]).action_({ | button |
			minimoogSynth.set(\oscModOn, button.value)
		}),
		Button(window).states_([["Decay Off"], ["Decay On"]]).action_({ | button |
			minimoogSynth.set(\decayOn, button.value)
		}),
		Button(window).states_([["Glide Off"], ["Glide On"]]).action_({ | button |
			minimoogSynth.set(\glideOn, button.value)
		}),
		EZKnob(window, 160@40, label: "Glide", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\glideTime, k.value);
		}, layout: \line2).view,
	),
	HLayout(
		StaticText(window).string_("Mod Selection:"),
		Button(window).states_([["[OSC3] Filter EG"], ["OSC3 [Filter EG]"]]).action_({ | button |
			minimoogSynth.set(\osc3FilterEG, button.value)
		}),
		Button(window).states_([["[Noise] LFO"], ["Noise [LFO]"]]).action_({ | button |
			minimoogSynth.set(\noiseLFO, button.value)
		}),
	),
	HLayout(
		StaticText(window).string_("Filter:"),
		Button(window).states_([["Mod Off"], ["Mod On"]]).action_({ | button |
			minimoogSynth.set(\filterModOn, button.value)
		}),
		Button(window).states_([["Kbd 0"], ["Kbd 1/3"]]).action_({ | button |
			minimoogSynth.set(\filterKeyboard1, button.value)
		}),
		Button(window).states_([["Kbd 0"], ["Kbd 2/3"]]).action_({ | button |
			minimoogSynth.set(\filterKeyboard2, button.value)
		}),
	),
	HLayout(
		EZKnob(window, 160@40, label: "Attack", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\filterAttack, k.value);
		}, layout: \line2).view,
		EZKnob(window, 160@40, label: "Decay", controlSpec: ControlSpec(0.04, 35, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\filterDecay, k.value);
		}, layout:\line2).view,
		EZKnob(window, 160@40, label: "Sustain", controlSpec: ControlSpec(0, 1, units: "%"), action: {
			| k | minimoogSynth.set(\filterSustain, k.value);
		}, layout: \line2,).view,
	),
	StaticText(window).string_("Loudness:"),
	HLayout(
		EZKnob(window, 160@40, label: "Attack", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\soundAttack, k.value);
		}, layout: \line2).view,
		EZKnob(window, 160@40, label: "Decay", controlSpec: ControlSpec(0.04, 35, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\soundDecay, k.value);
		}, layout: \line2).view,
		EZKnob(window, 160@40, label: "Sustain", controlSpec: ControlSpec(0, 1, units: "%"), action: {
			| k | minimoogSynth.set(\soundSustain, k.value);
		}, layout: \line2).view,
	),
);


noteOn = MIDIFunc.noteOn({ | velocity, note, channel, something |
	format("Note % on %", note, velocity).postln;
	notesOn.add(note);

	setNote.value(notesOn[0]);
	setGate.value(1);
});

noteOff = MIDIFunc.noteOff({| velocity, note, channel, something |
	format("Note % off", note, velocity).postln;
	notesOn.removeAt(notesOn.indexOfEqual(note));

	if ( notesOn.size == 0 ) {
		setGate.value(0);
	} {
		setNote.value(notesOn[0])
	};
});

bend = MIDIFunc.bend({| value, channel, something |
	format("Bend %", value).postln;
	minimoogSynth.set(\bend, value.linlin(0, 16383, -7, 7));
});

cc = MIDIFunc.cc({| value, control, channel, something |
	switch(control)
	{ 1 } {
		format("Mod = %", value).postln;
		minimoogSynth.set(\mod, value.linlin(0, 127, 0, 1));
	}
	{ 74 } {
		format("Rotary 1 = %", value).postln;
		setOSC1Volume.value(value.linlin(0, 127, 0, 1));
	}
	{ 71 } {
		format("Rotary 2 = %", value).postln;
		setOSC2Volume.value(value.linlin(0, 127, 0, 1));
	}
	{ 76 } {
		format("Rotary 3 = %", value).postln;
		setOSC3Volume.value(value.linlin(0, 127, 0, 1));
	}
	{ 77 } {
		format("Rotary 4 = %", value).postln;
		minimoogSynth.set(\noiseVolume, value.linlin(0, 127, 0, 1));
	}
	{ 93 } {
		format("Rotary 5 = %", value).postln;
		minimoogSynth.set(\lfoRate, value.linexp(0, 127, 0.05, 200));
	}
	{ 18 } {
		format("Rotary 6 = %", value).postln;
		if (value == 64) {
			minimoogSynth.set(\osc2NoteOffset, 0);
		} {
			minimoogSynth.set(\osc2NoteOffset, value.linlin(0, 127, -8, 8));
		};
	}
	{ 19 } {
		format("Rotary 7 = %", value).postln;
		if (value == 64) {
			minimoogSynth.set(\osc3NoteOffset, 0);
		} {
			minimoogSynth.set(\osc3NoteOffset, value.linlin(0, 127, -8, 8));
		};
	}
	{ 16 } {
		format("Rotary 8 = %", value).postln;
		minimoogSynth.set(\modMix, value.linlin(0, 127, 0, 1));
	}
	{ 82 } {
		format("Slider 1 = %", value).postln;
		minimoogSynth.set(\extVolume, value.linlin(0, 127, 0, 1));
	}
	{ 83 } {
		format("Slider 2 = %", value).postln;
		minimoogSynth.set(\filterCutoff, value);
	}
	{ 85 } {
		format("Slider 3 = %", value).postln;
		setFilterEmphasis.value(value.linlin(0, 127, 0.0, 1.0));
	}
	{ 17 } {
		format("Slider 4 = %", value).postln;
		minimoogSynth.set(\filterContour, value.linlin(0, 127, 0.0, 2));
	}
	{ 109 } {
		format("Pad 1A = %", value).postln;
		minimoogSynth.set(\osc3Control, value.linlin(0, 127, 1, 0));
	}
	{ 111 } {
		format("Pad 2A = %", value).postln;
		minimoogSynth.set(\osc1On, value/127);
	}
	{ 113 } {
		format("Pad 3A = %", value).postln;
		minimoogSynth.set(\osc2On, value/127);
	}
	{ 115 } {
		format("Pad 4A = %", value).postln;
		minimoogSynth.set(\osc3On, value/127);
	}
	{ 117 } {
		format("Pad 5A = %", value).postln;
		minimoogSynth.set(\noiseOn, value/127);
	}
	{ 119 } {
		format("Pad 6A = %", value).postln;
		minimoogSynth.set(\extOn, value/127);
	}
	{ 121 } {
		format("Pad 7A = %", value).postln;
		minimoogSynth.set(\lfoSelection, value / 127);
	}
	{ 123 } {
		format("Pad 8A = %", value).postln;
		minimoogSynth.set(\noiseSelection, value / 127);
	}
	{ 110 } {
		format("Pad 1B = %", value).postln;
		// [unmapped]
	}
	{ 112 } {
		format("Pad 2B = %", value).postln;
		// [unmapped]
	}
	{ 114 } {
		format("Pad 3B = %", value).postln;
		// [unmapped]
	}
	{ 116 } {
		format("Pad 4B = %", value).postln;
		// [unmapped]
	}
	{ 118 } {
		format("Pad 5B = %", value).postln;
		// [unmapped]
	}
	{ 120 } {
		format("Pad 6B = %", value).postln;
		// [unmapped]
	}
	{ 122 } {
		format("Pad 7B = %", value).postln;
		// [unmapped]
	}
	{ 124 } {
		format("Pad 8B = %", value).postln;
		// [unmapped]
	}

	{ format("control % = %", control, value).postln };
});


window.onClose_({
	minimoogSynth.free;
	noteOn.free;
	noteOff.free;
	cc.free;
});
CmdPeriod.doOnce({ window.close; });

window.front
)

