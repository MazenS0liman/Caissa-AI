import React, { useMemo, useState, useEffect, useContext } from "react";
import { Chessboard } from "react-chessboard";
import { Chess } from "chess.js";
import { fenContext, boardContext, mapBoardToFen, getPosition } from "../ChatInterface/ChatInterface";
import axios from 'axios';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import IconButton from '@mui/material/IconButton';
import Collapse from '@mui/material/Collapse';
import Button from '@mui/material/Button';
import CloseIcon from '@mui/icons-material/Close';

interface ThreeDParams {
  cause?: any,
  displayLoading: (a: boolean) => any,
  editBoard: boolean,
  clickedPiece: string
}

interface PieceParams {
  square?: any,
  squareWidth: number
}

interface PieceComp {
  piece: string,
  pieceHeight: number
}

type Piece = "wP" | "wN" | "wB" | "wR" | "bP" | "bN" | "bB" | "bR" | "bQ" | "bK"

const boardWrapper = {
  width: `70vw`,
  maxWidth: "70vh",
  margin: "3rem auto",
}

const colorVariants = [
  "darkred",
  "#48AD7E",
  "rgb(245, 192, 0)",
  "#093A3E",
  "#F75590",
  "#F3752B",
  "#058ED9",
]

export const ThreeDChess = ({ cause = [], displayLoading, editBoard, clickedPiece }: ThreeDParams) => {
    const [activeSquare, setActiveSquare] = useState<string>("");
    const [customArrows, setCustomArrows] = useState<any[]>([]);
    const [openAlert, setOpenAlert] = useState<boolean>(false);
    const [alert, setAlert] = useState<string>("");
    const [fen, setFen] = useContext<[string, React.Dispatch<React.SetStateAction<string>>]>(fenContext);
    const [board, setBoard] = useContext<[string[][], React.Dispatch<React.SetStateAction<string[][]>>]>(boardContext);

    useEffect(() => {
      let tmpCustomeArrows: any[] = [];

      if (cause.length === 0 || !Array.isArray(cause)) {
        setCustomArrows([])
        return;
      }

      if (cause[0] === undefined || cause[1] === undefined || !Array.isArray(cause[0]) || !Array.isArray(cause[1])) {
        setCustomArrows([])
        return;
      }

      let move = cause[0]
      let pieceCurrentPosition = move[2]
      let pieceNextPosition = move[3]

      cause[1].forEach((tactic: Array<any>) => {
        let tacticName = tactic[0]
        let arrayOfCause = tactic[1]

        if (tacticName == "discoveredAttack") {
          let arrow1 = [pieceCurrentPosition,  pieceNextPosition, colorVariants[1]];
          tmpCustomeArrows.push(arrow1);

          arrayOfCause.forEach((tuple: any) => {
            let allyPosition = tuple[2]
            let opponentPosition = tuple[5]
            let arrow2 = [allyPosition, opponentPosition, colorVariants[0]]
            tmpCustomeArrows.push(arrow2)
          })
        }
        else if (tacticName == "fork") {
          let arrow1 = [pieceCurrentPosition,  pieceNextPosition, colorVariants[1]]
          tmpCustomeArrows.push(arrow1)

          arrayOfCause.forEach((tuple: any) => {
            let opponentPosition = tuple[2]
            let arrow2 = [pieceNextPosition, opponentPosition, colorVariants[0]]
            tmpCustomeArrows.push(arrow2)
          })
        }
        else if (tacticName == "skewer") {
          let arrow1 = [pieceCurrentPosition, pieceNextPosition, colorVariants[1]]
          tmpCustomeArrows.push(arrow1)

          arrayOfCause.forEach((tuple: any) => {
            let opponentPosition1 = tuple[0][2]
            let opponentPosition2 = tuple[1][2]
            let arrow2 = [pieceNextPosition, opponentPosition1, colorVariants[0]]
            let arrow3 = [opponentPosition1, opponentPosition2, colorVariants[2]]
            tmpCustomeArrows.push(arrow2)
            tmpCustomeArrows.push(arrow3)
          })
        }
        else if (tacticName == "interference") {
          let arrow1 = [pieceCurrentPosition, pieceNextPosition, colorVariants[1]]
          tmpCustomeArrows.push(arrow1)

          arrayOfCause.forEach((tuple: any) => {
            let opponentPosition1 = tuple[2]
            let opponentPosition2 = tuple[5]
            let arrow2 = [opponentPosition1, opponentPosition2, colorVariants[2]]
            tmpCustomeArrows.push(arrow2)
          })
        }
        else if (tacticName == "mateIn2") {
          let arrow1 = [pieceCurrentPosition, pieceNextPosition, colorVariants[1]]

          arrayOfCause.forEach((tuple: any) => {
            let opponentCurrentPosition = tuple[0][1]
            let opponentNextPosition = tuple[0][2]
            tmpCustomeArrows.push(arrow1)

            let allyCurrentPosition = tuple[1][1]
            let allyNexttPosition = tuple[1][2]

            let arrow2 = [opponentCurrentPosition, opponentNextPosition, colorVariants[3]]
            let arrow3 = [allyCurrentPosition, allyNexttPosition, colorVariants[0]]
            tmpCustomeArrows.push(arrow2)
            tmpCustomeArrows.push(arrow3)
          })
        }
        else if (tacticName == "pin") {
          let arrow1 = [pieceCurrentPosition, pieceNextPosition, colorVariants[1]]
          tmpCustomeArrows.push(arrow1)

          arrayOfCause.forEach((tuple: any) => {
            let opponentPosition1 = tuple[0][2]
            let opponentPosition2 = tuple[1][2]
            let arrow2 = [pieceNextPosition, opponentPosition1, colorVariants[0]]
            let arrow3 = [opponentPosition1, opponentPosition2, colorVariants[2]]
            tmpCustomeArrows.push(arrow2)
            tmpCustomeArrows.push(arrow3)
          })
        }
      });
      
      setCustomArrows(tmpCustomeArrows);
    }, [fen, cause]);

    function onSquareClicked(square: string): void {
      if (editBoard) {
        let [x, y] = getPosition(square);
        let newBoard = [...board];
  
        if (newBoard[y][x] === clickedPiece.toLowerCase() || clickedPiece === " ") {
          newBoard[y][x] = " ";
        }
        else {
          newBoard[y][x] = clickedPiece.toLowerCase();
        }
 
        let newFen = mapBoardToFen(newBoard);
        setBoard(newBoard);
        setFen(newFen);
      }
    }

    function onPieceDrop(
      sourceSquare: string,
      targetSquare: string,
      piece: string
    ): boolean {
      void onDrop(sourceSquare, targetSquare, piece);
      return false;
    }
    
    async function onDrop(sourceSquare: string, targetSquare: string, piece: string): Promise<boolean> {
      try {
        displayLoading(true);

        let pieceName = '';
        let color = piece[0] === 'w' ? 'white' : 'black';
        let [x1, y1] = getPosition(sourceSquare);
        let [x2, y2] = getPosition(targetSquare);
        let promotion: boolean = (Number(targetSquare[1]) === 1 || Number(targetSquare[1]) === 8) && board[y1][x1][1] === 'p';

        switch (piece[1]) {
          case 'P': pieceName = 'pawn'; break;
          case 'K': pieceName = 'king'; break;
          case 'Q': pieceName = 'queen'; break;
          case 'N': pieceName = 'knight'; break;
          case 'B': pieceName = 'bishop'; break;
          case 'R': pieceName = 'rook'; break;
        }

        const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/make_move`, {
          fen_string: fen,
          piece: promotion ? "pawn" : pieceName,
          color: color,
          from_position: sourceSquare,
          to_position: targetSquare,
          promotion: promotion
        })
        
        let newBoard = response.data.new_board;
        const status = response.data.move_status;

        // Check if newBoard is defined and is an 8x8 array
        if (status && newBoard && Array.isArray(newBoard) && newBoard.length === 8 && newBoard[0].length === 8) {
            let newFen = mapBoardToFen(newBoard);

            if (promotion) {
              newBoard[y2][x2] = piece.toLowerCase();
              newFen = mapBoardToFen(newBoard);

              const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
                fen_string: newFen
              });
              
              newBoard = response.data.board;
              
              if (newBoard && Array.isArray(newBoard) && newBoard.length === 8 && newBoard[0].length === 8) {
                const newFen = mapBoardToFen(newBoard);
                setFen(newFen);
                setBoard(newBoard);
                return true;
              }
              else {
                return false;
              }
            }
            else {
              setFen(newFen);
              setBoard(newBoard);
              return true;
            }
          } else {
            return false;
          }
      }
      catch (e) {
        setAlert("Please make valid move");
        setOpenAlert(true);
        return false;
      }
      finally {
        displayLoading(false);
      }
    }

    const threeDPieces = useMemo(() => {
      const pieces = [
        { piece: "wP", pieceHeight: 1 },
        { piece: "wN", pieceHeight: 1.2 },
        { piece: "wB", pieceHeight: 1.2 },
        { piece: "wR", pieceHeight: 1.2 },
        { piece: "wQ", pieceHeight: 1.5 },
        { piece: "wK", pieceHeight: 1.6 },
        { piece: "bP", pieceHeight: 1 },
        { piece: "bN", pieceHeight: 1.2 },
        { piece: "bB", pieceHeight: 1.2 },
        { piece: "bR", pieceHeight: 1.2 },
        { piece: "bQ", pieceHeight: 1.5 },
        { piece: "bK", pieceHeight: 1.6 },
      ];
  
      const pieceComponents: any = {};
      pieces.forEach(({ piece, pieceHeight }: PieceComp) => {
        pieceComponents[piece] = ({ squareWidth, square }: PieceParams) => (
          <div
            style={{
              width: squareWidth,
              height: squareWidth,
              position: "relative",
              pointerEvents: "none",
            }}
          >
            <img
              src={`/media/3d-pieces/${piece}.webp`}
              style={{
                width: squareWidth,
                height: pieceHeight * squareWidth,
                position: "absolute",
                bottom: `${0.2 * squareWidth}px`,
                objectFit: piece[1] === "K" ? "contain" : "cover",
              }}
            />
          </div>
        );
      });
      return pieceComponents;
    }, []);
  
    return (
      <div style={boardWrapper}>
        <Collapse in={openAlert}>
          <Alert severity="error" 
            action={
              <IconButton
                aria-label="close"
                color="inherit"
                size="small"
                onClick={() => {
                  setOpenAlert(false);
                }}
              >
                <CloseIcon fontSize="inherit" />
              </IconButton>
            }
            sx={{ mb: 2 }}
          >
            {alert}
          </Alert>
        </Collapse>
        <div style={{ width: '90%', maxWidth: 600, aspectRatio: '1', margin: '0 auto' }}>
          <Chessboard
            customArrows = {customArrows}
            position={fen}
            onPieceDrop={onPieceDrop}
            allowDragOutsideBoard={true}
            onSquareClick={onSquareClicked}
            customBoardStyle={{
            transform: "rotateX(27.5deg)",
            transformOrigin: "center",
            border: "0px solid #b8836f",
            borderStyle: "outset",
            borderRightColor: " #b27c67",
            borderRadius: "4px",
            boxShadow: "rgba(0, 0, 0, 0.5) 2px 24px 24px 8px",
            borderRightWidth: "2px",
            borderLeftWidth: "2px",
            borderTopWidth: "0px",
            borderBottomWidth: "18px",
            borderTopLeftRadius: "8px",
            borderTopRightRadius: "8px",
            padding: "2px 2px 2px 2px",  
            background: "#e0c094",
            backgroundSize: "cover",
            width: "500px",
            height: "515px"
            }}
            customPieces={threeDPieces}
            customLightSquareStyle={{
              backgroundColor: "#e0c094",
              backgroundSize: "cover",
            }}
            customDarkSquareStyle={{
              backgroundColor: "#865745",
              backgroundSize: "cover",
            }}
            animationDuration={500}
            customSquareStyles={{
              [activeSquare]: {
                boxShadow: "inset 0 0 1px 6px rgba(255,255,255,0.75)",
              },
            }}
            onMouseOverSquare={(sq) => setActiveSquare(sq)}
            onMouseOutSquare={(sq) => setActiveSquare("")}
          />
        </div>
      </div>
    );
} 

