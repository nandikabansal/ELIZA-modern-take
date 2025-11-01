:- module(eliza_kb, [learn/1, fact/1, show_facts/0, clear_facts/0, log_fact/1]).
:- dynamic fact/1.
:- use_module(library(filesex)).

% learn/1: extract keywords and assert facts (simple starter)
learn(InputTokens) :-
    ( memberchk(sad, InputTokens)      -> assertz_fact(user_feels(sad)) ; true ),
    ( memberchk(happy, InputTokens)    -> assertz_fact(user_feels(happy)) ; true ),
    ( memberchk(lonely, InputTokens)   -> assertz_fact(user_feels(lonely)) ; true ),
    ( memberchk(family, InputTokens)   -> assertz_fact(user_talked_about(family)) ; true ),
    ( memberchk(work, InputTokens)     -> assertz_fact(user_talked_about(work)) ; true ),
    ( memberchk(stress, InputTokens)   -> assertz_fact(user_mentioned(stress)) ; true ).

% assert once and log
assertz_fact(Fact) :-
    ( \+ fact(Fact) ->
        assertz(fact(Fact)),
        log_fact(Fact)
    ; true ).

log_fact(F) :-
    setup_call_cleanup(
        open('facts.log', append, S, [type(text)]),
        ( write(S, F), write(S, '\n') ),
        close(S)
    ).

show_facts :-
    ( fact(_) -> listing(fact) ; write('No facts learned yet.'), nl ).

clear_facts :-
    retractall(fact(_)),
    write('Facts cleared.'), nl.