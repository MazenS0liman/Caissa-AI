:- [chess_rules].

:- use_module(library(aggregate)).
:- use_module(library(clpfd)).

% Rule:
% List = [(pawn, black, f6, e5), (queen, black, b2, e5), (queen, black, b2, a2), (queen, black, b2, c2), (queen, black, b2, b3), (rook, black, e7, e6)].
piece_legal_attack(_, _, _, [], []).

piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack, ListOfLegalAttacks) :- 
    (
        ListOfAllPiecesAttack = [Head | Rest],
        (Piece, Color, UCIPosition, AttackedUCIPosition) = Head,  !,
        piece_legal_attack(Piece, Color, UCIPosition, Rest, RemListOfLegalAttacks),
        ListOfLegalAttacks = [(Piece, Color, UCIPosition, AttackedUCIPosition) | RemListOfLegalAttacks]
    ).

piece_legal_attack(Piece, Color, UCIPosition, ListOfAllPiecesAttack, ListOfLegalAttacks) :-
    (
        ListOfAllPiecesAttack = [Head | Rest],
        (Piece, Color, UCIPosition, _) \== Head,
        piece_legal_attack(Piece, Color, UCIPosition, Rest, ListOfLegalAttacks)
    ).

return_pieces(Piece, Color, SanPositionAtom):-
    %start:
        (
            occupies(Piece, Color, CartesianPosition),
            Piece \== none,
            map(SanPositionString, CartesianPosition),
            string_to_atom(SanPositionString, SanPositionAtom)
        ).
    %end

% Rule:
move_cause_discover(Color, ListOfMovesCauseDiscover) :-
    %start:
        (
            moves_cause_discover_helper(Color, [], ListOfMovesCauseDiscover)
        ).
    
        moves_cause_discover_helper(Color, ListOfVisitedPieces, ListOfMovesCauseDiscover) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            moves_cause_discover_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseDiscoverPerPiece),
            ListofMovesCauseDiscoverPerPiece \== [],
            moves_cause_discover_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseDiscover),
            append([(Piece, CartesianPosition, ListofMovesCauseDiscoverPerPiece)], RemListOfMovesCauseDiscover, ListOfMovesCauseDiscover), !
        ).
    
        moves_cause_discover_helper(_, _, []).
    
        moves_cause_discover_per_piece(_, _, _, [], []).
    
        moves_cause_discover_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseDiscover) :-
            (
                ListOfMoves = [NewCartesianPosition | Rest],
                all_piece_legal_attacks(Color, PreviousList),
                (
                    move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, discover_condition(PreviousList)),
                    moves_cause_discover_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseDiscover),
                    ListOfMovesCauseDiscover = [NewCartesianPosition | RemListOfMovesCauseDiscover], !
                ;
                    moves_cause_discover_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseDiscover)
                )
            ).

            discover_condition(PreviousList, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
                (
                    map(NewUCIPositionString, NewCartesianPosition),
                    string_to_atom(NewUCIPositionString, NewUCIPositionAtom),
                    all_piece_legal_attacks(Color, NewList),
                    filter_attack(Piece, Color, NewUCIPositionAtom, NewList, NewListFiltered),
                    % format('NewListFiltered ~w', [NewListFiltered]),
                    get_difference_in_moves(PreviousList, NewListFiltered, Difference),
                    map(UCIPositionString, NewCartesianPosition),
                    string_to_atom(UCIPositionString, UCIPositionAtom),
                    once((
                        Difference \== [],
                        check_discover(UCIPositionAtom, Difference),
                        % format('Difference ~w\n', [Difference]),
                        undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
                    ;
                        (
                            Difference == []
                        ;
                            \+(check_discover(UCIPositionAtom, Difference))
                        ),
                        undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                        fail
                    ))
                ).
                    
            filter_attack(_, _, _, [], []).


            filter_attack(Piece, Color, Position, ListOfAttacks, FilteredListOfAttacks) :-
                ListOfAttacks = [Head | Rest],
                (
                    (_, Color, OtherPosition, _) = Head,
                    OtherPosition \== Position,

                    filter_attack(Piece, Color, Position, Rest, RemFilteredListOfAttacks),
                    FilteredListOfAttacks = [Head | RemFilteredListOfAttacks]
                ;
                    filter_attack(Piece, Color, Position, Rest, FilteredListOfAttacks)
                ).


            check_discover(UCIPosition, List) :-
                once((
                    % List = [(Piece, Color, Position, OpponentPosition) | _ ],
                    List = [(_, Color, Position, OpponentPosition) | _ ],
                    UCIPosition \== Position,
                    return_pieces(OpponentPiece, OpponentColor, OpponentPosition),
                    color(Color),
                    color(OpponentColor),
                    OpponentColor \== Color,
                    OpponentPiece \== pawn
                    % all_piece_legal_attacks(OpponentColor, ListOfAttacks)
                    % can_not_be_attacked(Piece, Color, Position, ListOfAttacks)
                )).

            check_discover(List) :-
                once((
                    List = [_| Tail],
                    check_discover(Tail)
                )).

            can_not_be_attacked(_, _, _, []).

            can_not_be_attacked(Piece, Color, UCIPosition, ListOfAttacks) :-
                (
                    ListOfAttacks = [(_, OpponentColor, _, AttackPosition) | Rest],
                    color(OpponentColor),
                    color(Color),
                    Color \== OpponentColor,
                    \+(AttackPosition == UCIPosition),
                    can_not_be_attacked(Piece, Color, UCIPosition, Rest)
                ).

% Rule:
move_cause_mate_in_2_helper(Color, ListOfVisitedPieces, ListOfMovesCauseMatIn2) :-
    (
        occupies(Piece, Color, CartesianPosition),
        Piece \== king,
        \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
        piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
        % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
        % format("List of moves: ~w\n", [ListOfMoves]),
        move_cause_mate_in_2_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseMateIn2PerPiece),
        % format("List of moves that cause mate: ~w\n", [ListofMovesCauseMatePerPiece]),
        ListofMovesCauseMateIn2PerPiece \== [],
        move_cause_mate_in_2_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseMateIn2),
        append([(Piece, CartesianPosition, ListofMovesCauseMateIn2PerPiece)], RemListOfMovesCauseMateIn2, ListOfMovesCauseMatIn2), !
    ).
    
    move_cause_mate_in_2_helper(_, _, []).

    move_cause_mate_in_2_per_piece(_, _, _, [], []).

    move_cause_mate_in_2_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseMateIn2) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            % format('NewCartesianPosition: ~w', [NewCartesianPosition]),
            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, mate_in_2_condition),
                move_cause_mate_in_2_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseMateIn2),
                ListOfMovesCauseMateIn2 = [NewCartesianPosition | RemListOfMovesCauseMateIn2], !
            ;
                move_cause_mate_in_2_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseMateIn2)
            )
        ).
    
    mate_in_2_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            color(ColorOfOpponent),
            ColorOfOpponent \== Color,
            ColorOfOpponent \== none,
            (
                in_check(ColorOfOpponent),
                play_a_move(ColorOfOpponent, [], ListofMovesToPlay),
                % format('ListofMovesToPlay: ~w\n', [ListofMovesToPlay]),
                ListofMovesToPlay \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;    
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail      
            )
        ).

    play_a_move(Color, ListOfVisitedPieces, ListofMovesToPlay) :-
        (
            % 1. find a legal move of opponent.
            occupies(Piece, Color, CartesianPosition),
            % Piece \== king,
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
            % format("List of moves: ~w\n", [ListOfMoves]),
            play_a_move_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesToPlayPerPiece),
            % format("List of moves that cause mate: ~w\n", [ListofMovesCauseMatePerPiece]),
            ListofMovesToPlayPerPiece \== [],
            play_a_move(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesToPlay),
            append([(Piece, CartesianPosition)], RemListOfMovesToPlay, ListofMovesToPlay), !
        ).

    play_a_move(_, _, []).

    play_a_move_per_piece(_, _, _, [], []).

    play_a_move_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesToPlay) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, play_a_move_per_piece_condition),
                play_a_move_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesToPlay),
                ListofMovesToPlay = [NewCartesianPosition | RemListOfMovesToPlay], !
            ;
                play_a_move_per_piece(Piece, Color, CartesianPosition, Rest, ListofMovesToPlay)
            )
        ).

    play_a_move_per_piece_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            color(ColorOfOpponent),
            ColorOfOpponent \== Color,
            ColorOfOpponent \== none,
            (
                moves_cause_mate(ColorOfOpponent, ListOfMoves),     % Is there a move that cause a checkmate
                ListOfMoves \== [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail      
            )
        ).
