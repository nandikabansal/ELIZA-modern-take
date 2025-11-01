:- module(eliza_io, [read_line_to_codes/2]).
% re-export read_line_to_codes/2 from the standard library
:- use_module(library(readutil), [read_line_to_codes/2]).

% The predicate is imported from library(readutil) and exported above.
% No local wrapper is required — avoid a wrapper that would recursively call
% itself and cause an infinite loop.