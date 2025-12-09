:- module(eliza_main, [eliza/0, stop_eliza/0]).
:- use_module(eliza_io).
:- use_module(eliza_utils).
:- use_module(eliza_kb).
:- use_module(eliza_rules_loader).
:- use_module(eliza_responses).

% Start: load rules and start conversation
eliza :-
    write('Loading rules...'), nl,
    eliza_rules_loader:load_rule_files(rules),
    write('ELIZA (therapist) — Hello. I am here to listen.'), nl,
    loop.

stop_eliza :-
    write('ELIZA: Goodbye.'), nl.

loop :-
    write('You: '), flush_output(current_output),
    read_line_to_codes(user_input, Codes),
    ( Codes = [] -> stop_eliza
    ; atom_codes(A, Codes),
      normalize_input_atom(A, NormAtom),
      tokenize(NormAtom, InputTokens),
      learn(InputTokens),
      select_reply(InputTokens, Reply),
      atomic_list_concat(Reply, ' ', ReplyAtom),
      write('ELIZA: '), write(ReplyAtom), nl,
      loop ).