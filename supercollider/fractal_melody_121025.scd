// leaf flutter - līf flȧte | flattering - flȧtering līvs

~melodyVoice = SynthDef.new(\melodyVoice, {
	arg freq = 261, amp = 0.3, out = 0, pan = 0;
	var voice, env;
	voice = SinOsc.ar(freq);
	env = EnvGen.kr(
		Env(
		[0.001, 1, 0.001],
		[0.1, 1.5],
		[3, -2.5]
		),
		doneAction: 2
	);
	voice = voice * env;
	voice = voice * amp;
	voice = Pan2.ar(voice, pan);
	Out.ar(out, voice);
}).add;

~accompVoice = SynthDef.new(\accompVoice, {
	arg freq = 261, amp = 0.3, out = 0;
	var voice, env;
	voice = SinOsc.ar(freq) ! 2;
	env = EnvGen.kr(
		Env(
		[0.001, 1, 0.001],
		[2, 3],
		[3, -2.5]
		),
		doneAction: 2
	);
	voice = voice * env;
	voice = voice * amp;
	Out.ar(out, voice);
}).add;

~rhythmicModes = [ // 0.5 = 1/8 - metre for each mode 5/8 (total 2.5) - to be combined as pairs in 5/4
	[2.5],
	[1.5, 1],
	[1, 1.5],
	[2, 0.5],
	[0.5, 2],
	[1, 1, 0.5],
	[0.5, 1, 1],
	[1, 0.5, 1],
	[1.5, 0.5, 0.5],
	[0.5, 1.5, 0.5],
	[0.5, 0.5, 1.5],
	[0.5, 0.5, 0.5, 0.5],
	[0.5, 0.5, 0.5, 0.5, 0.5]
];

~rhythmProbs = [
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[],
	[]
];

~allFreqs = {|root = 261|
	var supmaj77Degrees, supmaj77Freqs, upSupmaj77Degrees, upSupmaj77Freqs, edo77,
	supmaj94Degrees, supmaj94Freqs, upSupmaj94Degrees, upSupmaj94Freqs, edo94,
	supmaj99Degrees, supmaj99Freqs, upSupmaj99Degrees, upSupmaj99Freqs, edo99,
	supmaj88Degrees, supmaj88Freqs, upSupmaj88Degrees, upSupmaj88Freqs, edo88,
	supmaj53Degrees, supmaj53Freqs, upSupmaj53Degrees, upSupmaj53Freqs, edo53,
	supmaj66Degrees, supmaj66Freqs, upSupmaj66Degrees, upSupmaj66Freqs, edo66;

	supmaj77Degrees = [-6, 0, 15, 28, 35, 45, 60, 71, 77];
	supmaj77Freqs = supmaj77Degrees.collect {|deg| root * (2 ** (deg/77))};
	upSupmaj77Degrees = [-5, 0, 16, 29, 35, 45, 61, 72, 77 /*78, 80*/];
	upSupmaj77Freqs = upSupmaj77Degrees.collect {|deg| root * (2 ** (deg/77))};

	edo77 = [supmaj77Freqs, upSupmaj77Freqs];

	supmaj94Degrees = [-5, 0, 18, 34, 43, 55, 73, 89, 94];
	supmaj94Freqs = supmaj94Degrees.collect {|deg| root * (2 ** (deg/94))};
	upSupmaj94Degrees = [-4, 0, 19, 35, 43, 55, 74, 90, 94 /*95, 98*/];
	upSupmaj94Freqs = upSupmaj94Degrees.collect {|deg| root * (2 ** (deg/94))};

	edo94 = [supmaj94Freqs, upSupmaj94Freqs];

	supmaj99Degrees = [-5, 0, 19, 36, 45, 58, 77, 94, 99];
	supmaj99Freqs = supmaj99Degrees.collect {|deg| root * (2 ** (deg/99))};
	upSupmaj99Degrees = [-4, 0, 20, 37, 46, 59, 78, 95, 99 /*100, 103*/];
	upSupmaj99Freqs = upSupmaj99Degrees.collect {|deg| root * (2 ** (deg/99))};

	edo99 = [supmaj99Freqs, upSupmaj99Freqs];

	supmaj88Degrees = [-4, 0, 17, 32, 40, 52, 69, 84, 88];
	supmaj88Freqs = supmaj88Degrees.collect {|deg| root * (2 ** (deg/88))};
	upSupmaj88Degrees = [-3, 0, 18, 33, 40, 52, 70, 85, 88 /* 89, 92*/];
	upSupmaj88Freqs = upSupmaj88Degrees.collect {|deg| root * (2 ** (deg/88))};

	edo88 = [supmaj88Freqs, upSupmaj88Freqs];

	supmaj53Degrees = [-3, 0, 10, 19, 24, 31, 41, 50, 53];
	supmaj53Freqs = supmaj53Degrees.collect {|deg| root * (2 ** (deg/53))};
	upSupmaj53Degrees = [-2, 0, 11, 20, 24, 31, 42, 51, 53 /*54, 55*/];
	upSupmaj53Freqs = upSupmaj53Degrees.collect {|deg| root * (2 ** (deg/53))};

	edo53 = [supmaj53Freqs, upSupmaj53Freqs];

	supmaj66Degrees = [-3, 0, 13, 24, 30, 39, 52, 63, 66];
	supmaj66Freqs = supmaj66Degrees.collect {|deg| root * (2 ** (deg/66))};
	upSupmaj66Degrees = [-2, 0, 14, 25, 30, 39, 53, 64, 66 /*67, 69*/];
	upSupmaj66Freqs = upSupmaj66Degrees.collect {|deg| root * (2 ** (deg/66))};

	edo66 = [supmaj66Freqs, upSupmaj66Freqs];

	[edo77, edo94, edo99, edo88, edo53, edo66];
}.value;

