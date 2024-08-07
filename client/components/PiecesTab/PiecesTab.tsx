import React, { useState } from 'react';
import { motion } from "framer-motion";
import { getPieceName } from '../ChatInterface/ChatInterface';
import styles from './PiecesTab.module.css';

type IPiecesTab = {
    pieces: {piece: string, pieceHeight: number}[],
    squareWidth: number, 
    setClickedPiece: Function
}

export const PiecesTab = ({ pieces, squareWidth, setClickedPiece }: IPiecesTab) => {

    return (
        <motion.div className={styles['main-div']}>
            <motion.div 
                className={styles['sub-div']}
            >
                {
                    pieces.map(({ piece, pieceHeight }, key) => {
                        return(
                            <motion.div
                                style={{
                                    width: squareWidth + "px",
                                    height: squareWidth + "px",
                                    position: "relative",
                                }}
                                key={key}
                            >
                                <motion.img
                                    src={`/media/3d-pieces/${piece}.webp`}
                                    style={{
                                        width: squareWidth,
                                        height: pieceHeight * squareWidth,
                                        position: "absolute",
                                        bottom: `${5 * squareWidth}px`,
                                        objectFit: piece[1] === "K" ? "contain" : "cover", 
                                    }}
                                    onClick={() => setClickedPiece(piece.toLowerCase())}
                                />
                            </motion.div>
                        );
                    })
                }
            </motion.div>
        </motion.div>
    )
}
