import React from 'react'
import { motion, stagger } from 'framer-motion'
import styles from './Loading.module.css'

const loadingContainerVariants = {
    start: {
        transition: {
            staggerChildren: 0.2
        }
    },
    end: {
        transition: {
            staggerChildren: 0.2
        }
    }
};

const loadingCircleVariants = {
    start: {
        y: "30%"
    },
    end: {
        y: "10%"
    }
}

const loadingCircleTransition = {
    duration: .2,
    repeat: Infinity,
    ease: "easeOut",
    repeatDelay: .8
}


export const Loading = () => {
  return (
    <motion.div
        className={styles['loading-container']}
        variants={loadingContainerVariants}
        initial="start"
        animate="end"
        
    >
        <motion.span
            variants={loadingCircleVariants}
            transition={loadingCircleTransition}
        >♜</motion.span>
        <motion.span
            variants={loadingCircleVariants}
            transition={loadingCircleTransition}
        >♞</motion.span>
        <motion.span
            variants={loadingCircleVariants}
            transition={loadingCircleTransition}
        >♛</motion.span>
        <motion.span
            variants={loadingCircleVariants}
            transition={loadingCircleTransition}
        >♞</motion.span>
        <motion.span
            variants={loadingCircleVariants}
            transition={loadingCircleTransition}
        >♜</motion.span>
        
    </motion.div>
  );
}