~noteProbs = {
	// each index probs[i][] is the previous note (scale degree asc order), each index probs[][i] is the probability of the next note in the seq based on the prev

	var noteProbsOn, noteProbsOff, noteProbsEndQ, noteProbsEndA;

	noteProbsOn = [ // if on the beat
		[0.0626, 0.0039, 0.501, 0.2505, 0.1252, 0.0313, 0.0078, 0.0156, 0.002], /* if 7 below (-7)
		- most likely 2, 3, 4, -7, 5, 7, 6, 1, 8 */
		[0.2505, 0.0039, 0.0156, 0.501, 0.1252, 0.0626, 0.0078, 0.0313, 0.002], /* if 1
		- most likely 3, -7, 4, 5, 7, 2, 6, 8, 1 */
		[0.2505, 0.0078, 0.002, 0.1252, 0.501, 0.0156, 0.0626, 0.0313, 0.0039], /* if 2
		- most likely 4, -7, 3, 6, 7, 5, 1, 8, 2 */
		[0.2505, 0.0039, 0.0313, 0.0078, 0.501, 0.0626, 0.0156, 0.1252, 0.002], /* if 3
		- most likely 4, -7, 7, 5, 2, 6, 3, 1, 8 */
		[0.0626, 0.0039, 0.0313, 0.501, 0.0078, 0.2505, 0.0156, 0.1252, 0.002], /* if 4
		- most likely 3, 5, 7, -7, 2, 6, 4, 1, 8 */
		[0.0626, 0.002, 0.0156, 0.1252, 0.501, 0.0078, 0.0313, 0.2505, 0.0039], /* if 5
		- most likely 4, 7, 3, -7, 6, 2, 5, 8, 1 */
		[0.0313, 0.002, 0.0078, 0.0626, 0.2505, 0.1252, 0.0156, 0.501, 0.0039], /* if 6
		- most likely 7, 4, 5, 3, -7, 6, 2, 8, 1 */
		[0.0156, 0.002, 0.0078, 0.0313, 0.1252, 0.2505, 0.501, 0.0626, 0.0039], /* if 7
		- most likely 6, 5, 4, 7, 3, -7, 2, 8, 1 */
		[0.0078, 0.0039, 0.0156, 0.0626, 0.1252, 0.2505, 0.0313, 0.501, 0.002]  /* if 8
		- most likely 7, 5, 4, 3, 6, 2, -7, 1, 8 */
	];

	/*
	geometric series dividing 1 into 9 exponentially small parts:
	0.501, 0.2505, 0.1252, 0.0626, 0.0313, 0.0156, 0.0078, 0.0039, 0.002
	*/

	noteProbsOff = [ // if off the beat
		[0.002, 0.501, 0.0626, 0.2505, 0.0078, 0.1252, 0.0313, 0.0039, 0.0156], /* if -7
		- most likely 1 3 5 2 6 8 4 7 -7 | or 1 3 5 8 4 7 -7 2 6 **/
		[0.0078, 0.501, 0.0313, 0.2505, 0.0039, 0.1252, 0.0156, 0.002, 0.0626], /* if 1
		- most likely 1 3 5 8 2 6 -7 4 7 | or 1 3 5 8 -7 4 7 2 6 */
		[0.0156, 0.501, 0.002, 0.2505, 0.0078, 0.1252, 0.0313, 0.0039, 0.0626], /* if 2
		- most likely 1 3 5 8 6 -7 4 7 2 */
		[0.0039, 0.501, 0.0156, 0.0313, 0.0626, 0.2505, 0.0078, 0.002, 0.1252], /* if 3
		- most likely 1 5 8 4 3 2 6 -7 7 */
		[0.0078, 0.1252, 0.0313, 0.501, 0.002, 0.2505, 0.0156, 0.0039, 0.0626], /* if 4
		- most likely 3 5 1 8 2 6 -7 7 4 */
		[0.002, 0.1252, 0.0039, 0.2505, 0.0626, 0.0156, 0.0078, 0.0313, 0.501], /* if 5
		- most likely 8 3 1 4 7 5 6 2 -7 */
		[0.0078, 0.0626, 0.0039, 0.1252, 0.0156, 0.2505, 0.002, 0.0313, 0.501], /* if 6
		- most likely 8 5 3 1 7 4 -7 2 6 */
		[0.002, 0.0313, 0.0156, 0.1252, 0.0078, 0.2505, 0.0626, 0.0039, 0.501], /* if 7
		- most likely 8 5 3 6 1 2 4 7 -7 */
		[0.002, 0.0626, 0.0039, 0.1252, 0.0156, 0.2505, 0.0078, 0.0313, 0.501] /* if 8
		- most likely 8 5 3 1 7 4 6 2 -7 */
	];

	noteProbsEndQ = [ // end on a tension (not 1 or 8, low chance 3 and 5)
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if -7
		- most likely - none*/
		[0.85, 0, 0.05, 0, 0.1, 0, 0, 0, 0], /* if 1
		- most likely - -7 4 2*/
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if 2
		- most likely - none */
		[0, 0, 0.1, 0, 0.9, 0, 0, 0, 0], /* if 3
		- most likely - 4 2 */
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if 4
		- most likely - none */
		[0, 0, 0, 0, 0.45, 0, 0.1, 0.45, 0], /* if 5
		- most likely - 4 7 6 */
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if 6
		- most likely - none */
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if 7
		- most likely - none */
		[0, 0, 0, 0, 0, 0, 0.1, 0.9, 0]  /* if 8
		- most likely - 7 6 */
	];

	/*
	1 divided into 4 parts using geometric series:
	0.5333, 0.2667, 0.1333, 0.0667
	*/

	noteProbsEndA = [ // end on resolution, no tensions, high chance 1 or 8, lower chance 3 or 5
		[0, 0.9, 0, 0.1, 0, 0, 0, 0, 0], /* if -7
		- most likely - 1 3 */
		[0, 0, 0, 0, 0, 0, 0, 0, 0], /* if 1
		- most likely - none */
		[0, 0.9, 0, 0.1, 0, 0, 0, 0, 0], /* if 2
		- most likely - 1 3 */
		[0, 0.9, 0, 0, 0, 0.1, 0, 0, 0], /* if 3
		- most likely - 1 5*/
		[0, 0, 0, 0.9, 0, 0.1, 0, 0, 0], /* if 4
		- most likely - 3 5 */
		[0, 0.333, 0, 0.1, 0, 0, 0, 0, 0.5], /* if 5
		- most likely - 8 1 3 */
		[0, 0, 0, 0, 0, 0.1, 0, 0, 0.9], /* if 6
		- most likely - 8 5 */
		[0, 0, 0, 0, 0, 0.1, 0, 0, 0.9], /* if 7
		- most likely - 8 5 */
		[0, 0, 0, 0, 0, 0, 0, 0, 0]  /* if 8
		- most likely - none */
	];

	[noteProbsOn, noteProbsOff, noteProbsEndQ, noteProbsEndA]
}.value;

