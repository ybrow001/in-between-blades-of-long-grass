/* fȧncṡens tu jėnereit and intēpret þi l-sistem */

/*
new rule symbols:
// using pan2: -1 is left, 0 centre, +1 is right
// all below are left then right respectively
- '>' and '<' - big pan -/+0.3
- '-' and '+' - mid pan -/+0.2
- 'l' and 'r' - small pan -/+0.1
// adjust so pan doesn't go beyond -/+1

// for quadraphonic introduce "z-axis"/output 3 & 4 panning symbols
*/

~xRules = [
	['F', '[', '+', '<', 'X', ']', '[', '>', 'X', ']', 'F', 'X'], // 12 symbols
	['F', '[', '<', 'X', ']', '[', '-', '>', 'X', ']', 'F', 'X'], // 12 symbols
	['-','F', '[', '<', '<', 'X', ']', '[', '>', 'X', ']', 'F', '<', 'X'], // 14 symbols
	['+', 'F', '[', '<', 'X', ']', '[', '>', '>', 'X', ']', 'F', '>', 'X'], // 14 symbols
	['l', 'F', '[', '<', 'X', ']', '[', '>', 'X', ']', 'F', '+', '+', 'X'], //  14 symbols
	['r', 'F', '[', '<', 'X', ']', '[', '>', 'X', ']', 'F', '-', '-', 'X'], // 14 symbols
	['l','F', '[', '<', '<', 'X', ']', '[', '>', 'X', ']', 'F', '+', 'X'], // 14 symbols
	['r', 'F', '[', '<', 'X', ']', '[', '>', '>', 'X', ']', 'F', '-', 'X'], // 14 symbols
	['F', '[', '+', '<', 'X', ']', '[', '>', 'X', ']', '[', '+', '<', 'X', ']', 'F', '>', 'X'],//18
	['F', '[', '<', 'X', ']', '[', '-', '>', 'X', ']', '[', '-', '>', 'X', ']', 'F', '<', 'X'],//18
	['l', 'F', '[', '+', '<', 'X', ']', '[', '>', 'X', ']', '[', '+', '<', 'X', ']', 'F', 'X'],//18
	['r', 'F', '[', '<', 'X', ']', '[', '-', '>', 'X', ']', '[', '-', '>', 'X', ']', 'F', 'X']//18
];

~index = [
	0.0833, 0.0833, 0.0833, 0.0833,
	0.0833, 0.0833, 0.0833, 0.0833 ,
	0.0833, 0.0833,  0.0833, 0.0833
].windex;

~makeRules = IdentityDictionary[
	// original X rule: 'X' -> ['F', '[', '<', 'X', ']', '[', '>', 'X', ']', 'F', 'X'],
	'X' -> ~xRules[~index],
	'F' -> ['F', 'F']
];

~totalSymbols = {|iterations = 2|
	// get symbols counts from ~makeRules 'X' rulesets
	var numX = ~xRules[~index].count({|item| item == 'X'}); //no. of new Xs in X rule
	var numF = ~xRules[~index].count({|item| item == 'F'}); // no. of new Fs in X rule
	var numOther = ~xRules[~index].size - (numX + numF); // no. of new brackets and pan symbols

	// prev_  & count_ vars initialised at 0 iterations; prevX = 1 allows new_ vars to drive iteration
	var prevX = 1; // no. of prev unexpanded Xs - not counted after bc they have been expanded
	var countF = 0; // cumulative no. of prev Fs - multiplied by 2 each new iteration
	var countOther = 0; // cumulative no. of prev Other symbols

	var newX = numX*prevX; // no. of new unexpanded Xs in the new iteration
	var newF = numF*prevX; // no. of new Fs in the new iteration
	var newOther = numOther*prevX; // no. of new Others in the new iteration

	var total = 1; // initialised at 0 iterations - one 'X' symbol

	for(1, iterations){
		// reassign new values based on updated prev values
		// new_ vars are the CURRENT iteration)
		newX = numX*prevX;
		newF = numF*prevX;
		newOther = numOther*prevX;

		// count previous + current symbols
		// countX = newX;
		countF = (countF * 2) + newF;
		countOther = countOther + newOther;
		prevX = newX; // is NOT counted in total

		total = countF + countOther + newX;
	};

	total.postln;
}.value;

~generateLSystem = {|startSymbol = 'X', rules, iterations = 2, numSymbols|
	var lsys = Prewrite.new(startSymbol, rules, iterations);
	var output = lsys.asStream;
	var outputList = List.new;

	outputList = output.nextN(numSymbols);
	outputList.postln;
}; // .value stopped the func receiving correct param values

