:- [strategies].

% Fork
fork_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfOpponents) :-
    (
        atom_string(UCIPosition, UCIPositionString),
        map(UCIPositionString, CartesianPosition),
        atom_string(NextUCIPosition, NextUCIPositionString),
        map(NextUCIPositionString, NewCartesianPosition),
        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, fork_reason_helper(ListOfAttacks)),
        fork_reason_filter(Piece, Color, NextUCIPosition, ListOfAttacks, ListOfOpponents)
    ).

    fork_reason_helper(ListOfAttacks, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            once((
                can_fork(Piece, Color, NewCartesianPosition, _, _),
                all_piece_legal_attacks(Color, ListOfAttacks),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).
    
    fork_reason_filter(_, _, _, [], []).

    fork_reason_filter(Piece, Color, NextUCIPosition, ListOfAttacks, ListOfOpponents) :-
        ListOfAttacks = [Head | Rest],
        (
            (Piece, Color, NextUCIPosition, OpponentPosition) = Head,
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            return_pieces(OpponentPiece, OpponentColor, OpponentPosition),
            OpponentPiece \== pawn,
            fork_reason_filter(Piece, Color, NextUCIPosition, Rest, RemListOfOpponents),
            ListOfOpponents = [(OpponentPiece, OpponentColor, OpponentPosition) | RemListOfOpponents], !         
        ;
            fork_reason_filter(Piece, Color, NextUCIPosition, Rest, ListOfOpponents)
        ).

% Discovered Check
discovered_check_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfAttacks) :-
    (
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 

        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, discovered_check_reason_helper(ListOfAttacks))
    ).

    discovered_check_reason_helper(FilteredListOfAttacks, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            all_piece_legal_attacks(Color, ListOfAttacks),
            filter_attacks(ListOfAttacks, FilteredListOfAttacks),
            undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)            
        ).

    filter_attacks([], []).

    filter_attacks(ListOfAttacks, FilteredListOfAttacks) :-
        ListOfAttacks = [Head | Rest],
        (
            (Piece, Color, CurrentUCIPosition, AttackedPosition) = Head,
            atom_string(AttackedPosition, AttackedPositionString),
            map(AttackedPositionString, AttackedCartesianPosition),
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            occupies(king, OpponentColor, AttackedCartesianPosition),
            filter_attacks(Rest, RemFilteredListOfAttacks),
            FilteredListOfAttacks = [[Piece, Color, CurrentUCIPosition, AttackedPosition] | RemFilteredListOfAttacks]
        ;
            filter_attacks(Rest, FilteredListOfAttacks)
        ).

