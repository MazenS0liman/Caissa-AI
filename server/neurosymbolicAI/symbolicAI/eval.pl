:- [reason].

% King Safety
% Rule:
king_safety(Color, CheckSquareList, SupportSquareList, ControlledSquareList) :-
%start:
    once((
        occupies(king, Color, KingPosition),
        king_seige(Color, CheckSquareList),
        king_support(Color, SupportSquareList),
        piece_legal_moves(king, Color, KingPosition, ControlledSquareList),
        king_supported_by_pawns(Color)
    )).

king_seige(Color, Result) :- 
    (
        occupies(king, Color, KingPosition),
        piece_legal_moves(king, Color, KingPosition, Moves),
        king_surronding_squares(Color, Squares),
        king_surronding_checked_squares(Color, Squares, Moves, Result)
    ).

king_surronding_checked_squares(_, [], _, []).

king_surronding_checked_squares(Color, Squares, Moves, Result) :-
    (
        Squares = [Square | Rest],
        \+(member(Square, Moves)),
        \+(occupies(_, Color, Square)),
        Result = [Square | Rem],
        king_surronding_checked_squares(Color, Rest, Moves, Rem)
    ).

king_surronding_checked_squares(Color, Squares, Moves, Result) :-
    (
        Squares = [Square | Rest],
        (
            member(Square, Moves)
            ;
            occupies(_, Color, Square)
        ),
        king_surronding_checked_squares(Color, Rest, Moves, Result)
    ).

king_support(Color, Result) :- 
(
    occupies(king, Color, KingPosition),
    piece_legal_moves(king, Color, KingPosition, Moves),
    king_surronding_squares(Color, Squares),
    king_surronding_squares_filter(Squares, FilteredSquares),
    king_surronding_ally_occupied_squares(Color, FilteredSquares, Moves, Result)
).

king_surronding_ally_occupied_squares(_, [], _, []).

king_surronding_ally_occupied_squares(Color, Squares, Moves, Result) :-
    (
        Squares = [Square | Rest],
        \+(member(Square, Moves)),
        occupies(_, Color, Square),
        Result = [Square | Rem],
        king_surronding_ally_occupied_squares(Color, Rest, Moves, Rem)
    ).

king_surronding_ally_occupied_squares(Color, Squares, Moves, Result) :- 
    (
        Squares = [Square | Rest],
        (
            member(Square, Moves)
            ;
            \+(occupies(_, Color, Square))
        ),
        king_surronding_ally_occupied_squares(Color, Rest, Moves, Result)
    ).

king_surronding_squares(Color, Result) :-
    (
        occupies(king, Color, Position),
        (X, Y) = Position,
        X1 is X + 1, Y1 is Y,
        X2 is X - 1, Y2 is Y,
        X3 is X, Y3 is Y + 1,
        X4 is X, Y4 is Y - 1,
        X5 is X + 1, Y5 is Y + 1,
        X6 is X + 1, Y6 is Y - 1,
        X7 is X - 1, Y7 is Y + 1,
        X8 is X - 1, Y8 is Y - 1,
        Result = [(X1, Y1), (X2, Y2), (X3, Y3), (X4, Y4), (X5, Y5), (X6, Y6), (X7, Y7), (X8, Y8)]
    ).

king_surronding_squares([], []).

king_surronding_squares_filter(ListOfSquares, FilteredSquares) :-
    ListOfSquares = [Square | Rem],
    (
        (X, Y) = Square,
        X >= 1,
        X =< 8,
        Y >= 1,
        Y =< 8, 
        king_surronding_squares_filter(Rem, RemFilteredSquares),
        FilteredSquares = [(X, Y) | RemFilteredSquares]
    ;
        king_surronding_squares_filter(Rem, FilteredSquares)
    ).

king_castled(Color) :-
    (
        \+(side_castle(Color))
    ).

king_supported_by_pawns(Color) :-
    once((
        occupies(king, Color, KingCartesianPosition),
        (X, Y) = KingCartesianPosition, 
        (
            (
                is_white(Color),
                Y1 is Y + 1,
                X1 is X,
                X2 is X + 1,
                X3 is X - 1,
                occupies(pawn, white, (X1, Y1)),
                occupies(pawn, white, (X2, Y1)),
                occupies(pawn, white, (X3, Y1))
            )
            ;   
            (
                is_black(Color),
                Y1 is Y - 1,
                X1 is X,
                X2 is X + 1,
                X3 is X - 1,
                occupies(pawn, black, (X1, Y1)),
                occupies(pawn, black, (X2, Y1)),
                occupies(pawn, black, (X3, Y1))
            )
        )
    )).
