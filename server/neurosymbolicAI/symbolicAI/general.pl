:-[verify].

% Rule: Get Legal Moves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Determine the legal moves of a chess piece                                                                    %                                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_legal_moves(Piece, Color, UCIPosition, LegalMove):- 
    atom_string(UCIPosition, UCIPositionString),
    map(UCIPositionString, CartesianPosition),
    all_piece_legal_moves(Piece, Color, CartesianPosition, [], List),
    get_legal_moves_helper(List, LegalMove).

get_legal_moves_helper([Position| _], UCIPosition) :- 
    map(UCIPositionString, Position),
    string_to_atom(UCIPositionString, UCIPosition).

get_legal_moves_helper([_|Rem], UCIPosition):- get_legal_moves_helper(Rem, UCIPosition).

% Rule: Make Move
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Move a chess piece from one position to another                                                               %                                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
make_move(Piece, Color, FromUCIPosition, ToUCIPosition):-

    atom_string(FromUCIPosition, FromUCIPositionString),
    map(FromUCIPositionString, FromCartesianPosition),

    atom_string(ToUCIPosition, ToUCIPositionString),
    map(ToUCIPositionString, ToCartesianPosition),

    move_piece(Piece, Color, FromCartesianPosition, ToCartesianPosition).



