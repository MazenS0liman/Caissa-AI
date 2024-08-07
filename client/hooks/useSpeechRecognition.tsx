import { useEffect, useState } from "react";

let recognition: any = null;

export const useSpeechRecognition = () => {
    const [text, setText] = useState("");
    const [isListening, setIsListening] = useState(false);

    useEffect(() => {
        if ('webkitSpeechRecognition' in window) {
            recognition = new (window as any).webkitSpeechRecognition();
        } else if ('SpeechRecognition' in window) {
            recognition = new (window as any).SpeechRecognition();
        }

        if (!recognition) return;

        recognition.continuous = true;
        recognition.lang = "en-GB";

        recognition.onresult = (event: SpeechRecognitionEvent) => {
            console.log("onresult event: ", event);

            for (let i = 0; i < event.results.length; i++) {
                const result:SpeechRecognitionResult = event.results[i];

                if (result[0].transcript !== ' ' && result[0].transcript !== '') {
                    console.log(`result[0].transcript: ${result[0].transcript}`);
                    setText(result[0].transcript.toLowerCase());
                }
            }
        };

        recognition.onerror = (event: any) => {
            console.error("Speech recognition error: ", event);
        };

        recognition.onspeechstart = (event: any) => {
            console.log("onspeechstart event: ", event);
            console.log("Speech has been detected");
            setIsListening(true);
        };

        recognition.onspeechend = (event: any) => {
            console.log("onspeechend event: ", event);
            console.log("Speech has stopped being detected");
        };

        recognition.onend = (event: any) => {
            console.log("onend event: ", event);
            console.log("Speech recognition service disconnected");
            setIsListening(false);
            recognition.stop();
        };
    }, []);

    const startListening = () => {
        if (!recognition) return;
        setText('');
        setIsListening(true);
        recognition.start();
        console.log("Recognition started");
    };

    const stopListening = () => {
        if (!recognition) return;
        setIsListening(false);
        recognition.stop();
        console.log("Recognition stopped");
    };

    return {
        text,
        isListening,
        startListening,
        stopListening,
        hasRecognitionSupport: !!recognition
    };
};
