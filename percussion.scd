(
// based on the Sound on Sound, Synthecizing Drums: The Bass Drum article
SynthDef(\theoreticalBassDrum, { | out, releaseTime = 0.5, baseFreq = 60, clickReleaseTime = 0.02 |
	var mainAR = EnvGen.kr(Env.perc(releaseTime: releaseTime, curve: -6), doneAction: Done.freeSelf);
	var sound = LPF.ar(Saw.ar(freq: baseFreq + (baseFreq * mainAR)), 2*baseFreq);

	var clickAR = EnvGen.kr(Env.perc(releaseTime: clickReleaseTime, curve: -6), doneAction: Done.none);
	var clickFreq = 110, clickCarPartial = 5, clickModPartial = 1, clickIndex = 10;
	var modulator = SinOsc.ar(clickFreq * clickModPartial, mul: clickFreq * clickIndex);
	var carrier = SinOsc.ar(clickFreq * clickCarPartial + modulator);
	var click = LPF.ar(HPF.ar(carrier, freq:220), baseFreq + (500 * clickAR));

	Out.ar(out, (sound + click * mainAR) ! 2);
}).add;
)

(
~line = PbindProxy(
	\instrument, \theoreticalBassDrum,
);
)

~line.play
~line.set(\dur, 0.5)
~line.stops