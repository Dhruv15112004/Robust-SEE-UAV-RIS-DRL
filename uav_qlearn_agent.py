"""
uav_qlearn_agent.py

Discrete-grid Q-learning agent that queries a MATLAB server for SEE reward.
Usage:
    python uav_qlearn_agent.py
Edit the NGROK_URL and grid parameters below as needed.
"""

import requests
import time
import random
import numpy as np
import json
import os
import matplotlib.pyplot as plt

# ------------------ USER CONFIG ------------------
# Put your ngrok + route to MATLAB endpoint here (no trailing slash)
NGROK_URL = " https://8fdb573243f5.ngrok-free.app"   # <- change to your ngrok URL
SERVER_ROUTE = "/calculate"                          # endpoint (should accept x,y,z GET params)

SERVER_URL = NGROK_URL.rstrip("/") + SERVER_ROUTE

# Grid definition (discretize XY plane and altitudes)
X_RANGE = np.arange(0, 101, 10)    # e.g., 0,10,...,100
Y_RANGE = np.arange(0, 101, 10)
Z_RANGE = np.array([5.0, 10.0, 20.0, 40.0])  # altitudes to explore (tunable)

MAX_EPISODES = 200           # training episodes
MAX_STEPS_PER_EP = 30        # steps per episode
ALPHA = 0.3                  # learning rate
GAMMA = 0.98                 # discount factor
EPS_START = 1.0              # starting exploration epsilon
EPS_END = 0.05
EPS_DECAY = 0.995
REQUEST_TIMEOUT = 240        # seconds, increase if your MATLAB optimization is slow
RETRY_DELAY = 2.0            # seconds between retries
MAX_RETRIES = 3

# Where to store logs
OUT_DIR = "qlearn_results"
os.makedirs(OUT_DIR, exist_ok=True)
# --------------------------------------------------

# Build grid => mapping state index <-> coordinates
coords = []
for x in X_RANGE:
    for y in Y_RANGE:
        for z in Z_RANGE:
            coords.append((float(x), float(y), float(z)))
NUM_STATES = len(coords)
ACTIONS = [
    ( 0,  0,  0),  # stay
    ( 1,  0,  0),  # +x
    (-1,  0,  0),  # -x
    ( 0,  1,  0),  # +y
    ( 0, -1,  0),  # -y
    ( 0,  0,  1),  # +z (next higher altitude)
    ( 0,  0, -1),  # -z (next lower altitude)
]
NUM_ACTIONS = len(ACTIONS)

# helper dicts
coord_to_state = {coords[i]: i for i in range(NUM_STATES)}
# quick neighbor finding: state_index -> possible next state indices for each action
def step_from_state(state_idx, action_idx):
    x,y,z = coords[state_idx]
    dx,dy,dz = ACTIONS[action_idx]
    # find nearest grid cell in X_RANGE/Y_RANGE/Z_RANGE after applying delta
    # deltas are units of grid spacing: convert dx=1 to +10 m if using 10 m spacing
    # Implementation: find current indices, add dx and clamp
    ix = int(np.where(X_RANGE == x)[0][0])
    iy = int(np.where(Y_RANGE == y)[0][0])
    iz = int(np.where(Z_RANGE == z)[0][0])
    ix2 = min(max(ix + dx, 0), len(X_RANGE)-1)
    iy2 = min(max(iy + dy, 0), len(Y_RANGE)-1)
    iz2 = min(max(iz + int(dz), 0), len(Z_RANGE)-1)
    new_coord = (float(X_RANGE[ix2]), float(Y_RANGE[iy2]), float(Z_RANGE[iz2]))
    return coord_to_state[new_coord]

def query_server_for_reward(x, y, z):
    """Send HTTP GET to MATLAB server and return float reward (SEE).
       Retries a few times on network errors or non-200 responses.
    """
    params = {"x": float(x), "y": float(y), "z": float(z)}
    for attempt in range(1, MAX_RETRIES+1):
        try:
            resp = requests.get(SERVER_URL, params=params, timeout=REQUEST_TIMEOUT)
            if resp.status_code == 200:
                try:
                    j = resp.json()
                except json.JSONDecodeError:
                    print("ERROR: server returned non-JSON. Response text:", resp.text)
                    return None
                if isinstance(j, dict) and j.get("success", False):
                    return float(j.get("reward", j.get("SEE", j.get("reward_value", 0.0))))
                else:
                    # server responded but indicated processing error
                    print("Server returned error payload:", j)
                    return None
            else:
                print(f"HTTP {resp.status_code} from server; resp text: {resp.text}")
        except requests.exceptions.RequestException as e:
            print(f"Request exception (attempt {attempt}/{MAX_RETRIES}): {e}")
        if attempt < MAX_RETRIES:
            time.sleep(RETRY_DELAY)
    return None

# Initialize Q-table (states x actions)
Q = np.zeros((NUM_STATES, NUM_ACTIONS))

# Track best seen
best_reward = -1e9
best_coord = None

# training loop
eps = EPS_START
episode_rewards = []

print(f"Starting Q-learning over {NUM_STATES} discrete states ({len(X_RANGE)}x{len(Y_RANGE)}x{len(Z_RANGE)})")
print("Server URL:", SERVER_URL)
time0 = time.time()
for ep in range(1, MAX_EPISODES+1):
    # start at a random state
    s = random.randrange(NUM_STATES)
    total_reward = 0.0
    for step in range(MAX_STEPS_PER_EP):
        # epsilon-greedy action
        if random.random() < eps:
            a = random.randrange(NUM_ACTIONS)
        else:
            a = int(np.argmax(Q[s,:]))
        s2 = step_from_state(s, a)
        x,y,z = coords[s2]
        reward = query_server_for_reward(x, y, z)
        if reward is None:
            # failed to get reward: small penalty and break
            reward = -1.0
            print(f"[ep{ep} step{step}] failed to get reward for {x,y,z}, using {reward}")
            # optional: break or continue. We'll continue with penalty.
        # Q-learning update
        Q[s,a] += ALPHA * (reward + GAMMA * np.max(Q[s2,:]) - Q[s,a])
        total_reward += reward
        # track best globally
        if reward > best_reward:
            best_reward = reward
            best_coord = (x,y,z)
        # move to next state
        s = s2
    episode_rewards.append(total_reward)
    # decay epsilon
    eps = max(EPS_END, eps * EPS_DECAY)
    if ep % 10 == 0 or ep == 1:
        print(f"Episode {ep}/{MAX_EPISODES} | total_reward={total_reward:.4f} | eps={eps:.3f} | best_seen={best_reward:.4f} at {best_coord}")
time_tot = time.time() - time0

# Save results
np.save(os.path.join(OUT_DIR, "Q_table.npy"), Q)
with open(os.path.join(OUT_DIR, "best_coord.json"), "w") as f:
    json.dump({"best_coord": best_coord, "best_reward": float(best_reward)}, f)
np.savetxt(os.path.join(OUT_DIR, "episode_rewards.csv"), np.array(episode_rewards), delimiter=",")

print("\nTraining finished in %.1f s" % time_tot)
print("Best reward found:", best_reward, "at", best_coord)

# Simple plot of episode rewards
plt.figure(figsize=(8,4))
plt.plot(episode_rewards, '-o', markersize=3)
plt.xlabel('Episode')
plt.ylabel('Cumulative reward (sum of SEE during episode)')
plt.title('Q-learning training progress')
plt.grid(True)
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, "training_progress.png"), dpi=150)
print("Saved training plot to", os.path.join(OUT_DIR, "training_progress.png"))
