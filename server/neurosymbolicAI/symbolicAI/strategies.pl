:- [utils].

% Fork [Tested]
% Rule: A move that would cause threat on two Opponent's pieces that are not pawns.
move_cause_fork(Color,  Piece, UCIPosition, ListOfMoves) :-
    (
        moves_cause_fork_helper(Color, [], ListOfMovesCauseFork),
        output_seq(ListOfMovesCauseFork, Piece, UCIPosition, ListOfMoves)
    ).
   
    moves_cause_fork_helper(Color, ListOfVisitedPieces, ListOfMovesCauseFork) :-
    (
        occupies(Piece, Color, CartesianPosition),
        \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
        piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
        moves_cause_fork_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseForkPerPiece),
        ListofMovesCauseForkPerPiece \== [],
        moves_cause_fork_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseFork),
        append([(Piece, CartesianPosition, ListofMovesCauseForkPerPiece)], RemListOfMovesCauseFork, ListOfMovesCauseFork), !
    ).

    moves_cause_fork_helper(_, _, []).

    moves_cause_fork_per_piece(_, _, _, [], []).

    moves_cause_fork_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseFork) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, fork_condition),
                moves_cause_fork_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseFork),
                ListOfMovesCauseFork = [NewCartesianPosition | RemListOfMovesCauseFork], !
            ;
                moves_cause_fork_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseFork)
            )
        ).

    fork_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            once((
                can_fork(Piece, Color, NewCartesianPosition, _, _),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    fork(Color, Piece, UCIPosition, Opponent1, Opponent2):-
        (
            all_fork(Color, [], ListOfPositions),
            fork_helper(ListOfPositions, Piece, UCIPosition, Opponent1, Opponent2)
        ).

    fork_helper(List, Piece, Position, Opponent1, Opponent2) :-
        (
            List = [Head | _],
            (Piece, Position, Opponent1, Opponent2) = Head
        ;
            List = [_ | Tail],
            fork_helper(Tail, Piece, Position, Opponent1, Opponent2)
        ).

    all_fork(Color, ListOfPiecesCanForkSoFar, ListOfPiecesCanFork) :-
        (
            occupies(Piece, Color, CartesianPosition),
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            can_fork(Piece, Color, CartesianPosition, OpponentSanPositionAtom1, OpponentSanPositionAtom2),
            \+((
                member((Piece, UCIPositionAtom, OpponentSanPositionAtom1, OpponentSanPositionAtom2), ListOfPiecesCanForkSoFar))
            ;
                member((Piece, UCIPositionAtom, OpponentSanPositionAtom2, OpponentSanPositionAtom1), ListOfPiecesCanForkSoFar)
            ),!,
            all_fork(Color, [(Piece, UCIPositionAtom, OpponentSanPositionAtom1, OpponentSanPositionAtom2) | ListOfPiecesCanForkSoFar], ListOfPiecesCanFork)
        ).

    all_fork(_, Result, Result).

    can_fork(Piece, Color, CartesianPosition, OpponentSanPositionAtom1, OpponentSanPositionAtom2) :- % Must be instantiated (Piece)
        once((
            occupies(Piece, Color, CartesianPosition),
            Piece \== king,
            Color \== none,

            occupies(OpponentPiece1, OpponentColor, OpponentCartesiahPosition1),
            OpponentPiece1 \== pawn,
            OpponentPiece1 \== none,
            Color \== OpponentColor,
            OpponentColor \== none,

            occupies(OpponentPiece2, OpponentColor, OpponentCartesianPosition2),
            OpponentPiece2 \== pawn,
            OpponentPiece2 \== none,

            map(SanPositionString, CartesianPosition),
            map(OpponentSanPositionString1, OpponentCartesiahPosition1),
            map(OpponentSanPositionString2, OpponentCartesianPosition2),
            string_to_atom(SanPositionString, SanPositionAtom),
            string_to_atom(OpponentSanPositionString1, OpponentSanPositionAtom1),
            string_to_atom(OpponentSanPositionString2, OpponentSanPositionAtom2),

            threat(Piece, Color, SanPositionAtom, OpponentPiece1, OpponentColor, OpponentSanPositionAtom1),
            threat(Piece, Color, SanPositionAtom, OpponentPiece2, OpponentColor, OpponentSanPositionAtom2),
            OpponentSanPositionAtom1 \== OpponentSanPositionAtom2
        )).
%end

% Pins [Tested]
% Absolute Pin: a piece is pinned absolutely cannot move otherwise a check would occur.
move_cause_absolute_pin(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        moves_cause_abs_pin_helper(Color, [], ListOfMovesCauseAbsPin),
        output_seq(ListOfMovesCauseAbsPin, Piece, UCIPosition, ListOfMoves)
    ).

    moves_cause_abs_pin_helper(Color, ListOfVisitedPieces, ListOfMovesCausePin) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            moves_cause_abs_pin_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCausePinPerPiece),
            ListofMovesCausePinPerPiece \== [],
            moves_cause_abs_pin_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCausePin),
            append([(Piece, CartesianPosition, ListofMovesCausePinPerPiece)], RemListOfMovesCausePin, ListOfMovesCausePin), !
        ).
    
    moves_cause_abs_pin_helper(_, _, []).

    moves_cause_abs_pin_per_piece(_, _, _, [], []).

    moves_cause_abs_pin_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCausePin) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,

            all_absolute_pinned_pieces(OpponentColor, [], PrevPinnedList),

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, absolute_pin_condition(OpponentColor, PrevPinnedList)),
                moves_cause_abs_pin_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCausePin),
                ListOfMovesCausePin = [NewCartesianPosition | RemListOfMovesCausePin], !
            ;
                moves_cause_abs_pin_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCausePin)
            )
        ).

    absolute_pin_condition(ColorOfOpponent, PrevPinnedList, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),
            
            all_absolute_pinned_pieces(ColorOfOpponent, [], NewPinnedList),
            get_difference_in_moves(PrevPinnedList, NewPinnedList, Difference),
            % format('Strategy Difference: ~w', [Difference]),
            
            is_legal_absolute_pinned(Piece, Color, NewUCIPosition, Difference, CheckedDifference),

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_absolute_pinned(_, _, _, [], []).

    is_legal_absolute_pinned(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
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
                    is_legal_absolute_pinned(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(member((Piece, Color, UCIPosition, KingUCIPosition), NewListOfPieceLegalAttacks))
                    ),
                    is_legal_absolute_pinned(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

    absolute_pin(Color, Piece, UCIPosition) :-
        (
            all_absolute_pinned_pieces(Color, [], ListOfPinedPieces),
            absolute_pin_helper(ListOfPinedPieces, Piece, UCIPosition)
        ).

    absolute_pin_helper(List, Piece, Position) :-
        (
            List = [(Piece, _, Position) | _]
        ;
            List = [_ | Rest],
            absolute_pin_helper(Rest, Piece, Position)
        ).

    all_absolute_pinned_pieces(Color, ListOfVistedPieces, ListOfPinedPieces) :-
        (
            occupies(Piece, Color, CartesianPosition),
            Piece \== king,
            \+(member((Piece, CartesianPosition) , ListOfVistedPieces)),
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            % format('\nBefore predicate  is_absolute_pinned(~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom]),display_board,
            is_absolute_pinned(Piece, Color, UCIPositionAtom),
            % format('\nAfter predicate  is_absolute_pinned(~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom]), display_board,
            % format('~w\n', [ListOfVistedPieces]),
            all_absolute_pinned_pieces(Color, [(Piece, CartesianPosition) | ListOfVistedPieces], Res),
            ListOfPinedPieces = [(Piece, Color, UCIPositionAtom) | Res], !
        ).

    all_absolute_pinned_pieces(_, _, []).

    is_absolute_pinned(Piece, Color, UCIPositionAtom) :-
        (
            (
                is_white(Color),
                occupies(Piece, Color, CartesianPosition),
                map(UCIPositionString, CartesianPosition),
                string_to_atom(UCIPositionString, UCIPositionAtom),

                range_pieces_legal_attack(black, ListOfLegalAttacks1),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks1, LegalAttacks1),
                % format("Moves before remove: ~w\n", [LegalAttacks1]),
                remove_piece(Piece, Color, CartesianPosition),

                range_pieces_legal_attack(black, ListOfLegalAttacks2),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks2, LegalAttacks2),
                % format("Moves after remove: ~w\n", [LegalAttacks2]),
                add_piece(Piece, Color, CartesianPosition),
                
                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),
                
                get_difference_in_moves(L1, L2, Difference),
                % format('Difference ~w', [Difference]),
                Difference \== [],
                pinned_for_king(Piece, Color, CartesianPosition, Difference)
            )
        ;
            (
                is_black(Color),
                occupies(Piece, Color, CartesianPosition),
                map(UCIPositionString, CartesianPosition),
                string_to_atom(UCIPositionString, UCIPositionAtom),
                % format('\n Before is_absolute_pinned(~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom]), display_board,
                range_pieces_legal_attack(white, ListOfLegalAttacks1),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks1, LegalAttacks1),
                % format("Moves before remove: ~w\n", [LegalAttacks1]),
                remove_piece(Piece, Color, CartesianPosition),

                range_pieces_legal_attack(white, ListOfLegalAttacks2),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks2, LegalAttacks2),
                % format("Moves after remove: ~w\n", [LegalAttacks2]),
                add_piece(Piece, Color, CartesianPosition),
                
                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),  

                get_difference_in_moves(L1, L2, Difference), !,
                Difference \== [],
                % format('Difference ~w', [Difference]),
                % format('\n After is_absolute_pinned(~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom]), display_board,
                pinned_for_king(Piece, Color, CartesianPosition, Difference)
            )
        ).
