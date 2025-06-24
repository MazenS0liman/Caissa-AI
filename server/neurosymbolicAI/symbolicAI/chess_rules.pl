:- dynamic(occupies/3).
:- dynamic(enpassant/3).
:- dynamic(side_castle/1).
:- dynamic(rook_stationary/3).
:- dynamic(turn/1).
:- dynamic(half_move/1).
:- dynamic(full_move/1).
cls :- write('\33\[2J').

%*******************************************************************************
%* ChessBoard					                                               *
%*******************************************************************************
% Black Side
occupies(rook, 		black, (1, 8)).
occupies(knight, 	black, (2, 8)).
occupies(bishop, 	black, (3, 8)).
occupies(queen, 	black, (4, 8)).

occupies(king, 		black, (5, 8)).
occupies(bishop, 	black, (6, 8)).
occupies(knight, 	black, (7, 8)).
occupies(rook, 		black, (8, 8)).

occupies(pawn, 		black, (1, 7)).
occupies(pawn, 		black, (2, 7)).
occupies(pawn, 		black, (3, 7)).
occupies(pawn, 		black, (4, 7)).

occupies(pawn, 		black, (5, 7)).
occupies(pawn, 		black, (6, 7)).
occupies(pawn, 		black, (7, 7)).
occupies(pawn, 		black, (8, 7)).

% White Side
occupies(pawn,		white, (1, 2)).
occupies(pawn, 		white, (2, 2)).
occupies(pawn, 		white, (3, 2)).
occupies(pawn,		white, (4, 2)).

occupies(pawn, 		white, (5, 2)).
occupies(pawn, 		white, (6, 2)).
occupies(pawn, 		white, (7, 2)).
occupies(pawn, 		white, (8, 2)).

occupies(rook, 		white, (1, 1)).
occupies(knight, 	white, (2, 1)).
occupies(bishop, 	white, (3, 1)).
occupies(queen, 	white, (4, 1)).

occupies(king, 		white, (5, 1)).
occupies(bishop, 	white, (6, 1)).
occupies(knight, 	white, (7, 1)).
occupies(rook, 		white, (8, 1)).

% Empty Squares
occupies(none, 		none, (1, 6)).
occupies(none, 		none, (2, 6)).
occupies(none, 		none, (3, 6)).
occupies(none, 		none, (4, 6)).
		  
occupies(none, 		none, (5, 6)).
occupies(none, 		none, (6, 6)).
occupies(none, 		none, (7, 6)).
occupies(none, 		none, (8, 6)).
		 
occupies(none, 		none, (1, 5)).
occupies(none, 		none, (2, 5)).
occupies(none, 		none, (3, 5)).
occupies(none, 		none, (4, 5)).
		  
occupies(none, 		none, (5, 5)).
occupies(none, 		none, (6, 5)).
occupies(none, 		none, (7, 5)).
occupies(none, 		none, (8, 5)).

occupies(none, 		none, (1, 4)).
occupies(none, 		none, (2, 4)).
occupies(none, 		none, (3, 4)).
occupies(none, 		none, (4, 4)).
		  
occupies(none, 		none, (5, 4)).
occupies(none, 		none, (6, 4)).
occupies(none, 		none, (7, 4)).
occupies(none, 		none, (8, 4)).
		
occupies(none, 		none, (1, 3)).
occupies(none, 		none, (2, 3)).
occupies(none, 		none, (3, 3)).
occupies(none, 		none, (4, 3)).
		  
occupies(none, 		none, (5, 3)).
occupies(none, 		none, (6, 3)).
occupies(none, 		none, (7, 3)).
occupies(none, 		none, (8, 3)).

%*******************************************************************************
%* General 							                                           *
%*******************************************************************************
%%% Pieces
piece(king).
piece(queen).
piece(bishop).
piece(knight).
piece(rook).
piece(pawn).

%%% Colors
color(white).
color(black).

is_white(Color) :- Color == white.
is_black(Color) :- Color == black.

%%% En-Passant
enpassant(none, none, none).

%%% Side Castle
% side_castle(white).
% side_castle(black).

%%% Rook Move Check
rook_stationary(rook, white, (1, 1)).
rook_stationary(rook, white, (8, 1)).
rook_stationary(rook, black, (1, 8)).
rook_stationary(rook, black, (8, 8)).

%%% Player Turn
turn(white).

%%% Half Move
half_move(0).

%%% Full Move
full_move(0).

%%% Opening
is_opening(X) :- 
	X < 11.

%*******************************************************************************
%* Legal Moves						                                           *
%*******************************************************************************
% General
legal_move(Piece, Color, OldPosition, NewPosition) :-
%start:
	(
		pawn_legal_move(Piece, Color, OldPosition, NewPosition)
		;
		knight_legal_move(Piece, Color, OldPosition, NewPosition)
		;
		rook_legal_move(Piece, Color, OldPosition, NewPosition)
		;
		bishop_legal_move(Piece, Color, OldPosition, NewPosition)
		;
		king_legal_move(Piece, Color, OldPosition, NewPosition)
		;
		queen_legal_move(Piece, Color, OldPosition, NewPosition)
	).
%end
	
move_piece(Piece, Color, OldPosition, NewPosition) :-
%start:
	once((
		Piece = pawn,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before pawn move or attack\n"), display_board,
		pawn_move_or_attack(Piece, Color, OldPosition, NewPosition)
		;
		Piece = rook,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before rook move or attack\n"), display_board,
		rook_move_or_attack(Piece, Color, OldPosition, NewPosition)
		;
		Piece = knight,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before knight move or attack\n"), display_board,
		knight_move_or_attack(Piece, Color, OldPosition, NewPosition)
		;
		Piece = bishop,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before bishop move or attack\n"), display_board,
		bishop_move_or_attack(Piece, Color, OldPosition, NewPosition)
		;
		Piece = queen,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before queen move or attack\n"), display_board,
		queen_move_or_attack(Piece, Color, OldPosition, NewPosition)
		;
		Piece = king,
		occupies(Piece, Color, OldPosition),
		% format("\n test: before king move or attack\n"), display_board,
		king_move_or_attack(Piece, Color, OldPosition, NewPosition)
	)).
