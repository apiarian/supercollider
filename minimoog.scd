s.boot;

(
MIDIIn.connectAll;
)

(
var window = Window("Minimoog Controls");

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

gateButton = Button(window, Rect(10, 10, 20, 20))
.string_("G")
.action_(toggleGate);

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

StaticText(window, Rect(10, 35, 50, 20)).string_("OSC 1:");
osc1SelectionMenu = PopUpMenu(window, Rect(60, 35, 100, 20))
.items_(["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"])
.action_({ | menu | minimoogSynth.set(\osc1Selection, menu.value) });
osc1RangeMenu = PopUpMenu(window, Rect(170, 35, 50, 20))
.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
.action_({ | menu | minimoogSynth.set(\osc1Range, menu.value) })
.value_(3);

StaticText(window, Rect(10, 60, 50, 20)).string_("OSC 2:");
osc2SelectionMenu = PopUpMenu(window, Rect(60, 60, 100, 20))
.items_(["Triangle", "Tri/Saw", "Sawtooth", "Square", "Rect", "Pulse"])
.action_({ | menu | minimoogSynth.set(\osc2Selection, menu.value) });
osc2RangeMenu = PopUpMenu(window, Rect(170, 60, 50, 20))
.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
.action_({ | menu | minimoogSynth.set(\osc2Range, menu.value) })
.value_(3);

StaticText(window, Rect(10, 85, 50, 20)).string_("OSC 3:");
osc3SelectionMenu = PopUpMenu(window, Rect(60, 85, 100, 20))
.items_(["Triangle", "Rev. Saw", "Sawtooth", "Square", "Rect", "Pulse"])
.action_({ | menu | minimoogSynth.set(\osc3Selection, menu.value) });
osc3RangeMenu = PopUpMenu(window, Rect(170, 85, 50, 20))
.items_(["LO", "32'", "16'", "8'", "4'", "2'"])
.action_({ | menu | minimoogSynth.set(\osc3Range, menu.value) })
.value_(3);

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
		// volume noise
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
		// filter cutoff frequency
	}
	{ 85 } {
		format("Slider 3 = %", value).postln;
		setFilterEmphasis.value(value.linlin(0, 127, 0.0, 1.0));
	}
	{ 17 } {
		format("Slider 4 = %", value).postln;
		// filter amount of contour
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
		// filter keyboard control 1
	}
	{ 123 } {
		format("Pad 8A = %", value).postln;
		// filter keyboard control 2
	}
	{ 110 } {
		format("Pad 1B = %", value).postln;
		// filter modulation
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
		// noise color
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

SynthDef(\minimoog, { |
	out=0,
	note=60, amp=1, gate=0,
	osc1Volume = 1, osc1Range = 3, osc1Selection = 0,
	osc2Volume = 0, osc2Range = 3, osc2Selection = 0, osc2NoteOffset = 0,
	osc3Volume = 0, osc3Range = 3, osc3Selection = 0, osc3NoteOffset = 0,
	filterEmphasis=0.0
	|
	var osc1note = note + (12 * (osc1Range - 3));
	var osc1Freq = osc1note.midicps;

	var osc2note = note + (12 * (osc2Range - 3)) + osc2NoteOffset;
	var osc2Freq = osc2note.midicps;

	var osc3note = note + (12 * (osc3Range - 3)) + osc3NoteOffset;
	var osc3Freq = osc3note.midicps;

	var osc1 = Select.ar(osc1Selection, [
		LFTri.ar(osc1Freq),
		LFTri.ar(osc1Freq, mul: 0.5) + LFSaw.ar(osc1Freq, mul: 0.5),
		Saw.ar(osc1Freq),
		Pulse.ar(osc1Freq, width: 0.5),
		Pulse.ar(osc1Freq, width: 0.25),
		Pulse.ar(osc1Freq, width: 0.05),
	]);
	var osc2 = Select.ar(osc2Selection, [
		LFTri.ar(osc2Freq),
		LFTri.ar(osc2Freq, mul: 0.5) + LFSaw.ar(osc2Freq, mul: 0.5),
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
	]);

	var soundEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: 0.01,
			decayTime: 0.5,
			sustainLevel: 1,
			releaseTime: 1,
		),
		gate: gate
	);

	sound = MoogLadder.ar(
		in: sound,
		ffreq: note.midicps*8,
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


window.onClose_({
	minimoogSynth.free;
	noteOn.free;
	noteOff.free;
	cc.free;
});
CmdPeriod.doOnce({ window.close; });

window.front
)