%end

% Relative Pin [Tested]
% Rule: A piece that defend a piece of higher value and if it moved this piece will be attacked if it stayed the piece is not attacked.
move_cause_relative_pin(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        moves_cause_relative_pin_helper(Color, [], ListOfMovesCauseRelativePin),
        output_seq(ListOfMovesCauseRelativePin, Piece, UCIPosition, ListOfMoves)
    ).

    moves_cause_relative_pin_helper(Color, ListOfVisitedPieces, ListOfMovesCausePin) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            moves_cause_relative_pin_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCausePinPerPiece),
            ListofMovesCausePinPerPiece \== [],
            moves_cause_relative_pin_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCausePin),
            append([(Piece, CartesianPosition, ListofMovesCausePinPerPiece)], RemListOfMovesCausePin, ListOfMovesCausePin), !
        ).
    
    moves_cause_relative_pin_helper(_, _, []).

    moves_cause_relative_pin_per_piece(_, _, _, [], []).

    moves_cause_relative_pin_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCausePin) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,

            all_relative_pinned(OpponentColor, PrevPinnedList),

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, relative_pin_condition(OpponentColor, PrevPinnedList)),
                moves_cause_relative_pin_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCausePin),
                ListOfMovesCausePin = [NewCartesianPosition | RemListOfMovesCausePin], !
            ;
                moves_cause_relative_pin_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCausePin)
            )
        ).

    relative_pin_condition(ColorOfOpponent, PrevPinnedList, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            all_relative_pinned(ColorOfOpponent, NewPinnedList),

            get_difference_in_moves(PrevPinnedList, NewPinnedList, Difference),
            % format('Difference: ~w', [Difference]),

            is_legal_relative_pinned(Piece, Color, NewUCIPosition, Difference, CheckedDifference),
            % format('CheckedDifference: ~w', [CheckedDifference]),

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_relative_pinned(_, _, _, [], []).

    is_legal_relative_pinned(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
        (
            Difference = [Head | Rest],
            (OpponentPiece, OpponentColor, OpponentUCIPosition, ListOfRelativePinnedUCIPositions) = Head,

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
                    % format('ListOfRelativePinnedUCIPositions: ~w', [ListOfRelativePinnedUCIPositions]),
                    is_legal_relative_pinned_helper(Piece, Color, UCIPosition, NewListOfPieceLegalAttacks, ListOfRelativePinnedUCIPositions), !,
                    is_legal_relative_pinned(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(is_legal_relative_pinned_helper(Piece, Color, UCIPosition, NewListOfPieceLegalAttacks, ListOfRelativePinnedUCIPositions))
                    ),
                    is_legal_relative_pinned(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

    is_legal_relative_pinned_helper(Piece, Color, UCIPosition, ListOfAttacks, ListOfRelativePins):- 
        ListOfRelativePins = [OpponentUCIPosition | Rest],
        (
            (
                member((Piece, Color, UCIPosition, OpponentUCIPosition), ListOfAttacks), !
            )
        ;
            (
                is_legal_relative_pinned_helper(Piece, Color, UCIPosition, ListOfAttacks, Rest)
            )
        ).

    flatten_relative_pin_list([], List, List).

    flatten_relative_pin_list(ListOfSkewedPieces, ResultSoFar, FlattenListOfRelativePinnedPieces) :-
        (
            ListOfSkewedPieces = [Head | Rest],
            (Piece, Color, UCIPosition, ListOfDependentPieces) = Head,
            % format('ListOfDependentPieces ~w\n', [ListOfDependentPieces]),
            flatten_relative_pin_list_helper(Piece, Color, UCIPosition, ListOfDependentPieces, ResultPerPiece),
            append(ResultSoFar, ResultPerPiece, NewResultSoFar),
            % format('NewResultSoFar ~w\n', [NewResultSoFar]),
            % format('Rest ~w\n', [Rest]),
            flatten_relative_pin_list(Rest, NewResultSoFar, FlattenListOfRelativePinnedPieces)
        ).

    flatten_relative_pin_list_helper(_, _, _, [], []).

    flatten_relative_pin_list_helper(Piece, Color, UCIPosition, ListOfDependentPieces, ResultPerPiece) :-
        (
            ListOfDependentPieces = [AllyUCIPosition | Rest],
            flatten_relative_pin_list_helper(Piece, Color, UCIPosition, Rest, RemResultPerPiece),

            atom_string(AllyUCIPosition, AllyUCIPositionString),
            map(AllyUCIPositionString, AllyCartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),

            ResultPerPiece = [[Piece, Color, UCIPosition, AllyPiece, Color, AllyUCIPosition] | RemResultPerPiece]
            % format('ResultPerPiece ~w\n', [ResultPerPiece])
        ).

    relative_pin(Color, Piece, UCIPosition, ListOfPositions) :-
        (
            all_relative_pinned(Color, ListOfPinnedPositions),
            output_seq2(ListOfPinnedPositions, Piece, UCIPosition, ListOfPositions)
        ).

    all_relative_pinned(Color, ListOfPinnedPieces) :-
        (
            all_relative_pinned_helper(Color, [], ListOfPinnedPieces)
        ).

    all_relative_pinned_helper(Color, ListOfPiecesPinnedSoFar, ListOfPinnedPieces) :-
        (
            occupies(Piece, Color, CartesianPosition),
            Piece \== none,
            Piece \== king,
            Color \== none,
            is_relative_pinned(Piece, Color, CartesianPosition, ForList),
            ForList \== [],
            map(SanPositionString, CartesianPosition),
            string_to_atom(SanPositionString, SanPositionAtom),
            \+(member((Piece, Color, SanPositionAtom, ForList), ListOfPiecesPinnedSoFar)), !,
            all_relative_pinned_helper(Color, [(Piece, Color, SanPositionAtom, ForList) | ListOfPiecesPinnedSoFar], ListOfPinnedPieces)
        ).

    all_relative_pinned_helper(_, Result, Result).

    is_relative_pinned(Piece, Color, CartesianPosition, ForList) :-
        (
            (
                is_white(Color),
                range_pieces_legal_attack(black, ListOfLegalAttacks1),
                remove_piece(Piece, Color, CartesianPosition),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks1, LegalAttacks1),
                % format("Moves before remove: ~w\n", [LegalAttacks1]),

                range_pieces_legal_attack(black, ListOfLegalAttacks2),
                add_piece(Piece, Color, CartesianPosition),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks2, LegalAttacks2),
                % format("Moves after remove: ~w\n", [LegalAttacks2]),
                
                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),
                
                get_difference_in_moves(L1, L2, Difference),
                Difference \== [],
                pinned_for_list(Piece, Color, Difference, ForList)
            )
        ;
            (
                is_black(Color),

                range_pieces_legal_attack(white, ListOfLegalAttacks1),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks1, LegalAttacks1),
                % format("\n Moves before remove: ~w\n", [LegalAttacks1]), display_board,
                remove_piece(Piece, Color, CartesianPosition),

                range_pieces_legal_attack(white, ListOfLegalAttacks2),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks2, LegalAttacks2),
                % format("\n Moves after remove: ~w\n", [LegalAttacks2]), display_board,
                add_piece(Piece, Color, CartesianPosition),
                
                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),  

                % format('L1: ~w\n', [L1]),
                % format('L2: ~w\n', [L2]),

                get_difference_in_moves(L1, L2, Difference),
                % format('Difference: ~w\n', [Difference]),
                Difference \== [],
                pinned_for_list(Piece, Color, Difference, ForList)
            ), !
        ).

    pinned_for_king(_, _, _, []) :- !, fail.

    pinned_for_king(Piece, Color, Position, ListOfPositions) :- 
        (
            ListOfPositions = [AllyPositionUnderAttackAtom| Rest],
            atom_string(AllyPositionUnderAttackAtom, AllyPositionUnderAttackString),
            map(AllyPositionUnderAttackString, AllyCartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),
            (
                % format('\n Before piece_legal_moves(~w, ~w, ~w)\n', [Piece, Color, Position]), display_board,
                piece_legal_moves(Piece, Color, Position, []),
                % format('\n After piece_legal_moves(~w, ~w, ~w)\n', [Piece, Color, Position]), display_board,
                AllyPiece == king,
                % format("Piece ~w is pinned for ~w\n", [Piece, AllyPiece]),
                !
            ;
                pinned_for_king(Piece, Color, Position, Rest)
            )
        ).

    pinned_for_list(_, _, [], []).

    pinned_for_list(Piece, Color, ListOfPositions, Result) :- 
        (
            ListOfPositions = [AllyPositionUnderAttackAtom| Rest],
            atom_string(AllyPositionUnderAttackAtom, AllyPositionUnderAttackString),
            map(AllyPositionUnderAttackString, AllyCartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),
            evaluate_piece(Piece, Val1),
            evaluate_piece(AllyPiece, Val2),
            (
                Val2 > Val1,
                AllyPiece \== king,
                pinned_for_list(Piece, Color, Rest, RemResult),
                Result = [AllyPositionUnderAttackAtom | RemResult],
                !
            ;
                pinned_for_list(Piece, Color, Rest, Result)
            )
        ).