%end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								Pawn 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rule: give all possible legal moves or attacks for a pawn on OldPosition 
pawn_legal_move(Piece, Color, OldPosition, NewPosition) :-
%start:
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	Piece = pawn,
	(
		(
			is_white(Color),
			Y1 =\= 2,							% condition that pawn is not its first move then the pawn can move one square at a time.
			X2 = X1,
			Y2 is Y1 + 1,
			occupies(none, none,(X2, Y2))		% condition that the square moves to is empty.
		)
		;
		(
			is_white(Color),
			(X1, Y1) = OldPosition,
			Y1 == 2,
			X2 = X1,
			(
				Y2 is Y1 + 1,
				occupies(none, none,(X2, Y2))
				;
				Y2 is Y1 + 2,
				Y3 is Y1 + 1,
				occupies(none, none,(X2, Y3)),
				occupies(none, none,(X2, Y2))
			)
		)
		;
		(
			is_black(Color),
			(X1, Y1) = OldPosition,
			Y1 =\= 7,
			X2 = X1,
			Y2 is Y1 - 1,
			occupies(none, none, (X2, Y2))
		)
		;
		(
			is_black(Color),
			(X1, Y1) = OldPosition,
			Y1 == 7,
			X2 = X1,
			(
				Y2 is Y1 - 1,
				occupies(none, none, (X2, Y2))
			;
				Y2 is Y1 - 2,
				Y3 is Y1 - 1,
				occupies(none, none, (X2, Y3)),
				occupies(none, none, (X2, Y2))
			)
		)
		;
		(
			is_white(Color),
			(
				X2 is X1 + 1,
				Y2 is Y1 + 1		
			;
				X2 is X1 - 1,
				Y2 is Y1 + 1
			),
			
			occupies(_, black, NewPosition)			% condition that a black piece exists on NewPosition
		)
		;
		(
			is_white(Color),
			(
				X2 is X1 + 1,
				Y2 is Y1 + 1		
			;
				X2 is X1 - 1,
				Y2 is Y1 + 1
			),
			Y3 is Y2 - 1,
			enpassant(pawn, black, (X2, Y3)) 
		)
		;
		(
			is_black(Color),
			(
				X2 is X1 + 1,
				Y2 is Y1 - 1
			;
				X2 is X1 - 1,
				Y2 is Y1 - 1
			),	
			occupies(_, white, NewPosition)			% condition that a white piece exists on NewPosition	 
		)
		;
		(
			is_black(Color),
			(
				X2 is X1 + 1,
				Y2 is Y1 - 1
			;
				X2 is X1 - 1,
				Y2 is Y1 - 1
			),
			Y3 is Y2 + 1,
			enpassant(pawn, white, (X2, Y3)) 
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8.
%end
	
% Rule: move from OldPosition to NewPosition or attack a piece on NewPosition.
pawn_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
%start:
	\+(OldPosition == NewPosition),							% condition that OldPosition can not be same as NewPosition 
	(
		push_pawn(Piece, Color, OldPosition, NewPosition)
		;
		is_white(Color),
		pawn_attack(Piece, white, OldPosition, _, black, NewPosition)
		;
		is_black(Color),
		pawn_attack(Piece, black, OldPosition, _, white, NewPosition)
	).
%end

% Rule: push a pawn to the front if it is possible.
push_pawn(Piece, Color, OldPosition, NewPosition) :-
%start:
	(
		Piece = pawn, 												% condition that the Piece is a pawn.
		occupies(Piece, Color, OldPosition), 						% condition that the pawn occupies OldPosition.
		pawn_legal_move(Piece, Color, OldPosition, NewPosition),	% condition that move from OldPosition to the NewPosition is considered legal.
		(X1, Y1) = OldPosition,
		(X2, Y2) = NewPosition,
		X1 == X2,
		occupies(none, none, NewPosition),							% condition that NewPosition is empty.
		retract(occupies(Piece, Color, OldPosition)),				% remove the Piece from the OldPosition.
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the Piece to the NewPosition.
		assert(occupies(none, none, OldPosition)),
		% format("\n test: with in push pawn\n"), display_board, write("\n"), 
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			% format('pawn new position ~w', [NewPosition]),
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		)),
		once(
			(
				is_black(Color),
				Y1 == 7,
				X2 = X1,
				Y2 is Y1 - 2,
				assert(enpassant(Piece, Color, NewPosition))
			)
		;
			(
				is_white(Color),
				Y1 == 2,
				X2 = X1,
				Y2 is Y1 + 2,
				assert(enpassant(Piece, Color, NewPosition))
			)
		;
			true												% condition if the move is not an enpassat move. 
		)
	).
%end
	
% Rule: make a pawn attack a piece of the opponent.
pawn_attack(Piece, Color, Position, OpponentPiece, OpponentColor, OpponentPosition) :-
%start:
	Piece = pawn,												% condition that the Piece is a pawn.
	occupies(Piece, Color, Position),							% condition that the Piece occupies Position.
	(X1, Y1) = OpponentPosition,
	(
		(
			occupies(OpponentPiece, OpponentColor, OpponentPosition),	% condition that the OpponentPiece occupies OpponentPosition.
			\+ (OpponentColor == Color),								% condition that a pawn can not attack a piece of the same color.
			\+ (OpponentColor == none),									% condition that a pawn can not attack an empty square.
			pawn_legal_move(Piece, Color, Position, OpponentPosition), 				% condition that the attack of the pawn is considered a legal move.
			retract(occupies(OpponentPiece, OpponentColor, OpponentPosition)),		% remove OpponentPiece from position OpponentPosition. (add it to cemetery)
			retract(occupies(Piece, Color, Position)),								% remove Piece from position Position to place it to OpponentPosition later on.
			assert(occupies(Piece, Color, OpponentPosition)),
			assert(occupies(none, none, Position)),
			\+((
				in_check(Color), !,													% condition that the attack done by pawn will not result in a check to the player currently who has the turn.
				retract(occupies(Piece, Color, OpponentPosition)),
				retract(occupies(none, none, Position)),
				assert(occupies(Piece, Color, Position)),							% revert the last attack of the pawn.
				assert(occupies(OpponentPiece, OpponentColor, OpponentPosition))
			)),
			(
				enpassant(OpponentPiece, OpponentColor, OpponentPosition),
				retract(enpassant(OpponentPiece, OpponentColor, OpponentPosition))
			;
				true
			)
		)
		;
		(
			pawn_legal_move(Piece, Color, Position, OpponentPosition),			% condition that the attack of the pawn is considered a legal move.
			(
				(
					is_black(OpponentColor),												 
					Y2 is Y1 - 1,												% Y2 is the position that black pawn will move to. (leave it as it is)
					enpassant(OpponentPiece, OpponentColor, (X1, Y1)),			% condition that the last move by the opponent player is an enpassant move.
					retract(enpassant(OpponentPiece, OpponentColor, (X1, Y2))),
					
					retract(occupies(OpponentPiece, OpponentColor, (X1, Y2))),
					assert(occupies(none, none, (X1, Y2))),
					
					retract(occupies(none, none, OpponentPosition)),					
					assert(occupies(Piece, Color, OpponentPosition)),
					
					retract(occupies(Piece, Color, Position)),
					assert(occupies(none, none, Position)),	
					\+((
						in_check(Color), !,
						retract(occupies(Piece, Color, OpponentPosition)),
						retract(occupies(none, none, Position)),
						retract(occupies(none, none, (X1, Y2))),
						assert(enpassant(OpponentPiece, OpponentColor, (X1, Y2))),
						assert(occupies(Piece, Color, Position)),
						assert(occupies(OpponentPiece, OpponentColor, (X1, Y2))),
						assert(occupies(none, none, OpponentPosition))
					))
				)
				;
				(
					is_white(OpponentColor),
					Y2 is Y1 + 1,
					enpassant(OpponentPiece, OpponentColor, (X1, Y2)),			% condition that the last move by the opponent player is an enpassant move.
					retract(enpassant(OpponentPiece, OpponentColor, (X1, Y2))),
					
					retract(occupies(OpponentPiece, OpponentColor, (X1, Y2))),
					assert(occupies(none, none, (X1, Y2))),
					
					retract(occupies(none, none, OpponentPosition)),					
					assert(occupies(Piece, Color, OpponentPosition)),
					
					retract(occupies(Piece, Color, Position)),
					assert(occupies(none, none, Position)),	
					\+((
						in_check(Color), !,
						retract(occupies(Piece, Color, OpponentPosition)),
						retract(occupies(none, none, Position)),
						retract(occupies(none, none, (X1, Y2))),
						assert(enpassant(OpponentPiece, OpponentColor, (X1, Y2))),
						assert(occupies(Piece, Color, Position)),
						assert(occupies(OpponentPiece, OpponentColor, (X1, Y2))),
						assert(occupies(none, none, OpponentPosition))
					))
				)
			)
		)
	).
