# vata

This is going to be a simple-ish package to manage the VATA asic.

What it will include:

## Persistent vata interaction process
A process will be running to handle interactions with the VATA firmware,
and try and keep track of what's going on (Are we allowing triggers? Are we streaming
data packets? What is the current configuration?).

## Command and status server
A small bottle-based server to send commands to the persistent vata interaction process.
It should also be capable of taking status queries

