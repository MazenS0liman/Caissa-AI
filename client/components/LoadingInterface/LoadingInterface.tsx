import React from 'react';
import { motion } from "framer-motion";
import Spline from '@splinetool/react-spline';
import styles from './LoadingInterface.module.css';

export const LoadingInterface = () => {
  return (
    <motion.div
        className={styles['overlay-div']}
    >
        <motion.div
            className={styles['main-div']}
        >
            <Spline scene="https://prod.spline.design/4AEpsFD61SIaxWKA/scene.splinecode" />
        </motion.div>
    </motion.div>
  )
}