%end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								Rook 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rule: give all possible legal moves or attacks for a rook on OldPosition 
rook_legal_move(Piece, Color, OldPosition, NewPosition) :-
%start:
	Piece = rook,
	occupies(Piece, Color, OldPosition),
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	(
		(
			% Move Upward Vertically
			Y3 is Y1 + 1,
			empty_upward_vertical_range_of_squares_inclusive((X1,Y3),(X2,Y2), Color),
			X1 == X2,				% condition that the x-coordiante must be same as the original position.
			Y2 =\= Y1				% condition that the y-coordiante must be different from the original position.																			
		)
		;
		(
			% Move Downward Vertically
			Y3 is Y1 - 1,
			empty_downward_vertical_range_of_squares_inclusive((X1,Y3),(X2,Y2), Color),
			X1 == X2,				% condition that the x-coordiante must be same as the original position.
			Y2 =\=Y1				% condition that the y-coordiante must be different from the original position.
		)
		;
		(
			% Move Right Horizontally
			X3 is X1 + 1,
			empty_right_horizontal_range_of_squares_inclusive((X3,Y1),(X2,Y2), Color),
			X1 =\= X2,				% condition that the x-coordiante must be different from the original position.	
			Y2 ==Y1					% condition that the y-coordiante must be same as the original position.	
		)
		;
		(
			% Move Right Horizontally
			X3 is X1 - 1,
			empty_left_horizontal_range_of_squares_inclusive((X3,Y1),(X2,Y2), Color),
			X1 =\= X2,				% condition that the x-coordiante must be different from the original position.
			Y2 ==Y1					% condition that the y-coordiante must be same as the original position.
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8.
%end

% Rule: move from OldPosition to NewPosition or attack a piece on NewPosition.
rook_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
%start:
	Piece = rook, 												% condition that the Piece is a rook.
	occupies(Piece, Color, OldPosition), 						% condition that the rook occupies OldPosition.
	\+ (OldPosition == NewPosition),							% condition that OldPosition can not be same as NewPosition
	rook_legal_move(Piece, Color, OldPosition, NewPosition),	% condition that move from OldPosition to the NewPosition is considered legal.
	(
		occupies(none, none, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),				% remove the rook from the OldPosition. 
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the rook to the NewPosition.
		assert(occupies(none, none, OldPosition)),					% fill the OldPosition with blank. (as no piece occupies it)
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		)),
		(
		retract(rook_stationary(rook, Color, OldPosition))
		;
			true
		)
	;
		is_white(Color),											
		occupies(OpponentPiece, black, NewPosition),				% condition that a black piece occupies NewPosition. (which means that move is attack)
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, black, NewPosition)),		
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, black, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, black, NewPosition),
			retract(enpassant(OpponentPiece, black, NewPosition))
			;
			true
		)),
		(
		retract(rook_stationary(rook, Color, OldPosition))
		;
			true
		)
	;
		is_black(Color),
		occupies(OpponentPiece, white, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, white, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, undo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, white, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, white, NewPosition),
			retract(enpassant(OpponentPiece, white, NewPosition))
			;
			true
		)),
		(
			retract(rook_stationary(rook, Color, OldPosition))
		;
			true
		)
	).
%end

	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								Knight 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rule: give all possible legal moves or attacks for a knight on OldPosition 
knight_legal_move(Piece, Color, OldPosition, NewPosition) :-
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	Piece = knight,
	occupies(knight, Color, OldPosition),
	(
		(
			X2 is X1 + 1,
			Y2 is Y1 + 2
		)
		;
		(
			X2 is X1 + 1,
			Y2 is Y1 - 2
		)
		;
		(
			X2 is X1 + 2,
			Y2 is Y1 + 1
		)
		;
		(
			X2 is X1 + 2,
			Y2 is Y1 - 1
		)
		;
		(
			X2 is X1 - 1,
			Y2 is Y1 + 2
		)
		;
		(
			X2 is X1 - 1,
			Y2 is Y1 - 2
		)
		;
		(
			X2 is X1 - 2,
			Y2 is Y1 + 1
		)
		;
		(
			X2 is X1 - 2,
			Y2 is Y1 - 1
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8,
	\+ (occupies(_,Color,NewPosition)).
	
% Rule: move from OldPosition to NewPosition or attack a piece on NewPosition.
knight_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
	Piece = knight, 												% condition that the Piece is a knight.
	occupies(Piece, Color, OldPosition), 							% condition that the knight occupies OldPosition.
	\+ (OldPosition == NewPosition),								% condition that OldPosition can not be same as NewPosition
	knight_legal_move(Piece, Color, OldPosition, NewPosition),		% condition that move from OldPosition to the NewPosition is considered legal.
	(
		occupies(none, none, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),				% remove the knight from the OldPosition. 
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the knight to the NewPosition.
		assert(occupies(none, none, OldPosition)),					% fill the OldPosition with blank. (as no piece occupies it)
		\+((
			in_check(Color), !,										% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),			% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		))
	;
		is_white(Color),											
		occupies(OpponentPiece, black, NewPosition),				% condition that a black piece occupies NewPosition. (which means that move is attack)
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, black, NewPosition)),		
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,										% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),			% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, black, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, black, NewPosition),
			retract(enpassant(OpponentPiece, black, NewPosition))
			;
			true
		))
		
	;
		is_black(Color),
		occupies(OpponentPiece, white, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, white, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, undo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, white, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, white, NewPosition),
			retract(enpassant(OpponentPiece, white, NewPosition))
			;
			true
		))
	).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								Bishop 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bishop_legal_move(Piece, Color, OldPosition, NewPosition) :-
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	Piece = bishop,
	occupies(bishop, Color, OldPosition),
	(
		(
			X3 is X1 + 1,
			Y3 is Y1 + 1,
			empty_right_positive_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 - 1,
			Y3 is Y1 - 1,
			empty_left_positive_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 + 1,
			Y3 is Y1 - 1,
			empty_right_negative_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 - 1,
			Y3 is Y1 + 1,
			empty_left_negative_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8.
	
bishop_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
	Piece = bishop, 												% condition that the Piece is a bishop.
	occupies(Piece, Color, OldPosition), 						% condition that the bishop occupies OldPosition.
	\+ (OldPosition == NewPosition),							% condition that OldPosition can not be same as NewPosition
	bishop_legal_move(Piece, Color, OldPosition, NewPosition),	% condition that move from OldPosition to the NewPosition is considered legal.
	(
		occupies(none, none, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),				% remove the bishop from the OldPosition. 
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the bishop to the NewPosition.
		assert(occupies(none, none, OldPosition)),					% fill the OldPosition with blank. (as no piece occupies it)
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		))
	;
		is_white(Color),											
		occupies(OpponentPiece, black, NewPosition),				% condition that a black piece occupies NewPosition. (which means that move is attack)
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, black, NewPosition)),		
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, black, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, black, NewPosition),
			retract(enpassant(OpponentPiece, black, NewPosition))
			;
			true
		))
		
	;
		is_black(Color),
		occupies(OpponentPiece, white, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, white, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, undo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, white, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, white, NewPosition),
			retract(enpassant(OpponentPiece, white, NewPosition))
			;
			true
		))
	).
 	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								Queen 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