%end

% Pawn Structure
% Rule: Isolated Pawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A pawn is isolatd when it can not be protected by another pawn and has no other pawn on the adjacent files.   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
isolated_pawn(Piece, Color, UCIPosition) :-
    (
        Piece == pawn,        
        atom_string(UCIPosition, UCIPositionString),
        map(UCIPositionString, CartesianPosition),
        \+(defend(pawn, Color, _, Piece, Color, CartesianPosition))
    ).

% Rule: Double Pawns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Two pawns of the same color that are on the same file.                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
double_pawn(Piece, Color, UCIPosition, AllyPiece, AllyColor, AllyUCIPosition) :-
    (
        occupies(Piece, Color, CartesianPosition),
        occupies(AllyPiece, AllyColor, AllyCartesianPosition),
        Piece = pawn,
        AllyPiece = pawn,
        Color = AllyColor,
        Color \= none,
        (X1, Y1) = CartesianPosition,
        (X2, Y2) = AllyCartesianPosition,
        X2 == X1,
        Y1 \== Y2,
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        map(AllyUCIPositionString, AllyCartesianPosition),
        string_to_atom(AllyUCIPositionString, AllyUCIPosition)
    ).

% Rule: Backward Pawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A pawn that constitutes the base of a chain of pawns and that can not move because it can be captured by an   %
%               opponent. A pawn is considered a backward pawn if it defends a pawn that defends another pawn and it is not  %
%               defendent by any pawn.                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
backward_pawn(Piece, Color, UCIPosition) :-
    (
        occupies(Piece, Color, CartesianPosition),
        Piece == pawn,
        defend(Piece, Color, CartesianPosition, pawn, Color, AllyCartesianPosition),
        defend(pawn, Color, AllyCartesianPosition, pawn, Color, _),
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition)
    ).

% Rule: Passed Pawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A pawn that can not be stopped by other rival pawns on their way to being promoted. So that their is no       %
%              opponent piece that threat the pawn and the pawn is in the opponent half.                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
passed_pawn(Piece, Color, UCIPosition) :-
    (
        occupies(Piece, Color, CartesianPosition),
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        Piece == pawn,
        color(OpponentColor),
        OpponentColor \== Color,
        OpponentColor \== none,
        \+(threat(_, OpponentColor, _, Piece, Color, UCIPosition)),
        (_, Y) = CartesianPosition,
        (
            is_white(Color),
            Y >= 5,
            Y =< 7
        ;
            is_black(Color),
            Y =< 4,
            Y >= 2
        )
    ).

% Rule: Hanging Pawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A two connected pawns (of the same color) that do not have other pawns at the same side defending them.       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hanging_pawns(Piece, Color, UCIPosition, AllyPiece, AllyColor, AllyUCIPosition) :-
    (
        occupies(Piece, Color, CartesianPosition),
        Piece == pawn,
        (X1, Y1) = CartesianPosition,
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),

        occupies(AllyPiece, AllyColor, AllyCartesianPosition),
        AllyPiece == pawn,
        (X2, Y2) = AllyCartesianPosition,
        Y2 == Y1,
        (
            X2 is X1 - 1
        ;
            X2 is X1 + 1
        ),
        map(AllyUCIPositionString, AllyCartesianPosition),
        string_to_atom(AllyUCIPositionString, AllyUCIPosition),

        Color == AllyColor
    ).

% Rule: Pawn Majority in the Center
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Player have pawn majority in the center when he/she have more pawns in the center than the opponent. The side %
%               has a central majority generally has an advantage on more central squares.                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pawn_center(Piece, Color, UCIPosition) :-
    occupies(Piece, Color, CartesianPosition),
    Piece == pawn,
    Color \== none,
    map(UCIPositionString, CartesianPosition),
    string_to_atom(UCIPositionString, UCIPosition),
    (
        CartesianPosition = (3, 5); CartesianPosition = (4, 5); CartesianPosition = (5, 5); CartesianPosition = (6, 5);
        CartesianPosition = (3, 4); CartesianPosition = (4, 4); CartesianPosition = (5, 4); CartesianPosition = (6, 4)
    ).