~genMel = {
	var initRestQ, initRestA,
	durQ = List[], durA = List[],
	totalDurQ = 0, noteOnBeatQ = List[],
	totalDurA = 0, noteOnBeatA = List[],
	initProbOn = List[], initProbOff = List[],
	notes, scale, noteProbsOn = List[], noteProbsOff = List[],
	noteProbsEndQ = List[], noteProbsEndA = List[],
	melodyNotesQ = List[], melodyNotesA = List[];
	~layerDurs = List[List[], List[], List[], List[], List[], List[]];
	~layerNotes = List[List[], List[], List[], List[], List[], List[]];

	for(0,5){|i| // no. of layers

	for(0,3) { // total no. of Q and A pairs - each B and E needs one Q and one A
	// there are 2 Bs and 2 Es per layer - 4 total - so 8 Qs and As per layer - 4 pairs - 1 for each B & E
	// each pair generated and stored together are for one B or E of that layer
	// there should be 4 pairs stored together per layer [/*layer*/ [/*B1*/ [Q],[A]], [/*E1* ... ]

	durQ = List[];
	durA = List[];

	noteOnBeatQ = List[];
	noteOnBeatA = List[];

	totalDurQ = 0;
	totalDurA = 0;

	melodyNotesQ = List[];
	melodyNotesA = List[];

	durQ.add([~rhythmicModes.choose, ~rhythmicModes.choose]);
	durA.add([~rhythmicModes.choose, ~rhythmicModes.choose]);

	durQ = durQ.flat;
	durA = durA.flat;

	noteOnBeatQ.add(true);
	noteOnBeatA.add(true);

	for(1, durQ.size - 1) {|j|
		(durQ.size - 1 >= 1).if(
			{
				totalDurQ = totalDurQ + durQ[j -1];
				totalDurQ.postln;
				if(totalDurQ % 1 == 0) {noteOnBeatQ.add(true)} {noteOnBeatQ.add(false)}
			},
			{ "durQ: only one dur, no on/off beat assignment needed".postln }
		)
	};
	noteOnBeatQ.postln;

	for(1, durA.size - 1) {|j|
		(durA.size - 1 >= 1).if(
			{
				totalDurA = totalDurA + durA[j - 1];
				totalDurA.postln;
				if(totalDurA % 1 == 0) {noteOnBeatA.add(true)} {noteOnBeatA.add(false)}
			},
			{ "durA: only one dur, no on/off beat assignment needed".postln }
		)
	};
	noteOnBeatA.postln;

	initProbOn = [0, 0.25, 0, 0.25, 0, 0.25, 0, 0, 0.25];
	// gregorian ionian mode absolute initials: 1 3 5 (2 in polyphonic music)
	// use 1 3 5 w poss of rare substitutions (e.g. 1 -> 2)?

	initProbOff = [0.18, 0.05, 0, 0.18, 0.18, 0.18, 0, 0.18, 0.05];
	// increased chances of 4 and 7, reduced chances of 1 and 8

	/*scale = [0, 1].choose;*/

	notes = [~allFreqs[i][0][0], ~allFreqs[i][0][1], ~allFreqs[i][0][2], ~allFreqs[i][0][3],
	~allFreqs[i][0][4], ~allFreqs[i][0][5], ~allFreqs[i][0][6], ~allFreqs[i][0][7], ~allFreqs[i][0][8]];

	melodyNotesQ.add(notes[initProbOn.windex]);
	melodyNotesA.add(notes[initProbOn.windex]);

	for(1, noteOnBeatQ.size - 1) {|j|
		(noteOnBeatQ.size > 1).if(
			{
				var prevNote = melodyNotesQ[j - 1];
				var prevNoteI = notes.indexOf(prevNote);
				(noteOnBeatQ[j - 1] == true).if(
				{melodyNotesQ.add(notes[~noteProbs[0][prevNoteI].windex])},
				{melodyNotesQ.add(notes[~noteProbs[1][prevNoteI].windex])}
				)
			},
			{ "melodyNoteQ: only 1 note, no more assignment needed".postln }
		)
	};
	melodyNotesQ.postln;

	for(1, noteOnBeatA.size - 1) {|j|
		(noteOnBeatA.size > 1).if(
			{
				var prevNote = melodyNotesA[j - 1];
				var prevNoteI = notes.indexOf(prevNote);
				(noteOnBeatA[j - 1] == true).if(
				{melodyNotesA.add(notes[~noteProbs[0][prevNoteI].windex])},
				{melodyNotesA.add(notes[~noteProbs[1][prevNoteI].windex])}
				)
			},
			{ "melodyNoteA: only 1 note, no more assignment needed".postln }
		)
	};
	melodyNotesA.postln;

	1.do{
		var prevNoteQ = melodyNotesQ[melodyNotesQ.size - 1];
		var prevNoteIQ = notes.indexOf(prevNoteQ);

		var prevNoteA = melodyNotesA[melodyNotesA.size - 1];
		var prevNoteIA = notes.indexOf(prevNoteA);

			([1, 3, 5, 8].includes(prevNoteIQ)).if(
			{
				melodyNotesQ.add(notes[~noteProbs[2][prevNoteIQ].windex]);
				durQ.add(1)
			},
			{"melQ: no final needed".postln}
		);

			([0, 2, 4, 6, 7].includes(prevNoteIA)).if(
			{
				melodyNotesA.add(notes[~noteProbs[3][prevNoteIA].windex]);
				durA.add(1)
			},
			{"melA: no final needed".postln}
		)
	};

		[durQ, melodyNotesQ].do(_.postln);
	    [durA, melodyNotesA].do(_.postln);

		~layerDurs[i].add([durQ, durA]).postln;
		~layerNotes[i].add([melodyNotesQ, melodyNotesA]).postln;
	  };
	};

	[~layerDurs, ~layerNotes];
}.value;