queen_legal_move(Piece, Color, OldPosition, NewPosition) :-
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	Piece = queen,
	occupies(queen, Color, OldPosition),
	(
		(
			% Move Upward Vertically
			Y3 is Y1 + 1,
			empty_upward_vertical_range_of_squares_inclusive((X1,Y3),(X2,Y2), Color),
			X1 == X2,
			Y2 =\= Y1		
		)
		;
		(
			% Move Downward Vertically
			Y3 is Y1 - 1,
			empty_downward_vertical_range_of_squares_inclusive((X1,Y3),(X2,Y2), Color),
			X1 == X2,
			Y2 =\= Y1
		)
		;
		(
			% Move Right Horizontally
			X3 is X1 + 1,
			empty_right_horizontal_range_of_squares_inclusive((X3,Y1),(X2,Y2), Color),
			X1 =\= X2,
			Y2 == Y1
		)
		;
		(
			% Move Left Horizontally
			X3 is X1 - 1,
			empty_left_horizontal_range_of_squares_inclusive((X3,Y1),(X2,Y2), Color),
			X1 =\= X2,
			Y2 == Y1
		)
		;
		(
			X3 is X1 + 1,
			Y3 is Y1 + 1,
			empty_right_positive_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 - 1,
			Y3 is Y1 - 1,
			empty_left_positive_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 + 1,
			Y3 is Y1 - 1,
			empty_right_negative_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
		;
		(
			X3 is X1 - 1,
			Y3 is Y1 + 1,
			empty_left_negative_slope_diagonal_range_of_squares_inclusive((X3,Y3), (X2, Y2), Color),
			X2 =\= X1,
			Y2 =\= Y1
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8.

queen_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
	% format("\nQueen piece: ~w\n", [Piece]),
	Piece = queen, 												% condition that the Piece is a queen.
	occupies(Piece, Color, OldPosition), 						% condition that the queen occupies OldPosition.
	\+ (OldPosition == NewPosition),							% condition that OldPosition can not be same as NewPosition
	% format("\ntest: before within move (~w, ~w)\n", [OldPosition, NewPosition]), display_board, write("\n"),
	queen_legal_move(Piece, Color, OldPosition, NewPosition),	% condition that move from OldPosition to the NewPosition is considered legal.
	(
		occupies(none, none, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),				% remove the queen from the OldPosition. 
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the queen to the NewPosition.
		assert(occupies(none, none, OldPosition)),					% fill the OldPosition with blank. (as no piece occupies it)
		% format("\ntest: within move (~w, ~w)\n", [OldPosition, NewPosition]), display_board, write("\n"),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		))
	;
		is_white(Color),											
		occupies(OpponentPiece, black, NewPosition),				% condition that a black piece occupies NewPosition. (which means that move is attack)
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, black, NewPosition)),		
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, black, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, black, NewPosition),
			retract(enpassant(OpponentPiece, black, NewPosition))
		;
			true
		))
		
	;
		is_black(Color),
		occupies(OpponentPiece, white, NewPosition),
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, white, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, undo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, white, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, white, NewPosition),
			retract(enpassant(OpponentPiece, white, NewPosition))
			;
			true
		))
	).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 								King 	  								   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
king_legal_move(Piece, Color, OldPosition, NewPosition) :-
	% write("king legal moves\n"),
	% format("(~w, ~w)\n",[OldPosition, NewPosition]),
	% display_board,
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	Piece = king,
	occupies(king, Color, OldPosition),
	(
		(
			X2 is X1 + 1,
			Y2 is Y1
		)
		;
		(
			X2 is X1 - 1,
			Y2 is Y1
		)
		;
		(
			X2 is X1,
			Y2 is Y1 + 1
		)
		;
		(
			X2 is X1,
			Y2 is Y1 - 1
		)
		;
		(
			X2 is X1 + 1,
			Y2 is Y1 + 1
		)
		;
		(
			X2 is X1 + 1,
			Y2 is Y1 - 1
		)
		;
		(
			X2 is X1 - 1,
			Y2 is Y1 + 1
		)
		;
		(
			X2 is X1 - 1,
			Y2 is Y1 - 1
		)
		;
		(
			X2 is X1 + 2,
			Y2 is Y1,
			make_king_side_castle(Color), !,
			% write('test: check that king has king side castle rights.'),
			undo_make_king_side_castle(Color)
		)
		;
		(
			X2 is X1 - 2,	
			Y2 is Y1,
			make_queen_side_castle(Color), !,
			% write('test: check that king has queen side castle rights.'),
			undo_make_queen_side_castle(Color)
		)
	),
	X2 >= 1,
	X2 =< 8,
	Y2 >= 1,
	Y2 =< 8,
	\+ (occupies(_,Color,NewPosition)).
	
king_move_or_attack(Piece, Color, OldPosition, NewPosition) :-
	Piece = king, 												% condition that the Piece is a king.
	occupies(Piece, Color, OldPosition), 						% condition that the king occupies OldPosition.
	\+ (OldPosition == NewPosition),							% condition that OldPosition can not be same as NewPosition.
	king_legal_move(Piece, Color, OldPosition, NewPosition),	% condition that move from OldPosition to the NewPosition is considered legal.
	% format("~w \n",NewPosition),
	% display_board,
	% write('\n'),
	(X1, Y1) = OldPosition,
	(X2, Y2) = NewPosition,
	(
		X2 is X1 + 2,
		Y2 is Y1,
		make_king_side_castle(Color)
	;
		X2 is X1 - 2,
		Y2 is Y1,
		make_queen_side_castle(Color)
	;
		occupies(none, none, NewPosition),
		\+(X2 is X1 + 2),
		\+(X2 is X1 - 2),
		% write("test 1\n"),
		% display_board,
		retract(occupies(Piece, Color, OldPosition)),				% remove the king from the OldPosition. 
		retract(occupies(none, none, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),				% add the king to the NewPosition.
		assert(occupies(none, none, OldPosition)),					% fill the OldPosition with blank. (as no piece occupies it)
		% write("test 2\n"),
		% display_board,
		\+((
			in_check(Color), !,										% condition that current player who made the move is in check.
			% write("test 3\n"),
			% display_board,
			retract(occupies(Piece, Color, NewPosition)),			% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(none, none, NewPosition))
		)),
		% write("test 8"),
		(
			retract(side_castle(Color))
		;
			true
		)
	;
		is_white(Color),
		\+(X2 is X1 + 2),
		\+(X2 is X1 - 2),											
		occupies(OpponentPiece, black, NewPosition),				% condition that a black piece occupies NewPosition. (which means that move is attack)
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, black, NewPosition)),		
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, redo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, black, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, black, NewPosition),
			retract(enpassant(OpponentPiece, black, NewPosition))
		;
			true
		)),
		(
			retract(side_castle(Color))
		;
			true
		)
	;
		is_black(Color),
		occupies(OpponentPiece, white, NewPosition),
		\+(X2 is X1 + 2),
		\+(X2 is X1 - 2),
		retract(occupies(Piece, Color, OldPosition)),
		retract(occupies(OpponentPiece, white, NewPosition)),
		assert(occupies(Piece, Color, NewPosition)),
		assert(occupies(none, none, OldPosition)),
		\+((
			in_check(Color), !,									% condition that current player who made the move is in check.
			retract(occupies(Piece, Color, NewPosition)),		% if in check, undo the steps.
			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),
			assert(occupies(OpponentPiece, white, NewPosition))
		)),
		once((
			enpassant(OpponentPiece, white, NewPosition),
			retract(enpassant(OpponentPiece, white, NewPosition))
			;
			true
		)),
		(
			retract(side_castle(Color))				% remove castle rights if the king moved
		;
			true
		)
	).