% Rule: Pawn Majority in the Flank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Player have pawn majority in the flank when he/she have more pawns in one of the flanks than the opponent.    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pawn_flank(Piece, Color, UCIPosition) :- 
    (
        occupies(Piece, Color, CartesianPosition),
        Piece == pawn,
        Color \== none,
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        (
            is_black(Color),
            (
                CartesianPosition = (1, 2); CartesianPosition = (2, 2); CartesianPosition = (1, 3); CartesianPosition = (2, 3); CartesianPosition = (1, 4); CartesianPosition = (2, 4); CartesianPosition = (1, 5); CartesianPosition = (2, 5); CartesianPosition = (1, 6); CartesianPosition = (2, 6);  
                CartesianPosition = (7, 2); CartesianPosition = (8, 2); CartesianPosition = (7, 3); CartesianPosition = (8, 3); CartesianPosition = (7, 4); CartesianPosition = (8, 4); CartesianPosition = (7, 5); CartesianPosition = (8, 5); CartesianPosition = (7, 6); CartesianPosition = (8, 6)
            )
        ;
            is_white(Color),
            (
                CartesianPosition = (1, 3); CartesianPosition = (2, 3); CartesianPosition = (1, 4); CartesianPosition = (2, 4); CartesianPosition = (1, 5); CartesianPosition = (2, 5); CartesianPosition = (1, 6); CartesianPosition = (2, 6); CartesianPosition = (1, 7); CartesianPosition = (2, 7);  
                CartesianPosition = (7, 3); CartesianPosition = (8, 3); CartesianPosition = (7, 4); CartesianPosition = (8, 4); CartesianPosition = (7, 5); CartesianPosition = (8, 5); CartesianPosition = (7, 6); CartesianPosition = (8, 6); CartesianPosition = (7, 7); CartesianPosition = (8, 7)
            )
        )   
    ).