%end

% Skewer: [Tested]
% Rule: A move would cause an Opponent's piece to be skewed if the opponent's piece is not already skewed. 
move_cause_skewer(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        moves_cause_skewer_helper(Color, [], ListOfMovesCauseSkewer),
        output_seq(ListOfMovesCauseSkewer, Piece, UCIPosition, ListOfMoves)
    ).
    
    moves_cause_skewer_helper(Color, ListOfVisitedPieces, ListOfMovesCauseSkewer) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            moves_cause_skewer_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseSkewerPerPiece),
            ListofMovesCauseSkewerPerPiece \== [],
            moves_cause_skewer_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseSkewer),
            append([(Piece, CartesianPosition, ListofMovesCauseSkewerPerPiece)], RemListOfMovesCauseSkewer, ListOfMovesCauseSkewer), !
        ).

    moves_cause_skewer_helper(_, _, []).

    moves_cause_skewer_per_piece(_, _, _, [], []).

    moves_cause_skewer_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseSkewer) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],

            color(OpponentColor),  
            OpponentColor \== Color,
            OpponentColor \== none,

            all_skewed_helper(OpponentColor, [], PrevSkewedList),

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, skewer_condition(OpponentColor, PrevSkewedList)),
                moves_cause_skewer_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseSkewer),
                ListOfMovesCauseSkewer = [NewCartesianPosition | RemListOfMovesCauseSkewer], !
            ;
                moves_cause_skewer_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseSkewer)
            )
        ).

    skewer_condition(ColorOfOpponent, PreviousList, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),    
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            all_skewed_helper(ColorOfOpponent, [], NewSkewedList),
            % format('Piece ~w From ~w To ~w\n', [Piece, CartesianPosition, NewCartesianPosition]), format('PreviousList ~w\n', [PreviousList]), format('NewSkewedList ~w\n', [NewSkewedList]),
            
            flatten_skewed_list(NewSkewedList, [], NewSkewedListFlatten),
            flatten_skewed_list(PreviousList, [], PreviousListFlatten),
            % format('Piece ~w From ~w To ~w\n', [Piece, CartesianPosition, NewCartesianPosition]), format('PreviousListFlatten ~w\n', [PreviousListFlatten]), format('NewSkewedListFlatten ~w\n', [NewSkewedListFlatten]),
            
            get_difference_in_moves(PreviousListFlatten, NewSkewedListFlatten, Difference),
            % format('Difference: ~w\n', [Difference]),

            is_legal_skewed(Piece, Color, NewUCIPosition, Difference, CheckedDifference),
            % format('CheckedDifference ~w\n', [CheckedDifference]), !,

            once((
                CheckedDifference \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                CheckedDifference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

    is_legal_skewed(_, _, _, [], []).

    is_legal_skewed(Piece, Color, UCIPosition, Difference, CheckedDifference) :-
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
                    is_legal_skewed(Piece, Color, UCIPosition, Rest, RemCheckedDifference),
                    CheckedDifference = [Head | RemCheckedDifference]
                )
                ;
                (
                    (
                        \+(member((Piece, Color, UCIPosition, OpponentUCIPosition), PrevListOfPieceLegalAttacks))
                    ;
    
                        \+(member((Piece, Color, UCIPosition, OpponentSkewedForPosition), NewListOfPieceLegalAttacks))
                    ),
                    is_legal_skewed(Piece, Color, UCIPosition, Rest, CheckedDifference)
                )
            )
        ).

    flatten_skewed_list([], List, List).

    flatten_skewed_list(ListOfSkewedPieces, ResultSoFar, FlattenListOfSkewedPieces) :-
        (
            ListOfSkewedPieces = [Head | Rest],
            (Piece, CartesianPosition, ListOfDependentPieces) = Head,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),

            flatten_skewed_list_helper(Piece, UCIPositionAtom, ListOfDependentPieces, ResultPerPiece),
            append(ResultSoFar, ResultPerPiece, NewResultSoFar),
            % format('ResultSoFar ~w\n', [ResultSoFar]),
            flatten_skewed_list(Rest, NewResultSoFar, FlattenListOfSkewedPieces)
        ).

    flatten_skewed_list_helper(_, _, [], []).

    flatten_skewed_list_helper(Piece, UCIPositionAtom, ListOfDependentPieces, ResultPerPiece) :-
        (
            ListOfDependentPieces = [AllyCartesianPosition | Rest],
            map(AllyUCIPositionString, AllyCartesianPosition),
            string_to_atom(AllyUCIPositionString, AllyUCIPositionAtom),
            flatten_skewed_list_helper(Piece, UCIPositionAtom, Rest, RemResultPerPiece),
            ResultPerPiece = [(Piece, UCIPositionAtom, AllyUCIPositionAtom) | RemResultPerPiece]
            % format('ResultPerPiece ~w', [ResultPerPiece])
        ).

    skewer(Color, Piece, UCIPosition, ListOfMoves) :-
        (
            all_skewed_helper(Color, [], ListOfSkewedPieces),
            output_seq(ListOfSkewedPieces, Piece, UCIPosition, ListOfMoves) 
        ).

    all_skewed_helper(Color, ListOfPiecesSkewedSoFar, ListOfSkewedPieces) :-
        (
            occupies(Piece, Color, CartesianPosition),
            Piece \== none,
            Color \== none,
            is_skewed(Piece, Color, CartesianPosition, ForList),
            ForList \== [],
            \+(member((Piece, CartesianPosition, ForList), ListOfPiecesSkewedSoFar)), !,
            all_skewed_helper(Color, [(Piece, CartesianPosition, ForList) | ListOfPiecesSkewedSoFar], ListOfSkewedPieces)
        ).

    all_skewed_helper(_, Result, Result).

    is_skewed(Piece, Color, CartesianPosition, ForList) :-
        (
            (
                is_white(Color),                                                                
                range_pieces_legal_attack(black, ListOfLegalAttacks1),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks1, LegalAttacks1),
                % format("Moves before remove: ~w\n", [LegalAttacks1]),

                remove_piece(Piece, Color, CartesianPosition),

                range_pieces_legal_attack(black, ListOfLegalAttacks2),
                find_pieces_to_attack_from_moves(black, ListOfLegalAttacks2, LegalAttacks2),
                % format("Moves after remove: ~w\n", [LegalAttacks2]),
                
                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),
                
                add_piece(Piece, Color, CartesianPosition),
                get_difference_in_moves(L1, L2, Difference),
                % format('Difference: ~w\n', [Difference]),
                skewed_for_list(Piece, Color, Difference, ForList)
            )
        ;
            (
                is_black(Color),
                range_pieces_legal_attack(white, ListOfLegalAttacks1),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks1, LegalAttacks1),
                % format("Moves before remove: ~w\n", [LegalAttacks1]),
                
                remove_piece(Piece, Color, CartesianPosition),

                range_pieces_legal_attack(white, ListOfLegalAttacks2),
                find_pieces_to_attack_from_moves(white, ListOfLegalAttacks2, LegalAttacks2),
                % format("Moves after remove: ~w\n", [LegalAttacks2]),

                filter_to_list_of_squares(LegalAttacks1, L1),
                filter_to_list_of_squares(LegalAttacks2, L2),
                
                add_piece(Piece, Color, CartesianPosition),
                get_difference_in_moves(L1, L2, Difference),
                skewed_for_list(Piece, Color, Difference, ForList)
            ),
            !
        ).

    skewed_for(_, _, []) :- !, fail.

    skewed_for(Piece, Color, ListOfPositions) :- 
        (
            ListOfPositions = [AllyPositionUnderAttackAtom| Rest],
            atom_string(AllyPositionUnderAttackAtom, AllyPositionUnderAttackString),
            map(AllyPositionUnderAttackString, AllyCartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),
            evaluate_piece(Piece, Val1),
            evaluate_piece(AllyPiece, Val2),
            (
                Val2 =< Val1, 
                % format("Piece ~w is skewed for ~w\n", [Piece, AllyPiece]),
                !
            ;
                skewed_for(Piece, Color, Rest)
            )
        ).

    skewed_for_list(_, _, [], []).

    skewed_for_list(Piece, Color, ListOfPositions, Result) :- 
        (
            ListOfPositions = [AllyPositionUnderAttackAtom| Rest],
            % format('AllyPositionUnderAttackAtom ~w ', [AllyPositionUnderAttackAtom]),
            atom_string(AllyPositionUnderAttackAtom, AllyPositionUnderAttackString),
            map(AllyPositionUnderAttackString, AllyCartesianPosition),

            occupies(AllyPiece, Color, AllyCartesianPosition),
            % format('(~w, ~w, ~w)', [AllyPiece, Color, AllyCartesianPosition]),
            evaluate_piece(Piece, Val1),
            evaluate_piece(AllyPiece, Val2),

            (
                Val2 =< Val1,
                AllyPiece \== pawn,
                skewed_for_list(Piece, Color, Rest, RemResult),
                Result = [AllyCartesianPosition | RemResult],
                !
            ;
                skewed_for_list(Piece, Color, Rest, Result)
            )
        ).