%end

% Rule:
moves_cause_mate(Color, ListOfMovesCauseMate) :-
    %start:
        (
            move_cause_mate_helper(Color, [], ListOfMovesCauseMate), !
        ).
    
        move_cause_mate_helper(Color, ListOfVisitedPieces, ListOfMovesCauseMate) :-
            (
                occupies(Piece, Color, CartesianPosition),
                Piece \== king,
                \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
                piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
                % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
                % format("List of moves: ~w\n", [ListOfMoves]),
                move_cause_mate_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseMatePerPiece),
                % format("List of moves that cause mate: ~w\n", [ListofMovesCauseMatePerPiece]),
                ListofMovesCauseMatePerPiece \== [],
                move_cause_mate_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseMate),
                append([(Piece, CartesianPosition, ListofMovesCauseMatePerPiece)], RemListOfMovesCauseMate, ListOfMovesCauseMate), !
            ).
    
        move_cause_mate_helper(_, _, []).
    
        move_cause_mate_per_piece(_, _, _, [], []).
    
        move_cause_mate_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseMate) :-
            (
                ListOfMoves = [NewCartesianPosition | Rest],
                (
                    move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, mate_condition),
                    move_cause_mate_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseMate),
                    ListOfMovesCauseMate = [NewCartesianPosition | RemListOfMovesCauseMate], !
                ;
                    move_cause_mate_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseMate)
                )
            ).
    %end
    
    mate_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            color(ColorOfOpponent),
            ColorOfOpponent \== Color,
            ColorOfOpponent \== none,
            (
                
                in_checkmate(ColorOfOpponent), 
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                \+(in_checkmate(ColorOfOpponent)),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail      
            )
        ). 
    

% Rule:
interference_helper1(ListOfMovesCauseInference, Piece, Position, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) :-
    (
        ListOfMovesCauseInference = [Head | _],
        (Piece, Position, ListOfMoves) = Head,
        interference_helper2(ListOfMoves, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2)
    ;
        ListOfMovesCauseInference = [_ | Rest],
        interference_helper1(Rest, Piece, Position, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2)
    ).

interference_helper2(ListOfMoves, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) :-
    (
        ListOfMoves = [Head | _],
        (NextUCIPosition, Causes) = Head,
        interference_helper3(Causes, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2)
    ;        
        ListOfMoves = [_ | Tail],
        interference_helper2(Tail, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) 
    ).

interference_helper3(Causes, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) :-
    (
        Causes = [Cause | _],
        (OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) = Cause
    ;
    Causes = [_ | Rest],
        interference_helper3(Rest, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2) 
    ).