~sortMelodies = {
	var order = [\x,\x,\x,\y,\x,\x,\y,\y,\x,\y,\y,\y],
	qADurOrder = List[
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]]
	], // [0..2]layer [0..3]B1,E1,B2,E2
	b1E1Dur = List[List[], List[], List[], List[], List[], List[]],
	b2E2Dur = List[List[], List[], List[], List[], List[], List[]],
	qANotesOrder = List[
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]],
		List[List[],List[],List[],List[]]
	], // [0..2]layer [0..3]B1,E1,B2,E2
	b1E1Notes = List[List[], List[], List[], List[], List[], List[]],
	b2E2Notes = List[List[], List[], List[], List[], List[], List[]],
	restsQA = [3, 3.5, 4.5, 5, 5.5], restsBE = [3, 3.5, 4.5, 5, 5.5];
	~xYDur = List[List[], List[], List[], List[], List[], List[]];
	~xYNotes = List[List[], List[], List[], List[], List[], List[]];

	for(0,5) {|i|
		for(0,3) {|j|
			order.collect {|item|
				(item == \x).if(
					{
						qADurOrder[i][j].add(~layerDurs[i][j][0]);
						qADurOrder[i][j].add(restsQA.choose);

						qANotesOrder[i][j].add(~layerNotes[i][j][0]);
						qANotesOrder[i][j].add(\rest)
					},
					{
						qADurOrder[i][j].add(~layerDurs[i][j][1]);
						qADurOrder[i][j].add(restsQA.choose);

						qANotesOrder[i][j].add(~layerNotes[i][j][1]);
						qANotesOrder[i][j].add(\rest)
					}
				)
			}
		};
	};
	qADurOrder.postln;
	qANotesOrder.postln;

	for(0,5) {|i|
		var jB = 0, jE = 0, jBDur = 0, jEDur = 0;

		order.collect {|item|
			(item == \x).if(
				{ // B1 B2
					b1E1Dur[i].add([qADurOrder[i][0][jB], qADurOrder[i][0][jB+1], qADurOrder[i][0][jB+2], qADurOrder[i][0][jB+3]]); // is there a more effient way using loop - e.g. [jB+n]?
					b1E1Dur[i].add(restsBE.choose); // add rest value
					b2E2Dur[i].add([qADurOrder[i][2][jB], qADurOrder[i][2][jB+1], qADurOrder[i][2][jB+2], qADurOrder[i][2][jB+3]]);
					b2E2Dur[i].add(restsBE.choose);

					b1E1Notes[i].add([qANotesOrder[i][0][jB], qANotesOrder[i][0][jB+1], qANotesOrder[i][0][jB+2], qANotesOrder[i][0][jB+3]]);
					b1E1Notes[i].add(\rest); // add rest space to notes
					b2E2Notes[i].add([qANotesOrder[i][2][jB], qANotesOrder[i][2][jB+1], qANotesOrder[i][2][jB+2], qANotesOrder[i][2][jB+3]]);
					b2E2Notes[i].add(\rest);

					jB = jB + 4
				},
				{ // E1 E2
					b1E1Dur[i].add([qADurOrder[i][1][jE], qADurOrder[i][1][jE+1], qADurOrder[i][1][jE+2], qADurOrder[i][1][jE+3]]);
					b1E1Dur[i].add(restsBE.choose);
					b2E2Dur[i].add([qADurOrder[i][3][jE], qADurOrder[i][3][jE+1], qADurOrder[i][3][jE+2], qADurOrder[i][3][jE+3]]);
					b2E2Dur[i].add(restsBE.choose);

					b1E1Notes[i].add([qANotesOrder[i][1][jE], qANotesOrder[i][1][jE+1], qANotesOrder[i][1][jE+2], qANotesOrder[i][1][jE+3]]);
					b1E1Notes[i].add(\rest);
					b2E2Notes[i].add([qANotesOrder[i][3][jE], qANotesOrder[i][3][jE+1], qANotesOrder[i][3][jE+2], qANotesOrder[i][3][jE+3]]);
					b2E2Notes[i].add(\rest);

					jE = jE + 4
				}
			)
		};
	};
	b1E1Dur.postln;
	b2E2Dur.postln;
	b1E1Notes.postln;
	b2E2Notes.postln;
	// b1E1Dur and b2E2Dur gain the structure: bxExDur[index 0..2][B or E 0..11][Qs and As 0..1]

	for(0,5) {|i|
		var jX = 0, jY = 0;

		order.collect {|item|
			(item == \x).if(
				{ // X
					~xYDur[i].add([b1E1Dur[i][jX], b1E1Dur[i][jX+1]]);

					~xYNotes[i].add([b1E1Notes[i][jX], b1E1Notes[i][jX+1]]);

					jX = jX + 2
				},
				{ // Y
					~xYDur[i].add([b2E2Dur[i][jY], b2E2Dur[i][jY+1]]);

					~xYNotes[i].add([b2E2Notes[i][jY], b2E2Notes[i][jY+1]]);

					jY = jY + 2
				}
			)
		};
	};
	~xYDur.postln;
	~xYNotes.postln;

	/*
	possible new dimension:

	- copy XY
	- raise second version's freqs by 706.88¢: * 1.509796
	- reverse on all dimensions and select correct reversed parts for pattern
	- new pattern = [\r, \r, \r, \m, \r, \r, \m, \m, \r, \m, \m, \m, \r, \m, \m, \r, \r, \m, \r, \r, \r]
	- everything after m m m reversed
	- everything before the preceding r is the original pattern
	*/

	~xYDur = ~xYDur.flatten2(-3);
	~xYNotes = ~xYNotes.flatten2(-3);

	[~xYDur, ~xYNotes]
}.value;

