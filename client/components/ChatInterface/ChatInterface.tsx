import React, { useState, createContext, useEffect } from "react";
import { motion } from "framer-motion";
import styles from "../ChatInterface/ChatInterface.module.css";
import axios from "axios";
import { ThreeDChess } from "../ThreeDChess/ThreeDChessboard";
import { ChatBot } from "../ChatBot/ChatBot";
import { UploadFen } from "../UploadFen/UploadFen";
import { ChessScene } from "../ChessScene/ChessScene";
import { ControlBar } from "../ControlBar/ControlBar";
import { LoadingInterface } from "../LoadingInterface/LoadingInterface";
import { PiecesTab } from "../PiecesTab/PiecesTab";

const chatVariants = {
    hidden: { opacity: 0, y: -100 },
    visible: { opacity: 1, y: 0},
    exit: {opacity: 0, y: 100}
}

export const fenContext = createContext<[string, React.Dispatch<React.SetStateAction<string>>]>(["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR", () => null]);
export const boardContext = createContext<[string[][], React.Dispatch<React.SetStateAction<string[][]>>]>([[], () => null]);
export const chessContext = createContext<[string, React.Dispatch<React.SetStateAction<string>>, string, React.Dispatch<React.SetStateAction<string>>, string, React.Dispatch<React.SetStateAction<string>>, string, React.Dispatch<React.SetStateAction<string>>, string, React.Dispatch<React.SetStateAction<string>>]>(["", () => null, "", () => null, "", () => null, "", () => null, "", () => null]);

// Convert Cartesian position to a UCI position.
export const getUCIPosition = (position: number[]) => {
  let uci_position: string = '';
  
  switch(Number(position[0])) {
      case 0: uci_position += 'a'; break;
      case 1: uci_position += 'b'; break;
      case 2: uci_position += 'c'; break;
      case 3: uci_position += 'd'; break;
      case 4: uci_position += 'e'; break;
      case 5: uci_position += 'f'; break;
      case 6: uci_position += 'g'; break;
      case 7: uci_position += 'h'; break;
  }

  switch(Number(position[1])) {
      case 0: uci_position += '1'; break;
      case 1: uci_position += '2'; break;
      case 2: uci_position += '3'; break;
      case 3: uci_position += '4'; break;
      case 4: uci_position += '5'; break;
      case 5: uci_position += '6'; break;
      case 6: uci_position += '7'; break;
      case 7: uci_position += '8'; break;
  }

  return uci_position;
}

export const getPosition = (position: string): number[] => {
  let x: number = 0;
  let y: number = 0;
  
  switch(position[0]) {
    case 'a': x = 0; break;
    case 'b': x = 1; break;
    case 'c': x = 2; break;
    case 'd': x = 3; break;
    case 'e': x = 4; break;
    case 'f': x = 5; break;
    case 'g': x = 6; break;
    case 'h': x = 7; break;
  }

  switch(position[1]) {
    case '1': y = 0; break;
    case '2': y = 1; break;
    case '3': y = 2; break;
    case '4': y = 3; break;
    case '5': y = 4; break;
    case '6': y = 5; break;
    case '7': y = 6; break;
    case '8': y = 7; break;
  }

  return [x, y];
}

// function that convert fen string to a 2D array
export function mapFenToBoard(fen_string:string): string[][] {
    let x = 0;
    let newBoard = [];
    let column = [];
    
    for (let i = 0; i < fen_string.length; i++) {
      if (fen_string[i] === '/') {
        newBoard.push(column);
        x++;
        column = [];
      }
      else if (fen_string[i] === ' ') {
        newBoard.push(column);
        break;
      }
      else {
        switch(fen_string[i]) {
          case 'r': column.push('br'); break;
          case 'n': column.push('bn'); break;
          case 'b': column.push('bb'); break;
          case 'k': column.push('bk'); break;
          case 'p': column.push('bp'); break;
          case 'q': column.push('bq'); break;
  
          case 'R': column.push('wr'); break;
          case 'N': column.push('wn'); break;
          case 'B': column.push('wb'); break;
          case 'K': column.push('wk'); break;
          case 'P': column.push('wp'); break;
          case 'Q': column.push('wq'); break;
          
          default: 
            let numberOfSpaces = parseInt(fen_string[i]);

            if (Number.isNaN(numberOfSpaces)) {
              break;
            }
            else {
              for (let j = 0; j < numberOfSpaces; j++) {
                column.push(' ');
              }
            }
        }
      }
    }

    newBoard.reverse();

    return newBoard;
  }

