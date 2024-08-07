import { useContext, useRef } from 'react';
import { motion, AnimatePresence } from "framer-motion";
import { fenContext, boardContext, mapBoardToFen } from '../ChatInterface/ChatInterface';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faPaperPlane, faTimes } from '@fortawesome/free-solid-svg-icons';
import axios from "axios";
import styles from './UploadFen.module.css';

const spring = {
    type: "sprint",
    stiffness: 700,
    damping: 30
}

const variants = {
    open: {
      y: 0,
      opacity: 1,
      transition: {
        y: { stiffness: 1000, velocity: -100 }
      }
    },
    closed: {
      y: 50,
      opacity: 0,
      transition: {
        y: { stiffness: 1000 }
      }
    }
  };

type IUploadFen = {
  closeWindowFunc: Function,
  displayLoading: Function
}

export const UploadFen = ({ closeWindowFunc, displayLoading }: IUploadFen) => {
    const ref = useRef<any>();
    const [fen, setFen] = useContext(fenContext);
    const [board, setBoard] = useContext(boardContext);

    // function that change the state of the chessboard
    async function uploadFen() {
      displayLoading(true);
      closeWindowFunc();

      try {
        const response = await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/set_fen`, {
          fen_string: ref.current.value
        });
  
        const newBoard = response.data.board;
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
      } catch (e) {
        console.error("Error: " + e);
      } finally {
        displayLoading(false);
      }
    }

    return (
      <div 
        className={styles['overlay']}
        onClick={() => closeWindowFunc()}
      >
        <motion.div
          className={styles['main-div']}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.5, ease: "easeOut" }}
          onClick={(e) => e.stopPropagation()}
        >
          <AnimatePresence>
            <div className={styles['header-div']}>
              <p className={styles['title']}> Insert Forsyth-Edwards Notation (FEN)</p>
              <div className={styles['cross-div']}>
                    <motion.button className={styles['cross-button']} onClick={() => closeWindowFunc()} whileHover={{ scale: 1.2, backgroundColor: "#f05053"} }><FontAwesomeIcon icon={faTimes} /></motion.button>
              </div>
            </div>
            <div className={styles['input-div']}>
                <input className={styles['fen-input']} ref={ref} placeholder="Enter forsyth-edwards notation"/>
                <motion.button 
                  className={styles['send-button']}
                  whileHover={{ scale: 1.1, backgroundColor: "#38ef7d", color: "black" }} 
                  whileTap={{ scale: 0.9 }}
                  variants={variants}
                  onClick={uploadFen}
                >
                  <FontAwesomeIcon icon={faPaperPlane} />
                </motion.button>
            </div>
          </AnimatePresence>
        </motion.div>
      </div>
    );
}
