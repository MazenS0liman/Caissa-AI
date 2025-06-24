import React, { useEffect } from 'react';
import { motion } from 'framer-motion';
import styles from './MicInterface.module.css';
import { useSpeechRecognition } from '@/hooks/useSpeechRecognition';

type IMicInterface = {
    setMicStatus: Function
}

export const MicInterface = ({ setMicStatus }: IMicInterface) => {
    const {
        text,
        startListening,
        stopListening,
        isListening,
        hasRecognitionSupport
    } = useSpeechRecognition();

    return (
    <motion.div className={styles['overlay-div']}>
        <motion.div className={styles['main-div']}>
            <motion.div className={styles['bot-div']}>
                <motion.img
                    className={styles['bot-img']}
                    src={"bot-icon.png"}
                >
                </motion.img>
            </motion.div>
            <motion.div className={styles['user-div']}>
                <motion.img
                    className={styles['user-img']}
                    src={"mic-dynamic-color.png"}
                    onClick={
                        () => startListening()
                    }
                    whileHover={{ scale: 1.3, y: 10 }} 
                    whileTap={{ scale: 0.9 }}
                >
                </motion.img>
            </motion.div>
        </motion.div>
    </motion.div>
    )
}

export default MicInterface;