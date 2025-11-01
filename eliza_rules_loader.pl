:- module(eliza_rules_loader, [
    load_rule_files/1,
    pattern_rule/3
]).

:- dynamic pattern_rule/3.

% Load all .rules files from a folder
load_rule_files(RulesDir) :-
    writeln(['Checking folder:', RulesDir]),
    ( exists_directory(RulesDir) ->
        true
    ; writeln('[ERROR] Rules directory not found'), fail ),
    directory_files(RulesDir, Files),
    writeln(['Files in folder:', Files]),
    include(is_rule_file, Files, RuleFiles),
    writeln(['Rule files detected:', RuleFiles]),
    maplist(load_rule_file(RulesDir), RuleFiles),
    writeln('[Done loading rules.]').

% Identify *.rules files
is_rule_file(File) :-
    sub_atom(File, _, 6, 0, '.rules').

% Load one .rules file
load_rule_file(Dir, File) :-
    atomic_list_concat([Dir, '/', File], Path),
    read_file_to_string(Path, Content, []),
    split_string(Content, "\n", "\r\t ", Lines),
    maplist(process_rule_line, Lines).

% Skip blank lines or comments
process_rule_line(Line0) :-
    ( string(Line0) -> LineS = Line0 ; atom_string(Line0, LineS) ),
    normalize_space(string(Line), LineS),
    ( Line = "" -> true                       % empty line
    ; sub_string(Line, 0, 1, _, "%") -> true  % comment
    ; parse_and_assert_rule(Line)
    ).

parse_and_assert_rule(Line) :-
    writeln(['[Parsing line:]', Line]),
    split_string(Line, "|", "|", Parts),
    length(Parts, Len),
    ( Len >= 3 ->
        [WStr, PatternStr | RespStrings] = Parts,
        normalize_space(string(WTrim), WStr),
        ( catch(number_string(Weight, WTrim), _, fail) -> true ; Weight = 0 ),
        normalize_space(string(PatternClean), PatternStr),
        % Tokenize pattern
        split_string(PatternClean, " ", " ", PatternTokensRaw),
        maplist(pattern_token_transform, PatternTokensRaw, PatternTokens),
        % Process responses
        maplist(response_transform, RespStrings, RespAtoms),
        assertz(pattern_rule(Weight, PatternTokens, RespAtoms)),
        writeln(['[Rule OK]:', Weight, PatternTokens, '=>', RespAtoms])
    ; writeln(['[ERROR] Not enough parts in line:', Line]) ).
    
% Transform pattern tokens - handle wildcards
pattern_token_transform("*", '_') :- !.
pattern_token_transform("**", '__') :- !.
pattern_token_transform(X, Atom) :- atom_string(Atom, X).

% Transform response strings to atoms
response_transform(S0, Atom) :- 
    normalize_space(string(S), S0),
    atom_string(Atom, S).