export function mapBoardToFen(board: string[][]): string {
    let fen_string = "";
  
    for (let y = board.length - 1; y >= 0; y--) {
      let count = 0;
      let flag = false;
      for (let x = 0; x < board[y].length; x++) {
        if (flag && board[y][x] !== ' ') {
          fen_string += count;
          count = 0;
          flag = false;
        }

        switch(board[y][x]) {
          case 'br': fen_string += 'r'; break;
          case 'bn': fen_string += 'n'; break;
          case 'bb': fen_string += 'b'; break;
          case 'bk': fen_string += 'k'; break;
          case 'bp': fen_string += 'p'; break;
          case 'bq': fen_string += 'q'; break;
  
          case 'wr': fen_string += 'R'; break;
          case 'wn': fen_string += 'N'; break;
          case 'wb': fen_string += 'B'; break;
          case 'wk': fen_string += 'K'; break;
          case 'wp': fen_string += 'P'; break;
          case 'wq': fen_string += 'Q'; break;

          case ' ': 
            count++; 
            flag = true; 

            if (x === board[y].length - 1) {
              fen_string += count;
              count = 0;
              flag = false;
            }

            break;
        }
      }

      if (y !== 0) fen_string += "/";
    }
  
    let turn = 'b';
    let castling = 'KQkq';
    let enpassant = '-';
    let half_move = '0';
    let full_move = '1';
  
    fen_string += ' ' + turn + ' ' + castling + ' ' + enpassant + ' ' + half_move + ' ' + full_move;
    return fen_string;
  }

export const getPieceName = (piece: string) => {
    let pieceName: string = '';
      
    switch(piece[1]) {
        case 'r':
            pieceName = 'rook';
            break;
        case 'n':
            pieceName = 'knight';
            break;
        case 'b':
            pieceName = 'bishop';
            break;
        case 'q':
            pieceName = 'queen';
            break;
        case 'k':
            pieceName = 'king';
            break;
        case 'p':
            pieceName = 'pawn';
            break;
    }

    return pieceName;
}