~interpretSymbols = {|symbolList|
	var branchCounter = 0; // tracks branches - used to create unique branchIDs
	var current = IdentityDictionary[ // tracks data after interpreting a symbol in switch below
		'dur'-> 0,
		'pan' -> 0, // add both left and right pan explicitly? - not necessary bc of pos and neg vals?
		'panDegree' -> 0, // store current pan degree - to be used in incrementing pan in 'F'
		/* how to add up panning?
		- needs isolating per branch - handled by stack
		- must add up all pan symbols per branch - will accumulate anyway - bc it's not reset
		- branches inherit parents' panning - handled by stack?
		- should lead to pan/dur and endPan/Dur working?
		*/
		'branchDepth'-> 0,
		'branchID'-> 0,
		'parentID' -> nil, // keep empty until assigned value when creating new branch
		'childID' -> List.new // keep empty until adding value(s) when creating new branch
	];
	var stack = List.new; // allows isolation of updates to branches via pushing and popping
	var result = List.new; // tracks output every F - each time the l-system moves forwards
	var branchTree = List.new; // stores data for each branch individually
	var newBranch; // temporarily holds new branch data before storing in BranchTree
	var parentIndex = nil; // was isNew
	var branchEnd = nil;

	var i = Nil, root = Nil;

	branchTree.add( // initialising branchTree with the root branch
		current.copy;
	);

	symbolList.do {|symbol|
        switch(symbol,
			'F', {
                current.put('dur', current['dur'] + 1);
				current.put('pan', current['pan'] + current['panDegree']);

				// "update active branch in tree" - chatgpt
				i = branchTree.detectIndex({|b| b['branchID'] == current['branchID']});
				if(i.notNil) {
					branchTree[i].put('dur', current['dur']);
					branchTree[i].put('pan', current['pan']);
				};

                result.add(current.copy);
            },

			'>', {
				/*current.put('pan', current['pan'] - 0.3);*/
				current.put('panDegree', -0.3)
			},
			'<', {
				/*current.put('pan', current['pan'] + 0.3);*/
				current.put('panDegree', 0.3)
			},
			'-', {
				/*current.put('pan', current['pan'] - 0.1);*/
				current.put('panDegree', -0.1)
			},
			'+', {
				/*current.put('pan', current['pan'] + 0.1);*/
				current.put('panDegree', 0.1)
			},
			'l', {
				/*current.put('pan', current['pan'] - 0.06);*/
				current.put('panDegree', -0.06)
			},
			'r', {
				/*current.put('pan', current['pan'] + 0.06);*/
				current.put('panDegree', 0.06)
			},

			/* '[' and ']' are where branching takes place */

			'[', { // opens a new branch - isolation of events to that branch
				stack.add(current.copy);

				branchCounter = branchCounter + 1;

				newBranch = current.copy;
				newBranch.put('dur', 0);
				newBranch.put('branchDepth', current['branchDepth'] + 1);
				newBranch.put('branchID', branchCounter);
				/*newBranch.put('childID', List.new);*/ // now added initialising current

				branchTree.add(newBranch);
				/*branchTree[current['branchDepth']]['childID'].add(branchCounter);*/
				parentIndex = branchTree.detectIndex({|b| b['branchID'] == current['branchID']});
				if(parentIndex != nil) {
					branchTree[parentIndex]['childID'].add(branchCounter);
				};

				current = newBranch;
				current.put('childID', List.new);

				// use .detect to place child in correct branch entry? and only place new branchIDs in branchTree - to avoid duplicate entries of the same branch

            },
			']', { // close new branch - end isolation of events
				/*branchTree[branchTree.size - 1].put('endDur', current['dur']);
				branchTree[branchTree.size - 1].put('endPan', current['pan']);*/

				/*branchTree[current['branchID']].put('endDur', current['dur']);
				branchTree[current['branchID']].put('endPan', current['pan']);*/

				branchEnd = branchTree.detect({|b| b['branchID'] == current['branchID']});
				if(branchEnd != nil) {
					branchEnd.put('endDur', current['dur']);
					branchEnd.put('endPan', current['pan']);
				};

				current = stack.removeAt(stack.size - 1);
            }
        );
    };

	// close root branch at the end, after interpreting the whole expanded l-system
	root = branchTree.detect({|b| b['branchID'] == 0});
	// update endDur/Pan with the current dur/pan at the very end
	root.put('endDur', root['dur']);
	root.put('endPan', root['pan']);

	[result, branchTree];
};

