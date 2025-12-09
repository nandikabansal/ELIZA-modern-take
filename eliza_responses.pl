:- module(eliza_responses, [select_reply/2]).
:- use_module(eliza_rules_loader).
:- use_module(eliza_kb).
:- use_module(eliza_utils, [tokenize/2, transform/2]).
:- dynamic last_reply/1.

% Top-level selector: try KB-aware reply first, then fall back to rule-based
select_reply(InputTokens, ReplyTokens) :-
    kb_reply(InputTokens, ReplyTokens), !.
select_reply(InputTokens, ReplyTokens) :-
    select_reply_rules(InputTokens, ReplyTokens).

% -------------------------
% KB-aware replies
% -------------------------

% Use KB-driven replies mainly when the user says something short/unclear,
% but we already know important facts about them.

kb_reply(InputTokens, ReplyTokens) :-
    length(InputTokens, Len),
    Len =< 4,                 % only kick in on short inputs
    kb_feeling_reply(ReplyTokens), !.

kb_reply(InputTokens, ReplyTokens) :-
    length(InputTokens, Len),
    Len =< 4,
    kb_topic_reply(ReplyTokens), !.

% If no KB-based rule matches, let rule engine handle it.
kb_reply(_, _) :- fail.



% ---- Feelings-based KB replies ----

kb_feeling_reply(ReplyTokens) :-
    fact(user_feels(sad)), !,
    random_member(ReplyTokens,
        [
            ['You','mentioned','feeling','sad','earlier.','How','have','things','been','since','then?'],
            ['It','seems','sadness','has','been','on','your','mind.','What','has','been','the','hardest','part','lately?']
        ]).

kb_feeling_reply(ReplyTokens) :-
    fact(user_feels(happy)), !,
    random_member(ReplyTokens,
        [
            ['Earlier','you','said','you','were','happy.','Has','anything','changed','since','then?'],
            ['It','sounds','like','happiness','has','been','present','for','you.','What','is','helping','with','that?']
        ]).

kb_feeling_reply(ReplyTokens) :-
    fact(user_feels(lonely)), !,
    random_member(ReplyTokens,
        [
            ['You','have','talked','about','feeling','lonely.','When','do','you','notice','that','feeling','the','most?'],
            ['Earlier','you','mentioned','loneliness.','What','is','it','like','for','you','right','now?']
        ]).

kb_feeling_reply(ReplyTokens) :-
    fact(user_feels(anxious)), !,
    random_member(ReplyTokens,
        [
            ['You','mentioned','feeling','anxious.','What','tends','to','trigger','that','for','you?'],
            ['When','you','feel','anxious,','what','do','you','usually','do','to','cope?']
        ]).

kb_feeling_reply(ReplyTokens) :-
    fact(user_feels(angry)), !,
    random_member(ReplyTokens,
        [
            ['You','have','said','you','felt','angry.','What','do','you','think','is','underneath','that','anger?'],
            ['Anger','can','be','a','signal.','What','do','you','think','it','might','be','pointing','to?']
        ]).



% ---- Topic-based KB replies ----

kb_topic_reply(ReplyTokens) :-
    fact(user_talked_about(family)), !,
    random_member(ReplyTokens,
        [
            ['You','have','brought','up','your','family','before.','What','feels','most','important','there','right','now?'],
            ['Family','seems','to','matter','a','lot','to','you.','What','part','of','that','would','you','like','to','explore','more?']
        ]).

kb_topic_reply(ReplyTokens) :-
    fact(user_talked_about(work)), !,
    random_member(ReplyTokens,
        [
            ['Work','has','come','up','a','few','times.','How','are','things','going','with','work','these','days?'],
            ['You','have','mentioned','work','earlier.','What','is','feeling','most','difficult','about','it','lately?']
        ]).

kb_topic_reply(ReplyTokens) :-
    fact(user_talked_about(relationship)), !,
    random_member(ReplyTokens,
        [
            ['You','have','talked','about','your','relationship.','What','has','been','on','your','mind','there','today?'],
            ['It','sounds','like','relationships','are','important','to','you.','What','feels','most','alive','in','that','area','right','now?']
        ]).

kb_topic_reply(ReplyTokens) :-
    fact(user_mentioned(stress)), !,
    random_member(ReplyTokens,
        [
            ['You','mentioned','stress','before.','Has','anything','changed','with','your','stress','levels?'],
            ['Stress','has','been','a','theme','for','you.','What','situations','have','felt','most','stressful','recently?']
        ]).

