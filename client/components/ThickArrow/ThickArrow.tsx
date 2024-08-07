import * as THREE from 'three';
import { useTexture } from '@react-three/drei';

type IThickArrow = {
  start: [number, number, number],
  end: [number, number, number],
  color: string,
  shaftRadius: number,
  headRadius: number,
  headLength: number
}

export const ThickArrow = ({ start, end, color = '#9c88ff', shaftRadius = 0.05, headRadius = 0.15, headLength = 0.5 }: IThickArrow) => {
    const texture = useTexture('./texture/metal_12_basecolor-1K.png');
  
    // Convert grid coordinates to center positions
    const startPos = new THREE.Vector3(start[0] - 1.9, start[1] - 1.95, start[2]);
    const endPos = new THREE.Vector3(end[0] - 1.9, end[1] - 1.95, end[2]);
  
    const direction = new THREE.Vector3().subVectors(endPos, startPos).normalize();
    const length = new THREE.Vector3().subVectors(endPos, startPos).length();
    const arrowPosition = startPos.clone().addScaledVector(direction, (length - headLength) / 2);
    const headPosition = startPos.clone().addScaledVector(direction, length - headLength / 2);
  
    const quaternion = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), direction);
  
    return (
      <group>
        <mesh position={arrowPosition} quaternion={quaternion}>
          <cylinderGeometry args={[shaftRadius, shaftRadius, length - headLength, 8]} />
          <meshStandardMaterial attach={"material"} map={texture} />
        </mesh> 
        <mesh position={headPosition} quaternion={quaternion}>
          <coneGeometry args={[headRadius, headLength, 8]} />
          <meshStandardMaterial attach={"material"} map={texture} />
        </mesh>
      </group>
    );
}