export const ChatInterface = () => {
    const [fen, setFen] = useState<string>("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR");
    const [turn, setTurn] = useState<string>("w");
    const [castleRight, setCastleRight] = useState<string>("KQkq");
    const [enpassantMove, setEnpassantMove] = useState<string>("-");
    const [halfMove, setHalfMove] = useState<string>("0");
    const [fullMove, setFullMove] = useState<string>("1");
    const [board, setBoard] = useState([
      //|  1  |  2  |  3  |  4  |  5  |  6  |  7 |   8  |
        [ 'wr', 'wn', 'wb', 'wq', 'wk', 'wb', 'wn', 'wr'], // 1
        [ 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp'], // 2
        [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 3
        [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 4
        [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 5
        [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 6
        [ 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp'], // 7
        [ 'br', 'bn', 'bb', 'bq', 'bk', 'bb', 'bn', 'br'], // 8
      ]);
    const [cause, setCause] = useState<any[]>([]);
    const [openChat, setOpenChat] = useState<boolean>(false);
    const [openUploadFen, setOpenUploadFen] = useState<boolean>(false);
    const [threeD, setThreeD] = useState<boolean>(false);
    const [showLoadingScreen, setShowLoadingScreen] = useState<boolean>(true);
    const [whitePieces, setWhitePieces] = useState<any[]>(
      [
        { piece: "wP", pieceHeight: 1 },
        { piece: "wN", pieceHeight: 1.2 },
        { piece: "wB", pieceHeight: 1.2 },
        { piece: "wR", pieceHeight: 1.2 },
        { piece: "wQ", pieceHeight: 1.7 },
        { piece: "wK", pieceHeight: 1.6 },
      ]
    );
    const [blackPieces, setBlackPieces] = useState<any[]>(
      [
        { piece: "bP", pieceHeight: 1 },
        { piece: "bN", pieceHeight: 1.2 },
        { piece: "bB", pieceHeight: 1.2 },
        { piece: "bR", pieceHeight: 1.2 },
        { piece: "bQ", pieceHeight: 1.7 },
        { piece: "bK", pieceHeight: 1.6 },
      ]
    );
    const [clickedPiece, setClickedPiece] = useState<string>(" ");
    const [editBoard , setEditBoard] = useState<boolean>(false);
    const [previousFen, setPreviousFen] = useState<string>("");
    const [talkToGemini, setTalkToGemini] = useState<boolean>(false);
    const [talkToReinforcedGemini, setTalkToReinforcedGemini] = useState<boolean>(false);
    const [speechPrompt, setSpeechPrompt] = useState<string>("");

    useEffect(() => {
      const setServerBoard = async () => {
        try {
          await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
            fen_string: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
          });
        } catch (e) {
          console.error(e);
        } finally {
          setShowLoadingScreen(false);
        }
      };
  
      setServerBoard();
    }, []);

    const updateCause = (cause: any) => {
      setCause(cause);
    }

    const switchBoard = () => {
      setThreeD(!threeD);
    }

    const closeChat = () => {
      setOpenChat(false);
    }

    return (
        <fenContext.Provider value={[fen, setFen]}>
            <boardContext.Provider value={[board, setBoard]}>
                <chessContext.Provider value={[ turn, setTurn, castleRight, setCastleRight, enpassantMove, setEnpassantMove, halfMove, setHalfMove, fullMove, setFullMove]}>
                    <motion.div className={styles['main-div']}>
                      <motion.div className={styles['sub1-div']}>
                        {editBoard && <PiecesTab pieces={whitePieces} squareWidth={50} setClickedPiece={setClickedPiece}/>}
                        <motion.div className={styles['board-div']}>
                          <motion.div 
                              className={styles['chess-div']}
                              transition={{ ease: "easeInOut", duration: 2 }}
                              animate="visible"
                              exit="exit"
                              variants={chatVariants} 
                          >
                              {!threeD && <ThreeDChess cause={cause} displayLoading={setShowLoadingScreen} editBoard={editBoard} clickedPiece={clickedPiece}/>}
                              {threeD && < ChessScene displayLoading={setShowLoadingScreen}/>}
                          </motion.div>
                        </motion.div>
                        {editBoard && <PiecesTab pieces={blackPieces} squareWidth={50} setClickedPiece={setClickedPiece}/>}
                        {openChat &&
                          <motion.div 
                              className={styles['chat-div']} 
                              layout 
                              transition={{ ease: "easeInOut", duration: 2}}
                              initial="hidden"
                              animate="visible"
                              exit="exit"
                              variants={chatVariants}
                              drag
                              dragConstraints={{
                                top: -50,
                                left: -50,
                                right: 50,
                                bottom: 50,
                              }}
                          >
                              <ChatBot 
                                fen={fen} 
                                updateBoard={setFen} 
                                updateCause={updateCause} 
                                closeChat={closeChat} 
                                talkToGemini={talkToGemini} 
                                setTalkToGemini={setTalkToGemini} 
                                talkToReinforcedGemini={talkToReinforcedGemini} 
                                setTalkToReinforcedGemini={setTalkToReinforcedGemini}
                                speechPrompt={speechPrompt}
                              />
                          </motion.div>
                        }
                        </motion.div>
                        {openUploadFen &&
                          <motion.div>
                              <UploadFen closeWindowFunc={() => setOpenUploadFen(false)} displayLoading={setShowLoadingScreen}/>
                          </motion.div>
                        }
                        <motion.div 
                          className={styles['sub2-div']}
                          drag
                          dragConstraints={{
                            top: -1000,
                            left: -1000,
                            right: 1000,
                            bottom: 1000,
                          }}
                        >
                          <ControlBar 
                            openChatFunc={setOpenChat}
                            openUploadFenFunc={setOpenUploadFen}
                            switchBoard={() => switchBoard()} 
                            displayLoading={setShowLoadingScreen} 
                            editBoard={editBoard} 
                            setEditBoard={setEditBoard} 
                            previousFen={previousFen} 
                            setTalkToGemini={setTalkToGemini}
                            setTalkToReinforcedGemini={setTalkToReinforcedGemini}
                            setSpeechPrompt={setSpeechPrompt}
                          />
                        </motion.div>
                    </motion.div>
                    {showLoadingScreen &&
                      <motion.div>
                        <LoadingInterface />
                      </motion.div>
                    }
                </chessContext.Provider>
            </boardContext.Provider>
        </fenContext.Provider>
    );
}
