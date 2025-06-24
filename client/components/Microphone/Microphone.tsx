import React from 'react';
import { useSpeechRecognition } from '@/hooks/useSpeechRecognition';

export const Microphone = () => {
    const {
        text,
        startListening,
        stopListening,
        isListening,
        hasRecognitionSupport
    } = useSpeechRecognition();
    
    return (
        <div>
            {hasRecognitionSupport ? (
                <>
                    <div>
                        <button onClick={startListening}>Start listening</button>
                    </div>
                    <div>
                        <button onClick={stopListening}>Stop listening</button>
                    </div>
                    {isListening ? <div>Your browser is currently listening</div> : null}
                    <div>{text}</div>
                </>
            ) : (
                <h1>Your browser has no speech recognition support</h1>
            )}
        </div>
    );
};
