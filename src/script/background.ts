import * as THREE from "three";
import vertexSrc from "./shaders/vertex.glsl?raw";
import fragmentSrc from "./shaders/fragment.glsl?raw";

const background = document.getElementById("background");
const canvas = document.getElementById("canvas") as HTMLCanvasElement;

background?.appendChild(canvas);

const gl = canvas.getContext("webgl2")!;
const renderer = new THREE.WebGLRenderer({ canvas, context: gl, antialias: true });

// setup shader variables
const MAX_CLICKS = 10;
const uniforms = {
  uResolution: { value: new THREE.Vector2() },
  uTime: { value: 0 },
  uClickPosition: { value: Array.from({ length: MAX_CLICKS }, () => new THREE.Vector2(-1, -1)) },
  uClickTimes: { value: new Float32Array(MAX_CLICKS) },
};
const scene = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
const material = new THREE.ShaderMaterial({
  vertexShader: vertexSrc,
  fragmentShader: fragmentSrc,
  uniforms,
  glslVersion: THREE.GLSL3,
  transparent: true,
});

scene.add(new THREE.Mesh(new THREE.PlaneGeometry(2, 2), material));

// resize handling
const resize = () => {
  const w = canvas.clientWidth || window.innerWidth;
  const h = canvas.clientHeight || window.innerHeight;
  renderer.setSize(w, h, false);
  uniforms.uResolution.value.set(w, h);
};
window.addEventListener("resize", resize);
resize();

// on-click ripple effect
let clickIndex = 0;
window.addEventListener(
  "pointerdown",
  (e) => {
    const rect = canvas.getBoundingClientRect();
    const fx = (e.clientX - rect.left) * (canvas.width / rect.width);
    const fy = (rect.height - (e.clientY - rect.top)) * (canvas.height / rect.height);
    uniforms.uClickPosition.value[clickIndex].set(fx, fy);
    uniforms.uClickTimes.value[clickIndex] = uniforms.uTime.value;
    clickIndex = (clickIndex + 1) % MAX_CLICKS;
  },
  { capture: true }
);
const timer = new THREE.Timer();
// render loop
function animate(timestamp: number) {
  requestAnimationFrame(animate);
  timer.update(timestamp);
  // update time uniform
  uniforms.uTime.value = timer.getElapsed();
  renderer.render(scene, camera);
}
// begin render loop
requestAnimationFrame(animate);