%end

% Mate in Two [Tested]
% Rule: 
moves_cause_mate_in_two(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        move_cause_mate_in_2_helper(Color, [], ListOfMovesCauseMatIn2), !,
        output_seq(ListOfMovesCauseMatIn2, Piece, UCIPosition, ListOfMoves)
    ).

% Discovered Attack [Tested]
% Rule: 
discover_attack(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        move_cause_discover(Color, ListOfMovesCauseNoThreatAndControl), !,
        output_seq(ListOfMovesCauseNoThreatAndControl, Piece, UCIPosition, ListOfMoves)
    ).

    can_discover_attack(Color, ListOfMovesCauseNoThreatAndControl) :-    % Deprecated
        (
            moves_cause_control(Color, ListOfMovesCauseControl),
            % format('Moves Cause Control: ~w \n', [ListOfMovesCauseControl]),

            moves_cause_threat(Color, ListOfMovesCauseThreat),
            % format('Moves Cause Threat: ~w \n', [ListOfMovesCauseThreat]),

            get_intersection_of_moves(ListOfMovesCauseThreat, ListOfMovesCauseControl, ListOfMovesCauseNoThreatAndControl)
            % format('Moves Cause Control and Not be Threat: ~w \n', [ListOfMovesCauseNoThreatAndControl])
        ).

    get_intersection_of_moves([], _, []).

    get_intersection_of_moves(ListOfMoves1, ListOfMoves2, ListOfIntersectionOfMoves) :-
        (
            ListOfMoves1 = [Tuple1 | Tail1],
            get_tuple(Tuple1, ListOfMoves2, IntersectionPerTuple),
            get_intersection_of_moves(Tail1, ListOfMoves2, RemListOfIntersectionOfMoves),
            ListOfIntersectionOfMoves = [IntersectionPerTuple | RemListOfIntersectionOfMoves], !
        ;
            ListOfMoves1 = [Tuple1 | Tail1],
            \+(get_tuple(Tuple1, ListOfMoves2, _)),
            get_intersection_of_moves(Tail1, ListOfMoves2, ListOfIntersectionOfMoves), !   
        ).

    get_intersection_of_moves(ListOfMoves1, ListOfMoves2, ListOfIntersectionOfMoves) :-
        (
            ListOfMoves1 = [_ | Tail1],
            get_intersection_of_moves(Tail1, ListOfMoves2, ListOfIntersectionOfMoves)
        ).
    
    get_tuple(Tuple, List, Result) :-
        (
            List = [HeadTuple | _], 
            (Piece, CartesianPosition, ListOfMoves1) = HeadTuple,
            (Piece, CartesianPosition, ListOfMoves2) = Tuple,
            get_intersection(ListOfMoves1, ListOfMoves2, Interesection),
            Interesection \== [],
            Result = (Piece, CartesianPosition, Interesection)
        ).

    get_tuple(Tuple, List, Result) :-
        (   
            List = [HeadTuple | Tail],
            (_, OtherCartesianPosition, _) = HeadTuple,
            (_, CartesianPosition, _) = Tuple,
            OtherCartesianPosition \== CartesianPosition,
            get_tuple(Tuple, Tail, Result)          
        ).

    get_intersection([], _ , []).

    get_intersection(ListOfMoves1, ListOfMoves2, ListOfIntersection) :- 
        (
            ListOfMoves1 = [Move | Rest],
            member(Move, ListOfMoves2),
            get_intersection(Rest, ListOfMoves2, RemListOfIntersection),
            ListOfIntersection = [Move | RemListOfIntersection], !
        ).

    get_intersection([_ | Rest], ListOfMoves2, ListOfIntersection) :- 
        (
            get_intersection(Rest, ListOfMoves2, ListOfIntersection)
        ).
