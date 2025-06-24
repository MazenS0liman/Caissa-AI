import React from 'react'

import styles from './Message.module.css'

interface MessageProps {
    role: string;
    text: string;
}

export const Message = ({ role, text }: MessageProps) => {
    if (role == "assistant") {
        return (
            <>
                <img className={styles["logo-assistant"]} alt="" src="/bot-icon.png"/>
                <div className={styles[`message-assistant`]}>
                    <p style={{wordWrap: "break-word", overflow: "hidden"}}>{text}</p>
                </div>
            </>
          )
    }
    else {
        return (
            <>
                <img className={styles["logo-user"]} alt="" src="/boy-dynamic-color.png"/>
                <div className={styles[`message-user`]}>
                    <p style={{wordWrap: "break-word", overflow: "hidden"}}>{text}</p>
                 </div>
            </>
          )
    }
}
