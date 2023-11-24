MIDIIn.connectAll
MIDIClient.sources

MIDIdef.freeAll;

(
MIDIdef.noteOn(\testOn, { arg ...args; "on ".post; args.postln; });
MIDIdef.noteOff(\testOff, { arg ...args; "off ".post; args.postln; });
MIDIdef.cc(\testCC, { arg ...args; "cc ".post; args.postln; });
MIDIdef.bend(\testBend, { arg ...args; "bend ".post; args.postln; });
)