move_cause_interference(Color, ListOfMovesCauseInference) :-
    %start:
        (
            moves_cause_inference_helper(Color, [], ListOfMovesCauseInference)
        ).
    
        moves_cause_inference_helper(Color, ListOfVisitedPieces, ListOfMovesCauseInference) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            moves_cause_inference_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseInferencePerPiece),
            ListofMovesCauseInferencePerPiece \== [],
            moves_cause_inference_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseInference),
            append([(Piece, CartesianPosition, ListofMovesCauseInferencePerPiece)], RemListOfMovesCauseInference, ListOfMovesCauseInference), !
        ).
    
        moves_cause_inference_helper(_, _, []).
    
            moves_cause_inference_per_piece(_, _, _, [], []).
    
            moves_cause_inference_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListOfMovesCauseInference) :-
                (
                    ListOfMoves = [NewCartesianPosition | Rest],
                    color(OpponentColor),
                    OpponentColor \== Color,
                    OpponentColor \== none,
                    all_defended_pieces(OpponentColor, [], PreviousList),
                    (
                        move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, inference_condition(PreviousList, Difference, OpponentColor)),
                        moves_cause_inference_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseInference),
                        ListOfMovesCauseInference = [(NewCartesianPosition, Difference) | RemListOfMovesCauseInference], !
                    ;
                        moves_cause_inference_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseInference)
                    )
                ).

            inference_condition(PreviousList, FilteredDifference, ColorUsedOfOpponent, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
                (
                    all_defended_pieces(ColorUsedOfOpponent, [], NewList),
                    get_difference_in_moves(NewList, PreviousList, Difference),
                    filter_difference(Color, NewCartesianPosition, Difference, FilteredDifference),
                    % format('Difference: ~w\n', [Difference]),
                    % (
                    %     FilteredDifference \== [],
                    %     format('~w ~w (~w) (~w)\n', [Piece, Color, CartesianPosition, NewCartesianPosition]),
                    %     format('FilteredDifference: ~w\n', [FilteredDifference]), 
                    %     format('Previous: ~w\n', [PreviousList]),
                    %     format('Next: ~w\n', [NewList]), display_board, write('\n')
                    % ;
                    %     true
                    % ),
                    once((
                        FilteredDifference \== [],
                        undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
                    ;
                        FilteredDifference == [],
                        undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                        fail
                    ))
                ).

            filter_difference(_, _, [], []).

            filter_difference(Color, Position,  Difference, FilteredDifference) :-
                (
                    Difference = [Head | Tail],
                    (Piece1, Color1, Position1, Piece2, Color2, Position2) = Head,
                    Piece1 \== king,
                    Piece1 \== knight,
                    Piece2 \== pawn,
                    occupies(Piece1, Color1, Position1),
                    occupies(Piece2, Color2, Position2),
                    \+(member((Piece2, Color2, Position2, Piece1, Color1, Position1), Tail)),
                    % (
                    %     map(Position2UCIString, Position2),
                    %     string_to_atom(Position2UCIString, Position2UCIAtom),
                    %     threat(_, Color, AllyUCIPositionAtom, Piece2, Color2, Position2UCIAtom),
                    %     % format('Piece2: ~w , Position2UCIAtom: ~w\n', [Piece2, Position2UCIAtom]),
                    %     atom_string(AllyUCIPositionAtom, AllyUCIPositionString),
                    %     map(AllyUCIPositionString, AllyPosition),
                    %     % format('AllyPosition: ~w , Position: ~w\n', [AllyPosition, Position]),
                    %     AllyPosition \== Position
                    % ; 
                    %     map(Position1UCIString, Position1),
                    %     string_to_atom(Position1UCIString, Position1UCIAtom),
                    %     threat(_, Color, AllyUCIPositionAtom, Piece1, Color1, Position1UCIAtom),
                    %     atom_string(AllyUCIPositionAtom, AllyUCIPositionString),
                    %     map(AllyUCIPositionString, AllyPosition),
                    %     % format('AllyPosition: ~w , Position: ~w\n', [AllyPosition, Position]),
                    %     AllyPosition \== Position
                    % ),
                    filter_difference(Color, Position, Tail, RemFilteredDifference),
                    FilteredDifference = [(Piece1, Color1, Position1, Piece2, Color2, Position2) | RemFilteredDifference]
                ;
                    Difference = [_ | Tail],
                    filter_difference(Color, Position, Tail, FilteredDifference)
                ).

% Rule: Give all pieces that defend eachother.
all_defended_pieces(Color, ListOfPieceSoFar, FinalList) :-
    (
        occupies(AllyPiece, Color, AllyCartesianPosition),
        occupies(Piece, Color, CartesianPosition),
        CartesianPosition \== AllyCartesianPosition,
        \+(member((Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition), ListOfPieceSoFar)),
        once((
            Piece \== king,
            AllyPiece \== king,
            in_check(Color),
            remove_piece(king, Color, KingPosition),
            add_piece(pawn, Color, KingPosition),
            (
                defend(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition),
                remove_piece(pawn, Color, KingPosition),
                add_piece(king, Color, KingPosition)
            ;    
                remove_piece(pawn, Color, KingPosition),
                add_piece(king, Color, KingPosition),
                fail
            )
        ;    
            defend(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition)
        )), !,
        all_defended_pieces(Color, [(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition) | ListOfPieceSoFar], FinalList)
    ).

all_defended_pieces(_, List, List).

% Rule: Moves that does not cause piece to be in threat or either in threat but it is defended.
moves_cause_threat(Color, ListOfMovesCauseThreat) :-
%start:
    (
        moves_cause_threat_helper(Color, [], ListOfMovesCauseThreat)
    ).

    moves_cause_threat_helper(Color, ListOfVisitedPieces, ListOfMovesCauseThreat) :-
    (
        occupies(Piece, Color, CartesianPosition),
        \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
        piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
        moves_cause_threat_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseThreatPerPiece),
        ListofMovesCauseThreatPerPiece \== [],
        moves_cause_threat_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseThreat),
        append([(Piece, CartesianPosition, ListofMovesCauseThreatPerPiece)], RemListOfMovesCauseThreat, ListOfMovesCauseThreat), !
    ).

    moves_cause_threat_helper(_, _, []).

        moves_cause_threat_per_piece(_, _, _, [], []).

        moves_cause_threat_per_piece(Piece, Color, CartesianPosition, ListOfMovesCauseThreatoFar, ListOfMovesCauseThreat) :-
            (
                ListOfMovesCauseThreatoFar = [NewCartesianPosition | Rest],
                (
                    move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, threat_condition),
                    moves_cause_threat_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseThreat),
                    ListOfMovesCauseThreat = [NewCartesianPosition | RemListOfMovesCauseThreat], !
                ;
                    moves_cause_threat_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseThreat)
                )
            ).

    threat_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            once((
                map(NewSanPositionString,  NewCartesianPosition),
                string_to_atom(NewSanPositionString, NewSanPositionAtom),
                (
                    threat( _, OpponentColor, _, Piece, Color, NewSanPositionAtom),
                    defend( _, Color, _, Piece, Color, NewCartesianPosition)
                ;
                    \+(threat( _, OpponentColor, _, Piece, Color, NewSanPositionAtom))
                ),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                once((
                    map(NewSanPositionString,  NewCartesianPosition),
                    string_to_atom(NewSanPositionString, NewSanPositionAtom),
                    threat( _, OpponentColor, _, Piece, Color, NewSanPositionAtom),
                    undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
                )),
                fail
            ))
        ).


% Rule: estimate the state of the chessboard with respect to a player based on the value of possible attacks it can make.
estimate_value_of_possible_attacks(Color, Value) :-
% start:
    (
        all_piece_legal_attacks(Color, ListOfPossibleAttacks),
        estimate_value_of_possible_attacks_helper(ListOfPossibleAttacks, Value)  
    ).

    estimate_value_of_possible_attacks_helper([], 0).

    estimate_value_of_possible_attacks_helper(ListOfPossibleAttacks, Value) :-
        (
            ListOfPossibleAttacks = [AttackMove | Rest],
            (Piece, _, _, _) = AttackMove,
            evaluate_piece(Piece, TempValue1),
            estimate_value_of_possible_attacks_helper(Rest, TempValue2),
            Value is TempValue1 + TempValue2
        ).
%end

% Rule: a move that would lead the player to be able to caputre more pieces
moves_cause_control(Color, ListOfMovesCauseControl) :-
%start:
    (
        moves_cause_control_helper(Color, [], ListOfMovesCauseControl), !
    ).

moves_cause_control_helper(Color, ListOfVisitedPieces, ListOfMovesCauseControl) :-
    (
        occupies(Piece, Color, CartesianPosition),
        \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
        piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
        % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
        % format("List of moves: ~w\n", [ListOfMoves]),
        moves_cause_control_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseControlPerPiece),
        % format("List of moves that cause check: ~w\n", [ListofMovesCauseCheckPerPiece]),
        ListofMovesCauseControlPerPiece \== [],
        moves_cause_control_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseCheck),
        append([(Piece, CartesianPosition, ListofMovesCauseControlPerPiece)], RemListOfMovesCauseCheck, ListOfMovesCauseControl), !
    ).

moves_cause_control_helper(_, _, []).

moves_cause_control_per_piece(_, _, _, [], []).

moves_cause_control_per_piece(Piece, Color, CartesianPosition, ListOfMovesCauseControlSoFar, ListOfMovesCauseControl) :-
    (
        ListOfMovesCauseControlSoFar = [NewCartesianPosition | Rest],
        (
            move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, control_condition),
            moves_cause_control_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseControl),
            ListOfMovesCauseControl = [NewCartesianPosition | RemListOfMovesCauseControl], !
        ;
            moves_cause_control_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseControl)
        )
    ).
