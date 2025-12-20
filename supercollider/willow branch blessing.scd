
~voice1 = SynthDef.new(\voice1, {
	arg freq = 261, amp = 0.3, out = 0, pan = 0;
	var voice, env;
	voice = LFTri.ar(freq);
	env = EnvGen.kr(
		Env(
		[0.001, 1, 0.001],
		[3, 5],
		[3, -2.5]
		),
		doneAction: 2
	);
	voice = voice * env;
	voice = voice * amp;
	voice = Pan2.ar(voice, pan);
	Out.ar(out, voice);
}).add;

// trigger individual notes with unique envelopes


~majPentFreqs = {|root = 261|
	var supmaj77Degrees, supmaj77Freqs, upSupmaj77Degrees, upSupmaj77Freqs, edo77,
	supmaj94Degrees, supmaj94Freqs, upSupmaj94Degrees, upSupmaj94Freqs, edo94,
	supmaj99Degrees, supmaj99Freqs, upSupmaj99Degrees, upSupmaj99Freqs, edo99,
	supmaj88Degrees, supmaj88Freqs, upSupmaj88Degrees, upSupmaj88Freqs, edo88,
	supmaj53Degrees, supmaj53Freqs, upSupmaj53Degrees, upSupmaj53Freqs, edo53,
	supmaj66Degrees, supmaj66Freqs, upSupmaj66Degrees, upSupmaj66Freqs, edo66;

	supmaj77Degrees = [0, 15, 28, 45, 60, 77];
	supmaj77Freqs = supmaj77Degrees.collect {|deg| root * (2 ** (deg/77))};
	upSupmaj77Degrees = [0, 16, 29, 45, 61, 77 /*78, 80*/];
	upSupmaj77Freqs = upSupmaj77Degrees.collect {|deg| root * (2 ** (deg/77))};

	edo77 = [supmaj77Freqs, upSupmaj77Freqs];

	supmaj94Degrees = [0, 18, 34, 55, 73, 94];
	supmaj94Freqs = supmaj94Degrees.collect {|deg| root * (2 ** (deg/94))};
	upSupmaj94Degrees = [0, 19, 35, 55, 74, 94 /*95, 98*/];
	upSupmaj94Freqs = upSupmaj94Degrees.collect {|deg| root * (2 ** (deg/94))};

	edo94 = [supmaj94Freqs, upSupmaj94Freqs];

	supmaj99Degrees = [0, 19, 36, 58, 77, 99];
	supmaj99Freqs = supmaj99Degrees.collect {|deg| root * (2 ** (deg/99))};
	upSupmaj99Degrees = [0, 20, 37, 59, 78, 99 /*100, 103*/];
	upSupmaj99Freqs = upSupmaj99Degrees.collect {|deg| root * (2 ** (deg/99))};

	edo99 = [supmaj99Freqs, upSupmaj99Freqs];

	supmaj88Degrees = [0, 17, 32, 52, 69, 88];
	supmaj88Freqs = supmaj88Degrees.collect {|deg| root * (2 ** (deg/88))};
	upSupmaj88Degrees = [0, 18, 33, 52, 70, 88 /* 89, 92*/];
	upSupmaj88Freqs = upSupmaj88Degrees.collect {|deg| root * (2 ** (deg/88))};

	edo88 = [supmaj88Freqs, upSupmaj88Freqs];

	supmaj53Degrees = [0, 10, 19, 31, 41, 53];
	supmaj53Freqs = supmaj53Degrees.collect {|deg| root * (2 ** (deg/53))};
	upSupmaj53Degrees = [0, 11, 20, 31, 42, 53 /*54, 55*/];
	upSupmaj53Freqs = upSupmaj53Degrees.collect {|deg| root * (2 ** (deg/53))};

	edo53 = [supmaj53Freqs, upSupmaj53Freqs];

	supmaj66Degrees = [0, 13, 24, 39, 52, 66];
	supmaj66Freqs = supmaj66Degrees.collect {|deg| root * (2 ** (deg/66))};
	upSupmaj66Degrees = [0, 14, 25, 39, 53, 66 /*67, 69*/];
	upSupmaj66Freqs = upSupmaj66Degrees.collect {|deg| root * (2 ** (deg/66))};

	edo66 = [supmaj66Freqs, upSupmaj66Freqs];

	[edo77, edo94, edo99, edo88, edo53, edo66];
}.value;

~noteSeq = {
	var noteSeq1 = List[List[], List[]],
	noteDur1 = List[List[], List[]],
	notePan1 = List[List[], List[]],
	noteSeq2 = List[List[], List[]],
	noteDur2 = List[List[], List[]],
	notePan2 = List[List[], List[]],
	bassFreq = List[],
	bassDur = List[],
	bassPan = List[];

	20.do {
		for(0,1){|i|
			noteSeq1[i].add(~majPentFreqs.choose.choose.choose);
			noteDur1[i].add(rrand(0.5, 2));
			notePan1[i].add(rrand(-0.9, 0.25));

			noteSeq2[i].add(~majPentFreqs.choose.choose.choose);
			noteDur2[i].add(rrand(0.5, 2));
			notePan2[i].add(rrand(-0.25, 0.9));
		};

		bassFreq.add(rrand(130, 132));
		bassDur.add(rrand(5, 7.5));
		bassPan.add(rrand(-0.25, 0.25));
	};

	[[noteSeq1, noteSeq2], [noteDur1, noteDur2], [notePan1, notePan2], [bassFreq, bassDur, bassPan]]
}.value;

~playNote1 = Pbind(
	\instrument, \voice1,
	\freq, Pseq(~noteSeq[0][0][0], inf),
	\dur, Pseq(~noteSeq[1][0][0], inf),
	\amp, 0.05,
	\pan, Pseq(~noteSeq[2][0][0], inf)
);

~playNoteHigh1 = Pbind(
	\instrument, \voice1,
	\freq, Pseq(~noteSeq[0][0][1]*2, inf),
	\dur, Pseq(~noteSeq[1][0][1], inf),
	\amp, 0.01,
	\pan, Pseq(~noteSeq[2][0][1], inf)
);

~playNote2 = Pbind(
	\instrument, \voice1,
	\freq, Pseq(~noteSeq[0][1][0], inf),
	\dur, Pseq(~noteSeq[1][1][0], inf),
	\amp, 0.05,
	\pan, Pseq(~noteSeq[2][1][0], inf)
);

~playNoteHigh2 = Pbind(
	\instrument, \voice1,
	\freq, Pseq(~noteSeq[0][0][1]*2, inf),
	\dur, Pseq(~noteSeq[1][0][1], inf),
	\amp, 0.01,
	\pan, Pseq(~noteSeq[2][0][1], inf)
);

~playBass = Pbind(
	\instrument, \voice1,
	\freq, Pseq(~noteSeq[3][0], inf),
	\dur, Pseq(~noteSeq[3][1], inf),
	\amp, 0.075,
	\pan, Pseq(~noteSeq[3][2], inf)
);

~playNoteHigh1.play;
~playNoteHigh2.play;
~playNote1.play;
~playNote2.play;
~playBass.play;

/*
ideas / things to do:

- use l-system to arrange; panning, voice amp, timbre, etc?
  - may need a large l-system tree to have many notes at a given time
  - notes can be triggered at any point along a branch (freq of triggering down to probability?)
  - OR notes only play at the ends of branches (leaves/flowers), branches determine pan, amp, etc

- this piece may need its own l-system (each of willow branch, field recordings and visual may need their own to fit their own unique qualities
- this piece needs an l-system with more branches and density over a longer time
*/