% Rule: Move Difference Outcome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A general rule for generation of moves that are based on a condition and return the difference based on the   %
%              condition before making the move and after making the move                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_difference_outcome(Color, Condition, ListOfMoves) :-
    (
        move_difference_outcome_helper(Color, Condition, [], ListOfMoves), !
    ).

    move_difference_outcome_helper(Color, Condition, ListOfVisitedPieces, ListOfMoves) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, Color, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfLegalMoves),
            % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
            % format("List of legal moves: ~w\n", [ListOfLegalMoves]),
            move_difference_outcome_per_piece(Piece, Color, CartesianPosition, Condition, ListOfLegalMoves, ListofMovesPerPiece),
            % format("List of legal moves: ~w\n", [ListofMovesPerPiece]),
            ListofMovesPerPiece \== [],
            move_difference_outcome_helper(Color, Condition, [(Piece, Color, CartesianPosition) | ListOfVisitedPieces], RemListOfMoves),
            append(ListofMovesPerPiece, RemListOfMoves, ListOfMoves), !
        ).

    move_difference_outcome_helper(_, _, _, []).

    move_difference_outcome_per_piece(_, _, _, _, [], []).

    move_difference_outcome_per_piece(Piece, Color, CartesianPosition, Condition, ListOfMoves, ListOfMovesOutcome) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],
            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            apply(Condition, [Piece, Color, UCIPosition, [], PreviousList]),

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, difference_condition(Condition, PreviousList, Difference)),
                move_difference_outcome_per_piece(Piece, Color, CartesianPosition, Condition, Rest, RemListOfMoves),
                ListOfMovesOutcome = [[Piece, Color, UCIPosition, NewUCIPosition, Difference] | RemListOfMoves], !
            ;
                move_difference_outcome_per_piece(Piece, Color, CartesianPosition, Condition, Rest, ListOfMovesOutcome)
            )
        ).

    difference_condition(Condition, PreviousList, Difference, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            apply(Condition, [Piece, Color, NewUCIPosition, [], NewList]),
            get_difference_in_moves(PreviousList, NewList, Difference),

            once((
                Difference \== [],
                % format('Difference ~w\n', [Difference]),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                Difference == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

% Rule: Move Result Outcome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: A general rule for generation of moves that are based on a condition and return result based on that          %
%              condition                                                                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_result_outcome(Color, Condition, ListOfMoves) :-
    (
        move_result_outcome_helper(Color, Condition, [], ListOfMoves), !
    ).

    move_result_outcome_helper(Color, Condition, ListOfVisitedPieces, ListOfMoves) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, Color, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfLegalMoves),
            % format("Piece ~w at ~w\n", [Piece, CartesianPosition]),
            % format("List of legal moves: ~w\n", [ListOfLegalMoves]),
            move_result_outcome_per_piece(Piece, Color, CartesianPosition, Condition, ListOfLegalMoves, ListofMovesPerPiece),
            % format("List of legal moves: ~w\n", [ListofMovesPerPiece]),
            ListofMovesPerPiece \== [],
            move_result_outcome_helper(Color, Condition, [(Piece, Color, CartesianPosition) | ListOfVisitedPieces], RemListOfMoves),
            append(ListofMovesPerPiece, RemListOfMoves, ListOfMoves), !
        ).

    move_result_outcome_helper(_, _, _, []).

    move_result_outcome_per_piece(_, _, _, _, [], []).

    move_result_outcome_per_piece(Piece, Color, CartesianPosition, Condition, ListOfMoves, ListOfMovesOutcome) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, result_condition(Condition, Result)),
                move_result_outcome_per_piece(Piece, Color, CartesianPosition, Condition, Rest, RemListOfMoves),
                ListOfMovesOutcome = [[Piece, Color, UCIPosition, NewUCIPosition, Result] | RemListOfMoves], !
            ;
                move_result_outcome_per_piece(Piece, Color, CartesianPosition, Condition, Rest, ListOfMovesOutcome)
            )
        ).

    result_condition(Condition, Result, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            apply(Condition, [Piece, Color, NewUCIPosition, [], Result]),

            once((
                Result \== [],
                % format('Result ~w\n', [Difference]),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                Result == [],
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

% Rule: Move Threat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Moves that cause new threats to opponent's pieces                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_threat(Color, ListOfMoves) :-
    (
        moves_difference_outcome(Color, piece_list_of_threats, ListOfMoves) 
    ).

    piece_list_of_threats(Piece, Color, UCIPosition, ResultSoFar, Result) :-
        (
            occupies(Piece, Color, CartesianPosition),
            occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            Color \== none,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(OpponentUCIPositionString, OpponentCartesianPosition),
            string_to_atom(OpponentUCIPositionString, OpponentUCIPosition),

            \+(member([OpponentPiece, OpponentColor, OpponentUCIPosition], ResultSoFar)),

            threat(Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition),
            piece_list_of_threats(Piece, Color, UCIPosition, [[OpponentPiece, OpponentColor, OpponentUCIPosition]| ResultSoFar], Result)
        ).

    piece_list_of_threats(_, _, _, Result, Result).

% Rule: Move Defend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Moves that cause new defends to allies                                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_defends(Color, ListOfMoves) :-
    (
        moves_difference_outcome(Color, piece_list_of_defends, ListOfMoves) 
    ).

    piece_list_of_defends(Piece, Color, UCIPosition, ResultSoFar, Result) :-
        (
            occupies(Piece, Color, CartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),

            Color \== none,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(AllyUCIPositionString, AllyCartesianPosition),
            string_to_atom(AllyUCIPositionString, AllyUCIPosition),

            \+(member([AllyPiece, Color, AllyUCIPosition], ResultSoFar)),

            defend(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition),
            piece_list_of_defends(Piece, Color, UCIPosition, [[AllyPiece, Color, AllyUCIPosition]| ResultSoFar], Result)
        ).
        
    piece_list_of_defends(_, _, _, Result, Result).

% Rule: Move Is Defended
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Piece that defend a Move                                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
move_is_defended(Color, ListOfMoves) :-
    (
        moves_result_outcome(Color, move_list_of_defends, ListOfMoves)
    ).

    move_list_of_defends(Piece, Color, UCIPosition, ResultSoFar, Result) :-
        (
            occupies(Piece, Color, CartesianPosition),
            occupies(AllyPiece, Color, AllyCartesianPosition),

            Color \== none,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(AllyUCIPositionString, AllyCartesianPosition),
            string_to_atom(AllyUCIPositionString, AllyUCIPosition),

            \+(member([AllyPiece, Color, AllyUCIPosition], ResultSoFar)),

            defend(AllyPiece, Color, AllyCartesianPosition, Piece, Color, CartesianPosition),
            move_list_of_defends(Piece, Color, UCIPosition, [[AllyPiece, Color, AllyUCIPosition]| ResultSoFar], Result)
        ).
        
    move_list_of_defends(_, _, _, Result, Result).

% Rule: Move Is Attacked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Piece that attack a Move                                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_is_attacked(Color, ListOfMoves) :-
    (
        moves_result_outcome(Color, move_list_of_attacks, ListOfMoves) 
    ).

    move_list_of_attacks(Piece, Color, UCIPosition, ResultSoFar, Result) :-
        (
            occupies(Piece, Color, CartesianPosition),
            occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),

            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            Color \== none,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(OpponentUCIPositionString, OpponentCartesianPosition),
            string_to_atom(OpponentUCIPositionString, OpponentUCIPosition),

            \+(member([OpponentPiece, OpponentColor, OpponentUCIPosition], ResultSoFar)),

            threat(OpponentPiece, OpponentColor, OpponentUCIPosition, Piece, Color, UCIPosition),
            move_list_of_attacks(Piece, Color, UCIPosition, [[OpponentPiece, OpponentColor, OpponentUCIPosition]| ResultSoFar], Result)
        ).

    move_list_of_attacks(_, _, _, Result, Result).

% Rule: Move Search Based on Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Search for sequences of Moves based on conditions                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
moves_search(Color, ListOfConditions, Depth, ListOfMoves) :-
    (
        move_search_helper(Depth, Color, ListOfConditions, [], [], ListOfMoves), !
    ).

    move_search_helper(Depth, Color, ListOfConditions, ListOfPreviousMoves, ListOfVisitedPieces, ListOfMoves) :-
        (
            occupies(Piece, Color, CartesianPosition),
            \+(member((Piece, Color, CartesianPosition), ListOfVisitedPieces)),
            piece_legal_moves(Piece, Color, CartesianPosition, ListOfLegalMoves),
            % format("~w ~w at ~w\n", [Color, Piece, CartesianPosition]),
            % format("List of legal moves: ~w\n", [ListOfLegalMoves]),
            move_search_per_piece(Depth, Piece, Color, CartesianPosition, ListOfConditions, ListOfPreviousMoves, ListOfLegalMoves, ListofMovesPerPiece),
            % format("List of moves per piece: ~w\n", [ListofMovesPerPiece]),
            ListofMovesPerPiece \== [],
            move_search_helper(Depth, Color, ListOfConditions, ListOfPreviousMoves, [(Piece, Color, CartesianPosition) | ListOfVisitedPieces], RemListOfMoves),
            append(RemListOfMoves, ListofMovesPerPiece, ListOfMoves), !
        ).

    move_search_helper(_, _, _, _, _, []).

    move_search_per_piece(_, _, _, _, _, _, [], []).

    move_search_per_piece(Depth, Piece, Color, CartesianPosition, ListOfConditions, ListOfPreviousMoves, ListOfMoves, ListOfMovesOutcome) :-
        (
            ListOfMoves = [NewCartesianPosition | Rest],

            (
                move_condition_undo(Piece, Color, CartesianPosition, NewCartesianPosition, search_condition(Depth, ListOfConditions, ListOfPreviousMoves, Result)),
                Result \== [],
                move_search_per_piece(Depth, Piece, Color, CartesianPosition, ListOfConditions, ListOfPreviousMoves, Rest, RemListOfMoves),
                append(RemListOfMoves, [Result], ListOfMovesOutcome), !
                % format('Depth ~w, ListOfMovesOutcome: ~w', [Depth, ListOfMovesOutcome])
            ;
                move_search_per_piece(Depth, Piece, Color, CartesianPosition, ListOfConditions, ListOfPreviousMoves, Rest, ListOfMovesOutcome)
            )
        ).

    search_condition(Depth, ListOfConditions, ListOfPreviousMoves, Result, Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant, _) :-
        (
            NewDepth is Depth - 1,

            color(ColorOfOpponent),
            ColorOfOpponent \== none,
            ColorOfOpponent \== Color,

            map(UCIPositionString, CartesianPosition),
            string_to_atom(UCIPositionString, UCIPosition),

            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            ListOfConditions = [HeadCondition | RestOfConditions],

            % format('Depth: ~w, List Of Previous Moves: ~w, Move: (~w, ~w, ~w, ~w)\n', [Depth, ListOfPreviousMoves, Piece, Color, UCIPosition, NewUCIPosition]),
            % format('Move (~w, ~w, ~w, ~w) at Depth = ~w\n', [Piece, Color, UCIPosition, NewUCIPosition, Depth]),
            % format('Condition ~w\n', [HeadCondition]),

            once((
                Depth > 0,
                apply(HeadCondition, [Piece, Color, UCIPosition, NewUCIPosition, ListOfPreviousMoves]),
                append(ListOfPreviousMoves, [[Piece, Color, UCIPosition, NewUCIPosition]], ListOfNextMoves),
                move_search_helper(NewDepth, ColorOfOpponent, RestOfConditions, ListOfNextMoves, [], Result),
                Result \== [],
                % format('Depth at ~w, ListOfNextMoves: ~w, Result: ~w\n', [Depth, ListOfNextMoves, Result]),
                % format('-------------------------------------------------------\n'),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)		
            ;
                Depth == 0,
                apply(HeadCondition, [Piece, Color, UCIPosition, NewUCIPosition, ListOfPreviousMoves]),
                append(ListOfPreviousMoves, [[Piece, Color, UCIPosition, NewUCIPosition]], Result),
                % format('Depth at ~w, Result: ~w\n', [Depth, Result]),
                % format('-------------------------------------------------------\n'),
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant)
            ;
                undo_move(Piece, Color, CartesianPosition, NewCartesianPosition, OpponentPiece, OpponentColor, OpponentCartesianPosition, Enpassant),
                fail
            ))
        ).

