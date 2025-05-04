import "./style.css"
import * as THREE from "three"
import { OrbitControls } from "three/addons/controls/OrbitControls.js"

const APP = document.getElementById("app")!
const APP_SVG = document.getElementById("svg-app")!

const WIDTH = APP.clientWidth
const HEIGHT = APP.clientHeight

const proportion = 0.1

class Vector3 {
    public x: number
    public y: number
    public z: number

    constructor(x: number, y: number, z: number) {
        this.x = x
        this.y = y
        this.z = z
    }

    static sum(a: Vector3, b: Vector3): Vector3 {
        return new Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
    }

    static mutBy(a: Vector3, mut: number) {
        return new Vector3(a.x * mut, a.y * mut, a.z * mut)
    }

    mutBy(mut: number) {
        this.x *= mut
        this.y *= mut
        this.z *= mut
    }
}

class Atom {
    private color: number
    private radius: number
    private pos: Vector3

    public mesh: THREE.Mesh

    constructor(line: string, center: Vector3) {
        const [color_str, radius_str, x_str, y_str, z_str] = line.split(" ")

        this.color = parseInt(color_str, 16)
        this.radius = parseFloat(radius_str) * proportion

        const x = parseFloat(x_str)
        const y = parseFloat(y_str)
        const z = parseFloat(z_str)
        const pos = new Vector3(x, y, z)

        this.pos = Vector3.sum(pos, center)
        this.pos.mutBy(proportion)

        this.mesh = this.render()
    }

    private render() {
        const geometry = new THREE.SphereGeometry(this.radius, 32, 24)
        const material = new THREE.MeshBasicMaterial({
            color: this.color,
            wireframe: false,
        })
        const sphere = new THREE.Mesh(geometry, material)
        sphere.position.x = this.pos.x
        sphere.position.y = this.pos.y
        sphere.position.z = this.pos.z
        return sphere
    }
}

class Molecula {
    private static last_z1 = ""

    private atoms: Atom[]
    public scale: Vector3
    private center: Vector3

    constructor(z13: string) {
        const [sizes, ...lines] = z13.trim().split("\n")

        this.scale = this.handleSizes(sizes)
        this.center = new Vector3(0, 0, 0)

        this.atoms = lines.map((line) => new Atom(line, this.center))
    }

    get max_radius() {
        return Math.max(this.scale.x, this.scale.z) * proportion
    }

    private handleSizes(line: string): Vector3 {
        const [width_str, height_str, depth_str] = line.split(" ")
        const width = parseFloat(width_str)
        const height = parseFloat(height_str)
        const depth = parseFloat(depth_str)
        return new Vector3(width, height, depth)
    }

    public render(scene: THREE.Scene) {
        this.atoms.forEach((atom) => scene.add(atom.mesh))
    }

    public destroy(scene: THREE.Scene) {
        this.atoms.forEach((atom) => scene.remove(atom.mesh))
    }

    static async load(file: string): Promise<Molecula | null> {
        const res = await fetch(file)
        const data = await res.text()

        fetch("out.svg")
        .then(res => res.text())
        .then(svg => APP_SVG.innerHTML = svg)

        if (Molecula.last_z1 != data) {
            Molecula.last_z1 = data
            return new Molecula(data)
        } else return null
    }
}

const scene = new THREE.Scene()
const camera = new THREE.PerspectiveCamera(75, WIDTH / HEIGHT, 0.1, 1000)
const renderer = new THREE.WebGLRenderer()
const controls = new OrbitControls(camera, renderer.domElement)

renderer.setSize(WIDTH, HEIGHT)
APP.appendChild(renderer.domElement)

let camera_angle = 180
let camera_rotation_speed = 1 / 4
let camera_radius = 100
let camera_y_wave = 100

let is_loading = false
let molecula: Molecula | null = null

renderer.setAnimationLoop(animate)
function animate() {
    controls.update()

    if (!is_loading) {
        is_loading = true
        Molecula.load("out.z13")
            .then(newMolecula => {
                if (!newMolecula) return

                if (molecula) molecula.destroy(scene)
                molecula = newMolecula
                if (molecula) molecula.render(scene)

                camera_radius = molecula.max_radius + 20
            })
            .finally(() => (is_loading = false))
    }

    camera_angle += camera_rotation_speed
    if (camera_angle > 360 * camera_y_wave) camera_angle = camera_angle % 360

    let camera_x = Math.cos((camera_angle * Math.PI) / 180) * camera_radius
    let camera_y = Math.sin(camera_angle / camera_y_wave) * 20
    let camera_z = Math.sin((camera_angle * Math.PI) / 180) * camera_radius
    camera.position.x = camera_x
    camera.position.y = camera_y
    camera.position.z = camera_z
    camera.lookAt(0, 0, 0)

    renderer.render(scene, camera)
}