%end

control_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, Value) :-
    (
        estimate_value_of_possible_attacks(Color, NewValue),
        once((
            NewValue #> Value,
            undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
        ;
            NewValue #=< Value,
            undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
            fail         
        ))
    ).

% Rule:
moves_cause_check(Color, ListOfMovesCauseCheck) :-
%start:
    (
        move_cause_check_helper(Color, [], ListOfMovesCauseCheck), !
    ).

    move_cause_check_helper(Color, ListOfVisitedPieces, ListOfMovesCauseCheck) :-
        (
            occupies(Piece, Color, CartesianPosition),
            Piece \== king,
            \+(member((Piece, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),  
            % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
            % format("List of moves: ~w\n", [ListOfMoves]),
            move_cause_check_per_piece(Piece, Color, CartesianPosition, ListOfMoves, ListofMovesCauseCheckPerPiece),
            % format("List of moves that cause check: ~w\n", [ListofMovesCauseCheckPerPiece]),
            ListofMovesCauseCheckPerPiece \== [],
            move_cause_check_helper(Color, [(Piece, CartesianPosition) | ListOfVisitedPieces], RemListOfMovesCauseCheck),
            append([(Piece, CartesianPosition, ListofMovesCauseCheckPerPiece)], RemListOfMovesCauseCheck, ListOfMovesCauseCheck), !
        ).

    move_cause_check_helper(_, _, []).

    move_cause_check_per_piece(_, _, _, [], []).

    move_cause_check_per_piece(Piece, Color, CartesianPosition, ListOfMovesCauseCheckSoFar, ListOfMovesCauseCheck) :-
        (
            ListOfMovesCauseCheckSoFar = [NewCartesianPosition | Rest],
            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, check_condition),
                move_cause_check_per_piece(Piece, Color, CartesianPosition, Rest, RemListOfMovesCauseCheck),
                ListOfMovesCauseCheck = [NewCartesianPosition | RemListOfMovesCauseCheck], !
            ;
                move_cause_check_per_piece(Piece, Color, CartesianPosition, Rest, ListOfMovesCauseCheck)
            )
        ).

    check_condition(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            (
                in_check(OpponentColor),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                \+(in_check(OpponentColor)),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            )
        ).
%end
 

% Rule:
%start:
filter_to_list_of_squares([], []).

filter_to_list_of_squares(ListOfMoves, ListOfPositions) :-
    (
        ListOfMoves = [Move | Rest],
        (_, _, _, Position) = Move,
        filter_to_list_of_squares(Rest, RemPosition),
        ListOfPositions = [Position | RemPosition]
    ).
%end

% Rule:
%start:
all_piece_legal_attacks(Color, ListOfLegalAttacks) :-
    (
        all_pieces_legal_attacks_helper(Color, [], ListOfLegalAttacks)
    ).

all_pieces_legal_attacks_helper(Color, ListOfVistedPieces, ListOfLegalAttacks) :-
    (
        occupies(Piece, Color, CartesianPosition),
        \+ member(CartesianPosition, ListOfVistedPieces),
        map(SanPositionString, CartesianPosition),
        string_to_atom(SanPositionString, SanPositionAtom),
    
        all_piece_legal_moves(Piece, Color, CartesianPosition, [], ListOfPieceLegalMoves),
        (
            Piece == pawn,
            remove_push_pawn_moves(Piece, Color, CartesianPosition, ListOfPieceLegalMoves, ListOfLegalCartesianAttacks),
            convert_list_from_cartesian_to_san(Piece, Color, SanPositionAtom, ListOfLegalCartesianAttacks, ListOfLegalPawnSanMoves),
            all_pieces_legal_attacks_helper(Color, [CartesianPosition| ListOfVistedPieces], RemListOfLegalAttacks),
            append(ListOfLegalPawnSanMoves, RemListOfLegalAttacks, ListOfLegalAttacks)
        ;
            Piece \== pawn,
            Color \== none,
            convert_list_from_cartesian_to_san(Piece, Color, SanPositionAtom, ListOfPieceLegalMoves, ListOfLegalSanMoves),
            remove_move_to_empty_square(Color, ListOfLegalSanMoves, ListOfLegalSanAttacks),
            all_pieces_legal_attacks_helper(Color, [CartesianPosition| ListOfVistedPieces], RemListOfLegalAttacks),
            append(ListOfLegalSanAttacks, RemListOfLegalAttacks, ListOfLegalAttacks)
        ), !
    ).

all_pieces_legal_attacks_helper(_, _, []).

remove_move_to_empty_square(_, [], []).

remove_move_to_empty_square(Color, Moves, ListOfPiecesCanAttack) :-
    (
        Moves = [Move | Rest],
        (Piece, Color, SanMoveFrom, SabMoveTo) = Move,
        atom_string(SabMoveTo, SanMoveToString),
        map(SanMoveToString, CartesianPosition),
        (
            is_white(Color),
            once((
                occupies(_, black, CartesianPosition),
                remove_move_to_empty_square(Color, Rest, RemListOfPiecesCanAttack),
                ListOfPiecesCanAttack = [(Piece, Color, SanMoveFrom, SabMoveTo) | RemListOfPiecesCanAttack]
            ;
                occupies(none, none, CartesianPosition),
                remove_move_to_empty_square(Color, Rest, ListOfPiecesCanAttack)
            ))
        
        ;  
        
            is_black(Color),
            once((
                occupies(_, white, CartesianPosition),
                remove_move_to_empty_square(Color, Rest, RemListOfPiecesCanAttack),
                ListOfPiecesCanAttack = [(Piece, Color, SanMoveFrom, SabMoveTo) | RemListOfPiecesCanAttack]
            ;
                occupies(none, none, CartesianPosition),
                remove_move_to_empty_square(Color, Rest, ListOfPiecesCanAttack)
            ))
        )
    ).


remove_push_pawn_moves(_, _, _, [], []).

remove_push_pawn_moves(Piece, Color, CartesianPosition, ListOfMoves, FilteredListOfMoves) :- 
    (
        Piece = pawn,
        (X1, _) = CartesianPosition,
        ListOfMoves = [CartesianMove | Rest],
        (X2, _) = CartesianMove,
        (
            X2 #\= X1,
            remove_push_pawn_moves(Piece, Color, CartesianPosition, Rest, RemFilteredListOfMoves),
            FilteredListOfMoves = [CartesianMove | RemFilteredListOfMoves]
        ;   
            X2 #= X1,
            remove_push_pawn_moves(Piece, Color, CartesianPosition, Rest, FilteredListOfMoves)
        ), !
    ).
%end

% Rule:
%start:
range_pieces_legal_attack(Color, ListOfLegalAttacks) :-
    (
        range_pieces_legal_attack_helper(Color, [], ListOfLegalAttacks)
    ).

