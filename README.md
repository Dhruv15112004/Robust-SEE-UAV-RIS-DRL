# Robust Secrey Energy-Efficient UAV-RIS Communication using DRL-SCA

This repository presents the final research implementation and simulation framework for **robust secrecy energy-efficient UAV-RIS assisted wireless communication** under **unknown eavesdropper location**.

The work focuses on jointly optimizing **physical-layer security** and **UAV energy efficiency** by integrating **Successive Convex Approximation (SCA)** with **Deep Reinforcement Learning (DRL)**.

---

## 📌 Project Overview

Unmanned Aerial Vehicles (UAVs) combined with Reconfigurable Intelligent Surfaces (RIS) offer flexible and energy-efficient wireless communication. However, due to the broadcast nature of wireless channels, UAV-based communication is highly vulnerable to eavesdropping—especially when the eavesdropper’s location is unknown.

This project proposes a **robust secrecy energy efficiency (SEE) maximization framework** that:
- Does **not rely on perfect eavesdropper CSI**
- Models the eavesdropper location using a **bounded uncertainty region**
- Uses **worst-case SEE optimization** for guaranteed security
- Learns adaptive UAV trajectories using **Deep Reinforcement Learning**

---

## 🧠 Key Contributions

- Robust UAV-RIS assisted secure communication model with **unknown eavesdropper location**
- Secrecy Energy Efficiency (SEE) formulation considering:
  - Secrecy rate
  - UAV propulsion and circuit energy consumption
- **Two-layer optimization framework**:
  - **Inner loop:** Robust SCA for worst-case SEE computation
  - **Outer loop:** DRL-based UAV trajectory learning using SEE feedback
- Performance comparison with **greedy** and **random walk** baselines
- Stable convergence and superior long-term SEE performance

---

## ⚙️ System Architecture

- **Ground Base Station (BS)**
- **UAV-mounted Reconfigurable Intelligent Surface (RIS)**
- **Legitimate User Equipment (UE)**
- **Passive Eavesdropper with Unknown Location**

The UAV operates at a fixed altitude and dynamically adjusts its horizontal trajectory to maximize secrecy energy efficiency.

---

## 🧪 Methodology

### 🔹 Inner Optimization (Robust SCA)
- Computes worst-case eavesdropper SINR over uncertainty region
- Approximates non-convex SEE objective using SCA
- Provides robust reward signal for learning

### 🔹 Outer Optimization (DRL)
- Learns optimal UAV trajectory without eavesdropper CSI
- Uses SEE as the reward signal
- Ensures long-term secure and energy-efficient operation

---

## 📊 Simulation & Results

- Implemented using **MATLAB** (channel modeling & SEE computation)
- **Python-based DRL agent** (PPO-style learning)
- Performance evaluated using:
  - SEE vs Time
  - UAV Trajectory Behavior
  - Average SEE Comparison

### 🔸 Key Findings
- DRL-based policy achieves **stable and consistent SEE**
- Greedy policy overshoots optimal regions
- Random walk policy is highly unstable
- Robust DRL-SCA framework is most suitable for real-world deployment

---

## 📁 Project Contents

- Research paper (PDF)
- Simulation results and figures
- Algorithm description
- System model and mathematical formulation

---

## 🛠 Tools & Technologies

- MATLAB
- Python
- Deep Reinforcement Learning (PPO-style)
- Convex Optimization (SCA)
- UAV Communication Modeling
- RIS-based Secure Wireless Systems

---

## 👨‍🎓 Authors

- Dr. Rajkishor Kumar  
- Bhuvan Sonawane  
- **Dhruv Maheshwari**  
- Nimish Gulghane  

Department of Electronics and Communication Engineering  
Vellore Institute of Technology, Vellore, India

---

## 📄 Reference Paper

This repository is based on the research paper:

**"Robust Secrecy Energy-Efficient UAV-RIS Communication with Unknown Eavesdropper Location"** :contentReference[oaicite:0]{index=0}

---

## ⭐ Acknowledgement

This work was developed as part of academic research at VIT Vellore and aims to contribute toward secure and energy-efficient next-generation wireless communication systems.

---

## 📬 Contact

For queries or collaboration, feel free to connect via GitHub or LinkedIn.
