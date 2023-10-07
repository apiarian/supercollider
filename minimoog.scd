s.boot;

(
MIDIIn.connectAll;
)

(
var window = Window("Minimoog Controls");
var minimoogSynth;
var noteOn;
var noteOff;

var gate = 0;
var setGate;
var toggleGate;
var gateButton;

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

noteOn = MIDIFunc.noteOn({ | velocity, note, channel, something |
	setGate.value(1);
});
noteOff = MIDIFunc.noteOff({| velocity, note, channel, something |
	setGate.value(0);
});

SynthDef(\minimoog, { | out=0, amp=1, gate=0 |
	var sound = Saw.ar(440, amp);

	var soundEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: 0.01,
			decayTime: 0.5,
			sustainLevel: 0.5,
			releaseTime: 1,
		),
		gate: gate
	);

	sound = sound * soundEnv;

	sound = Pan2.ar(sound, 0);
	Out.ar(out, sound);
}).add;

forkIfNeeded {
	s.sync;
	minimoogSynth = Synth(\minimoog, [
		amp: 0.1,
		gate: gate,
	]);
};


window.onClose_({
	minimoogSynth.free;
	noteOn.free;
	noteOff.free;
});
CmdPeriod.doOnce({ window.close; });

window.front
)