range_pieces_legal_attack_helper(Color, ListOfVistedPieces, ListOfLegalAttacks) :-
	occupies(Piece, Color, CartesianPosition),
    Piece \== pawn,
    Piece \== knight,
    Piece \== king,
	\+ member(CartesianPosition, ListOfVistedPieces), 

	all_piece_legal_moves(Piece, Color, CartesianPosition, [], ListOfPieceLegalMoves), !,
    map(SanPositionString, CartesianPosition),
    string_to_atom(SanPositionString, SanPositionAtom),
    convert_list_from_cartesian_to_san(Piece, Color, SanPositionAtom, ListOfPieceLegalMoves, ListOfSanMoves),

	range_pieces_legal_attack_helper(Color, [CartesianPosition| ListOfVistedPieces], RemListOfLegalMoves),
	append(ListOfSanMoves, RemListOfLegalMoves, ListOfLegalAttacks).
	
range_pieces_legal_attack_helper(_, _,[]).
%end

% Rule:
%start:
convert_list_from_san_to_cartesian(_, _, _, [], []).

convert_list_from_san_to_cartesian(Piece, Color, SanPosition, ListOfSanMoves, ListOfCartesianMoves) :-
    (
        ListOfSanMoves = [SanMoveAtom | Rest],

        atom_string(SanMoveAtom, SanMoveString),
        map(SanMoveString, CartesianMove),

        atom_string(SanPosition, SanPositionString),
        map(SanPositionString, CartesianPosition),

        convert_list_from_san_to_cartesian(Piece, Color, SanPosition, Rest, RemListOfCartesianMoves),
        ListOfCartesianMoves = [(Piece, Color, CartesianPosition, CartesianMove) | RemListOfCartesianMoves]   
    ).
%end

% Rule:
%start:
convert_list_from_cartesian_to_san(_, _, _, [], []).

convert_list_from_cartesian_to_san(Piece, Color, SanPosition, ListOfCartesianMoves, ListOfSanMoves) :-
    (
        ListOfCartesianMoves = [CartesianMove | Rest],
        map(SanMoveString, CartesianMove),
        string_to_atom(SanMoveString, SanMoveAtom),
        convert_list_from_cartesian_to_san(Piece, Color, SanPosition, Rest, RemListOfSanMoves),
        ListOfSanMoves = [(Piece, Color, SanPosition, SanMoveAtom) | RemListOfSanMoves]
    ).
%end

% Rule:
position_can_attack(Color, ListOfPositionsPlayerCanAttack) :-
%start:
    (
        all_player_unique_legal_moves(Color, Moves1),
        find_pieces_to_attack_from_moves(Color, Moves1, ListOfPositionsPlayerCanAttack)
    ).
%end

% Rule: determine whether piece Piece defned piece AllyPiece. [Tested]
%start: 
defend(Piece, Color, CartesianPosition, AllyPiece, AllyColor, AllyCartesianPosition) :-
    (
        occupies(Piece, Color, CartesianPosition),
        occupies(AllyPiece, AllyColor, AllyCartesianPosition),
        CartesianPosition \== AllyCartesianPosition,
        Color == AllyColor,
            (
                % if the piece that is defending is a pwan
                Piece == pawn,
                (
                    is_white(Color),
                    (X1, Y1) = CartesianPosition,
                    (X2, Y2) = AllyCartesianPosition,
                    Y2 is Y1 + 1,
                    (
                        X2 is X1 - 1
                    ;
                        X2 is X1 + 1
                    )
                ;
                    is_black(Color),
                    (X1, Y1) = CartesianPosition,
                    (X2, Y2) = AllyCartesianPosition,
                    Y2 is Y1 - 1,
                    (
                        X2 is X1 - 1   
                    ;   
                        X2 is X1 + 1
                    )
                ) 
            ;    
                % if the piece that is defending is not a pwan
                Piece \== pawn,
                remove_piece(AllyPiece, AllyColor, AllyCartesianPosition),
                piece_legal_moves(Piece, Color, CartesianPosition, ListOfMoves),
                add_piece(AllyPiece, AllyColor, AllyCartesianPosition),
                member(AllyCartesianPosition, ListOfMoves)
            )
        % format('(~w, ~w, ~w) defend  (~w, ~w, ~w)\n', [Piece, Color, CartesianPosition, AllyPiece, AllyColor, AllyCartesianPosition])
    ).
%end

% Rule:
%start:
get_difference_in_moves(_, [], []).

get_difference_in_moves(OldMoves, NewMoves, Difference) :-
    (
        NewMoves = [SanPositionAtom | Rest],
        \+(member(SanPositionAtom, OldMoves)),
        Difference = [SanPositionAtom | RestOfDifference],
        get_difference_in_moves(OldMoves, Rest, RestOfDifference), !
    ).

get_difference_in_moves(OldMoves, NewMoves, Difference) :-
    (
        NewMoves = [SanPositionAtom | Rest],
        member(SanPositionAtom, OldMoves),
        get_difference_in_moves(OldMoves, Rest, Difference), !     
    ).
%end

% Rule:
%start:
find_pieces_to_attack_from_moves(_, [], []).

find_pieces_to_attack_from_moves(Color, Moves, ListOfPiecesCanAttack) :-
    (
        Moves = [Move | Rest],
        (Piece, Color, SanPosition, SanMoveAtom) = Move,
        atom_string(SanMoveAtom, SanMoveString),
        map(SanMoveString, CartesianPosition),
        (
            is_white(Color),
            once((
                occupies(_, black, CartesianPosition),
                find_pieces_to_attack_from_moves(Color, Rest, RemListOfPiecesCanAttack),
                ListOfPiecesCanAttack = [(Piece, Color, SanPosition, SanMoveAtom) | RemListOfPiecesCanAttack]
            ;
                occupies(none, none, CartesianPosition),
                find_pieces_to_attack_from_moves(Color, Rest, ListOfPiecesCanAttack)
            ))
        
        ;  
        
            is_black(Color),
            once((
                occupies(_, white, CartesianPosition),
                find_pieces_to_attack_from_moves(Color, Rest, RemListOfPiecesCanAttack),
                ListOfPiecesCanAttack = [(Piece, Color, SanPosition, SanMoveAtom) | RemListOfPiecesCanAttack]
            ;
                occupies(none, none, CartesianPosition),
                find_pieces_to_attack_from_moves(Color, Rest, ListOfPiecesCanAttack)
            ))
        )
    ).
%end

% Rule:
add_piece(Piece, Color, CartesianPosition) :-
%start:
    (
        occupies(none, none, CartesianPosition),
        retract(occupies(none, none, CartesianPosition)),
        assert(occupies(Piece, Color, CartesianPosition))
    ).
%end

% Rule:
remove_piece(Piece, Color, CartesianPosition) :-
%start:
    (
        occupies(Piece, Color, CartesianPosition),
        retract(occupies(Piece, Color, CartesianPosition)),
        assert(occupies(none, none, CartesianPosition))
    ).
%end

