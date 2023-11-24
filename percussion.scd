s.reboot
(
// based on the Sound on Sound, Synthecizing Drums: The Bass Drum article
SynthDef(\theoreticalBassDrum, {
	var baseFreq = \baseFreq.kr(60);
	var releaseTime = \releaseTime.kr(0.5);
	var clickReleaseTime = \clickReleaseTime.kr(0.02);

	var mainAR = EnvGen.kr(Env.perc(releaseTime: releaseTime, curve: -6), doneAction: Done.freeSelf);
	var sound = LPF.ar(Saw.ar(freq: baseFreq + (baseFreq * mainAR)), 2*baseFreq);

	var clickAR = EnvGen.kr(Env.perc(releaseTime: clickReleaseTime, curve: -6), doneAction: Done.none);
	var clickFreq = 110, clickCarPartial = 5, clickModPartial = 1, clickIndex = 10;
	var modulator = SinOsc.ar(clickFreq * clickModPartial, mul: clickFreq * clickIndex);
	var carrier = SinOsc.ar(clickFreq * clickCarPartial + modulator);
	var click = LPF.ar(HPF.ar(carrier, freq: 220), baseFreq + (500 * clickAR));

	Out.ar(\out.kr(-1), Pan2.ar((sound + click * mainAR), \pan.kr(0)));
}).add;
)

Synth(\theoreticalBassDrum)

Pdef(\x).play

(
Pdef(\beats, Pbind(
	\instrument, \theoreticalBassDrum,
	\dur, Pseq([0.5, 0.25, 0.25], inf),
	\baseFreq, Pseq([60, 50, 40], inf),
	\releaseTime, Pseq([0.5, 0.25, 0.9], inf),
	\clickReleaseTime, Pseq([0.02, 0.01, 0.1], inf),
)).quant_(4)
)

Pdef(\beats).play