% Rule: Moves Is Countered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Opponent's Moves that counter attack a Move                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
move_counter(Color, ListOfMoves) :-
    (
        ListOfConditions = [not_threated, counter_attack],
        Depth is 1,
        moves_search(Color, ListOfConditions, Depth, ListOfMoves)
    ).

    not_threated(Piece, Color, _, NewUCIPosition, _) :- 
        (
            occupies(Piece, Color, NewCartesianPosition),

            color(Color),
            Color \== none,

            map(NewUCIPositionString, NewCartesianPosition),
            string_to_atom(NewUCIPositionString, NewUCIPosition),

            % format('First Move (~w, ~w, ~w, ~w)\n', [Piece, Color, UCIPosition, NewUCIPosition]), display_board,
            \+((
                occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),
                color(OpponentColor),
                OpponentColor \== none,
                OpponentColor \== Color,

                map(OpponentUCIPositionString, OpponentCartesianPosition),
                string_to_atom(OpponentUCIPositionString, OpponentUCIPosition),

                threat(OpponentPiece, OpponentColor, OpponentUCIPosition, Piece, Color, NewUCIPosition)
            ))
            % format('Piece (~w, ~w, ~w) is not threated\n', [Piece, Color, NewUCIPosition]), display_board
        ).

    counter_attack(Piece, Color, _, NewUCIPosition, ListOfPreviousMoves) :-
        (
            occupies(AllyPiece, Color, AllyCartesianPosition),
            atom_string(NewUCIPosition, NewUCIPositionString),
            map(NewUCIPositionString, NewCartesianPosition),

            get_last(ListOfPreviousMoves, LastMove),
            LastMove = [OpponentPiece, OpponentColor, _, OpponentToUCIPosition],

            Piece \== king,

            % format('Do Piece (~w, ~w, ~w) threats (~w, ~w, ~w)?\n',[Piece, Color, NewUCIPosition, OpponentPiece, OpponentColor, OpponentToUCIPosition]),
            threat(Piece, Color, NewUCIPosition, OpponentPiece, OpponentColor, OpponentToUCIPosition),
            defend(AllyPiece, Color, AllyCartesianPosition, Piece, Color, NewCartesianPosition),
            (
                (
                    Piece \== pawn,

                    \+((
                        occupies(pawn, OpponentColor, OpponentPawnCartesianPosition),

                        map(OpponentPawnUCIPositionString, OpponentPawnCartesianPosition),
                        string_to_atom(OpponentPawnUCIPositionString, OpponentPawnUCIPosition),

                        threat(pawn, OpponentColor, OpponentPawnUCIPosition, Piece, Color, NewUCIPosition)
                    ))
                )
            ;
                (
                    Piece == pawn,
                    true
                )
            )
            % format('Yes Piece (~w, ~w, ~w) threats (~w, ~w, ~w)\n',[Piece, Color, NewUCIPosition, OpponentPiece, OpponentColor, OpponentToUCIPosition])
        ).

    get_last([LastElem], LastElem).

    get_last([_, Elem2 | Rest], LastElem) :-
        (
            get_last([Elem2 | Rest], LastElem)
        ).