% Rule:
evaluate_piece(Piece, Value) :-
%start:
    (
        (
            Piece = king,
            Value is 1000
        ;
            Piece = queen,
            Value is 9
        ;
            Piece = rook,
            Value is 5
        ;
            Piece = bishop,
            Value is 3
        ;
            Piece = knight,
            Value is 3
        ;
            Piece = pawn,
            Value is 1
        )
    ).
%end

% Rule:
has_material_advantage(Color) :-
%start:
    (
        is_white(Color),
        count_material(white, R1),
        count_material(black, R2),
        R1 > R2     
    ;
        is_black(Color),   
        count_material(white, R1),
        count_material(black, R2),
        R1 < R2
    ).

count_material(Color, Result) :-
    (
        aggregate_all(count, occupies(_,Color,_),Result)
    ).

evaluate_material(Color, Result) :-
    (
        findall((X,Color,(Z)), occupies(X,Color,(Z)),ListOfOccupied),
        evaluate_material_helper(Color, ListOfOccupied, Result)
    ).

evaluate_material_helper(_, [], _).

evaluate_material_helper(Color, ListOfOccupied, Value) :-
    (
        ListOfOccupied = [Square | Rest],        
        Square = (_, Color, _, _),
        (
            Square = king,
            evaluate_material_helper(Color, Rest, Value)
        ;
            Square = queen,
            NewValue is Value + 9,
            evaluate_material_helper(Color, Rest, NewValue)
        ;
            Square = rook,
            NewValue is Value + 5,
            evaluate_material_helper(Color, Rest, NewValue)
        ;
            Square = bishop,
            NewValue is Value + 3,
            evaluate_material_helper(Color, Rest, NewValue)
        ;
            Square = knight,
            NewValue is Value + 3,
            evaluate_material_helper(Color, Rest, NewValue)
        ;
            Square = pawn,
            NewValue is Value + 1,
            evaluate_material_helper(Color, Rest, NewValue)
        )
    ).
%end


% Rule: A piece Piece threat an opponent if it can attack an opponent piece by moving to its position. [Tested]
threat(Piece, Color, SanPosition, OpponentPiece, OpponentColor, OpponentSanPosition) :-   % Must be instantiated (Piece, Color, Position, OpponentPosition)
%start:
    once((
            nonvar(SanPosition),
            nonvar(OpponentSanPosition),
            atom_string(SanPosition, SanPositionString),
            atom_string(OpponentSanPosition, OpponentSanPositionString),
            map(SanPositionString, CartesianPosition),
            map(OpponentSanPositionString, OpponentCartesianPosition),
            occupies(Piece, Color, CartesianPosition),
            occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),
            Color \== OpponentColor,
            OpponentColor \== none,
            % format('(~w, ~w, ~w)', [Piece, Color, SanPosition]), display_board,
            piece_legal_moves(Piece, Color, CartesianPosition, Result),
            % format('(~w, ~w, ~w)', [Piece, Color, SanPosition]), display_board,
            member(OpponentCartesianPosition, Result),!
            % format('~w at ~w threats ~w at ~w', [Piece, SanPosition, OpponentPiece, OpponentSanPosition]),
            % format('-----------------------------------------------------------------------------------')
        ;
            (
                var(SanPosition)
            ;
                var(OpponentSanPosition)   
            ),
            occupies(Piece, Color, CartesianPosition),
            occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition), 
            OpponentColor \== Color,
            OpponentColor \== none,
            map(SanPositionString, CartesianPosition),
            map(OpponentSanPositionString, OpponentCartesianPosition),
            % format('Before Piece: (~w, ~w, ~w)\n', [Piece, Color, SanPositionString]), display_board,
            % format('Opponent: (~w, ~w, ~w)\n', [OpponentPiece, OpponentColor, OpponentCartesianPosition]), display_board, write('\n'),
            piece_legal_moves(Piece, Color, CartesianPosition, Result),
            % format('After Piece: (~w, ~w, ~w)\n', [Piece, Color, SanPositionString]), display_board,
            % format('Piece ~w Legal Moves: ~w\n', [Piece, Result]),

            string_to_atom(SanPositionString, SanPosition),
            string_to_atom(OpponentSanPositionString, OpponentSanPosition),

            member(OpponentCartesianPosition, Result), !
            % format('~w at ~w threats ~w at ~w', [Piece, SanPosition, OpponentPiece, OpponentSanPosition]),
            % format('-----------------------------------------------------------------------------------')
    )).
%end

% Rule: Show a list of squares controlled by player with color Color. [Tested]
control(Color, Result) :-
%start:
    once(
        control_helper(Color, [], Result)
    ).

control_helper(Color, ListOfOccupied, Result) :-
    (
        occupies(Piece, Color, CartesianPosition),
        map(SanPosition, CartesianPosition),
        \+ member(SanPosition, ListOfOccupied),
        all_piece_legal_moves(Piece, Color, CartesianPosition, [], List),
        string_to_atom(SanPosition, SanPositionAtom),
        adjust_list_of_moves(SanPositionAtom, List, ModifiedList),
        control_helper(Color, [SanPosition| ListOfOccupied], Remaning),
        append(ModifiedList, Remaning, Result)
    ).

control_helper(_, _, []).

adjust_list_of_moves(_, [], _) :- !.

adjust_list_of_moves(SanPositionAtom, ListOfPositions, Result) :-
    (
        ListOfPositions = [NextCartesianPosition | Rest], 
        map(NextSanPosition, NextCartesianPosition),
        string_to_atom(NextSanPosition, NextSanPositionAtom),
        adjust_list_of_moves(SanPositionAtom, Rest, Rem),
        Result = [(SanPositionAtom, NextSanPositionAtom) | Rem]
    ).
%end

% Rule:	[Tested]
display_board :- display_square(1, 8), !.

% Rule: Remove all pieces on the chess board. [Tested]
clear_board :-
%start:
    once((
        retract(turn(_)),
        retractall(occupies(_, _, _)),
        retractall(enpassant(_, _, _)),
        retractall(side_castle(_)),
        retractall(rook_stationary(_, _, _)),
        retractall(half_move(_)),
        retractall(full_move(_))
    ;
        true
    )).
%end

% Rule: [Tested]
piece_legal_moves(Piece, Color, Position, Result) :-
    (
        all_piece_legal_moves(Piece, Color, Position, [], Result)
    ).



% Rule: [Tested]
parse_fen(Fen) :-
%start:
    ((
        clear_board, !,
        split_string(Fen, " ", "", PrasedFen),
        PrasedFen = [FenBoard,PlayerTurn,CastleRights,EnpassantPosition,HalfMove,FullMove],
        read_fen(FenBoard),
        set_turn(PlayerTurn),
        string_chars(CastleRights, CastleList),
        set_castling_rights(CastleList),
        set_enpassant_capture(PlayerTurn, EnpassantPosition),
        set_half_move(HalfMove),
        set_full_move(FullMove)
    )).

set_half_move(HalfMove) :-
    (
        atom_number(HalfMove, Num),
        assert(half_move(Num))
    ).