(
~startMel77 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[0]*0.5, inf),
	\amp, 0.2,
	\dur, Pseq(~xYDur[0], inf),
	\pan, 0
);

~startMel94 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[1], inf),
	\amp, 0.2,
	\dur, Pseq(~xYDur[1], inf),
	\pan, -0.33
);

~startMel99 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[2]/* *1.509796 */, inf),
	\amp, 0.2,
	\dur, Pseq(~xYDur[2], inf),
	\pan, 0.33
);

~startMel88 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[3]/* *1.509796 */*2, inf),
	\amp, 0.1,
	\dur, Pseq(~xYDur[3], inf),
	\pan, -0.9
);

~startMel53 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[4]*2, inf),
	\amp, 0.1,
	\dur, Pseq(~xYDur[4], inf),
	\pan, 0.9
);

~startMel66 = Pbind(
	\instrument, \melodyVoice,
	\freq, Pseq(~xYNotes[5]*4, inf),
	\amp, 0.015,
	\dur, Pseq(~xYDur[5], inf),
	\pan, 0.1
);

~metroGnome = Pbind(
	\instrument, \accompVoice,
	\freq, 130.5, /*Pseq([130.5, ~allFreqs[0][0][4]/2, 130.5], inf),*/
	\amp, 0.2,
	\dur, 5 /*Pseq([1, 1, 2], inf)*/
);