%end

% Discovered Check [Tested]
% Rule: 
discover_check(Color, Piece, UCIPosition, ListOfMoves) :-
    (
        can_discover_check(Color, ListOfMovesCauseCheck), !,
        output_seq(ListOfMovesCauseCheck, Piece, UCIPosition, ListOfMoves)
    ).

    can_discover_check(Color, ListOfMovesCauseCheck) :-
        (
            moves_cause_check(Color, ListOfMovesCauseCheck)
        ).

% Hanging Piece [Tested]
% Rule:
hanging_piece(Color, Piece, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition) :-
    (
        all_threat(Color, [], List),
        hanging_piece_helper(List, Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition)
    ).

    hanging_piece_helper(List, Piece, Color, UCIPosition, OpponentPiece, OpponentColor,  OpponentUCIPosition) :-
        (
            List = [Head | _],
            (Piece, Color, UCIPosition, OpponentPiece, OpponentColor,  OpponentUCIPosition) = Head
        ;
            List= [_ | Tail],
            hanging_piece_helper(Tail, Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition)
        ).

    all_threat(Color, ListOfThreatedPiecesSoFar, Result) :-
        (
            occupies(Piece, Color, CartesianPosition),
            occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPositionAtom),
            map(OpponentUCIPositionString, OpponentCartesianPosition),
            string_to_atom(OpponentUCIPositionString, OpponentUCIPositionAtom),

            % format('Before (~w, ~w, ~w) threats (~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor, OpponentUCIPositionAtom]),
            threat(Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor, OpponentUCIPositionAtom),
            % format('After (~w, ~w, ~w) threats (~w, ~w, ~w)\n', [Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor, OpponentUCIPositionAtom]), display_board,
            \+(member((Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor,  OpponentUCIPositionAtom), ListOfThreatedPiecesSoFar)), 
            \+((
                defend(_, OpponentColor, OtherOpponentCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition),
                OtherOpponentCartesianPosition \== OpponentCartesianPosition
            )), 
            !,
            % format('No piece defends (~w, ~w, ~w)\n', [OpponentPiece, OpponentColor, OpponentUCIPositionAtom]), display_board,
            all_threat(Color, [(Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor, OpponentUCIPositionAtom) | ListOfThreatedPiecesSoFar], Result)
        ).

    all_threat(_, List, List).

