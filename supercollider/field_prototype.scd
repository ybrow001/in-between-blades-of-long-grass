~pinkNoise = SynthDef.new(\pinkNoise, { |amp = 0.33, pan = 0, cutoff = 1000, out = 0|
	var noise, env, e;

	noise = PinkNoise.ar(amp);

	noise = LPF.ar(noise, cutoff);
	noise = HPF.ar(noise, 200);

	env = EnvGen.kr(
		e = Env(
			levels: [0.001, 1.0, 0.001],
			times: [5, 20],
			curve: [1.0, -1.0]
		),
		doneAction: 2
	);
	noise = noise * env;

	e.plot();

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

~generatePatterns = {|instances = 5, cutoffIn = 8000|
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

			~patterns[i][0].add(rrand(20, 30)); // dur
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
			\instrument, \pinkNoise,
			\dur, Pseq(~patterns[i][0], inf),
			\pan, Pseq(~patterns[i][1], inf),
			\cutoff, Pseq(~patterns[i][2], inf)
		))
	};

	~pbPatterns.postln;
}.value;


/*~metro = TempoClock.new(1.0);*/

Ppar(~pbPatterns).play;