set_full_move(FullMove) :-
    (
        atom_number(FullMove, Num),
        assert(half_move(Num))
    ).

set_enpassant_capture(PlayerTurnAtom, EnpassantPositionAtom) :-
    (
        atom_string(PlayerTurnAtom, PlayerTurnString),
        atom_string(EnpassantPositionAtom, EnpassantPositionString),
        (
            EnpassantPositionString == "-"
            ;
            PlayerTurnString == "w",
            EnpassantPositionString \== "-",
            map(EnpassantPositionString, Position),
            (X1,Y1) = Position,
            Y2 is Y1 - 1, 
            assert(enpassant(pawn, black, (X1, Y2) ))
            ;
            PlayerTurnString == "b",
            EnpassantPositionString \== "-", 
            map(EnpassantPositionString, Position),
            (X1,Y1) = Position,
            Y2 is Y1 + 1,
            assert(enpassant(pawn, white, (X1, Y2)  ))  
        ),
        !
    ).

set_castling_rights([]).

set_castling_rights(CastleRights) :-
    (
        CastleRights = [RightAtom | Rest],
        atom_string(RightAtom, RightString),
        (
            RightString = "K",
            assert(side_castle(white)),
            assert(rook_stationary(rook, white, (8, 1)))
        ;
            RightString = "Q",
            assert(side_castle(white)),
            assert(rook_stationary(rook, white, (1, 1)))
        ;
            RightString = "k",
            assert(side_castle(black)),
            assert(rook_stationary(rook, black, (8, 8)))
        ;
            RightString = "q",
            assert(side_castle(black)),
            assert(rook_stationary(rook, black, (1, 8)))
        ;
            true
        ),
        set_castling_rights(Rest),
        !
    ).

set_turn(PlayerTurn) :-
    (
        atom_string(PlayerTurn, TurnString),
        (
            TurnString == "w",
            assert(turn(white))
        ;
            TurnString == "b",
            assert(turn(black))
        ),
        !
    ).

read_fen(Fen) :-
    (   
        split_string(Fen, "/", "", Rows),
        read_fen_row_by_row(Rows, 8)
    ).

read_fen_row_by_row([], _) :- !.

read_fen_row_by_row(Rows, RowNum) :-
    (
        RowNum =< 8,
        RowNum >= 1,
        Rows = [Row | Rest],
        string_chars(Row, CharRow),
        read_fen_col_by_col(CharRow, 1, RowNum),
        NewRowNum is RowNum - 1,
        read_fen_row_by_row(Rest, NewRowNum)
    ).

read_fen_col_by_col([], _, _).

read_fen_col_by_col(Row, ColNum, RowNum) :- % Must be instantiated (Col, ColNum, RowNum)
    (
        Row = [PieceAtom | Rest],
        atom_string(PieceAtom, Piece),
        (
            (   
                Piece = "r",
                assert(occupies(rook, black, (ColNum, RowNum)))
            ;
                Piece = "n",
                assert(occupies(knight, black, (ColNum, RowNum)))
            ;
                Piece = "b",
                assert(occupies(bishop, black, (ColNum, RowNum)))
            ;
                Piece = "q",
                assert(occupies(queen, black, (ColNum, RowNum)))
            ;
                Piece = "k",
                assert(occupies(king, black, (ColNum, RowNum)))
            ;
                Piece = "p",
                assert(occupies(pawn, black, (ColNum, RowNum)))
            ;
                Piece = "R",
                assert(occupies(rook, white, (ColNum, RowNum)))
            ;
                Piece = "N",
                assert(occupies(knight, white, (ColNum, RowNum)))
            ;
                Piece = "B",
                assert(occupies(bishop, white, (ColNum, RowNum)))
            ;
                Piece = "Q",
                assert(occupies(queen, white, (ColNum, RowNum))) 
            ;
                Piece = "K",
                assert(occupies(king, white, (ColNum, RowNum)))
            ;
                Piece = "P",
                assert(occupies(pawn, white, (ColNum, RowNum))) 
            ),
            !,
            NewColNum is ColNum + 1,
            read_fen_col_by_col(Rest, NewColNum, RowNum)        
        ;
            atom_number(PieceAtom, Blanks),
            StartColNum is ColNum,
            EndColNum is ColNum + Blanks,
            % format("(~w , ~w)\n", [StartColNum,EndColNum]),
            fill_square_blank(StartColNum, EndColNum, RowNum),
            !,
            read_fen_col_by_col(Rest, EndColNum, RowNum)   
        )
    ).

fill_square_blank(H, H, _):- !. % cut here is very important to avoid infinite loop

fill_square_blank(StartColNum, EndColNum, RowNum) :-
    (
        StartColNum < EndColNum,
        assert(occupies(none, none, (StartColNum, RowNum))),
        NewNum is StartColNum + 1,
        fill_square_blank(NewNum, EndColNum, RowNum)
    ).

convert([], []).
convert([H1|T1], [H2|T2]) :-  
    string_to_atom(H1, H2),
    convert(T1, T2).
%end


