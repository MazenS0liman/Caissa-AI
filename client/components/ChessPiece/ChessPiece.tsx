import { useRef, useState, useEffect, useContext } from "react";
import { useThree } from "@react-three/fiber";
import { useGLTF } from "@react-three/drei";
import { useDrag } from '@use-gesture/react';
import axios from "axios";
import * as THREE from 'three';
import { boardContext, fenContext, mapBoardToFen, getUCIPosition, getPosition } from '../ChatInterface/ChatInterface';

const DEG2RAD = Math.PI / 180;

// Set the chess piece to the nearest chessboard square
const getNearestSquare = (x: number, y: number, square_size: number): [number, number] => {
    const snappedX = Math.round(x / square_size) * square_size;
    const snappedY = Math.round(y / square_size) * square_size;
    return [snappedX, snappedY];
};

type IChessPiece = {
    piece: string,
    position: [number, number, number],
    square_size: number,
    displayLoading: Function
}

export const ChessPiece = ({ piece, position, square_size, displayLoading }: IChessPiece) => {
    const ref = useRef<any>();
    const { camera, mouse } = useThree();
    const [pieceName, setPieceName] = useState<string>('');
    const [color, setColor] = useState<string>('');
    const [currentPosition, setCurrentPosition] = useState<[number, number, number]>(position);
    const [oldPosition, setOldPosition] = useState<[number, number, number]>(position);
    const [opacity, setOpacity] = useState<number>(1);
    const [scale, setScale] = useState<[number, number, number]>([1, 1, 1]);
    const [board, setBoard] = useContext<[string[][], React.Dispatch<React.SetStateAction<string[][]>>]>(boardContext);
    const [fen, setFen] = useContext<[string, React.Dispatch<React.SetStateAction<string>>]>(fenContext);
    const [promote, setPromote] = useState<boolean>(false);
    const [pieceNextPosition, setPieceNextPosition] = useState<number[]>([0, 0]);
 
    // Load GLTF models
    const blackRook = useGLTF('pieces/Black-Rook.glb');
    const blackKnight = useGLTF('pieces/Black-Knight.glb');
    const blackBishop = useGLTF('pieces/Black-Bishop.glb');
    const blackQueen = useGLTF('pieces/Black-Queen.glb');
    const blackKing = useGLTF('pieces/Black-King.glb');
    const blackPawn = useGLTF('pieces/Black-Pawn.glb');
    const whiteRook = useGLTF('pieces/White-Rook.glb');
    const whiteKnight = useGLTF('pieces/White-Knight.glb');
    const whiteBishop = useGLTF('pieces/White-Bishop.glb');
    const whiteQueen = useGLTF('pieces/White-Queen.glb');
    const whiteKing = useGLTF('pieces/White-King.glb');
    const whitePawn = useGLTF('pieces/White-Pawn.glb');

    type IPromotionInterface = {
        position: [number, number, number]
    }
    
    const PromotionInterface = ({ position }: IPromotionInterface) => {
        const goldQueen = useGLTF('pieces/Gold-Queen.glb');
        const queenModelScale: [number, number, number] = [0.05, 0.05, 0.05];
        const queenPosition: [number, number, number] = [position[0] + 0.5, position[1] + 0.5, position[2] + 1];
    
        const goldRook = useGLTF('pieces/Gold-Rook.glb');
        const rookModelScale: [number, number, number]  = [0.017, 0.017, 0.017];
        const rookPosition: [number, number, number] = [position[0] - 0.5, position[1] + 0.5, position[2] + 1];
        
        const goldKnight = useGLTF('pieces/Gold-Knight.glb');
        const knightModelScale: [number, number, number]  = [0.025, 0.025, 0.025];
        const knightPosition: [number, number, number] = [position[0] + 0.5, position[1] - 0.5, position[2] + 1];
        
        const goldBishop = useGLTF('pieces/Gold-Bishop.glb');
        const bishopModelScale: [number, number, number]  = [0.025, 0.025, 0.025];
        const bishopPosition: [number, number, number] = [position[0] - 0.5, position[1] - 0.5, position[2] + 1];

        function handleClick(pieceName: string) {
            let [x, y] = pieceNextPosition;
            setPromote(false);
            makeMove(pieceName, color, getUCIPosition(oldPosition), getUCIPosition([x, y, currentPosition[2]]), pieceName).then((response) => {
                if (response) {
                    setCurrentPosition([x, y, currentPosition[2]]);
                    setOldPosition([x, y, currentPosition[2]]);
                    setOpacity(1);
                }
                else {
                    setCurrentPosition(oldPosition);
                }
            });
        }
    
        return (
            <group dispose={null}>
                <mesh
                    castShadow
                    receiveShadow
                    position={queenPosition}
                    scale={queenModelScale}
                    rotation={[90 * DEG2RAD, 0, 0]}
                    //@ts-ignore
                    geometry={goldQueen.nodes.Mesh_0.geometry}
                    material={goldQueen.materials['Metal 034']}
                    onClick={() => handleClick("Q")}
                />
                <mesh
                    castShadow
                    receiveShadow
                    position={knightPosition}
                    rotation={[90 * DEG2RAD, 90 * DEG2RAD, 0]}
                    scale={knightModelScale}
                    //@ts-ignore
                    geometry={goldKnight.nodes.Mesh_0.geometry}
                    material={goldKnight.materials['Metal 034']}
                    onClick={() => handleClick("N")}
                />
                <mesh
                    castShadow
                    receiveShadow
                    position={rookPosition}
                    scale={rookModelScale}
                    rotation={[90 * DEG2RAD, 0, 0]}
                    //@ts-ignore
                    geometry={goldRook.nodes.Mesh_0.geometry}
                    material={goldRook.materials['Metal 034']}
                    onClick={() => handleClick("R")}
                />
                <mesh
                    castShadow
                    receiveShadow
                    position={bishopPosition}
                    scale={bishopModelScale}
                    rotation={[90 * DEG2RAD, 0, 0]}
                    //@ts-ignore
                    geometry={goldBishop.nodes.Mesh_0.geometry}
                    material={goldBishop.materials['Metal 034']}
                    onClick={() => handleClick("B")}
                />
            </group>
        );
    }

    useEffect(() => {
        const updatedPosition: [number, number, number] = [...currentPosition];
        let model, modelScale: [number, number, number];
        updatedPosition[2] = .82;
        
        switch (piece) {
            case 'br':
                updatedPosition[2] -= 0.05;
                model = blackRook;
                modelScale = [0.017, 0.017, 0.017];
                setPieceName("rook");
                setColor("black");
                break;
            case 'bn':
                updatedPosition[2] += 0.2;
                model = blackKnight;
                modelScale = [0.025, 0.025, 0.025];
                setPieceName("knight");
                setColor("black");
                break;
            case 'bb':
                updatedPosition[2] += 0.2;
                model = blackBishop;
                modelScale = [0.025, 0.025, 0.025];
                setPieceName("bishop");
                setColor("black");
                break;
            case 'bq':
                updatedPosition[2] += 0.51;
                model = blackQueen;
                modelScale = [0.05, 0.05, 0.05];
                setPieceName("queen");
                setColor("black");
                break;
            case 'bk':
                updatedPosition[2] += 0.55;
                model = blackKing;
                modelScale = [0.04, 0.04, 0.04];
                setPieceName("king");
                setColor("black");
                break;
            case 'bp':
                model = blackPawn;
                modelScale = [0.02, 0.02, 0.02];
                setPieceName("pawn");
                setColor("black");
                break;
            case 'wr':
                updatedPosition[2] -= 0.05;
                model = whiteRook;
                modelScale = [0.017, 0.017, 0.017];
                setPieceName("rook");
                setColor("white");
                break;
            case 'wn':
                updatedPosition[2] += 0.2;
                model = whiteKnight;
                modelScale = [0.025, 0.025, 0.025];
                setPieceName("knight");
                setColor("white");
                break;
            case 'wb':
                updatedPosition[2] += 0.2;
                model = whiteBishop;
                modelScale = [0.025, 0.025, 0.025];
                setPieceName("bishop");
                setColor("white");
                break;
            case 'wq':
                updatedPosition[2] += 0.51;
                model = whiteQueen;
                modelScale = [0.05, 0.05, 0.05];
                setPieceName("queen");
                setColor("white");
                break;
            case 'wk':
                updatedPosition[2] += 0.65;
                model = whiteKing;
                modelScale = [0.04, 0.04, 0.04];
                setPieceName("king");
                setColor("white");
                break;
            case 'wp':
                model = whitePawn;
                modelScale = [0.02, 0.02, 0.02];
                setPieceName("pawn");
                setColor("white");
                break;
            default:
                modelScale = [0, 0, 0];
        }

        if (model) {
            const { nodes, materials } = model;

            setScale(modelScale);
            setCurrentPosition(updatedPosition);
            setOldPosition(updatedPosition);

            if (ref.current) {
                //@ts-ignore
                ref.current.geometry = nodes.ASSET_Joined.geometry.clone();
                ref.current.material = materials.ASSET_Baked.clone();
            }
        }
    }, []);

    // a function that allow a chess piece to move from one square to another
    async function makeMove(piece: string, color: string, from_position: string, to_position: string, promotedPiece: string) {
        try {
            let [x1, y1] = getPosition(from_position);
            let [x2, y2] = getPosition(to_position);
            let promotion = (Number(y2) === 0 || Number(y2) === 7) && board[y1][x1][1] === 'p';
            
            if (promotion && promotedPiece == "") {
                setPieceNextPosition([x2, y2]);
                setPromote(true);
                return;
            }
            
            displayLoading(true);
            const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/make_move`, {
                fen_string: fen,
                piece: piece,
                color: color,
                from_position: from_position,
                to_position: to_position,
                promotion: promotion
            });

            let newBoard = response.data.new_board;
            const status = response.data.move_status;
            
            // Check if newBoard is defined and is an 8x8 array
            if (status && newBoard && Array.isArray(newBoard) && newBoard.length === 8 && newBoard[0].length === 8) {
                let newFen = mapBoardToFen(newBoard   );

                if (promotion) {
                    promotedPiece = (color == "white" ? "w" : "b") + promotedPiece.toLowerCase();
                    newBoard[y2][x2] = promotedPiece;
                    newFen = mapBoardToFen(newBoard);
      
                    const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
                      fen_string: newFen
                    });
              
                    newBoard = response.data.board;
                    displayLoading(false);
                    
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
                    return true;
                }
            } else {
                return false;
            }
        } catch (error) {
            console.error("Error making move:", error);
            return false;
        } finally {
            displayLoading(false);
        }
    }
  
    const bind: any = useDrag(({ offset: [x, y], down }) => {
        const vec = new THREE.Vector3();
        const pos = new THREE.Vector3();
        vec.set(mouse.x, mouse.y, 0.5);
        vec.unproject(camera);
        vec.sub(camera.position).normalize();
        const distance = -camera.position.z / vec.z;
        pos.copy(camera.position).add(vec.multiplyScalar(distance));

        if (down) {
            setCurrentPosition([pos.x + 3.5, pos.y + 2.2, currentPosition[2]]);
            setOpacity(0.5);
        } else {
            const [snappedX, snappedY] = getNearestSquare(pos.x + 3.5, pos.y + 2.2, square_size);
            if (!(snappedX < 0 || snappedX > 7 || snappedY < 0 || snappedY > 7)) {
                makeMove(pieceName, color, getUCIPosition(oldPosition), getUCIPosition([snappedX, snappedY]), "").then((response) => {
                    if (response) {
                        setCurrentPosition([snappedX, snappedY, currentPosition[2]]);
                        setOldPosition([snappedX, snappedY, currentPosition[2]]);
                        setOpacity(1);
                    }
                    else {
                        setCurrentPosition(oldPosition);
                    }
                });
            }
        }
    });
  
    return (
        <>
            <group dispose={null} {...bind()}>
                <mesh
                    castShadow
                    receiveShadow
                    position={currentPosition}
                    rotation={[90 * DEG2RAD, piece === 'bn' ? 180 * DEG2RAD : 0, 0]}
                    scale={scale}
                    ref={ref}
                />
                <meshStandardMaterial color={"blue"} />
            </group>
            {promote && <PromotionInterface position={currentPosition}/>}
        </>
    );
};
