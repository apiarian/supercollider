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
	note=60, amp=1, gate=0, mod = 0,
	osc1Volume = 0, osc1Range = 3, osc1Selection = 0,
	osc2Volume = 0, osc2Range = 3, osc2Selection = 0, osc2NoteOffset = 0,
	osc3Volume = 0, osc3Range = 3, osc3Selection = 0, osc3NoteOffset = 0,
	noiseVolume = 0, noiseSelection = 0,
	decayOn = 0,
	filterCutoff = 0, filterEmphasis = 0.0, filterKeyboard1 = 0, filterKeyboard2 = 0, filterContour = 0,  filterModOn = 0,
	filterAttack = 0.1, filterDecay = 0.1, filterSustain = 0,
	soundAttack = 0.1, soundDecay = 0.1, soundSustain = 0
	|

	var audioNoise = Select.ar(noiseSelection, [
		WhiteNoise.ar,
		PinkNoise.ar,
	]);

	var osc1note = note + (12 * (osc1Range - 3));
	var osc1Freq = osc1note.midicps;

	var osc2note = note + (12 * (osc2Range - 3)) + osc2NoteOffset;
	var osc2Freq = osc2note.midicps;

	var osc3note = note + (12 * (osc3Range - 3)) + osc3NoteOffset;
	var osc3Freq = osc3note.midicps;

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
		LFTri.ar(osc3Freq),
		LFSaw.ar(osc3Freq, mul: -1),
		Saw.ar(osc3Freq),
		Pulse.ar(osc3Freq, width: 0.5),
		Pulse.ar(osc3Freq, width: 0.25),
		Pulse.ar(osc3Freq, width: 0.05),
	]);

	var sound = Mix([
		osc1Volume * osc1,
		osc2Volume * osc2,
		osc3Volume * osc3,
		noiseVolume * audioNoise,
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

	var filterEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: filterAttack,
			decayTime: filterDecay,
			sustainLevel: filterSustain,
			releaseTime: decayOn * filterDecay,
		),
		gate: gate
	);

	var filterNote = filterCutoff + (filterEnv * filterContour) + (filterKeyboard1 * 1/3 * note) + (filterKeyboard2 * 2/3 * note) + (filterModOn * mod * 127);

	sound = MoogLadder.ar(
		in: sound,
		ffreq: filterNote.midicps,
		res: filterEmphasis,
	);

	sound = amp * sound * soundEnv;

	sound = Pan2.ar(sound, 0);
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
	Button(window).states_([["Decay Off"], ["Decay On"]]).action_({ | button |
		minimoogSynth.set(\decayOn, button.value)
	}),
	StaticText(window).string_("Filter:"),
	HLayout(
		EZKnob(window, 160@40, label: "Attack", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\filterAttack, k.value);
		}, layout: \horz).view,
		EZKnob(window, 160@40, label: "Decay", controlSpec: ControlSpec(0.04, 35, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\filterDecay, k.value);
		}, layout:\horz).view,
		EZKnob(window, 160@40, label: "Sustain", controlSpec: ControlSpec(0, 1, units: "%"), action: {
			| k | minimoogSynth.set(\filterSustain, k.value);
		}, layout: \horz,).view,
	),
	StaticText(window).string_("Loudness:"),
	HLayout(
		EZKnob(window, 160@40, label: "Attack", controlSpec: ControlSpec(0.01, 10, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\soundAttack, k.value);
		}, layout: \horz).view,
		EZKnob(window, 160@40, label: "Decay", controlSpec: ControlSpec(0.04, 35, \exp, units: "s"), action: {
			| k | minimoogSynth.set(\soundDecay, k.value);
		}, layout:\horz).view,
		EZKnob(window, 160@40, label: "Sustain", controlSpec: ControlSpec(0, 1, units: "%"), action: {
			| k | minimoogSynth.set(\soundSustain, k.value);
		}, layout: \horz, initVal: 1, initAction: true).view,
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
		// lfo rate
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
		// mod mix
	}
	{ 82 } {
		format("Slider 1 = %", value).postln;
		// volume ext.
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
		// oscillator modulation
	}
	{ 111 } {
		format("Pad 2A = %", value).postln;
		// osc 1 mix
	}
	{ 113 } {
		format("Pad 3A = %", value).postln;
		// osc 2 mix
	}
	{ 115 } {
		format("Pad 4A = %", value).postln;
		// osc 3 mix
	}
	{ 117 } {
		format("Pad 5A = %", value).postln;
		// noise mix
	}
	{ 119 } {
		format("Pad 6A = %", value).postln;
		// ext. mix
	}
	{ 121 } {
		format("Pad 7A = %", value).postln;
		minimoogSynth.set(\filterKeyboard1, value / 127);
	}
	{ 123 } {
		format("Pad 8A = %", value).postln;
		minimoogSynth.set(\filterKeyboard2, value / 127);
	}
	{ 110 } {
		format("Pad 1B = %", value).postln;
		minimoogSynth.set(\filterModOn, value / 127);
	}
	{ 112 } {
		format("Pad 2B = %", value).postln;
		// lfo shape
	}
	{ 114 } {
		format("Pad 3B = %", value).postln;
		// [unmapped]
	}
	{ 116 } {
		format("Pad 4B = %", value).postln;
		// osc 3 control
	}
	{ 118 } {
		format("Pad 5B = %", value).postln;
		minimoogSynth.set(\noiseSelection, value / 127);
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

