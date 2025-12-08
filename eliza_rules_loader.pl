:- module(eliza_rules_loader,
    [ load_rule_files/1
    , pattern_rule/3
    ]).

:- use_module(library(readutil), [read_file_to_string/3]).

:- dynamic pattern_rule/3.

% ===============================
% Load all .rules files from dir
% ===============================

load_rule_files(RulesDir) :-
    (   exists_directory(RulesDir)
    ->  true
    ;   writeln('[ERROR] Rules directory not found'),
        fail
    ),
    directory_files(RulesDir, Files),
    include(is_rule_file, Files, RuleFiles),
    maplist(load_rule_file(RulesDir), RuleFiles).

% File name ends with ".rules"
is_rule_file(File) :-
    sub_atom(File, _, 6, 0, '.rules').

% Read one rules file and process each line
load_rule_file(Dir, File) :-
    atomic_list_concat([Dir, '/', File], Path),
    read_file_to_string(Path, Content, []),
    split_string(Content, "\n", "\r\t ", Lines),
    maplist(process_rule_line, Lines).

% ===============================
% Parsing individual rule lines
% ===============================

process_rule_line(Line0) :-
    (   string(Line0)
    ->  LineS = Line0
    ;   atom_string(Line0, LineS)
    ),
    normalize_space(string(Line), LineS),
    (   Line = "" ->
        true                          % skip empty
    ;   sub_string(Line, 0, 1, _, "%") ->
        true                          % skip comments
    ;   parse_and_assert_rule(Line)
    ).

parse_and_assert_rule(Line) :-
    split_string(Line, "|", "|", Parts),
    length(Parts, Len),
    (   Len >= 3 ->
        [WStr, PatternStr | RespStrings] = Parts,

        % Weight
        normalize_space(string(WTrim), WStr),
        (   catch(number_string(Weight, WTrim), _, fail)
        ->  true
        ;   Weight = 0
        ),

        % Pattern
        normalize_space(string(PatternClean), PatternStr),
        split_string(PatternClean, " ", " ", PatternTokensRaw),
        maplist(pattern_token_transform, PatternTokensRaw, PatternTokens),

        % Responses
        maplist(response_transform, RespStrings, RespAtoms),

        assertz(pattern_rule(Weight, PatternTokens, RespAtoms))
    ;   writeln('[ERROR] Not enough parts in rule line')
    ).

% ===============================
% Token & response transforms
% ===============================

% "*"  -> single-token wildcard symbol '_'
pattern_token_transform("*", '_') :- !.
% "**" -> rest-of-input wildcard symbol '__'
pattern_token_transform("**", '__') :- !.
% anything else -> normal atom
pattern_token_transform(TokenStr, TokenAtom) :-
    normalize_space(string(Clean), TokenStr),
    Clean \= "",
    atom_string(TokenAtom, Clean).

% Clean response strings and store as atoms
response_transform(Str, Atom) :-
    normalize_space(string(Clean), Str),
    Clean \= "",
    atom_string(Atom, Clean).
