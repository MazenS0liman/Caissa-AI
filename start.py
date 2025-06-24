import os
import threading
import warnings
warnings.filterwarnings("ignore")

def start_client():
    os.chdir("client")  # Change to the client directory
    os.system("npm run start")  # Adjust the command if necessary
    os.chdir("..")  # Change back to the original directory

def start_server():
    os.system("server/proj_env/bin/python3.10 -m flask --app server/server.py run")

if __name__ == "__main__":
    
    t1 = threading.Thread(target=start_server, args=())
    t2 = threading.Thread(target=start_client, args=())

    t1.start()
    t2.start()
    
    t1.join()
    t2.join()
    
    input("Press any key to exit.")