~patterns = List.new;

~makePatterns = {|output|
	/*for(0, output.size - 1) {|i|
		~patterns.add(Pbind(
			'dur', output[i]['dur']
		)
		);
		// put branch properties into patterns, store in pattern List
	};*/
	output.do{|branch|
		~patterns.add(Pbind(
			'dur', branch['dur']
		)
		);
	};
	~patterns.postln;
};

(
{
	var iterations = 4;
	var rules = ~makeRules;
	var numSymbols = ~totalSymbols.(iterations);
	var symbols = ~generateLSystem.('X', rules, iterations, numSymbols);
	var outcome = ~interpretSymbols.(symbols);
	rules.postln;

	"result:".postln;
	outcome[0].do(_.postln);

	"branchTree:".postln;
	outcome[1].do(_.postln);

	"patterns:".postln;
	~makePatterns.(outcome[1]);
}.value
);

/*
creating patterns:

loop through output of interpret symbols:
for each branchID create a pattern from its corresponding values.
*/



/*
containing pan values within -1 to 1 range:

after all pan values are added up - store in List and loop through to find lowest and highest values
- with those extreme values as the outer limits, map all values onto the range -1 to 1
- using LinLin()?
*/


/* fȧncṡens tu jėnereit saund */

/*PinkNoise.ar();
LPF.ar();*/

// create a new pair(?) of PinkNoise duplicates for each branch - pair to allow stereo/panning
// create 1 LPF duplicate for each new branch
// each new branch becomes quieter and has more high end attenuated

/*
data generated by l-system and how to interpret
- branch ID
- parent/child branches
- branch depth
- duration
- end dur
- pan
- end pan
- pan degree (what's the difference with pan? - current pan vs pan difference?)

panning:
- aim to keep pan within -1 to 1 range - if it falls outside/or insideaim to map it onto -1 to 1 - or widest L to widest R - e.g. -0.9 to 0.9

branch ID/parent-child relationship:
- allows connection between branches to be maintained
- useful for determining samples/sounds being played, arrangement, etc

duration:
- increases with every F (equiv to line drawn forward)
- representitive of time
- can be used to determine volume or decrease in vol over time?
- represents how long a branch exists for? (larger dur = more important/enduring sound used?)
- does higher dur = more children?
- can also determine timbre, filtering, etc

branch depth:
- can be used for volume, filtering, sample, selection - significance and prominence of sample?

in order to use the l-system tree, values need to be assigned to the properties of the tree
- dur needs value in time
- a sound should be triggered when a new branch is created and change over time accordingy
- changes over time can be determined from the beginning bc the tree is generated in its entirety before the piece begins
*/

/*
creating sounds:
- make a SynthDef that generates pink noise, can be panned, have its amplitude adjusted and be filtered
- use the data from the l-system tree to sequence the sound changes
*/

/*
mixing:
- use pink/brown noise formula as a guiding principle, applied to branch length rather than frequency
*/

~pink_noise = SynthDef.new(\pink_noise, { |amp = 0.33, pan = 0, cutoff = 1000, out = 0|
	var voice, env;
	voice = PinkNoise.ar(amp);
	env = EnvGen.kr(
		Env.sine(4.67,1),
		doneAction: 2
	);
	voice = voice * env;
	voice = LPF.ar(voice, cutoff);
	voice = Pan2.ar(voice, pan);
	Out.ar(out, voice)
}).add;

~play_pink_noise = Pbind(
	\instrument, \pink_noise,
	\pan, 0.0,
	\dur, Pseq([9], inf),
	\amp, 0.5,
	\cutoff, 2200
);

(
~metre = TempoClock.new(1.333);
~play_pink_noise.play(~metre);
)

/*
to use the l-system tree:
- create sequences for each sound parameter of pink_noise using the tree data
- each new branch create a new Pbind() to play the sequences of parameters and call a unique instance of pink_noise (ultimately a new instance of the sample player and with the right sample)

l-system - synth def param correspondance:
- pan&panDegree-pan
- dur-dur
- branch-sample (branchID to track what sample is used when?)

- track branchID and trigger a new sample when it changes
- the new sample then gets passed the properties of the new branch (pan, dur, etc)

- determine all patterns at the beginnning then run

how to:
- gather data for each branch - each [...], use this to create the patterns for it
  - also determine at what time the branch off of their parent branches - time to start them and end (+ their own duration)

*/