make_king_side_castle(Color) :-
%start:
	(
		is_white(Color),
		\+(in_check(Color)),									% check 1: the king is not in check.
		occupies(king, Color, (5,1)),						
		occupies(rook, Color, (8, 1)), 
		side_castle(Color),								% check 2: the king has not already been moved in the game.
		rook_stationary(rook, Color, (8,1)),					% check 3: the rook has not already been moved in the game.
		empty_right_king_side_castling((6,1),(7,1),Color),		% check 4: their is no piece between the rook and king.
		all_player_unique_legal_moves(black, Res),
		\+(member((6, 1), Res)),								% check 5: the square (6, 1) is not under attack.
		\+(member((7, 1), Res)),								% check 6: the square (7, 1) is not under attack.
		retract(occupies(king, Color, (5,1))),			
		assert(occupies(none, none, (5,1))),

		retract(occupies(none, none, (6,1))),
		assert(occupies(rook, Color, (6,1))),

		retract(occupies(none, none, (7,1))),
		assert(occupies(king, Color, (7,1))),

		retract(occupies(rook, Color, (8,1))),
		assert(occupies(none, none, (8,1))),
		!,

		\+((
			in_check(Color),
			retract(occupies(none, none, (5,1))),			
			assert(occupies(king, Color, (5,1))),
	
			retract(occupies(rook, Color, (6,1))),
			assert(occupies(none, none, (6,1))),
	
			retract(occupies(king, Color, (7,1))),
			assert(occupies(none, none, (7,1))),
	
			retract(occupies(none, none, (8,1))),
			assert(occupies(rook, Color, (8,1))),
			fail
		)),
		!,
		retract(side_castle(Color)),
		retract(rook_stationary(rook, Color, (8,1)))
	;
		is_black(Color),
		\+(in_check(Color)),									% check 1: the king is not in check.
		occupies(king, Color, (5,8)),						
		occupies(rook, Color, (8, 8)), 
		side_castle(Color),								% check 2: the king has not already been moved in the game.
		rook_stationary(rook, Color, (8,8)),					% check 3: the rook has not already been moved in the game.
		empty_right_king_side_castling((6,8),(7,8),Color),		% check 4: their is no piece between the rook and king.
		all_player_unique_legal_moves(white, Res),
		\+(member((6, 8), Res)),								% check 5: the square (6, 1) is not under attack.
		\+(member((7, 8), Res)),								% check 6: the square (7, 1) is not under attack.
		retract(occupies(king, Color, (5,8))),			
		assert(occupies(none, none, (5,8))),

		retract(occupies(none, none, (6,8))),
		assert(occupies(rook, Color, (6,8))),

		retract(occupies(none, none, (7,8))),
		assert(occupies(king, Color, (7,8))),

		retract(occupies(rook, Color, (8,8))),
		assert(occupies(none, none, (8,8))),
		!,

		\+((
			in_check(Color),
			retract(occupies(none, none, (5,8))),			
			assert(occupies(king, Color, (5,8))),
	
			retract(occupies(rook, Color, (6,8))),
			assert(occupies(none, none, (6,8))),
	
			retract(occupies(king, Color, (7,8))),
			assert(occupies(none, none, (7,8))),
	
			retract(occupies(none, none, (8,8))),
			assert(occupies(rook, Color, (8,8))),
			fail
		)),
		!,
		retract(side_castle(Color)),
		retract(rook_stationary(rook, Color, (8,8)))
	).
%end

undo_make_king_side_castle(Color) :-
%start:
	(
		is_white(Color),
		retract(occupies(none, none, (5,1))),			
		assert(occupies(king, Color, (5,1))),

		retract(occupies(rook, Color, (6,1))),
		assert(occupies(none, none, (6,1))),

		retract(occupies(king, Color, (7,1))),
		assert(occupies(none, none, (7,1))),

		retract(occupies(none, none, (8,1))),
		assert(occupies(rook, Color, (8,1))),

		assert(side_castle(Color)),
		assert(rook_stationary(rook, Color, (8,1)))
	;	
		is_black(Color),
		retract(occupies(none, none, (5,8))),			
		assert(occupies(king, Color, (5,8))),

		retract(occupies(rook, Color, (6,8))),
		assert(occupies(none, none, (6,8))),

		retract(occupies(king, Color, (7,8))),
		assert(occupies(none, none, (7,8))),
		
		retract(occupies(none, none, (8,8))),
		assert(occupies(rook, Color, (8,8))),

		assert(side_castle(Color)),
		assert(rook_stationary(rook, Color, (8,8)))
	).
%end


