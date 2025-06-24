import React, { useState, useContext, useEffect } from "react";
import { motion } from "framer-motion";
import { fenContext, boardContext, mapFenToBoard, mapBoardToFen } from "../ChatInterface/ChatInterface";
import { useSpeechRecognition } from '@/hooks/useSpeechRecognition';
import axios from 'axios';
import styles from './ControlBar.module.css';

type IControlBar = {
    openChatFunc: Function,
    openUploadFenFunc: Function,
    switchBoard: Function,
    displayLoading: Function,
    editBoard: boolean,
    setEditBoard: Function,
    previousFen: string,
    setTalkToGemini: Function,
    setTalkToReinforcedGemini: Function,
    setSpeechPrompt: Function
}

export const ControlBar = ({ openChatFunc, openUploadFenFunc, switchBoard, displayLoading, editBoard, setEditBoard, previousFen, setTalkToGemini, setTalkToReinforcedGemini, setSpeechPrompt }: IControlBar) => {
    const [openChat, setOpenChat] = useState(false);
    const [openUploadFen, setUploadFen] = useState(false);
    const [fen, setFen] = useContext(fenContext);
    const [board, setBoard] = useContext(boardContext);
    const {
        text,
        startListening,
        stopListening,
        isListening,
        hasRecognitionSupport
    } = useSpeechRecognition();
    const [micStatus, setMicStatus] = useState(false);

    useEffect(() => {
        setSpeechPrompt(text);
    }, [text]);

    const resetBoard = async () => {
        displayLoading(true);
        await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
            fen_string: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        }).then(() => {
            displayLoading(false);
            setFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
            setBoard([
                //|  1  |  2  |  3  |  4  |  5  |  6  |  7 |   8  |
                  [ 'wr', 'wn', 'wb', 'wk', 'wq', 'wb', 'wn', 'wr'], // 1
                  [ 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp'], // 2
                  [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 3
                  [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 4
                  [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 5
                  [ ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' , ' ' ], // 6
                  [ 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp'], // 7
                  [ 'br', 'bn', 'bb', 'bk', 'bq', 'bb', 'bn', 'br'], // 8
                ]);
        });
    }

    async function acceptBoardEdits() {
        let newFen = mapBoardToFen(board);

        displayLoading(true);
        const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
          fen_string: newFen
        });

        const newBoard = response.data.board;
        displayLoading(false);
        
        if (newBoard && Array.isArray(newBoard) && newBoard.length === 8 && newBoard[0].length === 8) {
          const newFen = mapBoardToFen(newBoard);
          setFen(newFen);
          setBoard(newBoard);
          setEditBoard(false);
          return true;
        }
        else {
          return false;
        }
    }

    function rejectBoardEdits() {
        let newBoard = mapFenToBoard(previousFen);
        setBoard(newBoard);
        setFen(previousFen);
        setEditBoard(false);
    }

    return (
        <motion.div className={styles['main-div']}>
            {!editBoard &&
            <>
                {!micStatus &&
                    <>
                        <motion.div className={styles['message-div']}>
                            <motion.img 
                                src={'./message3d.png'}
                                className={styles['message-img']}
                                onClick={() => {
                                    openChatFunc(!openChat)
                                    setOpenChat(!openChat)
                                }}
                                whileHover={{ scale: 1.2, y: 10 }}
                                whileTap={{ scale: 0.9 }}
                            />
                        </motion.div>
                        <motion.div className={styles['reset-div']}>
                            <motion.img
                                src={'./switch3d.png'}
                                className={styles['message-img']}
                                onClick={() => {
                                    resetBoard()
                                }}
                                whileHover={{ scale: 1.2, y: 10 }} 
                                whileTap={{ scale: 0.9 }}
                            />
                        </motion.div>
                        <motion.div className={styles['edit-div']}>
                            <motion.img 
                                src={'./pencil-dynamic-color.png'}
                                className={styles['message-img']}
                                onClick={() => {
                                    openUploadFenFunc(!openUploadFen)
                                    setUploadFen(!openUploadFen)
                                }}
                                whileHover={{ scale: 1.2, y: 10 }} 
                                whileTap={{ scale: 0.9 }}
                            />
                        </motion.div>
                        <motion.div className={styles['switch-div']}>
                            <motion.img
                                src={'./chess-dynamic-color.png'}
                                className={styles['message-img']}
                                onClick={() => {
                                    switchBoard()
                                }}
                                whileHover={{ scale: 1.2, y: 10 }}
                                whileTap={{ scale: 0.9 }}
                            />
                        </motion.div>
                        {/* <motion.div className={styles['plus-div']}>
                                <motion.img
                                    src={'./plus-dynamic-premium.png'}
                                    className={styles['message-img']}
                                    onClick={() => {
                                        setEditBoard(true)
                                        setPreviousFen(fen)
                                    }}
                                    whileHover={{ scale: 1.2, y: 10 }} 
                                    whileTap={{ scale: 0.9 }}
                                />
                        </motion.div> */}
                    </>
                }
                {micStatus &&
                    <motion.div className={styles['cross-div']}>
                        <motion.img
                            className={styles['cross-img']}
                            src={"back-dynamic-premium.png"}
                            onClick={
                                () => {
                                    setMicStatus(false)
                                    stopListening()
                                }
                            }
                            whileHover={{ scale: 1.2, y: 10 }} 
                            whileTap={{ scale: 0.9 }}
                        >
                        </motion.img>
                    </motion.div>
                }
                <motion.div className={styles['mic-div']}>
                    <motion.img
                        src={'./mic-dynamic-color.png'}
                        className={styles['message-img']}
                        onClick={
                            () => {
                                setMicStatus(true);
                                openChatFunc(true);
                                setTalkToGemini(true);
                                setTalkToReinforcedGemini(true);
                                if (!isListening) {
                                    startListening();
                                }
                            }
                        }
                        whileHover={{ scale: 1.2, y: 10 }} 
                        whileTap={{ scale: 0.9 }}
                    />
                </motion.div>
            </>
            }
            {editBoard &&
                <>
                    <motion.div className={styles['plus-div']}>
                        <motion.img
                            src={'./thumb-down-dynamic-color.png'}
                            className={styles['message-img']}
                            onClick={rejectBoardEdits}
                            whileHover={{ scale: 1.3, y: 10 }} 
                            whileTap={{ scale: 0.9 }}
                        />
                    </motion.div>
                    <motion.div className={styles['plus-div']}>
                        <motion.img
                            src={'./thumb-up-dynamic-color.png'}
                            className={styles['message-img']}
                            onClick={acceptBoardEdits}
                            whileHover={{ scale: 1.3, y: 10 }} 
                            whileTap={{ scale: 0.9 }}
                        />
                    </motion.div>
                </>
            }
        </motion.div>
    );
}


