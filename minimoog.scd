s.boot;

(
var window = Window("Minimoog Controls");
var minimoogSynth;

var gate = 0;
var toggleGate;
var gateButton;

toggleGate = {
	if(gate == 0, { gate = 1 }, { gate = 0 });
	minimoogSynth.set(\gate, gate);
};

gateButton = Button(window, Rect(10, 10, 20, 20))
.string_("G")
.action_(toggleGate);

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


window.onClose_({ minimoogSynth.free; });
CmdPeriod.doOnce({ window.close; });

window.front
)