(
~metre48 = TempoClock.new(4.57142857); // layer 6
/*~metre24 = TempoClock.new(2.28571429); // layer 6*/
~metre32 = TempoClock.new(3.04761905); // layer 5
~metre27 = TempoClock.new(2.57142857); // layer 4
~metre21 = TempoClock.new(/*2.50000001*/ 2); // layer 3
~metre18 = TempoClock.new(/*2.14285715*/ 1.71428571); // layer 2
~metre14 = TempoClock.new(/*1.66666667*/ 1.33333333); // layer 1 and accomp - 80 bpm
);

(
~metroGnome.play(~metre14);
~startMel77.play(~metre14);
~startMel94.play(~metre18); // rhythmic phrasing not consistent - is it a long phrase?
~startMel99.play(~metre21);
~startMel88.play(~metre27);
~startMel53.play(~metre32);
~startMel66.play(~metre48);
);

~dynamicStructure = {
	// start and stop layers
	// determine tempo

	// determine rest lengths

	// determine scale in use (supmaj or upsupmaj)
	// - by probability per layer

	// determine sound design params

	// control things via probabilities that are mapped onto the dynamic structure
	// begin by determining trajectory of piece dynamics - low-high-low, high-low-high, low-high, high-low
	// for l-h-l and h-l-h determine where the peak occurs in 5ths or 6ths of the dur of the piece?
	// - e.g. peak at 3/5 or 5/6 of the way through

	// possibly create more interesting patterns by overlaying layers of dynamics
	// - e.g. h-l-h tempo and l-h "space" (longer - shorter rest bar lengths)
	// also correlate tempo/layers and rest lengths (~ density and speed)
	// e.g. while there might be a case where the piece is slow by has short rests; at slow tempos rests can only be so short - there will be certain ranges allowed at certain tempos

	// also include degrees of "height" so the highs of high-low-high might be to different degrees
	// - can also be expressed as fractions


	// first - structure type (possibly loop for layers for dynamics)
	// number of peaks 1 or 2 (in other words number of plot points 2 or 3)
	// trajectories (high-low orders)
	// height of peaks
	// position of peak/trough in 3 point strucs

	var structure = [[0, 1] /*2 points*/, [2, 3] /*3 points*/], chosenStruc = nil,
	highPoints = nil, highPointVals = List[],
	midPointPos = nil, midPointSched = nil,
	totalXYDur0 = 0;

	chosenStruc = {structure.choose.choose}.value; // 0: low(l)-high(h), 1: h-l, 2: l-h-l, 3: h-l-h
	// determine from [0..1][x], then [x][0..3]

	if(chosenStruc == 3) {highPoints = 2} {highPoints = 1}; // determine no. of high points

	highPoints.do { // intensity value of high points
		highPointVals.add(rrand(0.333, 1));
	};
	highPointVals.postln;

	(chosenStruc >= 2).if( // percentage of 1 along the duration of the piece
		{midPointPos = [0.2, 0.4, 0.6, 0.8].choose; midPointPos.postln},
		{midPointPos = nil; "two point structure, no midpoint needed".postln}
	);

	~xYDur[0].do({|item|
		totalXYDur0 = totalXYDur0 + item;
	});
	totalXYDur0;

	if(midPointPos != nil) {midPointSched = totalXYDur0 * midPointPos} {"no mid point to schedule".postln};
	midPointSched;

	// intensity - get all 2 or 3 points of intensity (also create for low points)
	// divide range from low to high by beats and map onto number of beats from point to point
	// get numbers of beats by finding totalXYDur (only for 2 points) and midPointSched (for 3 points)
	// 0 to midPointSched is from beginning to mid point, and mPS to totalXYDur is mid point to end

	/* play and schedule

	~startMel77.play(~metre14);
	~metre14.sched(totalXYDur0, ~startMel77.stop);

	*/


	// then generate numbers - tempo, rests, timings, sound design params, etc
}

/*
next steps:

- use probability to determine rhythm choices/rhythmic phrasing (coherent and natural sounding?)

- refine melodic movement (more emphasis on 4 -> 3 and 8/1 -> 7, and more clear patterns it gravitates to, less random?)

- ^ ^ clearer phrasing
- can study real melodies for more insight into how to make it sound more natural - esp. improvisation

- create multiple layers - ADDED 2ND LAYER - more? - interweave 2nd XY structure?

- move between supermajor and upsupermajor

- possible metric coherency, limiting phrasing by bars (2 bars per phrase?)

dynamic structure:
- useable across all sound pieces and moving image?
- layer diff strucs fir diff pieces/etc?
*/
