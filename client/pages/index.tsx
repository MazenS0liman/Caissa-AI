import React from 'react';
import { ChatInterface } from '../components/ChatInterface/ChatInterface';
import { MainInterface } from '../components/MainInterface/MainInterface';
import styles from './index.module.css';

function index() {
  return (
    <div className={styles['main-div']}>
        <MainInterface />
        <ChatInterface />
    </div>
  )
}

export default index