:- module(eliza_utils, [
    tokenize/2,
    downcase_str/2,
    normalize_input_atom/2,
    transform/2,
    swap/2
]).

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).

downcase_str(Atom, Lower) :-
    atom_chars(Atom, Chars),
    maplist(replace_punctuation, Chars, CleanChars),
    atom_chars(Clean, CleanChars),
    downcase_atom(Clean, Lower).

replace_punctuation('.', ' ') :- !.
replace_punctuation(',', ' ') :- !.
replace_punctuation('?', ' ') :- !.
replace_punctuation('!', ' ') :- !.
replace_punctuation(Char, Char).

normalize_input_atom(AtomIn, AtomOut) :-
    downcase_str(AtomIn, Trim),
    atomic_list_concat(Parts, ' ', Trim),
    exclude(=( '' ), Parts, Clean),
    atomic_list_concat(Clean, ' ', AtomOut).

tokenize(Str, Tokens) :-
    atomic_list_concat(Parts, ' ', Str),
    exclude(=( '' ), Parts, Tokens).

swap(i, you).
swap(im, you_are).
swap(i_am, you_are).
swap('i\'m', you_are).
swap(my, your).
swap(me, you).
swap(am, are).
swap(you, i).
swap(your, my).
swap(X, X).

transform([], []).
transform([H|T], [H2|T2]) :-
    swap(H, H2),
    transform(T, T2).