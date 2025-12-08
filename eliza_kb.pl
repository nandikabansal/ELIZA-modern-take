:- module(eliza_kb, [learn/1, fact/1, show_facts/0, clear_facts/0, log_fact/1]).
:- dynamic fact/1.
:- use_module(library(filesex)).

% learn/1: extract keywords and assert facts (simple starter)
learn(InputTokens) :-
    % feelings / emotions
    ( ( memberchk(sad, InputTokens)
      ; memberchk(unhappy, InputTokens)
      ) -> assertz_fact(user_feels(sad))       ; true ),
    ( ( memberchk(happy, InputTokens)
      ; memberchk(glad, InputTokens)
      ; memberchk(joyful, InputTokens)
      ) -> assertz_fact(user_feels(happy))     ; true ),
    ( ( memberchk(lonely, InputTokens)
      ; memberchk(alone, InputTokens)
      ) -> assertz_fact(user_feels(lonely))    ; true ),
    ( ( memberchk(anxious, InputTokens)
      ; memberchk(anxiety, InputTokens)
      ; memberchk(nervous, InputTokens)
      ; memberchk(worried, InputTokens)
      ) -> assertz_fact(user_feels(anxious))   ; true ),
    ( ( memberchk(angry, InputTokens)
      ; memberchk(anger, InputTokens)
      ) -> assertz_fact(user_feels(angry))     ; true ),
    ( ( memberchk(depressed, InputTokens)
      ; memberchk(hopeless, InputTokens)
      ) -> assertz_fact(user_feels(depressed)) ; true ),

    % topics / domains
    ( ( memberchk(family, InputTokens)
      ; memberchk(parents, InputTokens)
      ) -> assertz_fact(user_talked_about(family)) ; true ),
    ( ( memberchk(work, InputTokens)
      ; memberchk(job, InputTokens)
      ; memberchk(office, InputTokens)
      ) -> assertz_fact(user_talked_about(work))   ; true ),
    ( ( memberchk(study, InputTokens)
      ; memberchk(studies, InputTokens)
      ; memberchk(exams, InputTokens)
      ) -> assertz_fact(user_talked_about(study))  ; true ),
    ( ( memberchk(relationship, InputTokens)
      ; memberchk(girlfriend, InputTokens)
      ; memberchk(boyfriend, InputTokens)
      ; memberchk(partner, InputTokens)
      ) -> assertz_fact(user_talked_about(relationship)) ; true ),

    % stress and load
    ( ( memberchk(stress, InputTokens)
      ; memberchk(stressed, InputTokens)
      ) -> assertz_fact(user_mentioned(stress)) ; true ),
    ( ( memberchk(pressure, InputTokens)
      ; memberchk(overwhelmed, InputTokens)
      ) -> assertz_fact(user_mentioned(pressure)) ; true ).

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