make_queen_side_castle(Color) :-
%start:
(
	is_white(Color),
	\+(in_check(Color)),									% check 1: the king is not in check.
	occupies(king, Color, (5,1)),						
	occupies(rook, Color, (1, 1)), 
	side_castle(Color),										% check 2: the king has not already been moved in the game.
	rook_stationary(rook, Color, (1,1)),					% check 3: the rook has not already been moved in the game.
	empty_left_queen_side_castling((4,1),(2,1),Color),		% check 4: their is no piece between the rook and king.
	all_player_unique_legal_moves(black, Res),
	\+(member((4, 1), Res)),								% check 5: the square (4, 1) is not under attack.
	\+(member((3, 1), Res)),								% check 6: the square (3, 1) is not under attack.
	retract(occupies(king, Color, (5,1))),			
	assert(occupies(none, none, (5,1))),

	retract(occupies(none, none, (3,1))),
	assert(occupies(king, Color, (3,1))),

	retract(occupies(none, none, (4,1))),
	assert(occupies(rook, Color, (4,1))),

	retract(occupies(rook, Color, (1,1))),
	assert(occupies(none, none, (1,1))),

	!,

	\+((
		in_check(Color),
		retract(occupies(none, none, (5,1))),			
		assert(occupies(king, Color, (5,1))),

		retract(occupies(king, Color, (3,1))),
		assert(occupies(none, none, (3,1))),

		retract(occupies(rook, Color, (4,1))),
		assert(occupies(none, none, (4,1))),

		retract(occupies(none, none, (1,1))),
		assert(occupies(rook, Color, (1,1))),
		fail
	)),
	!,
	retract(side_castle(Color)),
	retract(rook_stationary(rook, Color, (1,1)))
	
;
	is_black(Color),
	\+(in_check(Color)),									% check 1: the king is not in check.
	occupies(king, Color, (5,8)),						
	occupies(rook, Color, (1, 8)), 
	side_castle(Color),										% check 2: the king has not already been moved in the game.
	rook_stationary(rook, Color, (1,8)),					% check 3: the rook has not already been moved in the game.
	empty_left_queen_side_castling((4,8),(2,8),Color),		% check 4: their is no piece between the rook and king.
	all_player_unique_legal_moves(white, Res),
	\+(member((4, 8), Res)),								% check 5: the square (4, 8) is not under attack.
	\+(member((3, 8), Res)),								% check 6: the square (3, 8) is not under attack.
	retract(occupies(king, Color, (5,8))),			
	assert(occupies(none, none, (5,8))),

	retract(occupies(none, none, (3,8))),
	assert(occupies(king, Color, (3,8))),

	retract(occupies(none, none, (4,8))),
	assert(occupies(rook, Color, (4,8))),

	retract(occupies(rook, Color, (1,8))),
	assert(occupies(none, none, (1,8))),

	!,

	\+((
		in_check(Color),
		retract(occupies(none, none, (5,8))),			
		assert(occupies(king, Color, (5,8))),

		retract(occupies(king, Color, (3,8))),
		assert(occupies(none, none, (3,8))),

		retract(occupies(rook, Color, (4,8))),
		assert(occupies(none, none, (4,8))),

		retract(occupies(none, none, (1,8))),
		assert(occupies(rook, Color, (1,8))),
		fail
	)),
	!,
	retract(side_castle(Color)),
	retract(rook_stationary(rook, Color, (1,8)))
).
%end

undo_make_queen_side_castle(Color) :-
%start:
(
	is_white(Color),
	retract(occupies(none, none, (5,1))),			
	assert(occupies(king, Color, (5,1))),

	retract(occupies(king, Color, (3,1))),
	assert(occupies(none, none, (3,1))),

	retract(occupies(rook, Color, (4,1))),
	assert(occupies(none, none, (4,1))),

	retract(occupies(none, none, (1,1))),
	assert(occupies(rook, Color, (1,1))),

	assert(side_castle(Color)),
	assert(rook_stationary(rook, Color, (1,1)))
;	
	is_black(Color),
	retract(occupies(none, none, (5,8))),			
	assert(occupies(king, Color, (5,8))),

	retract(occupies(king, Color, (3,8))),
	assert(occupies(none, none, (3,8))),

	retract(occupies(rook, Color, (4,8))),
	assert(occupies(none, none, (4,8))),

	retract(occupies(none, none, (1,8))),
	assert(occupies(rook, Color, (1,8))),

	assert(side_castle(Color)),
	assert(rook_stationary(rook, Color, (1,8)))
).
%end
	
%*******************************************************************************
%* Appendices Rules					                                           *
%*******************************************************************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% General %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General Rule 1: [Tested]
all_piece_legal_moves(Piece, Color, Position, L1, L2) :-
	occupies(Piece, Color, Position),										
	legal_move(Piece, Color, Position, NewPosition),						% gives a legal moves for a piece on the chessboard.
	\+ member(NewPosition, L1),												% check that the legal move is not already in the list L1.
	% format("\n check (~w) (~w)\n",[Position, NewPosition]), display_board, write("\n"),
	(X1, Y1) = Position,
	(X2, Y2) = NewPosition,
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
			(X3, _) = OpponentPosition,
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
			(X3, _) = OpponentPosition,
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
		undo_move(Piece, Color, Position, NewPosition, none, none, none, none)
		% format("\n after undo move (~w, ~w)\n",[Position, NewPosition]), display_board, write("\n")
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
		undo_move(Piece, Color, Position, NewPosition, none, none, none, enpassant)
	;
		is_white(Color),												% check if the piece color is white	.
		occupies(OpponentPiece, black, OpponentPosition),				% check if there exists an opponent piece that is black.
		(
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, _) = OpponentPosition,
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
			% format('Before undo (~w,~w,~w)\n',[Piece, Color, Position]), display_board,
			undo_move(Piece, Color, Position, NewPosition, OpponentPiece, black, OpponentPosition, enpassant)
			% format('After undo (~w,~w,~w)\n',[Piece, Color, Position]), display_board
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
			undo_move(Piece, Color, Position, NewPosition, OpponentPiece, black, OpponentPosition, none)		
		)
	;	
		is_black(Color),											% check if the piece color is black.
		occupies(OpponentPiece, white, OpponentPosition),			% check if there exists an opponent piece that is white.
		% format('(~w, ~w, ~w)\n', [OpponentPiece, white, OpponentPosition]),
		(
			Piece == pawn,
			OpponentPiece == pawn,
			(X3, _) = OpponentPosition,
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
			undo_move(Piece, Color, Position, NewPosition, OpponentPiece, white, OpponentPosition, enpassant)
			% format('After undo (~w,~w,~w)\n',[Piece, Color, Position]), display_board
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
			% format('After move (~w, ~w, ~w, ~w,)\n', [Piece, Color, Position, NewPosition]), 
			% format('Opponent (~w, ~w, ~w)', [OpponentPiece, white, OpponentPosition]),display_board,
			% format('NewPosition: ~w', NewPosition),
			undo_move(Piece, Color, Position, NewPosition, OpponentPiece, white, OpponentPosition, none)		
		)
	)),!,
	all_piece_legal_moves(Piece, Color, Position, [NewPosition| L1], L2).
	
all_piece_legal_moves(_, _, _, List, List) :- !.							% condition if there is no more legal moves then the result is List.

% General Rule 2:
all_player_legal_moves(Color, L1, Res) :-
	occupies(Piece, Color, Position),
	all_piece_legal_moves(Piece, Color, Position, [], L2),
	\+ member(Position, L1), !,
	all_player_legal_moves(Color, [Position| L1], R),
	append(L2, R, Res).
	
all_player_legal_moves(_, _,[]).

% General Rule 3:
all_player_unique_legal_moves(Color, Res) :-
	all_player_legal_moves(Color, [], R),
	remove_duplicates(R, Res).
	
% General Rule 4:
remove_duplicates([], []).

remove_duplicates([Head | Tail], Result) :-
	member(Head, Tail), !,
	remove_duplicates(Tail, Result).
	
remove_duplicates([Head | Tail], [Head | Result]) :-
	\+ member(Head, Tail),
	remove_duplicates(Tail, Result).

% General Rule 5:
display_square(_, 0) :- !.