% Protection
% Rule:
protect(Piece, Color, UCIPosition, AllyPiece, UCIAllyPosition) :-
    (
        defend(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition),  
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        map(UCAllyIPositionString, AllyCartesianPosition),
        string_to_atom(UCAllyIPositionString, UCIAllyPosition)
    ).

% Interference
% Rule:
interference(Color, Piece, UCIPosition, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentUCIPosition1, OpponentPiece2, OpponentColor2, OpponentUCIPosition2) :-
    (
        move_cause_interference(Color, ListOfMovesCauseInference),
        interference_helper1(ListOfMovesCauseInference, Piece, CartesianPosition, NextCartesianPosition, OpponentPiece1, OpponentColor1, OpponentCartesianPosition1, OpponentPiece2, OpponentColor2, OpponentCartesianPosition2),
        
        % Piece
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),

        map(NextUCIPositionString, NextCartesianPosition),
        string_to_atom(NextUCIPositionString, NextUCIPosition),

        % Opponent 1
        map(OpponentUCIPosition1String, OpponentCartesianPosition1),
        string_to_atom(OpponentUCIPosition1String, OpponentUCIPosition1),

        % Opponent 2
        map(OpponentUCIPosition2String, OpponentCartesianPosition2),
        string_to_atom(OpponentUCIPosition2String, OpponentUCIPosition2)
    ).