% Rule: Move Is Not Countered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: No Opponent's Moves that counter attack a Move                                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
move_not_counter(Color, ListOfMoves) :-
    (
        ListOfConditions = [not_counter_attack],
        Depth is 0,
        moves_search(Color, ListOfConditions, Depth, ListOfMoves)
    ).

    not_counter_attack(Piece, Color, _, NewUCIPosition, _) :-
        (
            color(OpponentColor),
            OpponentColor \== Color,
            OpponentColor \== none,
            % format('(~w, ~w, ~w)\n', [Piece, Color, NewUCIPosition]),

            not_threated(Piece, Color, _, NewUCIPosition, _),
            moves_threat(OpponentColor, ListOfMoves),
            % format('ListOfMoves: ~w\n', [ListOfMoves]),
            not_counter_attack_helper(Piece, Color, _, NewUCIPosition, ListOfMoves)
        ).

    not_counter_attack_helper(_, _, _, _, []).

    not_counter_attack_helper(Piece, Color, _, NewUCIPosition, ListOfMoves) :-
        (
            ListOfMoves = [Head | Tail],
            Head = [_, _, _, _, ListOfThreats],
            % format('ListOfThreats: ~w\n', [ListOfThreats]),
            \+(member([Piece, Color, NewUCIPosition], ListOfThreats)), !,
            % format('Piece: (~w, ~w, ~w) can not be a counter attacked by (~w, ~w, ~w, ~w)\n', [Piece, Color, NewUCIPosition, OpponentPiece, OpponentColor, OpponentFromUCIPosition, OpponentToUCIPosition]),
            not_counter_attack_helper(Piece, Color, _, NewUCIPosition, Tail)
        ).