display_square(X, Y) :-
    occupies(Piece, Color, (X, Y)),
    Mod is X mod 8,
    (
        (
            Color = white,
            (
                Piece = pawn, 	format('|| wp  ')
                ;
                Piece = queen, format('|| wq  ')
                ;
                Piece = king, 	format('|| wk  ')
                ;
                Piece = rook, 	format('|| wr  ')							
                ;
                Piece = knight, format('|| wn  ')							
                ;
                Piece = bishop, format('|| wb  ')							
            )
        )
        ;
        (
            Color = black,
            (
                Piece = pawn, 	format('|| bp  ')
                ;
                Piece = queen, 	format('|| bq  ')
                ;
                Piece = king, 	format('|| bk  ')
                ;
                Piece = rook, 	format('|| br  ')
                ;
                Piece = knight, format('|| bn  ')
                ;
                Piece = bishop, format('|| bb  ')
            )
        )
        ;
        (
            Color = none,
            format('|| ___ ')
        )
    ),

    Mod == 0 -> 
        (
            Y1 is Y - 1,
			write('||'),
            write('\n'), 
            Y1 =< 8,  
            display_square(1, Y1) 
        )
        ;
        (
            X1 is X + 1,
            X1 =< 8, 
            X1 >= 1, 
            display_square(X1, Y)		
        ).

