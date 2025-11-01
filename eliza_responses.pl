:- module(eliza_responses, [select_reply/2]).
:- use_module(eliza_rules_loader).
:- use_module(eliza_kb).
:- use_module(eliza_utils).
:- dynamic last_reply/1.

% select_reply(InputTokens, ReplyList)
select_reply(InputTokens, ReplyTokens) :-
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
select_reply(_, ['I', 'see.', 'Please', 'tell', 'me', 'more.']) :-
    writeln('[WARNING] No matching rules found, using fallback').

% pattern_matches supports '_' wildcard capturing rest or a single token.
% For simplicity, '_' captures the next token and '__' captures rest of line.
pattern_matches(PatternList, InputTokens, Captures) :-
    pattern_matches_(PatternList, InputTokens, [], Captures).

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
phrase_to_tokens(Atom, Tokens) :-
    split_string(Atom, " ", "", Parts),
    maplist(atom_string, Tokens, Parts).

% Replace placeholder token "__" or "__cap" with captured text(s)
fill_placeholders([], _Caps, []).
fill_placeholders([Tok|Rest], Caps, [OutTok|RestOut]) :-
    ( Tok = "__" ->
        ( Caps = [C|_] -> OutTok = C ; OutTok = "" )
    ; Tok = "____" ->  % double placeholder: join all captures
        atomic_list_concat(Caps, ' ', All), OutTok = All
    ; OutTok = Tok
    ),
    fill_placeholders(Rest, Caps, RestOut).