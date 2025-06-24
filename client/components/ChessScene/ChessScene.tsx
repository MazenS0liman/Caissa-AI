import { Canvas } from "@react-three/fiber";
import { useEffect, useState } from "react";
import * as THREE from 'three'
import { OrbitControls } from "@react-three/drei";
import { ChessBoard } from "../ChessBoard/ChessBoard";
import './ChessScene.module.css';

const DEG2RAD = Math.PI / 180;
const pointer = new THREE.Vector3();

function onPointerMove(event: any) {
  pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.y = - (event.clientY / window.innerHeight) * 2 + 1;
  pointer.z = 0;
}

type IChessScene = {
  displayLoading: Function
}

export const ChessScene = ({ displayLoading }: IChessScene) => {

  useEffect(() => {
    window.addEventListener('pointermove', onPointerMove);

    return () => {
      window.removeEventListener('pointermove', onPointerMove);
    };
  }, []);

  return (
    <>
      <Canvas linear flat style={{width: "100%", height: "100%"}} camera={{ position: [0, 0, 8] }}>
      <directionalLight 
            position={[0, 0, .1]} 
            color={"white"}
            intensity={2.5}
        />
        <ambientLight intensity={0.9} />
        <group position={[-1.77, -1, 0]} rotation={[-35 * DEG2RAD, 0, 0]}>
          <ChessBoard position={[-1.75, -2, 0]} scale={[50000, 50000, 0.2]} displayLoading={displayLoading}/>
          <mesh position={[0, 5, 5]}>
            <boxGeometry />
            <meshStandardMaterial color={"red"}/>
          </mesh>
        </group>
        <OrbitControls 
            enablePan={false}
            enableRotate={false} 
            enableZoom={false}
        />
      </Canvas>
    </>
  );
};

