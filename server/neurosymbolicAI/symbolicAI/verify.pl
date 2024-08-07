:- [eval].

% Rule: Verify Position
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Determine whether piece Piece occupies a position UCIPosition                                                 %                                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verify_position(Piece, Color, UCIPosition):-
    (
        occupies(Piece, Color, CartesianPosition),
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),

        Piece \= none,
        Color \= none
    ).

% Rule: Verify Relation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Determine whether piece Piece have relation with ally piece AllyPiece.                                        %                                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verify_relation(Piece, Color, UCIPosition, AllyPiece, Color, AllyUCIPosition, Relation):-
    (
        occupies(Piece, Color, CartesianPosition),
        occupies(AllyPiece, Color, AllyCartesianPosition),
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        map(AllyUCIPositionString, AllyCartesianPosition),
        string_to_atom(AllyUCIPositionString, AllyUCIPosition),

        % Check that a piece does not have a relation with itself.
        UCIPosition \== AllyUCIPosition,
        Color \== none,

        % Check that the relation is `defend` between the two pieces.
        Relation == defend,

        % Check that their exist a `defend` relation between the two pieces.
        defend(Piece, Color, CartesianPosition, AllyPiece, Color, AllyCartesianPosition)
    ).

verify_relation(Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition, Relation):-
    (
        occupies(Piece, Color, CartesianPosition),
        occupies(OpponentPiece, OpponentColor, OpponentCartesianPosition),
        map(UCIPositionString, CartesianPosition),
        string_to_atom(UCIPositionString, UCIPosition),
        map(OpponentUCIPositionString, OpponentCartesianPosition),
        string_to_atom(OpponentUCIPositionString, OpponentUCIPosition),

        % Check that piece Piece and piece OpponentPiece have different colors.
        Color \== OpponentColor,
        Color \== none,
        OpponentColor \== none,
        
        % Check that the relation is `attack` between the two pieces.
        Relation == threat,

        % Check that their exist an `attack` relation between the two pieces.
        threat(Piece, Color, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition)
    ).