% Mate
% Rule:
mate(Color, Piece, UCIPosition, ListOfListMoves) :-
    %start:
    (
        move_cause_mate_helper(Color, [], ListOfMovesCauseMate), !,
        output_seq(ListOfMovesCauseMate, Piece, UCIPosition, ListOfListMoves)
    ).

% General Predicates
return_squares(SanPositionAtom):-
%start:
    (
        occupies(_, _, CartesianPosition),
        map(SanPositionString, CartesianPosition),
        string_to_atom(SanPositionString, SanPositionAtom)
    ).
%end

%start:   
convert_list([], []).

convert_list(ListOfTuples, ListOfList):-
    (
        ListOfTuples = [Head | Tail],
        map(SanPositionString, Head),
        string_to_atom(SanPositionString, SanPositionAtom),
        convert_list(Tail, RemListOfList),
        ListOfList = [SanPositionAtom | RemListOfList]
    ).
%end

output_seq(InputList, Piece, SanPositionAtom, ListOfListMoves) :-
% start:
    ( 
        InputList = [Head | _],
        (Piece, CartesianPosition, ListOfTuplesMoves) = Head,
        map(SanPositionString, CartesianPosition),
        string_to_atom(SanPositionString, SanPositionAtom),
        convert_list(ListOfTuplesMoves, ListOfListMoves)
    ).

output_seq(InputList, Piece, SanPosition, ListOfMoves) :-
    (
        InputList = [_ | Rest],
        output_seq(Rest, Piece, SanPosition, ListOfMoves)
    ).
%end

output_seq2(InputList, Piece, UCIPosition, ListOfMoves) :-
% start:
    ( 
        InputList = [Head | _],
        (Piece, _, UCIPosition, ListOfMoves) = Head
    ).

    output_seq2(InputList, Piece, UCIPosition, ListOfMoves) :-
    (
        InputList = [_ | Rest],
        output_seq2(Rest, Piece, UCIPosition, ListOfMoves)
    ).
%end