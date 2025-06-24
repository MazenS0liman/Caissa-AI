import * as THREE from 'three';
import { useEffect, useState, useContext } from "react";
import { fenContext, boardContext, getPieceName } from "../ChatInterface/ChatInterface";
import { useTexture } from "@react-three/drei";
import { ChessPiece } from "../ChessPiece/ChessPiece";

const DEG2RAD = Math.PI / 180;
const SQUARE_SIZE = 1;

type ISquare = {
  position: [x: number, y: number, z: number],
  size: [width: number, height: number, depth: number],
  color: string,
  scale: [width: number, height: number, depth: number],
  rotation: any
}

const Square = ({ position, size, color, scale, rotation }: ISquare) => {
    const texture = useTexture(color === "white" ? "texture/white.png" : "texture/black.png");
    const material = new THREE.MeshStandardMaterial({map: texture});
    material.transparent = true;
    material.opacity = 0.75;
  
    return (
      <group>
        <mesh position={position} material={material}>
          <boxGeometry args={size} />
        </mesh>
      </group>
    );
  };
  
type IChessBoard = {
  position: [x: number, y: number, z: number],
  scale: [width: number, height: number, depth: number],
  displayLoading: Function
}

export const ChessBoard = ({ position, scale, displayLoading }: IChessBoard) => {
  const [board, setBoard] = useContext(boardContext);
  const [fen, setFen] = useContext(fenContext);
  const [chessboard, setChessboard] = useState<any>([]);

  useEffect(() => {
    let newChessboard = [];

    for (let x = 0; x < 8; x++) {
      for (let y = 0; y < 8; y++) {
        let square = {
          x: x,
          y: y,
          color: (x + y) % 2 === 0 ? "white" : "black",
          piece: board[y][x] === undefined ? ' ' : board[y][x]
        };
    
        newChessboard.push(square);
      }
    }

    setChessboard(newChessboard);
  }, [fen, board]);
  
  return (
    <group position={position}>
      {chessboard.map((square: {x: number, y: number, color: string, higlight: boolean, piece: string}) => (
        <>
          <Square position={[square.x, square.y, 0]} color={square.color} size={[1, 1, 0.5]} scale={scale} rotation={[-45 * DEG2RAD, 0, 0]} />
          {square.piece !== ' ' && square.piece !== undefined && 
          <ChessPiece 
            position={[square.x, square.y, .82]} 
            piece={square.piece} 
            square_size={SQUARE_SIZE} 
            displayLoading={displayLoading}
          />}
        </>
      ))}
    </group>
  );
};