kb_topic_reply(ReplyTokens) :-
    fact(user_mentioned(pressure)), !,
    random_member(ReplyTokens,
        [
            ['It','sounds','like','you','have','been','under','pressure.','Where','do','you','feel','that','pressure','the','most?'],
            ['You','mentioned','feeling','pressure.','What','expectations','do','you','think','are','driving','that?']
        ]).

% select_reply_rules(InputTokens, ReplyList)
select_reply_rules(InputTokens, ReplyTokens) :-
    findall(Weight-Resp, (
        pattern_rule(Weight, PatternList, RespAtoms),
        pattern_matches(PatternList, InputTokens, Captures),
        Resp = (RespAtoms-Captures)
    ), Candidates),
    
    Candidates \= [],
    keysort(Candidates, SortedAsc),
    reverse(SortedAsc, Sorted),         % highest first
    
    % pick first candidate that doesnt equal last reply if possible
    ( last_reply(Prev) ->
        ( select(_- (RespAtoms-Captures), Sorted, Rest),
          RespAtoms \= Prev, Rest \= [] -> Chosen = (RespAtoms-Captures)
        ; Sorted = [_-Chosen|_]
        )
    ; Sorted = [_-Chosen|_] ),
    
    % pick a random response variant from RespAtoms
    Chosen = (RespAtoms-Captures),
    ( is_list(RespAtoms) -> random_member(RawResp, RespAtoms) ; RawResp = RespAtoms ),
    
    % process placeholders and transforms
    phrase_to_tokens(RawResp, RawTokens),
    
    fill_placeholders(RawTokens, Captures, Filled),
    
    % save last reply
    retractall(last_reply(_)),
    assertz(last_reply(RawResp)),
    ReplyTokens = Filled.

% Fallback if no rules match
select_reply_rules(_, ['I', 'see.', 'Please', 'tell', 'me', 'more.']) :-
    writeln('[WARNING] No matching rules found, using fallback').

% pattern_matches supports '_' wildcard capturing rest or a single token.
pattern_matches(PatternList, InputTokens, Captures) :-
    pattern_matches_(PatternList, InputTokens, [], RevCaptures),
    reverse(RevCaptures, Captures).

pattern_matches_([], [], Caps, Caps).
pattern_matches_(['_'|P], [H|T], Acc, Caps) :-
    % single-token wildcard capture
    pattern_matches_(P, T, [H|Acc], Caps).
pattern_matches_(['__'|P], Input, Acc, Caps) :-
    % capture rest of input as one string
    atomic_list_concat(Input, ' ', RestAtom),
    pattern_matches_(P, [], [RestAtom|Acc], Caps).
pattern_matches_([PatH|P], [InH|T], Acc, Caps) :-
    downcase_atom(PatH, PLH),
    downcase_atom(InH, ILH),
    PLH = ILH,
    pattern_matches_(P, T, Acc, Caps).

% Convert response string with __ placeholder into token list; handle injection
phrase_to_tokens(String, Tokens) :-
    split_string(String, " ", "", Parts),
    maplist(string_to_atom, Parts, Tokens).

string_to_atom(Str, Atom) :-
    atom_string(Atom, Str).

% Replace placeholder token "*" with captured text(s)
fill_placeholders([], _Caps, []).

fill_placeholders([Tok|Rest], Caps, [OutTok|RestOut]) :-
    (   has_placeholder(Tok, Base, Suffix)
    ->  (   Base = '*' ->
                (   Caps = [C|_] ->
                    reflect_capture(C, RC),
                    atom_concat(RC, Suffix, OutTok)
                ;   OutTok = Suffix
                )
        ;   Base = '**' ->
                (   Caps = [] ->
                    OutTok = Suffix
                ;   atomic_list_concat(Caps, ' ', CapsAtom),
                    reflect_capture(CapsAtom, RC),
                    atom_concat(RC, Suffix, OutTok)
                )
        )
    ;   OutTok = Tok
    ),
    fill_placeholders(Rest, Caps, RestOut).

% Tok may be exactly '*' / '**' or may start with them and have punctuation after.
has_placeholder(Tok, Base, Suffix) :-
    (   atom_concat('**', Suffix, Tok) ->
        Base = '**'
    ;   atom_concat('*', Suffix, Tok) ->
        Base = '*'
    ).

reflect_capture(CapAtom, ReflectedAtom) :-
    % turn the captured phrase into tokens
    tokenize(CapAtom, Tokens),
    % swap pronouns
    transform(Tokens, RefTokens),
    % back to a single atom
    atomic_list_concat(RefTokens, ' ', ReflectedAtom).