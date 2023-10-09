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

noteOn = MIDIFunc.noteOn({ | velocity, note, channel, something |
	format("Note % on %", note, velocity).postln;
	setNote.value(note);
	setGate.value(1);
});
noteOff = MIDIFunc.noteOff({| velocity, note, channel, something |
	format("Note % off", note, velocity).postln;
	setGate.value(0);
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
		// osc 2 freq
	}
	{ 19 } {
		format("Rotary 7 = %", value).postln;
		// osc 3 freq
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

SynthDef(\minimoog, { | out=0, note=60, amp=1, gate=0, osc1Volume = 1, osc2Volume = 1, osc3Volume = 1, filterEmphasis=0.0 |
	var noteFreq = note.midicps;

	var osc1 = Saw.ar(noteFreq);
	var osc2 = Pulse.ar(noteFreq);
	var osc3 = LFTri.ar(noteFreq);

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

