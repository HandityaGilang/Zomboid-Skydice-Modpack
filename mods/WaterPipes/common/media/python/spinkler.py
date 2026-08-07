from PIL import Image, ImageDraw
import numpy as np
import os

# ---------------------
# Settings
# ---------------------
width, height = 1600, 1600
scale = 70  # pixels per meter
SCALE_FACTOR = 2  # for supersampling
hi_w, hi_h = width * SCALE_FACTOR, height * SCALE_FACTOR
center_px_hi = hi_w // 2
center_py_hi = hi_h // 2

dt = 0.1
gravity = -9.81
frames = 720  # total frames (2 full rotations)
particles_per_frame = 80
base_speed = 18
fade_duration = 36
particle_color = (246, 251, 255)
tilt_deg = 22.3
tilt_rad = np.radians(tilt_deg)

output_dir = "frames_loop_only"
os.makedirs(output_dir, exist_ok=True)

# ---------------------
# Utility Functions
# ---------------------
origin = [0.0, 0.0, 0.0]
center_px = width // 2
center_py = height // 2

tile_w = 64
tile_h = 32
elevation_scale = 64  # project zomboid height scale

def to_screen_coords(x, y, z):
    px = (x - z) * (tile_w / 2)
    py = (x + z) * (tile_h / 2) - y * elevation_scale
    return int(center_px_hi + px), int(center_py_hi + py)

# ---------------------
# Simulation
# ---------------------
particles = []

for frame in range(frames):
    angle_deg = (frame / frames) * 360 * 2
    angle_deg = angle_deg + np.random.uniform(-5, 5)
    angle_rad = np.radians(angle_deg)

    for _ in range(particles_per_frame):
        speed = np.random.uniform(0.5 * base_speed, base_speed)
        vx = speed * np.cos(angle_rad) + np.random.normal(0, 0.5)
        vy = speed * 0.5 + np.random.normal(0, 0.5)
        vz = speed * np.sin(angle_rad) + np.random.normal(0, 0.5)

        particles.append({
            "pos": [0.0, 0.0, 0.0],
            "vel": [vx, vy, vz],
            "age": 0
        })

    img_hi = Image.new("RGBA", (hi_w, hi_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img_hi)
    new_particles = []

    for p in particles:
        for i in range(3):
            p["pos"][i] += p["vel"][i] * dt
        p["vel"][1] += gravity * dt
        p["age"] += 1

        x, y, z = p["pos"]
        if y < 0:
            continue

        start_px, start_py = to_screen_coords(x, y, z)

        streak_len = 0.025
        vx, vy, vz = p["vel"]
        x_end = x + vx * streak_len
        y_end = y + vy * streak_len
        z_end = z + vz * streak_len
        end_px, end_py = to_screen_coords(x_end, y_end, z_end)

        alpha = int(200 * max(0, 1 - p["age"] / fade_duration))
        if alpha <= 0:
            continue

        draw.line(
            (start_px, start_py, end_px, end_py),
            fill=(*particle_color, alpha),
            width=3
        )

        new_particles.append(p)

    particles = new_particles

    img_final = img_hi.resize((width, height), resample=Image.LANCZOS)
    img_final.save(f"{output_dir}/{frame+1:03d}.png", "PNG")

print("✅ Saved loopable frames to:", os.path.abspath(output_dir))
