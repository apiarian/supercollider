{SinOsc.ar(mul:0.1)!2}.play

s.boot

Quarks.gui

ProxySpace.push

(
SynthDef(\hat, {
	| out, amp=1 |
	var audio = WhiteNoise.ar(mul: amp);
	var env = EnvGen.kr(Env.perc(releaseTime: 0.1), doneAction: Done.freeSelf);
	Out.ar(out, audio * env ! 2);
}).add;

SynthDef(\kik, {
	| out, amp=1 |
	var audio = SinOsc.ar(80, mul: amp);
	var env = EnvGen.kr(Env.perc(releaseTime: 0.25), doneAction: Done.freeSelf);
	Out.ar(out, audio ! 2);
}).add;
)

Bjorklund(5, 16).collect({|x| (0: Rest(), 1: 1)[x]})

(
// 16th notes, 32 steps
//         |--------------||--------------|
//                   1         2         3
//         01234567890123456789012345678901
~hatseq = "x       x       x       x       ";
~kikseq = "   x       x       x       x    ";
)

(
~seqfunc = { | sequenceName |
	Pfunc.new({ |e|
		var sequence, idx, val;
		while { true } {
			sequence = currentEnvironment[sequenceName];
			idx = (thisThread.clock.beats * e[\dur].reciprocal).mod(sequence.size);
			val = Array.newFrom(sequence).collect({|x| switch(x)
				{ $x } { 1 }
				{ $  } { Rest() }
				{ Rest() }
			})[idx];
			val.yield
		}
	})
};
)

t = TempoClock.new;
t.tempo = 120/60;
t.permanent = true;

(
~euclidianPseq = { | hits, total, rotation |
	Pseq(Bjorklund(hits, total).collect({|x| (0: Rest(), 1: 1)[x] }).rotate(rotation), inf)
}
)

x = PbindProxy.new;
x.set(\instrument, \kik);
x.set(\gate, ~euclidianPseq.value(9, 16, 0));
x.play;
x.set(\dur, 1/4);

(
var dur = 1/4; // 1/16-th notes
var quant = 8; // 2 4-beat measures

~hat = PbindProxy.new(
	\instrument, \hat,
	\dur, dur,
	\amp, 0.1,
);
~hat.set(\gate, Pseq(Bjorklund(5, 16), inf));
~hat.play(t, quant: quant);
)
(
~kik = PbindProxy(
	\instrument, \kik,
	\dur, dur,
	\gate, ~seqfunc.value(\kikseq),
	\amp, 0.1,
);
~kik.play(t, quant: quant)
)

~hat.free;
~hat.stop;
~hat.set(\gate, Pseq(Bjorklund(2, 16), inf));
~hat.at(\gate)
~hat.play

~hat.mute; ~kik.mute;
~hat.unmute;
~kik.unmute;
