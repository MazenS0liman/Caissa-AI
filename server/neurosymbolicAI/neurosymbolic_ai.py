from .symbolicAI import Symbolic
# from .llmAI import ChessGPT # predict next move
from os.path import join, dirname
from dotenv import load_dotenv
import os
import csv
import re

# Load environment variables
dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

KB_PATH = os.getenv('KB_PATH')
# print(f"""KB: {KB_PATH}""")

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    RED = '\033[31m'

class NeuroSymbolic():
    reason_flag = True
    
    def __init__(self):
        # self.gpt = ChessGPT()
        self.symbolic = Symbolic()
        self.symbolic.consult(KB_PATH)
        
    def predict(self, fen_string):
        output = self.gpt.play_puzzle(fen_string, ["fork", "discoveredAttack", "pin", "skewer", "mate", "mateIn2", "endgame", "hangingPiece"])
        predicted_move = output.split(",")[0]
        return predicted_move
    
    def get_move_from_str(self, fen_string, uci_move):
        self.symbolic.parse_fen(fen_string)
        turn = fen_string.split(" ")[1]
        player = ""
        
        if turn == "b":
            player = "black"
        else:
            player = "white"
            
        items = list(self.symbolic.prolog.query("occupies(Piece, Color, Position)"))
        
        if len(uci_move) == 4:
            from_uci = uci_move[0:2]
            to_uci = uci_move[2:4]
            
            pieces = list(self.symbolic.prolog.query(f"""return_pieces(Piece, {player}, {from_uci})"""))
            
            if pieces == []:
                return None
            else:
                piece = pieces[0]['Piece']
                return (piece, player, from_uci, to_uci)

        else:
            return None
                            
    def reason(self, fen_string, uci_move):
        self.symbolic.parse_fen(fen_string)
        turn = fen_string.split(" ")[1]
        player = ""
        
        if turn == "b":
            player = "black"
        else:
            player = "white"
            
        list(self.symbolic.prolog.query("display_board"))
        
        if len(uci_move) == 4:
            from_uci = uci_move[0:2]
            to_uci = uci_move[2:4]
            
            print(f"""Player: {player}, From: {from_uci}, To: {to_uci}""")
            pieces = list(self.symbolic.prolog.query(f"""return_pieces(Piece, {player}, {from_uci})"""))
            move = list(self.symbolic.prolog.query(f"is_legal(Piece, {player}, {from_uci}, {to_uci})"))
            
            print(f"Pieces: {pieces}, Legal Move: {move}")
            
            if pieces == [] or move == []:
                return "incorrect position"
            else:
                piece = pieces[0]['Piece']
                self.symbolic.construct_graph(player)
                result = self.symbolic.reason(piece, player, from_uci, to_uci)
        else:
            return "incorrect uci"
         
        if result == "incorrect uci" or result == "incorrect position":
            if not(self.reason_flag):
                return ""
        
        return result
    
    # Commentary Functions
    def suggest(self, fen_string: str = None, move: str = None, test: bool = False):
        if fen_string == None:
            return "Enter a valid FEN"
        
        output = self.predict(f"""{fen_string}""")
        
        # For testing purposes
        if test:
            output = move
        
        if (fen_string[0] == '{'):
            fen_string = re.findall(r'\{(.*?)\}', fen_string)[0]
            
            pattern = r"'fen_string': '(.*?)'"

            fen_string = str(re.search(pattern, fen_string).group(1))

        print(f"""Fen: {fen_string}\n""")
        
        reason = self.reason(fen_string, output)
        print(f"""\nReason: {reason}\n""")

        if reason == "incorrect position":
            return ("""Error: I do not know the answer!""", output, [])
        elif reason == "incorrect uci":
            return ("""Error: Enter a valid UCI position""", output, [])
        elif reason == [] and not(output == ""):
            return (f"""My prediction is {output} but I have no reason yet.""", output, [])
        else:
            statement = f"""My prediction of the next move is {output}. """
            list_of_tactics = []
            reason = list(dict.fromkeys(reason))
            move = self.get_move_from_str(fen_string, output)
            
            if not(move is None):
                (piece, color, from_uci, to_uci) = move

                for strategy in reason:
                        
                    if strategy == "discoveredAttack":
                        causes = self.clarify(fen_string, output, "discoveredAttack") # ex: [('rook', 'white', 'd1', 'queen', 'black', 'd8')]
                        list_of_tactics.append((strategy, causes))
                        
                        statement = statement + f"""I am using the discovery attack tactic. A discovered attack happens when a player moves one piece out of the way to reveal a previously blocked attack by another piece or when the move result in a check. """
                    
                        for index, cause in enumerate(causes):
                            (ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position) = cause
                            
                            if index == 0:
                                statement = statement + f"""{color.capitalize()} {piece} moves from {from_uci} to {to_uci} causes {ally_color} {ally_piece} at {ally_position} to be able to attack {opponent_color} {opponent_piece} at {opponent_position}. """                            
                            else:
                                statement = statement + f"""It causes {ally_color} {ally_piece} at {ally_position} to be able to attack {opponent_color} {opponent_piece} at {opponent_position}. """ 

                    elif strategy == "fork":                 
                        causes = self.clarify(fen_string, output, "fork") # ex: [('queen', 'black', 'd8'), ('rook', 'black', 'h8')]
                        list_of_tactics.append((strategy, causes))

                        statement = statement + f"""I am using the fork tactic. A fork is a tactic in which a piece attack multiple enemy pieces simultaneously. """
                        
                        length = len(causes)
                        for index, cause in enumerate(causes):
                            (opponent_piece, opponent_color, opponent_position) = cause
                            
                            if index == 0:
                                statement = statement + f"""{color.capitalize()} {piece} at {from_uci} moves to {to_uci} to attack {opponent_color} {opponent_piece} at {opponent_position}"""
                            elif index == length - 1:
                                statement = statement + f""" and {opponent_color} {opponent_piece} at {opponent_position}. """
                            else:
                                statement = statement + f""", {opponent_color} {opponent_piece} at {opponent_position}"""
                        
                    elif strategy == "skewer":
                        causes = self.clarify(fen_string, output, "skewer") # ex: [(('queen', 'black', 'f7'), ('rook', 'black', 'g8'))]
                        list_of_tactics.append((strategy, causes))

                        statement = statement + f"""I am using skewer tactic. A skewer consists of taking advantage of aligned pieces to gain material advantage or in some cases, a strategic edge against the other player. """

                        length = len(causes)
                        for index, cause in enumerate(causes):
                            (opponent_piece1, opponent_color1, opponent_position1) = cause[0]
                            (opponent_piece2, opponent_color2, opponent_position2) = cause[1]
                    
                            if index == 0:
                                statement = statement + f"""{color.capitalize()} {piece} moves from {from_uci} to {to_uci} causes {opponent_color1} {opponent_piece1} at {opponent_position1} to be skewed for {opponent_color2} {opponent_piece2} at {opponent_position2}. """
                            else:
                                statement = statement + f"""It causes {opponent_color1} {opponent_piece1} at {opponent_position1} to be skewed for {opponent_color2} {opponent_piece2} at {opponent_position2}. """

                    elif strategy == "pin":
                        causes = self.clarify(fen_string, output, "pin") # ex: [(('knight', 'white', 'f6'), ('rook', 'white', 'h8'))]
                        list_of_tactics.append((strategy, causes))

                        statement = statement + f"""I am using pin tactic. A pin is a tactic which defending piece cannot move out of an attacking piece's line of attack without exposing a more valuable defending piece. """
                                        
                        length = len(causes)
                        for index, cause in enumerate(causes):
                            (opponent_piece1, opponent_color1, opponent_position1) = cause[0]
                            (opponent_piece2, opponent_color2, opponent_position2) = cause[1]

                            if index == 0:
                                statement = statement + f"""{color.capitalize()} {piece} moves from {from_uci} to {to_uci} causes {opponent_color1} {opponent_piece1} at {opponent_position1} to be pinned for {opponent_color2} {opponent_piece2} at {opponent_position2}. """
                            else:
                                statement = statement + f"""It causes {opponent_color1} {opponent_piece1} at {opponent_position1} to be pinned for {opponent_color2} {opponent_piece2} at {opponent_position2}. """
                    
                    elif strategy == "interference":
                        causes = self.clarify(fen_string, output, "interference") # ex: [('queen', 'black', 'f4', 'king', 'black', 'f7')]
                        list_of_tactics.append((strategy, causes))

                        statement = statement + f"""I am using intereference tactic. An interference is a tactic which consists of a move that would cause the opponent pieces to not be supported by another piece. """

                        length = len(causes)
                        for index, cause in enumerate(causes):
                            (opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2) = cause
                            
                            if index == 0:
                                statement = statement + f"""{color.capitalize()} {piece} moves from {from_uci} to {to_uci} interfer {opponent_color1} {opponent_piece1} at {opponent_position1} and {opponent_color2} {opponent_piece2} at {opponent_position2} where {opponent_color1} {opponent_piece1} at {opponent_position1} defends {opponent_color2} {opponent_piece2} at {opponent_position2}. """
                            else:
                                statement = statement + f"""It interfers {opponent_color1} {opponent_piece1} at {opponent_position1} and {opponent_color2} {opponent_piece2} at {opponent_position2} where {opponent_color1} {opponent_piece1} at {opponent_position1} defends {opponent_color2} {opponent_piece2} at {opponent_position2}. """
                
                    elif strategy == "hangingPiece":
                        (opponent_piece, opponent_color, opponent_position) = self.symbolic.return_piece(to_uci)
                        list_of_tactics.append((strategy, []))
                        statement = statement + f"""I am using hanging piece attack. A hanging piece is a piece that is unprotected and can be captured. {color.capitalize()} {piece} attacks {opponent_color} {opponent_piece} by moving from {from_uci} to {to_uci}. """
                    
                    elif strategy == "mate":
                        list_of_tactics.append((strategy, []))
                        
                        if color == "white":
                            opponent_color = "black"
                        else:
                            opponent_color = "white"
                            
                        (opponent_king, opponent_king_color, opponent_king_position) = self.symbolic.return_king(opponent_color)
                        
                        statement = statement + f"""I am using mate tactic. A mate is a move that would results opponent's king in check and there is no escape. By moving {color} {piece} from {from_uci} to {to_uci} would result {opponent_king_color} {opponent_king} at {opponent_king_position} to be in checkmate. """
                    
                    elif strategy == "mateIn2":
                        causes = self.clarify(fen_string, output, "mateIn2") # ex: [(('king', 'f8', 'g8'), ('rook', 'e1', 'e8'))]
                        list_of_tactics.append((strategy, causes))

                        statement = statement + f"""I am using mateIn2 tactic. A mateIn2 is a move that would results opponent's king to be in checkmate by my next move. """
                        
                        tmp = 0
                        
                        for cause in causes:
                            (opponent_piece, opponent_current_position, opponent_next_position) = cause[0]
                            (ally_piece, ally_current_position, ally_next_position) = cause[1]
                            tmp = tmp + 1
                            
                            if color == "white":
                                opponent_color = "black"
                            else:
                                opponent_color = "white"
                                
                            if tmp > 1:
                                statement = statement + " "
                                statement = statement + f"""Or {color} {piece} moves from {from_uci} to {to_uci} causes {opponent_color} {opponent_piece} at {opponent_current_position} move to {opponent_next_position} then {color} {ally_piece} move from {ally_current_position} to {ally_next_position}. """
                            else:
                                statement = statement + f"""A scenario could be that {color} {piece} move from {from_uci} to {to_uci} causes {opponent_color} {opponent_piece} at {opponent_current_position} move to {opponent_next_position} then {color} {ally_piece} move from {ally_current_position} to {ally_next_position}. """
                
            return (statement, move, list_of_tactics)
            
    def clarify(self, fen_string, move, strategy):
        move = self.get_move_from_str(fen_string, move)
        list_of_cause = []
        
        if move == None:
            return ""
        else:
            (piece, color, from_uci, to_uci) = move 
        
            if strategy == "fork":
                list_of_cause = self.symbolic.fork_reason(piece, color, from_uci, to_uci)
                
            elif strategy == "skewer":
                list_of_cause = self.symbolic.skewer_reason(piece, color, from_uci, to_uci)
                
            elif strategy == "interference":
                list_of_cause = self.symbolic.interference_reason(piece, color, from_uci, to_uci)
                
            elif strategy == "mateIn2":
                list_of_cause = self.symbolic.mate_in_two_reason(piece, color, from_uci, to_uci)
                
            elif strategy == "pin":
                list_of_cause1 = self.symbolic.absolute_pin_reasoner(piece, color, from_uci, to_uci)
                list_of_cause2 = self.symbolic.relative_pin_reasoner(piece, color, from_uci, to_uci)
                list_of_cause = list_of_cause1 + list_of_cause2
                list_of_cause = list(dict.fromkeys(list_of_cause))

            elif strategy == "discoveredAttack":
                list_of_cause1 = self.symbolic.discovery_attack_reason(piece, color, from_uci, to_uci)
                list_of_cause2 = []
                list_of_cause = list_of_cause1 + list_of_cause2
                list_of_cause = list(dict.fromkeys(list_of_cause))
        
        return list_of_cause
        
    def give_move_description(self, fen_string = None, uci_move = None) :
        '''
        @description: give a descripion for a move with respect to its threats and developments
        '''
        if fen_string == None:
            return "Invalid FEN"
        
        if uci_move == None:
            return "Invalid UCI move"
        
        elem = self.get_move_from_str(fen_string, uci_move)
        
        if elem == None:
            return "No comment"
        else:
            
            (piece, color, from_uci, to_uci) = elem
            
            move = list(self.symbolic.prolog.query("is_legal(Piece, {color}, {from_uci}, {to_uci})"))
            
            if move == []:
                return "Invalid UCI move"
            
            commentary = f"The move of {color} {piece} from {from_uci} to {to_uci}. "
            
            self.symbolic.parse_fen(fen_string)

            # Q1: What are the allies that defend the move?
            list_of_allies_defend_move = self.symbolic.retrieve_info("move_is_defended", piece, color, from_uci, to_uci)
            
            if not(len(list_of_allies_defend_move) == 0):
                commentary = commentary + "The ally pieces that defend the move are "
            
            length = len(list_of_allies_defend_move)
            for index, item in enumerate(list_of_allies_defend_move):
                (ally_piece, ally_color, ally_position) = item
                if index == length - 1:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position}."
                elif index == length - 2:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position} and "
                else:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position}, "
            
            # Q2: What are the opponents that attack the move?
            list_opponent_attack_move = self.symbolic.retrieve_info("moves_is_attacked", piece, color, from_uci, to_uci)
            
            if not(len(list_opponent_attack_move) == 0):
                commentary = commentary + "The opponent pieces that attacks the move are "
            
            length = len(list_opponent_attack_move)
            for index, item in enumerate(list_opponent_attack_move):
                (opponent_piece, opponent_color, opponent_position) = item
                if index == length - 1:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position}."
                elif index == length - 2:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position} and "
                else:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position}, "
                        
            # Q3: What are the allies that are defended by the move
            list_allies_defend_by_move = self.symbolic.retrieve_info("moves_defends", piece, color, from_uci, to_uci)
            
            if not(len(list_allies_defend_by_move) == 0):
                commentary = commentary + "The ally pieces that are defended by the move are "
            
            length = len(list_allies_defend_by_move)
            for index, item in enumerate(list_allies_defend_by_move):
                (ally_piece, ally_color, ally_position) = item
                if index == length - 1:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position}."
                elif index == length - 2:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position} and "
                else:
                    commentary = commentary + f"{ally_color} {ally_piece} at {ally_position}, "
                                    
            # Q4: What are the opponents attacked by the move?
            list_opponent_attacked_by_move = self.symbolic.retrieve_info("moves_threat", piece, color, from_uci, to_uci)

            if not(len(list_opponent_attacked_by_move) == 0):
                commentary = commentary + "The opponent pieces that are attacked by the move are "
            
            length = len(list_opponent_attacked_by_move)
            for index, item in enumerate(list_opponent_attacked_by_move):
                (opponent_piece, opponent_color, opponent_position) = item
                if index == length - 1:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position}."
                elif index == length - 2:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position} and "
                else:
                    commentary = commentary + f"{opponent_color} {opponent_piece} at {opponent_position}, "
                                
            # Q5: What are the counter attacks by the opponents with respect to the move?
            list_of_moves = self.symbolic.move_counter_attack(color)
            filtered_list_of_moves = []
            
            for item in list_of_moves:
                (ally_piece, ally_color, ally_from_uci_position, ally_to_uci_position) = item[0]
                (opponent_piece, opponent_color, opponent_from_uci_position, opponent_to_uci_position) = item[1]
                
                if ally_piece == piece and ally_color == color and ally_from_uci_position == from_uci and ally_to_uci_position == to_uci:
                    filtered_list_of_moves.append(item)
                    
            if not(len(filtered_list_of_moves) == 0):
                if len(filtered_list_of_moves) == 1:
                    commentary = commentary + f"The counter attack that can be done by {opponent_color} is "
                else:
                    commentary = commentary + f"The counter attacks that can be done by {opponent_color} are "
                    
            length = len(filtered_list_of_moves)
                
            for index, item in enumerate(filtered_list_of_moves):
                (opponent_piece, opponent_color, opponent_from_uci_move, opponent_to_uci_move) = item[1]
                
                if index == length - 1:
                    commentary = commentary + f"{opponent_color} {opponent_piece} from {opponent_from_uci_move} to {opponent_to_uci_move}."
                elif index == length - 2:
                    commentary = commentary + f"{opponent_color} {opponent_piece} from {opponent_from_uci_move} to {opponent_to_uci_move} and "
                else:
                    commentary = commentary + f"{opponent_color} {opponent_piece} from {opponent_from_uci_move} to {opponent_to_uci_move}, "
                
            print(commentary)
            
            # Q6: What tactics does the move follow?
            # TODO
            
            # Q7: Does the move enhance king safety?
            # TODO
            
            # Q8: Does the move enhance pawn structure?
            # TODO
            
            # Q9: Does the move gives material advantage?
            # TODO
            
            # Q10: Does the move develop a piece?
            # TODO
    
            return commentary
        
    def give_move_comparison(self, fen_string, uci_move1, uci_move2):
        '''
        Compare two moves based on their impact and state.
        '''
        commentary1 = self.give_move_description(fen_string, uci_move1)
        commentary2 = self.give_move_description(fen_string, uci_move2)
        
        final_commentary = f"For the first move, {commentary1}" + "While for the second move, {commentary2}"
        
        return final_commentary
    
    def chat(self, fen_string):
        '''
        Suggest a move with its respect tactic.
        '''
        response = self.suggest(fen_string)
        return response[0]
    
    def run_test(self, csv_path, fen_string, best_move, predicted_move, theme):
        '''
        Testing Function
        '''
        reason = self.suggest(fen_string, best_move, True)
        statement = reason[0]
        list_of_tactics = []
        
        for item in reason[2]:
            list_of_tactics.append(item[0])
            
        # print(bcolors.OKGREEN + statement + bcolors.ENDC)
        row = [[fen_string, best_move, predicted_move, theme, list_of_tactics, statement]]
        with open(csv_path, 'a') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerows(row)