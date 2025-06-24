import { useScroll, useTransform } from "framer-motion"
import React, { useRef } from "react"
import Spline from '@splinetool/react-spline';

export const MainInterface = () => {
    const ref = useRef(null)
    const { scrollYProgress } = useScroll({
        target: ref,
        offset: ["start start", "end start"],
    })
    const backgroundY = useTransform(scrollYProgress, [0, 1], ["0%", "100%"])
    const textY = useTransform(scrollYProgress, [0, 1], ["0%", "200%"])

    return (
        <div
            ref={ref}
            className="w-full h-screen overflow-hidden relative grid place-items-center"
        >
            <Spline scene="https://prod.spline.design/48WFHrTIRJoK4oAh/scene.splinecode" />
        </div>
    )
}