% Discovered Attack
discovered_attack_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfOpponents) :-
    (
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 

        all_piece_legal_attacks(Color, PrevListOfAttacks),      % get all legal attacks for color Color
        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, discovered_attack_reason_helper(PrevListOfAttacks, Difference)),  
        % format('Difference: ~w', Difference),   
        discovered_attack_reason_filter(Color, Difference, ListOfOpponents)     % select the opponents who are not pawns
    ).

    discovered_attack_reason_helper(PrevListOfAttacks, Difference, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPositionAtom),
            all_piece_legal_attacks(Color, NextListOfAttacks),
            filter_attack(Piece, Color, NewUCIPositionAtom, NextListOfAttacks, NewListFiltered),
            get_difference_in_moves(PrevListOfAttacks, NewListFiltered, Difference),
            once((
                Difference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                Difference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    discovered_attack_reason_filter(_, [], []).

    discovered_attack_reason_filter(Color, Difference, ListOfOpponents) :-
        Difference = [Head | Rest],
        (
            (Piece, Color, UCIPosition, OpponentUCIPosition) = Head,
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            return_pieces(OpponentPiece, OpponentColor, OpponentUCIPosition),
            OpponentPiece \== pawn,
            discovered_attack_reason_filter(Color, Rest, RemListOfOpponents),
            ListOfOpponents = [[Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition] | RemListOfOpponents], !         
        ;
            discovered_attack_reason_filter(Color, Rest, ListOfOpponents)
        ).

% Skewer
skewed_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfSkews) :-
    (
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 

        color(OpponentColor),  
        OpponentColor \== Color,
        OpponentColor \== none,

        all_skewed_helper(OpponentColor, [], PrevSkewedList),

        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, skewed_reason_helper(OpponentColor, PrevSkewedList, Difference)),
        % format('Difference: ~w', [Difference]),

        skewed_reason_structure(OpponentColor, Difference, ListOfSkews) % structure the list in the form of (piece1, color, position1) -[skews]->(piece2, color, position2) = (piece1, color, position1, piece2, color, position2)
    ).

    skewed_reason_helper(ColorOfOpponent, PreviousList, CheckedDifference, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            all_skewed_helper(ColorOfOpponent, [], NewSkewedList),
            % format('Piece ~w From ~w To ~w\n', [Piece, CartesianPosition, NewCartesianPosition]), format('PreviousList ~w\n', [PreviousList]), format('NewSkewedList ~w\n', [NewSkewedList]),
            flatten_skewed_list(NewSkewedList, [], NewSkewedListFlatten),
            flatten_skewed_list(PreviousList, [], PreviousListFlatten),
            % format('Piece ~w From ~w To ~w\n', [Piece, CartesianPosition, NewCartesianPosition]), format('PreviousListFlatten ~w\n', [PreviousListFlatten]), format('NewSkewedListFlatten ~w\n', [NewSkewedListFlatten]),
            get_difference_in_moves(PreviousListFlatten, NewSkewedListFlatten, Difference),
            % format('Difference ~w\n', [Difference]),

            is_legal_reason_skewed(Piece, Color, NewUCIPosition, Difference, CheckedDifference), !,
            % format('CheckedDifference ~w\n', [CheckedDifference]),

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_reason_skewed(_, _, _, [], []).

    is_legal_reason_skewed(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
        (
            Difference = [Head | Rest],
            (OpponentPiece, OpponentUCIPosition, OpponentSkewedForPosition) = Head,

            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,

            atom_string(OpponentUCIPosition, OpponentUCIPositionString),
            map(OpponentUCIPositionString, OpponentCartesianPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack1),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack1, PrevListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack1: ~w\n', [ListOfAllPiecesAttack1]),

            remove_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack2),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack2, NewListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack2: ~w\n', [ListOfAllPiecesAttack2]),

            add_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            % format('PrevListOfPieceLegalAttacks: ~w', [PrevListOfPieceLegalAttacks]),
            % format('NewListOfPieceLegalAttacks: ~w', [NewListOfPieceLegalAttacks]),

            ( 
                (
                    member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks),
                    member((Piece, Color, UCIPosition, OpponentSkewedForPosition), NewListOfPieceLegalAttacks), !,
                    is_legal_reason_skewed(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(member((Piece, Color, UCIPosition, OpponentSkewedForPosition), NewListOfPieceLegalAttacks))
                    ),
                    is_legal_reason_skewed(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

    % Difference: [(bishop,b6,c6),(bishop,b7,c8)]
    skewed_reason_structure(_, [], []).

    skewed_reason_structure(Color, TempList, ListOfSkews) :-
        (
            TempList = [Head | Rest],
            Head = (Piece1, UCIPosition1Atom, UCIPosition2Atom),
            
            atom_string(UCIPosition2Atom, UCIPosition2String),
            map(UCIPosition2String, CartesianPosition),
            occupies(Piece2, Color, CartesianPosition),
            
            skewed_reason_structure(Color, Rest, RemListOfSkews),
            ListOfSkews = [[Piece1, Color, UCIPosition1Atom, Piece2, Color, UCIPosition2Atom] | RemListOfSkews]
        ).


% Absolute Pin
absolute_pin_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfPins) :-
    (
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string

        color(OpponentColor),
        OpponentColor \== Color,
        OpponentColor \== none,

        all_absolute_pinned_pieces(OpponentColor, [], PrevPinnedList),  
        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, absolute_pin_reason_helper(OpponentColor, PrevPinnedList, Difference)),
        % format('Difference: ~w', [Difference]),

        absolute_pin_reason_structure(OpponentColor, Difference, ListOfPins)
    ).

    absolute_pin_reason_helper(ColorOfOpponent, PrevPinnedList, CheckedDifference, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            all_absolute_pinned_pieces(ColorOfOpponent, [], NewPinnedList),
            get_difference_in_moves(PrevPinnedList, NewPinnedList, Difference),
            % format('Absolute Pin Reason Difference: ~w', [Difference]),

            is_legal_absolute_reason_pinned(Piece, Color, NewUCIPosition, Difference, CheckedDifference),

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_absolute_reason_pinned(_, _, _, [], []).

    is_legal_absolute_reason_pinned(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
        (
            Difference = [Head | Rest],
            (OpponentPiece, OpponentColor, OpponentUCIPosition) = Head,
            occupies(king, OpponentColor, KingCartesianPosition),

            atom_string(OpponentUCIPosition, OpponentUCIPositionString),
            map(OpponentUCIPositionString, OpponentCartesianPosition),

            map(KingUCIPositionString, KingCartesianPosition),
            string_to_atom(KingUCIPositionString, KingUCIPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack1),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack1, PrevListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack1: ~w\n', [ListOfAllPiecesAttack1]),

            remove_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack2),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack2, NewListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack2: ~w\n', [ListOfAllPiecesAttack2]),

            add_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),
            
            (
                (
                    member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks),
                    member((Piece, Color, UCIPosition, KingUCIPosition), NewListOfPieceLegalAttacks), !,
                    is_legal_absolute_reason_pinned(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(member((Piece, Color, UCIPosition, KingUCIPosition), NewListOfPieceLegalAttacks))
                    ),
                    is_legal_absolute_reason_pinned(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

    absolute_pin_reason_structure(_, [], []).

    absolute_pin_reason_structure(Color, Difference, ListOfPins) :-
        (
            occupies(king, Color, KingCartesianPosition),
            map(KingUCIPositionString, KingCartesianPosition),
            string_to_atom(KingUCIPositionString, KingUCIPositionAtom),

            Difference = [Head | Rest],
            Head = (Piece, Color, UCIPosition),
            
            absolute_pin_reason_structure(_, Rest, RemListOfPins),
            ListOfPins = [[Piece, Color, UCIPosition, king, Color, KingUCIPositionAtom] | RemListOfPins]
        ).

% Relative Pin
relative_pin_reason(Piece, Color, UCIPosition, NextUCIPosition, ListOfPins) :-
    (
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string

        color(OpponentColor),
        OpponentColor \== Color,
        OpponentColor \== none,

        all_relative_pinned(OpponentColor, PrevPinnedList),  
        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, relative_pin_reason_helper(OpponentColor, PrevPinnedList, ListOfPins))

        % relative_pin_reason_structure(Difference, ListOfPins)
    ).

    relative_pin_reason_helper(ColorOfOpponent, PrevPinnedList, CheckedDifference, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            all_relative_pinned(ColorOfOpponent, NewPinnedList),
            % format('PrevPinnedList: ~w\n', [PrevPinnedList]), format('NewPinnedList: ~w\n', [NewPinnedList]),

            flatten_relative_pin_list(PrevPinnedList, [], PrevPinnedListFlatten),
            flatten_relative_pin_list(NewPinnedList, [], NewPinnedListFlatten),

            get_difference_in_moves(PrevPinnedListFlatten, NewPinnedListFlatten, Difference),
            % format('Reason Difference: ~w\n', [Difference]),
            
            is_legal_relative_reason_pinned(Piece, Color, NewUCIPosition, Difference, CheckedDifference),

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_relative_reason_pinned(_, _, _, [], []).

    is_legal_relative_reason_pinned(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
        (
            Difference = [Head | Rest],
            [OpponentPiece, OpponentColor, OpponentUCIPosition, _, _, OpponentPinnedForPosition] = Head,

            atom_string(OpponentUCIPosition, OpponentUCIPositionString),
            map(OpponentUCIPositionString, OpponentCartesianPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack1),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack1, PrevListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack1: ~w\n', [ListOfAllPiecesAttack1]),

            remove_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            all_piece_legal_attacks(Color, ListOfAllPiecesAttack2),
            piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack2, NewListOfPieceLegalAttacks),
            % format('ListOfAllPiecesAttack2: ~w\n', [ListOfAllPiecesAttack2]),

            add_piece(OpponentPiece, OpponentColor, OpponentCartesianPosition),
            
            (
                (
                    member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks),
                    member((Piece, Color, UCIPosition, OpponentPinnedForPosition), NewListOfPieceLegalAttacks), !,
                    is_legal_relative_reason_pinned(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(member((Piece, Color, UCIPosition, OpponentPinnedForPosition), NewListOfPieceLegalAttacks))
                    ),
                    is_legal_relative_reason_pinned(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

% MateIn2
mate_in_2_reason(Piece, Color, UCIPosition, NextUCIPosition, Reason) :-
    (
        map(UCIPositionString, CartesianPosition),              % map from UCI position to Cartesian position
        atom_string(NextUCIPosition, NextUCIPositionString),    % convert NextUCIPosition from atom to string
        map(NextUCIPositionString, NewCartesianPosition),       % map from Next UCI position to Cartesian position 
        atom_string(UCIPosition, UCIPositionString),            % convert UCIPosition from atom to string

        color(OpponentColor),
        OpponentColor \== Color,
        OpponentColor \== none,

        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, mate_in_2_reason_condition(OpponentColor, Reason))
    ).

    mate_in_2_reason_condition(ColorOfOpponent, ListofMovesToPlay, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            (
                in_check(ColorOfOpponent),
                play_a_move_cause_mate(ColorOfOpponent, [], ListofMovesToPlay),
                % format('ListofMovesToPlay: ~w\n', [ListofMovesToPlay]),
                ListofMovesToPlay \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;    
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail      
            )
        ).

    play_a_move_cause_mate(Color, ListOfVisitedPieces, ListofMovesToPlay) :-
        (
            % find a legal move of opponent.
            occupies(Piece, Color, CartesianPosition),
            % Piece \== king,
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
            % format("List of moves: ~w\n", [ListOfMoves]),
            play_a_move_cause_mate_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesToPlayPerPiece),
            % format("List of moves to play per piece: ~w\n", [ListofMovesToPlayPerPiece]),
            ListofMovesToPlayPerPiece \== [],
            play_a_move_cause_mate(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesToPlay),
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            append([[Piece, UCIPositionAtom, ListofMovesToPlayPerPiece]], RemListOfMovesToPlay, ListofMovesToPlay), !
        ).

    play_a_move_cause_mate(_, _, []).

    play_a_move_cause_mate_per_piece(_, _, _, [], []).

    play_a_move_cause_mate_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesToPlay) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, play_a_move_per_piece_condition(ListOfMovesCauseMate)),
                play_a_move_cause_mate_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesToPlay),
                map(NewUCIPositionString, NewCartesianPosition),
                string_to_atom(NewUCIPositionString, NewUCIPositionAtom),
                ListofMovesToPlay = [[NewUCIPositionAtom, ListOfMovesCauseMate] | RemListOfMovesToPlay], !
            ;
                play_a_move_cause_mate_per_piece(Piece, Color, CartesianPosition, Rest, ListofMovesToPlay)
            )
        ).

    play_a_move_per_piece_condition(ListOfMovesCauseMateAdjusted, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            color(ColorOfOpponent),
            ColorOfOpponent \== Color,
            ColorOfOpponent \== none,
            (
                moves_cause_mate(ColorOfOpponent, ListOfMovesCauseMate),     % Is there a move that cause a checkmate
                % format('ListOfMovesCauseMate ~w\n', [ListOfMovesCauseMate]),
                ListOfMovesCauseMate \== [],
                adjust_list(ListOfMovesCauseMate, ListOfMovesCauseMateAdjusted),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail      
            )
        ).

    %   [( queen, (8, 3), [(8, 7)] )] ), (h8, [(queen, (8, 3), [(8, 7)])])]
    adjust_list([], []).

    adjust_list(List, Result) :-
        (
            List = [Head| Rest],
            (Piece, CartesianPosition, ListOfMoves) = Head,
            % format('Head ~w\n', [Head]),
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            adjust_list_helper(ListOfMoves, Output),
            % format('Output ~w\n', [Output]),
            adjust_list(Rest, Rem),
            Result = [[Piece, UCIPositionAtom, Output]| Rem]
        ).

    adjust_list_helper([], []).

    adjust_list_helper(ListOfMoves, Result) :-
        (
            ListOfMoves = [CartesianPosition | Rest],
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            adjust_list_helper(Rest, Rem),
            Result = [UCIPositionAtom | Rem]
        ).

