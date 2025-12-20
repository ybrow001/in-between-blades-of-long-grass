/*~masterBus = Bus.audio(s, 2);

SynthDef.new(\rmsRegulator,
	var sigma, rms, gain;

	// receive input from master bus;
	sigma = In.ar(~masterBus, 2);

	// signal energy regulation using RMS
	rms = Amplitude.kr(sigma, 1.0, 1.0); // input, attack time, release time
	gain = 0.2 / max(rms, 0.001); // loudness: target / current (max() to avoid dividing by 0)
	sigma = sigma * Lag.kr(gain, 1.0); // in, lag time

	// limiting
	sigma = Limiter.ar(sigma, 0.99);

	Out(0, sigma);
).add;*/

~pink = SynthDef.new(\pink, { |amp = 0.33, pan = 0, cutoff = 1000, out = 0|
	var noise, env;

	noise = PinkNoise.ar(amp);

	noise = LPF.ar(noise, cutoff);

	env = EnvGen.kr(
		Env(
			levels: [0.001, 1.0, 0.001],
			times: [5, 20],
			curve: \exps
		),
		doneAction: 2
	);
	noise = noise * env;

	noise = Compander.ar( // may not be necessary
		in: noise,
		control: noise,
		thresh: 0.33,
		slopeBelow: 1.0,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.1
	);

	noise = Pan2.ar(noise, pan);

	// send output to master bus
	Out.ar(out, noise);
}).add;

//  rhythm sequence
/*
- no. voices roughly 8 at a time?
- degree of pan ~9.5deg - avg of MAA (minimum audible angle) between 0 and 90 degrees
  * -1 pan = L, 1 pan = R, 0 = centre. range of 2 from 90deg L to 90deg R
  * 2/180 = 0.0111
  * 0.0111 * 9.5 = 0.1055
  * on avg, a pan of 0.1 should be audible
  * **studies on MAA, seemly not using headphones
*/

~genPatterns = {|instances = 5, cutoffIn = 8000|
	var cutoffDecrement = (cutoffIn-800)/instances;

	~patterns = List[];

	8.do {|i|
		var cutoffPattern = cutoffIn;
		if(cutoffIn <= 2000) {cutoffPattern = 2000}; // safety measure to avoid error in cutoffDecrement

		~patterns.add(Array[ // each dur, pan and cutoff should correspond (equal no. of each)
			List[], // durations
			List[], // panning
			List[], // lpf cutoff
			List[] // amp
		]);

		for(0, instances) {
			cutoffPattern = cutoffPattern - cutoffDecrement;
			/*cutoffPattern = cutoffPattern.clip(400,8000); // contain within specified limits*/
			if(cutoffPattern <= 800) {cutoffPattern = 800};

			~patterns[i][0].add(rrand(20, 50)); // dur
			~patterns[i][1].add(rrand(-0.9, 0.9)); // pan
			~patterns[i][2].add(cutoffPattern); // decrement cutoff
		}
	};

	~patterns
}.value;

~assemblePatterns = {
	~pbPatterns = List[];

	for(0,~patterns.size-1) {|i|
		~pbPatterns.add(Pbind(
			\instrument, \pink,
			\dur, Pseq(~patterns[i][0], inf),
			\pan, Pseq(~patterns[i][1], inf),
			\cutoff, Pseq(~patterns[i][2], inf)
		))
	};

	~pbPatterns.postln;
}.value;


/*~metro = TempoClock.new(1.0);*/

/*
~playPatterns = {
	~pbPatterns.do({|pattern|
		pattern.play(~metro)
	})
};
*/

// ~rmsSynth = Synth(\rmsRegulator, [\out, 0]);

Ppar(~pbPatterns).play;



// pbind/patterns

// metronomes?