import matlab.engine
from flask import Flask, request, jsonify
import io
import sys

# --- Setup MATLAB Engine ---
print("Starting MATLAB engine... (This may take a moment)")
try:
    eng = matlab.engine.start_matlab()
    print("MATLAB engine started successfully.")
    
    # Add the current directory to MATLAB's path
    # This allows MATLAB to find your 'calculate_reward_3d.m' file
    script_path = eng.genpath('.')
    eng.addpath(script_path, nargout=0)
    print(f"Adding '{script_path}' to MATLAB path.")
    
except Exception as e:
    print(f"--- FAILED to start MATLAB engine ---")
    print(f"Error: {e}")
    print("Please ensure MATLAB is installed and the Python engine API is set up.")
    sys.exit(1)
# -----------------------------

app = Flask(__name__)

@app.route('/calculate', methods=['GET'])
def calculate():
    """
    This function is called by the Python client (or your RL agent).
    It receives the UAV's 3D position, passes it to MATLAB,
    and returns the calculated reward (SEE).
    """
    try:
        # --- 1. Get 3D Coordinates from Request ---
        # We now expect 'x', 'y', and 'z'
        uav_x = request.args.get('x', type=float)
        uav_y = request.args.get('y', type=float)
        uav_z = request.args.get('z', type=float) # <-- NEW Z-COORDINATE

        if uav_x is None or uav_y is None or uav_z is None:
            print(f"Server: Received incomplete request. Missing x, y, or z.")
            return jsonify({'success': False, 'error': 'Missing x, y, or z coordinate'}), 400

        print(f"Server: Received request: x={uav_x}, y={uav_y}, z={uav_z}")

        # --- 2. Call MATLAB Function ---
        # We capture MATLAB's text output to show in the console
        out = io.StringIO()
        err = io.StringIO()
        
        # Call the new MATLAB function 'calculate_reward_3d'
        # Note: We must pass arguments as floats (MATLAB default)
        final_see = eng.calculate_reward(float(uav_x), float(uav_y), float(uav_z), 
                                 stdout=out, stderr=err, nargout=1)

        
        # Print MATLAB's output
        matlab_stdout = out.getvalue()
        matlab_stderr = err.getvalue()
        if matlab_stdout:
            print("--- MATLAB Output ---")
            print(matlab_stdout, end='')
            print("---------------------")
        if matlab_stderr:
            print("--- MATLAB Error ---")
            print(matlab_stderr, end='')
            print("--------------------")

        print(f"Server: MATLAB returned SEE = {final_see}")

        # --- 3. Return Reward to Client ---
        return jsonify({
            'success': True,
            'reward': final_see,
            'location': {'x': uav_x, 'y': uav_y, 'z': uav_z}
        })

    except Exception as e:
        error_message = f"An error occurred: {str(e)}"
        print(f"Server: {error_message}")
        # Also print any MATLAB errors if they exist
        if 'matlab_stderr' in locals() and matlab_stderr:
            print(f"Server: MATLAB Error Dump -> {matlab_stderr}")
            
        return jsonify({'success': False, 'error': error_message}), 500

if __name__ == '__main__':
    print("Starting Flask server on http://0.0.0.0:5000")
    print("Press CTRL+C to quit")
    app.run(host='0.0.0.0', port=5000, debug=False)