import React, { useState, useEffect, useRef } from 'react';
import { motion } from "framer-motion";
import axios from 'axios';
import styles from './ChatBot.module.css';
import { Message } from '../Message/Message';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faPaperPlane, faWindowClose, faTimes, faLightbulb, faBoltLightning } from '@fortawesome/free-solid-svg-icons';
import { Loading } from '../Loading/Loading';

type Message = {
    role: string,
    message: string
}

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

export const ChatBot = ({ fen , updateBoard, updateCause, closeChat, talkToGemini = false, setTalkToGemini, talkToReinforcedGemini = false, setTalkToReinforcedGemini, speechPrompt = "" }: any) => {
    const [messages, setMessages]: [Message[], any] = useState([]);
    const [prompt, setPrompt]: [any, any] = useState(speechPrompt);
    const [cause, setCause]: [any, any] = useState([]);
    const [previousFen, setPreviousFen] = useState("");
    const [currentFen, setCurrentFen]: [any, any] = useState(fen);
    const [isOn, setIsOn] = useState(talkToGemini);
    const [isLoading, setIsLoading] = useState(false);
    const [isReinforced, setIsReinforced] = useState(talkToReinforcedGemini);
    const listRef = useRef<any>(null);

    useEffect(() => {
        if (listRef.current && listRef.current.lastElementChild) {
            listRef.current.lastElementChild.scrollIntoView()
        }
    }, [messages]);

    useEffect(() => {
        if (speechPrompt !== "") {
            const storePrompt: string = speechPrompt;
            let fenString: string = fen;
    
            setIsLoading(true);
    
            let newMessage: Message = {
                role: "user",
                message: storePrompt
            }
    
            let newMessages = [...messages, newMessage];
            setMessages(newMessages);
            setPrompt("");
    
            axios.post(`${process.env.NEXT_PUBLIC_SERVER}/chatbot`, {
                prompt: storePrompt,
                fen: fenString
            }).then((response) => {
                
                let prevAnswer: Message = {
                    role: "assistant",
                    message: `Given FEN : ${fen}`
                }
    
                let newAnswer: Message = {
                    role: "assistant",
                    message: response.data.answer
                }
    
                let updatedMessages = [...newMessages, prevAnswer, newAnswer];
    
                setMessages(updatedMessages);
                setIsLoading(false);
            }).catch(error => console.log(error));
        }
    }, [speechPrompt]);

    const toggleSwitch = (event: any) => {
        setTalkToGemini(!isOn);
        setIsOn(!isOn);
    }

    const receiveResponse = async (event: any) => {
        event.preventDefault()

        if (isOn) { // Talk to Gemini
            if (isReinforced) {
                fetchChatResponseFromReinforcedBot(event)
            }
            else {
                fetchChatResponse(event)
            }
        }
        else { // Talk directly to NeuroSymbolic
            fetchTactic(event)
        }
    }

    const fetchChatResponseFromReinforcedBot = async (event: any) => {
        event.preventDefault()
        const storePrompt: string = prompt;
        let fenString: string = fen;

        setIsLoading(true);

        let newMessage: Message = {
            role: "user",
            message: prompt
        }

        let newMessages = [...messages, newMessage];
        setMessages(newMessages);
        setPrompt("");

        await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/reinforced_chatbot`, {
            prompt: storePrompt,
            fen: fenString
        }).then((response) => {

            let newAnswer: Message = {
                role: "assistant",
                message: response.data.answer
            }

            let updatedMessages = [...newMessages, newAnswer];

            setMessages(updatedMessages);
            setIsLoading(false);

        }).catch(error => console.log(error));
    }

    const fetchChatResponse = async (event: any) => {
        event.preventDefault()
        const storePrompt = prompt

        setIsLoading(true)

        let newMessage: Message = {
            role: "user",
            message: prompt
        }

        let newMessages = [...messages, newMessage]
        setMessages(newMessages)
        setPrompt("")

        await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/chatbot`, {
            prompt: storePrompt,
        }).then((response) => {

            let newAnswer: Message = {
                role: "assistant",
                message: response.data.answer
            }

            let updatedMessages = [...newMessages, newAnswer]

            setMessages(updatedMessages)
            setIsLoading(false)

        }).catch(error => console.log(error))
    }

    const fetchTactic = async (event: any) => {
        event.preventDefault();
        const regex = /([(1-8)*rnbqkpRNBQKP]{1,8}\/)*[(1-8)*rnbqkpRNBQKP]{1,8} [w | b] ((?<=\s)(.*?)(?=\s)) ((?<=\s)(.*?)(?=\s)) ((?<=\s)(.*?)(?=\s)) (.?)/;
        const match = prompt.match(regex);

        setIsLoading(true);

        let newMessage: Message = {
            role: "user",
            message: prompt
        };

        let newMessages = [...messages, newMessage];
        setMessages(newMessages);
        setPrompt("");

        if (match === null) {
            let newAnswer: Message = {
                role: "assistant",
                message: "Please add a valid FEN"
            }

            let updatedMessages = [...newMessages, newAnswer]
            setIsLoading(false)
            setMessages(updatedMessages)
            setPrompt("")
            return;
        }

        let fen_string = match[0]

        await axios.post(`${process.env.NEXT_PUBLIC_SERVER}/neurosym`, {
            fen: fen_string,
        }).then((response) =>{
            let statement: string = ""
            let cause: any[] = []

            if (response.data.answer == "Enter valid FEN") {
                statement = "Enter valid FEN"
            }
            else {
                statement = response.data.answer[0]
                cause = [response.data.answer[1], response.data.answer[2]]
            }
            
            let newAnswer: Message = {
                role: "assistant",
                message: statement
            }

            let updatedMessages = [...newMessages, newAnswer]
            setMessages(updatedMessages)

            setIsLoading(false)
            updateBoard(fen_string)
            updateCause(cause)
            setPreviousFen(currentFen)
            setCurrentFen(fen_string)
            setCause(cause)
        }).catch(error => console.log(error))
    }

    // useEffect(() => {}, [messages])

    return (
        <div className={styles['main-div']}>
            <div className={styles['chat-title-div']}>
                <div className={styles['chat-sub1-title-div']}>
                    {isOn &&
                        <p className={styles['chat-bot-title']}> Caïssa</p>
                    }
                    {!isOn &&
                        <p className={styles['chat-bot-title']}> Caïssa</p>
                    }
                    <div className={styles["switch"]} data-isOn={isOn}>
                        <motion.div className={styles["handle"]} layout transition={spring} onClick={(e) => toggleSwitch(e)}/>
                    </div>
                </div>
                <div>
                    <motion.button className={styles['chat-cross-button']} onClick={closeChat} whileHover={{ scale: 1.2, backgroundColor: "#f05053"} }><FontAwesomeIcon icon={faTimes} /></motion.button>
                </div>
            </div>
            <motion.div className={styles['chat-messages-div']} ref={listRef}>
                {
                    messages.map((message, index) => {
                        return(
                            <Message key={index} role={message.role} text={message.message} />
                        )
                    })
                }
                {isLoading &&
                    <Loading />
                }
            </motion.div>
            <div className={styles['chat-input-div']}>
                <input
                    className={styles['text-area-input']}
                    type="text" placeholder="Enter your prompt"
                    value={prompt}
                    onChange={(e) => {
                        setPrompt(e.target.value)
                    }}
                    onKeyDown={(e) => {
                       if (e.key === 'Enter') {
                            receiveResponse(e)
                        }
                    }}
                />
                {isOn&&!isReinforced&&
                    <motion.button 
                    className={styles['text-area-button']}
                    onClick={() => {
                        setTalkToReinforcedGemini(!isReinforced);
                        setIsReinforced(!isReinforced);
                    }}
                    whileHover={{ scale: 1.1, backgroundColor: "#f12711", color: "white" }} 
                    whileTap={{ scale: 0.9 }}
                    variants={variants}
                    >
                        {
                            <FontAwesomeIcon icon={faLightbulb}/>
                        }
                    </motion.button>
                }
                {isOn&&isReinforced&&
                    <motion.button 
                    className={styles['text-area-button-on']}
                    onClick={() => {
                        setTalkToReinforcedGemini(!isReinforced);
                        setIsReinforced(!isReinforced);
                    }}
                    whileHover={{ scale: 1.1, backgroundColor: "#f12711", color: "white" }} 
                    whileTap={{ scale: 0.9 }}
                    variants={variants}
                    >
                        {
                            <FontAwesomeIcon icon={faBoltLightning}/>
                        }
                    </motion.button>
                }
                <motion.button 
                    className={styles['text-area-button']}
                    onClick={receiveResponse}
                    whileHover={{ scale: 1.1, backgroundColor: "#38ef7d", color: "black" }} 
                    whileTap={{ scale: 0.9 }}
                    variants={variants}
                    >
                        <FontAwesomeIcon icon={faPaperPlane}/>
                </motion.button>
            </div>
        </div>
    )
}