% Rule: [Tested]
map(PositionString, PositionCoordinate) :- % Must be instantiated (PositionString)
%start:
    (
        PositionString = "a1", PositionCoordinate = (1,1);
        PositionString = "a2", PositionCoordinate = (1,2);
        PositionString = "a3", PositionCoordinate = (1,3);
        PositionString = "a4", PositionCoordinate = (1,4);
        PositionString = "a5", PositionCoordinate = (1,5);
        PositionString = "a6", PositionCoordinate = (1,6);
        PositionString = "a7", PositionCoordinate = (1,7);
        PositionString = "a8", PositionCoordinate = (1,8);
    
        PositionString = "b1", PositionCoordinate = (2,1);
        PositionString = "b2", PositionCoordinate = (2,2);
        PositionString = "b3", PositionCoordinate = (2,3);
        PositionString = "b4", PositionCoordinate = (2,4);
        PositionString = "b5", PositionCoordinate = (2,5);
        PositionString = "b6", PositionCoordinate = (2,6);
        PositionString = "b7", PositionCoordinate = (2,7);
        PositionString = "b8", PositionCoordinate = (2,8);

        PositionString = "c1", PositionCoordinate = (3,1);
        PositionString = "c2", PositionCoordinate = (3,2);
        PositionString = "c3", PositionCoordinate = (3,3);
        PositionString = "c4", PositionCoordinate = (3,4);
        PositionString = "c5", PositionCoordinate = (3,5);
        PositionString = "c6", PositionCoordinate = (3,6);
        PositionString = "c7", PositionCoordinate = (3,7);
        PositionString = "c8", PositionCoordinate = (3,8);
    
        PositionString = "d1", PositionCoordinate = (4,1);
        PositionString = "d2", PositionCoordinate = (4,2);
        PositionString = "d3", PositionCoordinate = (4,3);
        PositionString = "d4", PositionCoordinate = (4,4);
        PositionString = "d5", PositionCoordinate = (4,5);
        PositionString = "d6", PositionCoordinate = (4,6);
        PositionString = "d7", PositionCoordinate = (4,7);
        PositionString = "d8", PositionCoordinate = (4,8);

        PositionString = "e1", PositionCoordinate = (5,1);
        PositionString = "e2", PositionCoordinate = (5,2);
        PositionString = "e3", PositionCoordinate = (5,3);
        PositionString = "e4", PositionCoordinate = (5,4);
        PositionString = "e5", PositionCoordinate = (5,5);
        PositionString = "e6", PositionCoordinate = (5,6);
        PositionString = "e7", PositionCoordinate = (5,7);
        PositionString = "e8", PositionCoordinate = (5,8);

        PositionString = "f1", PositionCoordinate = (6,1);
        PositionString = "f2", PositionCoordinate = (6,2);
        PositionString = "f3", PositionCoordinate = (6,3);
        PositionString = "f4", PositionCoordinate = (6,4);
        PositionString = "f5", PositionCoordinate = (6,5);
        PositionString = "f6", PositionCoordinate = (6,6);
        PositionString = "f7", PositionCoordinate = (6,7);
        PositionString = "f8", PositionCoordinate = (6,8);

        PositionString = "g1", PositionCoordinate = (7,1);
        PositionString = "g2", PositionCoordinate = (7,2);
        PositionString = "g3", PositionCoordinate = (7,3);
        PositionString = "g4", PositionCoordinate = (7,4);
        PositionString = "g5", PositionCoordinate = (7,5);
        PositionString = "g6", PositionCoordinate = (7,6);
        PositionString = "g7", PositionCoordinate = (7,7);
        PositionString = "g8", PositionCoordinate = (7,8);

        PositionString = "h1", PositionCoordinate = (8,1);
        PositionString = "h2", PositionCoordinate = (8,2);
        PositionString = "h3", PositionCoordinate = (8,3);
        PositionString = "h4", PositionCoordinate = (8,4);
        PositionString = "h5", PositionCoordinate = (8,5);
        PositionString = "h6", PositionCoordinate = (8,6);
        PositionString = "h7", PositionCoordinate = (8,7);
        PositionString = "h8", PositionCoordinate = (8,8)
    ).
%end

move_condition_undo(Piece, Color, Position, NewPosition, Condition) :-
    occupies(Piece, Color, Position),
    Color \== none,
	(X1, Y1) = Position,
	(X2, Y2) = NewPosition,
    estimate_value_of_possible_attacks(Color, Value),
	% format('(~w, ~w, ~w, ~w)\n', [Piece, Color, Position, NewPosition]), display_board,
	once(
	(
		% format('Move from ~w to ~w\n', [Position, NewPosition]),
		occupies(none, none, NewPosition),
		\+((											% check that new position will not result in an enpassant attack (handled later in the predicate)
			is_white(Color),
			occupies(OpponentPiece, black, OpponentPosition),
			enpassant(OpponentPiece, black, OpponentPosition),
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, Y3) = OpponentPosition,
			(
				X3 is X1 + 1
			;
				X3 is X1 - 1
			),
			X2 \== X1,
			X2 == X3,
			Y2 is Y1 + 1
		;
			is_black(Color), !,
			occupies(OpponentPiece, white, OpponentPosition),
			enpassant(OpponentPiece, white, OpponentPosition),
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, Y3) = OpponentPosition,
			(
				X3 is X1 + 1
			;
				X3 is X1 - 1
			),
			X2 \== X1,
			X2 == X3,
			Y2 is Y1 - 1
		)), 
		% format("\n before move (~w, ~w)\n",[Position, NewPosition]), display_board, write("\n"),
		move_piece(Piece, Color, Position, NewPosition),
		% format("\n before undo move (~w, ~w)\n",[Position, NewPosition]), display_board, write("\n"),
        apply(Condition, [Piece, Color, Position, NewPosition, none, none, none, none, Value])
	;	
		occupies(none, none, NewPosition),
		(
			is_white(Color),
			Y1 is 2,
			Y2 is Y1 + 2
		;
			is_black(Color),
			Y1 is 7,
			Y2 is Y1 - 2
		),
		move_piece(Piece, Color, Position, NewPosition),
        apply(Condition, [Piece, Color, Position, NewPosition, none, none, none, enpassant, Value])
	;
		is_white(Color),												% check if the piece color is white	.
		occupies(OpponentPiece, black, OpponentPosition),				% check if there exists an opponent piece that is black.
		(
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, Y3) = OpponentPosition,
			enpassant(pawn, black, OpponentPosition),
			(
				X3 is X1 + 1
			;
				X3 is X1 - 1
			),
			X2 == X3,
			X2 \== X1,
			Y2 is Y1 + 1,
			% format('Before move from (~w,~w) from ~w to ~w\n', [Piece, Color, Position, NewPosition]), display_board,
			move_piece(Piece, Color, Position, NewPosition),
            apply(Condition, [Piece, Color, Position, NewPosition, OpponentPiece, black, OpponentPosition, enpassant, Value])
		;
			\+((
				Piece == pawn,
				Y3 is Y2 - 1,
				X3 is X2,
				occupies(pawn, black, (X3, Y3)),
				enpassant(pawn, black, (X3, Y3))
			)),	
			OpponentPosition == NewPosition,
			move_piece(Piece, Color, Position, NewPosition),
            apply(Condition, [Piece, Color, Position, NewPosition, OpponentPiece, black, OpponentPosition, none, Value])
		)
	;	
		is_black(Color),											% check if the piece color is black.
		occupies(OpponentPiece, white, OpponentPosition),			% check if there exists an opponent piece that is white.
		% format('(~w, ~w, ~w)\n', [OpponentPiece, white, OpponentPosition]),
		(
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, Y3) = OpponentPosition,
			enpassant(pawn, white, OpponentPosition),
			(
				X3 is X1 + 1
			;
				X3 is X1 - 1
			),
			X2 == X3,
			X2 \== X1,
			Y2 is Y1 - 1,
			% format('Before move from (~w,~w) from ~w to ~w\n',[Piece, Color, Position, NewPosition]), display_board,
			move_piece(Piece, Color, Position, NewPosition),
			% format('Before undo (~w,~w,~w)\n',[Piece, Color, Position]), display_board,
            apply(Condition, [Piece, Color, Position, NewPosition, OpponentPiece, white, OpponentPosition, none, Value])
		;
			% handle different moves 
			\+((
				Piece == pawn,
				Y3 is Y2 + 1,
				X3 is X2,
				occupies(pawn, white, (X3, Y3)),
				enpassant(pawn, white, (X3, Y3))
			)),
			OpponentPosition == NewPosition,
			% format('Before move (~w, ~w, ~w, ~w,)\n', [Piece, Color, Position, NewPosition]), display_board,
			move_piece(Piece, Color, Position, NewPosition),
            % format('Before undo (~w,~w,~w)\n',[Piece, Color, Position]), display_board,
            apply(Condition, [Piece, Color, Position, NewPosition, OpponentPiece, white, OpponentPosition, none, Value])
		)
	)).