% Rule: Least Active Piece
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Piece that is least active among its ally pieces                                                              % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%
%    TODO    %
%%%%%%%%%%%%%%

% Rule: Check a Move is legal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Check whether a move is a legal move                                                                          % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_legal(Piece, Color, FromUCIPosition, ToUCIPosition) :-
    (
        occupies(Piece, Color, FromCartesianPosition),

        map(FromUCIPositionString, FromCartesianPosition),
        string_to_atom(FromUCIPositionString, FromUCIPosition),

        
        atom_string(ToUCIPosition, ToUCIPositionString),
        map(ToUCIPositionString, ToCartesianPosition),
    
        format('Piece (~w, ~w, ~w)\n', [Piece, Color, FromUCIPosition]),
        all_piece_legal_moves(Piece, Color, FromCartesianPosition, [], ListOfMoves),
        member(ToCartesianPosition, ListOfMoves)
    ).

% Rule: All Threats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Check for opponent pieces that are under threat by ally pieces                                                % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_threat(Color, Result) :-
    (
        all_threat_helper2(Color, [], ListOfThreats),
        all_threat_helper1(ListOfThreats, Result)
    ).
    
    all_threat_helper1([], []).

    all_threat_helper1(ListOfThreats, Result) :-
        (
            ListOfThreats = [Head | Taill],
            (Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition) = Head,
            all_threat_helper1(Taill, RemResult),
            Result = [[Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition] | RemResult]
        ).

    all_threat_helper2(Color, ListOfThreatedPiecesSoFar, Result) :-
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
                !,
                % format('No piece defends (~w, ~w, ~w)\n', [OpponentPiece, OpponentColor, OpponentUCIPositionAtom]), display_board,
                all_threat_helper2(Color, [(Piece, Color, UCIPositionAtom, OpponentPiece, OpponentColor, OpponentUCIPositionAtom) | ListOfThreatedPiecesSoFar], Result)
            ).
    
        all_threat_helper2(_, List, List).