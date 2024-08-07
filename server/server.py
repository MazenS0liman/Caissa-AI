from flask import Flask, jsonify, request
from flask_cors import CORS
import multiprocessing
from neurosymbolicAI import NeuroSymbolic
from neurosymbolicAI.symbolicAI.symbolic_ai import Symbolic
from agent import generate_response
from pipeline import chat
import os

ns = NeuroSymbolic()

KB_PATH = os.getenv('KB_PATH')

# App Instance
app = Flask(__name__, static_url_path='', static_folder='frontend/build')
CORS(app, resources={r"*": {"origin": "*"}})

# Helper methods
def execute_tactic(tactic_method, color, description, filepath, fen_string) -> None:
    '''
    Add a tactic relation to knowledge graph.
    
    :param: :tactic_method: tactic to execute
    :param: :color: player color
    :param: :description: tactic's name
    :param: :filepath: prolog file path
    :param: :fen_string: current forsyth-edwards notation of a chessboard
    
    :return: #### None
    '''
    try:
        s = Symbolic()
        s.consult(filepath)
        s.parse_fen(fen_string)
        tactic_method(s, color)
        print(f"{color.capitalize()} {description}")
    except Exception as e:
        print(f"Error executing tactic {description}: {e}")
            
def add_tactics_to_graph(filepath, fen_string):
    '''
    Add all supported tactics relations to the knowledge graph.
    
    :param: :filepath: prolog file path
    :param: :fen_string: current forsyth-edwards notation of a chessboard
    
    :return: #### None
    '''
    
    # Tactics
    with multiprocessing.get_context('spawn').Pool(processes=os.cpu_count()) as pool:
        tactics = [
            (Symbolic.mate, "white", "Mate"),
            (Symbolic.create_fork_relation, "white", "Fork"),
            (Symbolic.create_absolute_pin_relation, "white", "Absolute Pin"),
            (Symbolic.create_relative_pin_relation, "white", "Relative Pin"),
            (Symbolic.create_skewer_relation, "white", "Skewer"),
            (Symbolic.create_discovery_attack_relation, "white", "Discover Attack"),
            (Symbolic.hanging_piece, "white", "Hanging Piece"),
            (Symbolic.create_interference_relation, "white", "Interference"),
            (Symbolic.create_mate_in_two_relation, "white", "Mate in 2"),
            (Symbolic.defend, "white", "Defend"),
            (Symbolic.threat, "white", "Threat"),
            (Symbolic.move_defend, "white", "Move Defend"),
            (Symbolic.move_threat, "white", "Move Threat"),
            (Symbolic.protected_move, "white", "Protected Move"),
            (Symbolic.attackted_move, "white", "Attacked Move"),
            (Symbolic.mate, "black", "Mate"),
            (Symbolic.create_fork_relation, "black", "Fork"),
            (Symbolic.create_absolute_pin_relation, "black", "Absolute Pin"),
            (Symbolic.create_relative_pin_relation, "black", "Relative Pin"),
            (Symbolic.create_skewer_relation, "black", "Skewer"),
            (Symbolic.create_discovery_attack_relation, "black", "Discover Attack"),
            (Symbolic.hanging_piece, "black", "Hanging Piece"),
            (Symbolic.create_interference_relation, "black", "Interference"),
            (Symbolic.create_mate_in_two_relation, "black", "Mate in 2"),
            (Symbolic.defend, "black", "Defend"),
            (Symbolic.threat, "black", "Threat"),
            (Symbolic.move_defend, "black", "Move Defend"),
            (Symbolic.move_threat, "black", "Move Threat"),
            (Symbolic.protected_move, "black", "Protected Move"),
            (Symbolic.attackted_move, "black", "Attacked Move")
        ]
        
        results = [
            pool.apply_async(execute_tactic, (tactic_method, color, description, filepath, fen_string))
            for tactic_method, color, description in tactics
        ]
        
        # Ensure all tasks are completed
        for r in results:
            r.get()

# GET APIs
@app.route("/legal_moves", methods=['GET'])
def get_legal_moves():
    '''
    Fetch the legal moves of a piece.
    '''
    piece = request.args.get('piece')
    color = request.args.get('color')
    position = request.args.get('position')
    
    if not piece or not color or not position:
        return jsonify({'error': 'Missing parameters'}), 400
    
    ns.symbolic.parse_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    list_of_moves = ns.symbolic.legal_moves(piece, color, position)
    
    return jsonify({
        'legal_moves': list_of_moves
    })
    
# POST APIs
@app.route("/reinforced_chatbot", methods=['POST'])
def post_message_with_reinforced_chatbot():
    '''
    Chat with Eureka llm enhanced by langGraph.
    '''
    data = request.json
    prompt = data.get('prompt')
    fen_string = data.get('fen')
    
    try:
        response = chat(input=prompt, fen_string=fen_string)
    except Exception as e:
        print(f"Error {e}")
        response = "Try Again!"
    
    return jsonify({
        'answer': response,
    })
    
@app.route("/chatbot", methods=['POST'])
def post_message():
    '''
    Chat with Eureka.
    '''
    data = request.json
    prompt = data.get('prompt')
    
    try:
        response = generate_response(prompt)
    except Exception as e:
        print(f"Error {e}")
        response = "Try Again!"
    
    return jsonify({
        'answer': response,
    })
    
@app.route("/neurosym", methods=['POST'])
def post_tactic():
    '''
    Chat with neurosymbolic module.
    '''
    data = request.json
    fen_string = data.get('fen')
    ns.symbolic.parse_fen(fen_string)
    response = ns.suggest(fen_string = fen_string, move = None, test = False)
    
    return jsonify({
        'answer': response
    })
    
@app.route("/make_move", methods=['POST'])
def make_move():
    '''
    Move a chess piece from a position to another position.
    '''
    data = request.json
    fen_string = data.get('fen_string')
    piece = data.get('piece')
    color = data.get('color')
    from_position = data.get('from_position')
    to_position = data.get('to_position')
    promotion = data.get('promotion')
    ns.symbolic.parse_fen(fen_string)
    result, new_board = ns.symbolic.make_move(piece, color, from_position, to_position)
    
    if new_board == None:
        new_board = []
    else:
        if not promotion:
            ns.symbolic.construct_graph()
            add_tactics_to_graph(KB_PATH, fen_string)
            
    return jsonify({
        'move_status': len(result) != 0,
        'new_board': new_board
    })

@app.route("/set_fen", methods=['POST'])
def set_fen():
    '''
    Set a forsyth-edwards notation.
    '''
    data = request.json
    fen_string = data.get('fen_string')
    ns.symbolic.update_board(fen_string)
    board = ns.symbolic.get_board()
    ns.symbolic.construct_graph()
    add_tactics_to_graph(KB_PATH, fen_string)
    
    return jsonify({
        "board": board
    })
    
if __name__ == "__main__":
    app.run(debug=False, port=os.getenv("PORT"))