% General Rule 6:
undo_move(Piece, Color, OldPosition, NewPosition, OpponentPiece, OpponentColor, OpponentPosition, Enpassant) :-
%start:
	((
		(% undo a move made by a piece to a blank space.
			OpponentPiece == none,
			Enpassant == none,
			(X1,Y1) = OldPosition,
			(X2, Y2) = NewPosition,
			\+((
				Piece = pawn,
				is_white(Color),
				Y1 is 2,
				Y2 is 4,
				X2 is X1
			;
				Piece = pawn,
				is_black(Color),
				Y1 is 7,
				Y2 is 5,
				X2 is X1
			)),
			% write("undo \n"),
			% display_board,
			retract(occupies(Piece, Color, NewPosition)),
			assert(occupies(none, none, NewPosition)),

			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition))
		)
		;
		(% undo the first move made by a pawn.
			OpponentPiece == none,
			Enpassant == none,
			(X1,Y1) = OldPosition,
			(X2, Y2) = NewPosition,
			((
				Piece = pawn,
				is_white(Color),
				Y1 is 2,
				Y2 is 4,
				X2 is X1
			;
				Piece = pawn,
				is_black(Color),
				Y1 is 7,
				Y2 is 5,
				X2 is X1
			)),
			retract(occupies(Piece, Color, NewPosition)),
			assert(occupies(none, none, NewPosition)),

			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),

			retract(enpassant(Piece, Color, NewPosition))
		)
		;
		(
			OpponentPiece == none,
			\+(Enpassant == none),
			retract(occupies(Piece, Color, NewPosition)),
			assert(occupies(none, none, NewPosition)),

			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),

			retract(enpassant(Piece, Color, NewPosition))
		)
		;
		(% undo an attack made by a piece.
			OpponentPiece \== none,
			OpponentColor \== none,
			OpponentPiece \== none,
			Enpassant == none,			
			% format('Piece (~w, ~w, ~w) vs Opponent (~w, ~w, ~w)', [Piece, Color, OldPosition, OpponentPiece, OpponentColor, OpponentPosition]),
			retract(occupies(Piece, Color, OpponentPosition)),
			assert(occupies(OpponentPiece, OpponentColor, OpponentPosition)),

			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition))
		)
		;
		(% undo an attack made by piece on an enpassant pawn
			OpponentPiece \== none,
			OpponentColor \== none,
			OpponentPiece \== none,
			Enpassant \== none,
			retract(occupies(Piece, Color, NewPosition)),
			assert(occupies(none, none, NewPosition)),

			retract(occupies(none, none, OldPosition)),
			assert(occupies(Piece, Color, OldPosition)),

			retract(occupies(none, none, OpponentPosition)),
			assert(occupies(OpponentPiece, OpponentColor, OpponentPosition)),

			assert(enpassant(OpponentPiece, OpponentColor, OpponentPosition))
		)
	)),
	!.
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pawn %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pawn Rule 1: promote pawns that are available for promotion.
promote() :- 
	once((
		occupies(pawn, white, (X, Y)),
		Y is 8,
		retract(occupies(pawn, white, (X, Y))),
		assert(occupies(queen, white, (X, Y))),
		promote
	;
		occupies(pawn, black, (X, Y)),
		Y is 1,
		retract(occupies(pawn, black, (X, Y))),
		assert(occupies(queen, black, (X, Y))),
		promote
	;
		true
	)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Rook %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rook Rule 1: validate empty upward vertical range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
%start: 
empty_upward_vertical_range_of_squares_inclusive((X,Y), (X,Y), Color) :-
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_upward_vertical_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	X2 = X1,
	Y3 is Y1 + 1,
	occupies(none, none, From), !,
	empty_upward_vertical_range_of_squares_inclusive((X1, Y3), (X2, Y2), Color).
%end

% Rook Rule 2: validate empty downward vertical range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
%start:
empty_downward_vertical_range_of_squares_inclusive((X, Y), (X, Y), Color) :-
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_downward_vertical_range_of_squares_inclusive(From, To, Color) :-
%start:
	(
		(X1, Y1) = From,
		(X2, Y2) = To,
		X2 = X1,
		Y3 is Y1 - 1,
		occupies(none, none, From), !,
		empty_downward_vertical_range_of_squares_inclusive((X1, Y3), (X2, Y2), Color)
	).

%end

% Rook Rule 3: validate empty right horizontal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
%start:
empty_right_horizontal_range_of_squares_inclusive((X, Y), (X, Y), Color) :-
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_right_horizontal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	Y2 = Y1,
	X3 is X1 + 1,
	occupies(none, none, From), !,
	empty_right_horizontal_range_of_squares_inclusive((X3, Y1), (X2, Y2), Color).
%end

% Rook Rule 4: validate empty left horizontal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
%start:
empty_left_horizontal_range_of_squares_inclusive((X, Y), (X, Y), Color) :-
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_left_horizontal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	Y2 = Y1,
	X3 is X1 - 1,
	occupies(none, none, From), !,
	empty_left_horizontal_range_of_squares_inclusive((X3, Y1), (X2, Y2), Color).
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Bishop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bishop Rule 1: Validate empty right positive slope diagonal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
empty_right_positive_slope_diagonal_range_of_squares_inclusive((X,Y), (X,Y), Color) :-
%start
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_right_positive_slope_diagonal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	X3 is X1 + 1,
	Y3 is Y1 + 1,
	occupies(none, none, From), !,
	empty_right_positive_slope_diagonal_range_of_squares_inclusive((X3, Y3), (X2, Y2), Color).
%end
	
% Bishop Rule 2: Validate left positive slope diagonal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
empty_left_positive_slope_diagonal_range_of_squares_inclusive((X,Y), (X,Y), Color) :-
%start:
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_left_positive_slope_diagonal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	X3 is X1 - 1,
	Y3 is Y1 - 1,
	occupies(none, none, From), !,
	empty_left_positive_slope_diagonal_range_of_squares_inclusive((X3, Y3), (X2, Y2), Color).
%end

% Bishop Rule 3: Validate right negative slope diagonal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
empty_right_negative_slope_diagonal_range_of_squares_inclusive((X,Y), (X,Y), Color) :-
%start:
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_right_negative_slope_diagonal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	X3 is X1 + 1,
	Y3 is Y1 - 1,
	occupies(none, none, From), !,
	empty_right_negative_slope_diagonal_range_of_squares_inclusive((X3, Y3), (X2, Y2), Color).
%end

% Bishop Rule 4: Validate left negative slope diagonal range of squares on the chessboard and that the last square either contain an opponent piece or square is empty.
empty_left_negative_slope_diagonal_range_of_squares_inclusive((X,Y), (X,Y), Color) :-
%start:
	(
		occupies(none, none, (X, Y))
		;
		is_white(Color), occupies(_,black,(X,Y))
		;
		is_black(Color), occupies(_,white,(X,Y))
	).

empty_left_negative_slope_diagonal_range_of_squares_inclusive(From, To, Color) :-
	(X1, Y1) = From,
	(X2, Y2) = To,
	X3 is X1 - 1,
	Y3 is Y1 + 1,
	occupies(none, none, From), !,
	empty_left_negative_slope_diagonal_range_of_squares_inclusive((X3, Y3), (X2, Y2), Color).
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% King %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% King Rule 1: Determine whether the king is in check.
in_check(Color) :-
	% format("\n test: show board before checking whether king is in check for ~w \n", [Color]), display_board, write("\n"),
	once((
	occupies(king, Color, PiecePosition),
	% format("test: the position of ~w king is ~w\n", [Color, PiecePosition]),
	(
		(
			is_white(Color),													% condition that color of the king is white.
			occupies(OpponentPiece, black, OpponentPosition),					% condition that their exist a black piece.	
			% format("test: One of the pieces for ~w that could cause check is ~w\n", [black, OpponentPiece]),
			(
				once((
					OpponentPiece = king,
					retract(occupies(king, Color, PiecePosition)),
					assert(occupies(none, none, PiecePosition)),
					(
						legal_move(OpponentPiece, black, OpponentPosition, PiecePosition),	% condition that the black piece have a legal move to the king's position.
						retract(occupies(none, none, PiecePosition)),
						assert(occupies(king, Color, PiecePosition))
						% format("\n test: opponent piece ~w does check ~w king \n", [OpponentPiece, Color]), display_board
					;
						\+(legal_move(OpponentPiece, black, OpponentPosition, PiecePosition)),	% condition that the black piece have a legal move to the king's position.
						retract(occupies(none, none, PiecePosition)),
						assert(occupies(king, Color, PiecePosition)),
						% format("\n test: opponent piece ~w does not check ~w king \n", [OpponentPiece, Color]), display_board,
						fail
					)				
				))
			;
				OpponentPiece \= king,
				legal_move(OpponentPiece, black, OpponentPosition, PiecePosition)	% condition that the black piece have a legal move to the king's position.
				% format("\n test: opponent piece ~w does check ~w king \n", [OpponentPiece, Color]), display_board
			)
		)

		;
		
		(
			is_black(Color),													% condition that color of the king is black.
			occupies(OpponentPiece, white, OpponentPosition),				% condition that their exist a white piece.
			% format('All Opponent: (~w, ~w, ~w)\n', [OpponentPiece, white, OpponentPosition]),
			(
				OpponentPiece = king,
				retract(occupies(king, Color, PiecePosition)),
				assert(occupies(none, none, PiecePosition)),
				once((
					legal_move(OpponentPiece, white, OpponentPosition, PiecePosition),	% condition that the black piece does have a legal move to the king's position.
					retract(occupies(none, none, PiecePosition)),
					assert(occupies(king, Color, PiecePosition))
				;
					once((
						\+(legal_move(OpponentPiece, white, OpponentPosition, PiecePosition)),	% condition that the black piece does not have a legal move to the king's position.
						retract(occupies(none, none, PiecePosition)),
						assert(occupies(king, Color, PiecePosition))
					)),
					fail
				))
			;
				% format('Opponent: (~w, ~w, ~w)\n', [OpponentPiece, white, OpponentPosition]),
				OpponentPiece \= king,
				legal_move(OpponentPiece, white, OpponentPosition, PiecePosition)	% condition that the white piece have a legal move to the king's position.
			)	
		)
	))).
	
% King Rule 2:
check(Piece, Color, PiecePosition, king, OpponentColor, OpponentKingPosition) :-
	all_piece_legal_moves(Piece, Color, PiecePosition, [], L),
	occupies(king, OpponentColor, OpponentKingPosition),
	member(OpponentKingPosition, L).

% King Rule 3: A king is in checkmate if all position of that the king can move to including its original position is considered a legal move to the opponent.
in_checkmate(Color) :-
%start:
	once((
		occupies(Piece, Color, KingPosition),
		is_white(Color),
		Piece = king,
		all_player_unique_legal_moves(Color, Result),
		Result == [],
		all_player_unique_legal_moves(black, List),
		member(KingPosition, List)
		;
		occupies(Piece, Color, KingPosition),
		is_black(Color),	
		Piece = king,
		all_player_unique_legal_moves(Color, Result),
		Result == [],
		all_player_unique_legal_moves(white, List),
		member(KingPosition, List)		
	)).
%end

% King Rule 4: A king is in stalemate if all position of that the king can move to including its original position is considered a legal move to the opponent.
in_stalemate(Color) :- 
%start:
once((
	occupies(Piece, Color, KingPosition),
	is_white(Color),
	Piece = king,
	all_player_unique_legal_moves(Color, Result),
	Result == [],
	all_player_unique_legal_moves(black, List),
	\+member(KingPosition, List)
	;
	occupies(Piece, Color, KingPosition),
	is_black(Color),	
	Piece = king,
	all_player_unique_legal_moves(Color, Result),
	Result == [],
	all_player_unique_legal_moves(white, List),
	\+member(KingPosition, List)		
)).
%end

% King Rule 4: Validate the left side squares is empty for Queen Side Castling.
empty_left_queen_side_castling((X,Y), (X,Y), _) :-
%start:
	(
		occupies(none, none, (X, Y))
	).
	
empty_left_queen_side_castling(From, To, Color) :-
	(
		(X1, Y1) = From,
		(X2, Y2) = To,
		X3 is X1 - 1,
		X3 >= 1,
		X3 =< 8,
		Y3 is Y1,
		occupies(none, none, From), !, 
	empty_left_queen_side_castling((X3, Y3), (X2, Y2), Color)
	).
%end

% King Rule 5: Validate the right side squares is empty for Queen Side Castling.
empty_right_queen_side_castling((X,Y), (X,Y), _) :-
%start:
	(
		occupies(none, none, (X, Y))
	).
	
empty_right_king_side_castling(From, To, Color) :-
	(
		(X1, Y1) = From,
		(X2, Y2) = To,
		X3 is X1 + 1,
		X3 >= 1,
		X3 =< 8,
		Y3 is Y1,
		occupies(none, none, From), !,
		empty_left_negative_slope_diagonal_range_of_squares_inclusive((X3, Y3), (X2, Y2), Color)
	).
%end
	

	
	



