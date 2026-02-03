from flask import Flask, request, jsonify
import matlab.engine
import traceback

app = Flask(__name__)

print("Starting MATLAB engine (this can take some time)...")
eng = matlab.engine.start_matlab()

# 👉 Make sure MATLAB can see your .m files
#    CHANGE THE PATH BELOW IF YOUR PROJECT FOLDER IS DIFFERENT
eng.addpath(r'C:\Users\251026\Desktop\DroneProject', nargout=0)

print("MATLAB engine started.")

@app.route("/see", methods=["POST"])
def see_endpoint():
    """
    Expects JSON: {"x": <float>, "y": <float>, "z": <float>}
    Returns: {"see": <float>}
    """
    data = request.get_json(force=True)
    x = float(data.get("x", 0.0))
    y = float(data.get("y", 0.0))
    z = float(data.get("z", 20.0))

    print(f"Flask: received position x={x}, y={y}, z={z}")

    try:
        # Call your MATLAB function: it must be on MATLAB path
        see = eng.calculate_reward_3d(x, y, z, nargout=1)
        see = float(see)
        print(f"Flask: MATLAB returned SEE = {see}")
        return jsonify({"see": see})
    except Exception as e:
        print("Error calling MATLAB:", e)
        traceback.print_exc()
        # Return error too (useful for debugging in Colab if needed)
        return jsonify({"see": 0.0, "error": str(e)}), 500


@app.route("/ping", methods=["GET"])
def ping():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    # run Flask on port 5000
    app.run(host="0.0.0.0", port=5000, debug=True)
