s.boot;

(
~gateBus = Bus.control(s, 1).set(0);
)

(
w = Window.new(
	name: "minimoog controls",
);

b = Button(w, Rect(10, 10, 20, 20));
b.string = "G";
b.action_({|button|
	~gateBus.get({|value|
		~gateBus.set((value + 1) % 2);
	});
});

w.front;
)

(
SynthDef.new(\minimoog, {|out=0, mul=1, gate=1|
	var soundEnv = EnvGen.kr(
		envelope: Env.adsr(
			attackTime: 0.01,
			decayTime: 0.5,
			sustainLevel: 0.5,
			releaseTime: 1,
		),
		gate: gate
	);

	Out.ar(out, Pan2.ar(soundEnv * Saw.ar(440, mul), 0));
}).send;

~moog.free;

~moog = Synth(\minimoog, [
	\mul: 0.1,
	\gate: 0,
]);
~moog.map(\gate, ~gateBus);

)
