from crypt import methods
from os.path import join, dirname
from dotenv import load_dotenv
from pyswip import Prolog
from neo4j import GraphDatabase
import chess
import streamlit as st

# Load environment variables
dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

URI = st.secrets["NEO4J_URI"]
USER = st.secrets["NEO4J_USERNAME"]
PASSWORD = st.secrets["NEO4J_PASSWORD"]

class Symbolic():
    
    def __init__(self):
        self.board = chess.Board()
        self.prolog = Prolog()
        self.graph = InferenceGraph(URI, USER, PASSWORD)
    
    def consult(self, filepath):
        self.filepath = filepath
        self.prolog.consult(filepath)
    
    def parse_fen(self, fen_string):
        query = None
        self.fen_string = fen_string
        try:
            query = self.prolog.query(f"""parse_fen("{fen_string}")""")
            result = list(query)
            return result
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if query is not None:
                query.close()
        
    def display_board_gui(self):
        return self.board

    def display_board_cli(self):
        try:
            query = self.prolog.query(f"""display_board""")
            result = list(query)
            return result
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def construct_graph(self):
        query1 = None
        query2 = None
        try:
            self.destruct_graph()
            
            query1 = self.prolog.query("return_pieces(Piece, Color, Position)")
            pieces = list(query1)
            query2 = self.prolog.query("return_squares(Position)")
            squares = list(query2)
            
            for piece in pieces:
                self.graph.create_piece(piece['Piece'], piece['Color'], piece['Position'])
            
            for square in squares:
                self.graph.create_square(square['Position'])
                
            for piece in pieces:
                self.graph.create_locate(piece['Piece'], piece['Color'], piece['Position'])  
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if query1 is not None:
                query1.close()
            if query2 is not None:
                query2.close()
            
    def reason(self, piece, color, from_position, to_position):
        return self.graph.fetch_suggest(piece, color, from_position, to_position)
        
    def destruct_graph(self):
        self.graph.destroy()
    
    # Tactics
    def discover_attack(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""discover_attack({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            self.add_strategy(player, result, "discoveredAttack")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()

    def discovery_attack_reason(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""discovered_attack_reason({piece}, {color}, {current_position}, {next_position}, ListOfOpponents) """)
            result = list(query)
        
            if result == []:
                return None
            
            output = result[0]['ListOfOpponents']
            
            list_of_discoveries = []
            
            for item in output:
                ally_piece = item[0]
                ally_color = item[1]
                ally_position = item[2]
                
                opponent_piece = item[3]
                opponent_color = item[4]
                opponent_position = item[5]
                
                discovery_attack_tuple = (ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position)
                list_of_discoveries.append(discovery_attack_tuple)
                
            return list_of_discoveries
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def create_discovery_attack_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""discover_attack({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item['Piece']
                position = item['UCIPosition']
                for move in item['ListOfMoves']:
                    list_of_discoveries = self.discovery_attack_reason(piece, player, position, move)
                    
                    for (ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position) in list_of_discoveries:
                        self.graph.create_discovery_attack_relation(piece, player, position, move, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def skewer(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""move_cause_skewer({player}, Piece, UCIPosition, ListOfMoves) """)
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                
                for move in list_of_moves:
                    self.graph.create_suggest(piece, player, position, move, "skewer")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def skewer_reason(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""skewed_reason({piece}, {color}, {current_position}, {next_position}, ListOfSkews)""")
            result = list(query)
        
            if result == []:
                return None
            
            output = result[0]['ListOfSkews']
            
            list_of_elements = []
            
            for item in output:
                opponent_piece1 = item[0]
                opponent_color1 = item[1]
                opponent_position1 = item[2]
                opponent_piece2 = item[3]
                opponent_color2 = item[4]
                opponent_position2 = item[5]
                
                opponent1 = (opponent_piece1, opponent_color1, opponent_position1)
                opponent2 = (opponent_piece2, opponent_color2, opponent_position2)
                
                skewed_tuple = (opponent1, opponent2)
                list_of_elements.append(skewed_tuple)
            
            return list_of_elements
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def create_skewer_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""move_cause_skewer({player}, Piece, UCIPosition, ListOfMoves) """)
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                
                for move in list_of_moves:
                    list_of_opponents = self.skewer_reason(piece, player, position, move)
                    
                    for (opponent1, opponent2) in list_of_opponents:
                        (opponent_piece1, opponent_color1, opponent_position1) = opponent1
                        (opponent_piece2, opponent_color2, opponent_position2) = opponent2
                        self.graph.create_skewer_relation(piece, player, position, move, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
                
    def fork(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""move_cause_fork({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                
                for move in list_of_moves:
                    self.graph.create_suggest(piece, player, position, move, "fork")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()

    def fork_reason(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""fork_reason({piece}, {color}, {current_position}, {next_position}, ListOfOpponents)""")
            result = list(query)
        
            if result == []:
                return None
            
            output = result[0]['ListOfOpponents']
            list_opponents = []
            
            for item in output:
                cleaned_output = item.strip(',()').split(", ,(")
                opponent_piece = cleaned_output[0]
                opponent_color = cleaned_output[1].split(", ")[0]
                opponent_position = cleaned_output[1].split(", ")[1]
                opponent = (opponent_piece, opponent_color, opponent_position)
                list_opponents.append(opponent)
                
            return list_opponents
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def create_fork_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""move_cause_fork({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                
                for move in list_of_moves:
                    list_of_opponents = self.fork_reason(piece, player, position, move)
                    
                    for (opponent_piece, opponent_color, opponent_position) in list_of_opponents:
                        self.graph.create_fork_relation(piece, player, position, move, opponent_piece, opponent_color, opponent_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()

    def absolute_pin(self, player):
        query1 = None
        query2 = None
        query3 = None
        
        try:
            query1 = self.prolog.query(f"""absolute_pin({player}, Piece, UCIPosition)""")
            result1 = list(query1)
            query2 = self.prolog.query(f"""return_pieces(king, {player}, KingUCIPosition)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            if not(result2 == [] or result1 == []):
                king_position = result2[0]['KingUCIPosition']
                
                for item in result1:
                    piece = item['Piece']
                    position = item['UCIPosition']
                    self.graph.create_suggest(piece, player, position, king_position, "absolute_pinned")
            
            try:
                query3 = self.prolog.query(f"""move_cause_absolute_pin({player}, Piece, UCIPosition, ListOfMoves)""")
                result3 = list(query3)
                
                for item in result3:
                    piece = item["Piece"]
                    position = item["UCIPosition"]
                    list_of_moves = item["ListOfMoves"]
                    
                    for move in list_of_moves:
                        self.graph.create_suggest(piece, player, position, move, "pin")
            finally:
                if not(query3 == None):
                    query3.close()
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query1 == None):
                query1.close()
                
            if not(query2 == None):
                query2.close()
    
    def absolute_pin_reasoner(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""absolute_pin_reason({piece}, {color}, {current_position}, {next_position}, ListOfPins)""")
            result = list(query)
            
            if result == []:
                return []
            
            output = result[0]['ListOfPins']
            
            list_of_pins = []
            
            for item in output:
                opponent_piece1 = item[0]
                opponent_color1 = item[1]
                opponent_position1 = item[2]
                opponent_piece2 = item[3]
                opponent_color2 = item[4]
                opponent_position2 = item[5]
                
                opponent1 = (opponent_piece1, opponent_color1, opponent_position1)
                opponent2 = (opponent_piece2, opponent_color2, opponent_position2)
                pin_tuple = (opponent1, opponent2)
                list_of_pins.append(pin_tuple)
                
            return list_of_pins
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def create_absolute_pin_relation(self, player):
        query1 = None
        query2 = None
        query3 = None
        
        try:
            query1 = self.prolog.query(f"""absolute_pin({player}, Piece, UCIPosition)""")
            result1 = list(query1)
            query2 = self.prolog.query(f"""return_pieces(king, {player}, KingUCIPosition)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            if not(result2 == [] or result1 == []):
                king_position = result2[0]['KingUCIPosition']
                
                for item in result1:
                    piece = item['Piece']
                    position = item['UCIPosition']
                    self.graph.create_suggest(piece, player, position, king_position, "absolute_pinned")
            
            try:
                query3 = self.prolog.query(f"""move_cause_absolute_pin({player}, Piece, UCIPosition, ListOfMoves)""")
                result3 = list(query3)
                
                for item in result3:
                    piece = item["Piece"]
                    position = item["UCIPosition"]
                    list_of_moves = item["ListOfMoves"]
                    
                    for move in list_of_moves:
                        list_of_pins = self.absolute_pin_reasoner(piece, player, position, move)
                        
                        for (opponent1, opponent2) in list_of_pins:
                            (opponent_piece1, opponent_color1, opponent_position1) = opponent1
                            (opponent_piece2, opponent_color2, opponent_position2) = opponent2

                            self.graph.create_absolute_pin_relation(piece, player, position, move, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
            finally:
                if not(query3 == None):
                    query3.close()
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query1 == None):
                query1.close()
                
            if not(query2 == None):
                query2.close()
            
    def relative_pin(self, player):
        query1 = None
        quert2 = None
        
        try:
            query1 = self.prolog.query(f"""relative_pin({player}, Piece, UCIPosition, ListOfMoves)""")
            result1 = list(query1)
            query2 = self.prolog.query(f"""move_cause_relative_pin({player}, Piece, UCIPosition, ListOfMoves)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            self.add_strategy(player, result1, "relative_pinned")
            
            for item in result2:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                for move in list_of_moves:
                    self.graph.create_suggest(piece, player, position, move, "pin")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if query1 != None: 
                query1.close()
            if query2 != None:
                query2.close()
    
    def relative_pin_reasoner(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""relative_pin_reason({piece}, {color}, {current_position}, {next_position}, ListOfPins)""")
            result = list(query)
            
            if result == []:
                return None
            
            output = result[0]['ListOfPins']
            
            list_of_pins = []
            
            for item in output:
                opponent_piece1 = item[0]
                opponent_color1 = item[1]
                opponent_position1 = item[2]
                opponent_piece2 = item[3]
                opponent_color2 = item[4]
                opponent_position2 = item[5]
                
                opponent1 = (opponent_piece1, opponent_color1, opponent_position1)
                opponent2 = (opponent_piece2, opponent_color2, opponent_position2)
                pin_tuple = (opponent1, opponent2)
                list_of_pins.append(pin_tuple)
                
            return list_of_pins
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def create_relative_pin_relation(self, player):
        query1 = None
        query2 = None
        
        try:
            query1 = self.prolog.query(f"""relative_pin({player}, Piece, UCIPosition, ListOfMoves)""")
            result1 = list(query1)
            query2 = self.prolog.query(f"""move_cause_relative_pin({player}, Piece, UCIPosition, ListOfMoves)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            self.add_strategy(player, result1, "relative_pinned")
            
            for item in result2:
                piece = item["Piece"]
                position = item["UCIPosition"]
                list_of_moves = item["ListOfMoves"]
                for move in list_of_moves:
                    list_of_pins = self.relative_pin_reasoner(piece, player, position, move)

                    for (opponent1, opponent2) in list_of_pins:
                        (opponent_piece1, opponent_color1, opponent_position1) = opponent1
                        (opponent_piece2, opponent_color2, opponent_position2) = opponent2
                        self.graph.create_relative_pin_relation(piece, player, position, move, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query1 == None):
                query1.close()
                
            if not(query2 == None):
                query2.close()
    
    def discovery_check(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""discover_check({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            self.add_strategy(player, result, "discoveredAttack")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def discovery_check_reason(self, piece, color, from_uci, to_uci):
        query1 = None
        query2 = None
        
        try:
            query1 = self.prolog.query(f"""discovered_check_reason({piece}, {color}, {from_uci}, {to_uci}, ListOfMoves)""")
            result1 = list(query1)
            
            if color == "black":
                opponent_color = "white"
            else:
                opponent_color = "black"
                
            query2 = self.prolog.query(f"""return_pieces(king, {opponent_color}, KingUCIPosition)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            output = result1[0]['ListOfMoves']
            king_position = result2[0]['KingUCIPosition']
            list_of_attacks = []
            
            for item in output:
                ally_piece = item[0]
                ally_color = item[1]
                ally_position = item[2]
                discovery_check_tuple = (ally_piece, ally_color, ally_position, "king", opponent_color, king_position)
                list_of_attacks.append(discovery_check_tuple)
                
            return list_of_attacks
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query1 == None):
                query1.close()
                
            if not(query2 == None):
                query2.close()
    
    def create_discovery_check_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""discover_check({player}, Piece, UCIPosition, ListOfMoves)""")
            result = list(query)
            
            for item in result:
                piece = item['Piece']
                position = item['UCIPosition']
                
                for move in item['ListOfMoves']:
                    list_of_attacks = self.discovery_check_reason(piece, player, position, move)

                    for (ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position) in list_of_attacks:
                        self.graph.create_discovery_check_relation(piece, player, position, move, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
        
    def interference(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""interference({player}, Piece, Position, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2).""")
            result = list(query)
        
            if result == []:
                return None
        
            for item in result:
                piece = item['Piece']
                position = item['Position']
                next_position = item['NextUCIPosition']
                opponent_piece1 = item['OpponentPiece1']
                opponent_color1 = item['OpponentColor1']
                opponent_position1 = item['OpponentPosition1']
                opponent_piece2 = item['OpponentPiece2']
                opponent_color2 = item['OpponentColor2']
                opponent_position2 = item['OpponentPosition2']
                self.graph.create_suggest(piece, player, position, next_position, "interference")
                self.graph.add_property_interference(piece, player, position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
        
    def interference_reason(self, piece, color, current_position, next_position):
        query = None
        
        try:          
            query = list(self.prolog.query(f"""interference({color}, {piece}, {current_position}, {next_position}, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2)"""))
            result = list(query)

            if result == []:
                return None

            list_of_interferences = []
            
            for item in result:
                opponent_piece1 = item['OpponentPiece1']
                opponent_color1 = item['OpponentColor1']
                opponent_position1 = item['OpponentPosition1']
                
                opponent_piece2 = item['OpponentPiece2']
                opponent_color2 = item['OpponentColor2']
                opponent_position2 = item['OpponentPosition2']
                
                list_of_interferences.append((opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2))
            
            return list_of_interferences
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def create_interference_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""interference({player}, Piece, Position, NextUCIPosition, OpponentPiece1, OpponentColor1, OpponentPosition1, OpponentPiece2, OpponentColor2, OpponentPosition2).""")
            result = list(query)
        
            if result == []:
                return None
        
            for item in result:
                piece = item['Piece']
                position = item['Position']
                next_position = item['NextUCIPosition']
                opponent_piece1 = item['OpponentPiece1']
                opponent_color1 = item['OpponentColor1']
                opponent_position1 = item['OpponentPosition1']
                opponent_piece2 = item['OpponentPiece2']
                opponent_color2 = item['OpponentColor2']
                opponent_position2 = item['OpponentPosition2']
                self.graph.create_interference_relation(piece, player, position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def mate_in_two(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""moves_cause_mate_in_two({player}, Piece, Position, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item['Piece']
                position = item['Position']
                list_of_moves = item['ListOfMoves']
                
                for move in list_of_moves:
                    self.graph.create_suggest(piece, player, position, move, "mateIn2")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
                
    def mate_in_two_reason(self, piece, color, current_position, next_position):
        query = None
        
        try:
            query = self.prolog.query(f"""mate_in_2_reason({piece}, {color}, {current_position}, {next_position}, Reason)""")
            result = list(query)
            
            if result == []:
                return None
            
            output = result[0]['Reason']
            
            list_of_cause = []
            
            for item in output:
                opponent_piece = item[0]
                opponent_current_position = item[1]
                list_of_opponent_moves = item[2]
                
                for opponent_move in list_of_opponent_moves:
                    opponent_next_position = opponent_move[0]
                    list_of_ally_moves = opponent_move[1]
                    
                    for ally_move in list_of_ally_moves:
                        ally_piece = ally_move[0]
                        ally_current_position = ally_move[1]
                        ally_next_position = ally_move[2][0]
                        
                        cause = ((opponent_piece, opponent_current_position, opponent_next_position), (ally_piece, ally_current_position, ally_next_position))
                        list_of_cause.append(cause)
                        
            return list_of_cause
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def create_mate_in_two_relation(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""moves_cause_mate_in_two({player}, Piece, Position, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item['Piece']
                position = item['Position']
                list_of_moves = item['ListOfMoves']
                
                for move in list_of_moves:
                    list_of_cause = self.mate_in_two_reason(piece, player, position, move)
                    
                    for (opponent, ally) in list_of_cause:
                        opponent_color = None
                        ally_color = None
                        
                        if (player == "white"):
                            opponent_color = "black"
                            ally_color = "white"
                        else:
                            opponent_color = "white"
                            ally_color = "black"
                            
                        (opponent_piece, opponent_current_position, opponent_next_position) = opponent
                        (ally_piece, ally_current_position, ally_next_position) = ally

                        self.graph.create_mate_in_two_relation(piece, player, position, move, opponent_piece, opponent_color, opponent_current_position, opponent_next_position, ally_piece, ally_color, ally_current_position, ally_next_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
    
    def hanging_piece(self, player):
        query = None
        
        try:            
            query = self.prolog.query(f"""hanging_piece({player}, Piece, UCIPosition, OpponentPiece, OpponentColor, OpponentUCIPosition)""")
            result = list(query)
            
            if result == []:
                return None
            
            for item in result:
                piece = item['Piece']
                position = item['UCIPosition']
                opponent_piece = item['OpponentPiece']
                opponent_color = item['OpponentColor']
                opponent_position = item['OpponentUCIPosition']
                self.graph.create_suggest(piece, player, position, opponent_position, "hangingPiece")
                self.graph.create_hanging_piece_relation(piece, player, position, opponent_position, opponent_piece, opponent_color, opponent_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
            
    def mate(self, player):
        query = None
        
        try:
            query = self.prolog.query(f"""mate({player}, Piece, UCIPosition, ListOfListMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            opponent_color = None
                    
            if (player == "white"):
                opponent_color = "black"
            else:
                opponent_color = "white"
            
            (_, _, opponent_position) = self.return_king(opponent_color)
                    
            for item in result:
                piece = item['Piece']
                position = item['UCIPosition']
                list_of_moves =   list(item['ListOfListMoves'])
                
                for move in list_of_moves:
                    self.graph.create_suggest(piece, player, position, move, "mate")
                    self.graph.create_mate_in_one_relation(piece, player, position, move, "king", opponent_color, opponent_position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if not(query == None):
                query.close()
                
    # Evaluation
    def retrieve_info(self, predicate, piece, color, from_uci, to_uci):
        try:
            query = self.prolog.query(f"""{predicate}({color}, ListOfMoves)""")
            result = list(query)
            
            if result == []:
                return None
            
            output = result[0]['ListOfMoves']
            
            list_info = []
            
            for item in output:
                if piece == item[0] and color == item[1] and from_uci == item[2] and to_uci == item[3]:
                    for elem in item[4]:
                        impacted_piece = elem[0]
                        impacted_piece_color = elem[1]
                        impacted_piece_position = elem[2]
                        
                        list_info.append((impacted_piece, impacted_piece_color, impacted_piece_position))
            
            return list_info            
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def move_counter_attack(self, player):
        try:
            query = list(self.prolog.query(f"""move_counter({player}, ListOfMoves)"""))
        
            if query == []:
                return None
            
            output = query[0]['ListOfMoves']
            
            list_of_counter_attacked_moves = []
            
            for item in output:
                for moves in item:
                    list_of_moves = []
                    for move in moves:
                        piece = move[0]
                        color = move[1]
                        from_uci = move[2]
                        to_uci = move[3]
                        
                        list_of_moves.append((piece, color, from_uci, to_uci))
                    
                    list_of_counter_attacked_moves.append(list_of_moves)
            
            return list_of_counter_attacked_moves
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def move_threat(self, player):
        try:
            query = self.prolog.query(f"""moves_threat({player}, ListOfMoves)""")
            result = list(query)
        
            if result == []:
                return []
            
            output = result[0]['ListOfMoves']
            
            for item in output:
                piece = item[0]
                color = item[1]
                from_uci = item[2]
                to_uci = item[3]
                            
                for opponent in item[4]:
                    opponent_piece = opponent[0]
                    opponent_color = opponent[1]
                    opponent_position = opponent[2]
                    
                    self.graph.create_feature(piece, color, from_uci, to_uci, opponent_piece, opponent_color, opponent_position, "move_threat")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
                
    def move_defend(self, player):
        try:
            query = self.prolog.query(f"""moves_defends({player}, ListOfMoves)""")
            result = list(query)
        
            if result == []:
                return None
        
            output = result[0]['ListOfMoves']
        
            for item in output:
                piece = item[0]
                color = item[1]
                from_uci = item[2]
                to_uci = item[3]
                
                for ally in item[4]:
                    ally_piece = ally[0]
                    ally_color = ally[1]
                    ally_position = ally[2]
                    
                    self.graph.create_feature(piece, color, from_uci, to_uci, ally_piece, ally_color, ally_position, "move_defend")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()         
   
    def protected_move(self, player):
        try:
            query = self.prolog.query(f"""move_is_defended({player}, ListOfMoves)""")
            result = list(query)
        
            if result == []:
                return None
            
            output = result[0]['ListOfMoves']
            
            for item in output:
                piece = item[0]
                color = item[1]
                from_uci = item[2]
                to_uci = item[3]
                
                for ally in item[4]:
                    ally_piece = ally[0]
                    ally_color = ally[1]
                    ally_position = ally[2]
                    
                    self.graph.create_feature(piece, color, from_uci, to_uci, ally_piece, ally_color, ally_position, "move_is_protected")
                    
        except Exception as e:
            print(f"Error during Prolog query: {e}")            
        finally:
            query.close()

    def attackted_move(self, player):
        try:
            query = self.prolog.query(f"""moves_is_attacked({player}, ListOfMoves)""")
            result = list(query)
        
            if result == []:
                return None
        
            output = result[0]['ListOfMoves']
        
            for item in output:
                piece = item[0]
                color = item[1]
                from_uci = item[2]
                to_uci = item[3]
                
                for opponent in item[4]:
                    opponent_piece = opponent[0]
                    opponent_color = opponent[1]
                    opponent_position = opponent[2]
                    
                    self.graph.create_feature(piece, color, from_uci, to_uci, opponent_piece, opponent_color, opponent_position, "move_is_attacked")
                
        except Exception as e:
            print(f"Error during Prolog query: {e}")            
        finally:
            query.close()
 
    def defend(self, player):
        '''
        Update the knowledge graph for ally chess pieces that defend ally chess pieces directly.
        
        :param: :player: color of the current player
        '''
        try:
            query = self.prolog.query(f"""protect(Piece, {player}, Position, AllyPiece, AllyPosition)""")
            result = list(query)
        
            if result == []:
                return None
            
            for item in result:
                piece = item['Piece']
                position = item['Position']
                ally_piece = item['AllyPiece']
                ally_position = item['AllyPosition']
                self.graph.create_suggest(piece, player, position, ally_position, "defend")
        except Exception as e:
            print(f"Error during Prolog query: {e}")            
        finally:
            query.close()
            
    def threat(self, player):
        '''
        Update the knowledge graph for ally chess pieces that threat opponent chess pieces directly.
        
        :param: :player: color of the current player
        '''
        try:
            query = self.prolog.query(f"""all_threat({player}, ListOfThreats)""")
            result = list(query)

            if result == []:
                return None
                  
            output = result[0]['ListOfThreats']
        
            for item in output:
                piece = item[0]
                color = item[1]
                position = item[2]
                
                opponent_piece = item[3]
                opponent_color = item[4]
                opponent_position = item[5]
                
                self.graph.create_suggest(piece, player, position, opponent_position, "threat")

        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
        
    
    def legal_moves(self, piece, color, position):
        '''
        Returns the legal moves of a chess piece.
        '''
        try:
            query = self.prolog.query(f"""get_legal_moves({piece}, {color}, {position}, Result)""")
            result = list(query)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
        
        list_of_moves = []
        
        for move in result:
            list_of_moves.append(move['Result'])
        
        return list_of_moves
    
    def get_board(self):
        '''
        Get 2D representation of the chessboard.
        '''
        query = None
        try:
            query = self.prolog.query(f"""occupies(Piece, Color, Position)""")
            list(self.prolog.query(f"""display_board"""))
            result = list(query)
            board = [[' '] * 8 for _ in range(8)]
            color = None
            piece = None
            
            for elem in result:                
                if elem['Color'] == 'white':
                    color = 'w'
                else:
                    color = 'b'
                    
                if elem['Piece'] == 'king':
                    piece = 'k'
                elif elem['Piece'] == 'rook':
                    piece = 'r'
                elif elem['Piece'] == 'queen':
                    piece = 'q'
                elif elem['Piece'] == 'pawn':
                    piece = 'p'
                elif elem['Piece'] == 'knight':
                    piece = 'n'
                elif elem['Piece'] == 'bishop':
                    piece = 'b'
                    
                position = tuple(map(int, elem['Position'][1:].strip('()').split(', ')))
                
                if elem['Piece'] == 'none':
                    board[position[1] - 1][position[0] - 1] = ' '
                else:
                    board[position[1] - 1][position[0] - 1] = color + piece
            
            return board
            
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            if query is not None:
                query.close()
    
    def make_move(self, piece, color, from_position, to_position):
        '''
        Move a piece from position to another.
        '''
        try:
            query = self.prolog.query(f"""make_move({piece}, {color}, {from_position}, {to_position})""")
            result = list(query) # execute prolog query
            list(self.prolog.query(f"""display_board"""))
            return result, self.get_board()
        except Exception as e:
            print(f"Error during Prolog query: {e}")
            return None, None
        finally:
            query.close()
    
    def update_board(self, fen_string):
        '''
        Updates the state of the board.
        :param: :fen_string: forsyth-edwards notation string.
        '''
        self.board = chess.Board(fen_string)
        return self.parse_fen(fen_string)
        
    def return_piece(self, position):
        try:
            query = self.prolog.query(f"""return_pieces(Piece, Color, {position})""")
            result = list(query)
            
            if result == []:
                return None
            
            piece = result[0]['Piece']
            color = result[0]['Color']
            
            return (piece, color, position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def return_king(self, color):
        try:
            query = self.prolog.query(f"""return_pieces({"king"}, {color}, Position)""")
            result = list(query)
            
            if result == []:
                return None
                    
            position = result[0]['Position']
            
            return ("king", color, position)
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def evaluate_king_safety(self, player):
        try:
            query1 = self.prolog.query(f"""king_safety({player}, CheckSquareList, SupportSquareList, ControlledSquareList)""")
            result1 = list(query1)
            query2 = self.prolog.query(f"""return_pieces(king, {player}, KingUCIPosition)""")
            result2 = list(query2)
            
            if result1 == [] or result2 == []:
                return None
            
            king_position = result2[0]['KingUCIPosition']
            
            check_square_tmp = result1[0]['CheckSquareList']
            check_square_list = []
            for item in check_square_tmp:
                position = self.convert_string_to_tuple(item)
                check_square_list.append(position)
            
            support_square_tmp = result1[0]['SupportSquareList']
            support_square_list = []
            for item in support_square_tmp:
                position = self.convert_string_to_tuple(item)
                support_square_list.append(position)
            
            controlled_square_tmp = result1[0]['ControlledSquareList']
            controlled_square_list = []
            for item in controlled_square_tmp:
                position = self.convert_string_to_tuple(item)
                controlled_square_list.append(position)
                
            check_square_len = len(check_square_list)
            support_square_len = len(support_square_list)
            controlled_square_len = len(controlled_square_list)
            
            king_node_props = self.graph.fetch_props("king", player, king_position)
            
            if (check_square_len > support_square_len + controlled_square_len) or (controlled_square_len == 1):
                if "props" in king_node_props[0] and "safe" in king_node_props[0]['props']:
                    self.graph.remove_property("king", player, king_position, "safe")    
        
                if "props" in king_node_props[0] and "unsafe" not in king_node_props[0]['props']:
                    self.graph.add_property("king", player, king_position, "unsafe")
            else:
                if "props" in king_node_props[0] and "unsafe" in king_node_props[0]['props']:
                    self.graph.remove_property("king", player, king_position, "unsafe") 
                
                if "props" in king_node_props[0] and "safe" not in king_node_props[0]['props']:
                    self.graph.add_property("king", player, king_position, "safe")
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query1.close()
            query2.close(0)
    
    def add_strategy(self, player, query, strategy):
        moves = {}
        
        for move in query:
            piece = move['Piece']
            current_position = move['UCIPosition']
            list_of_moves = move['ListOfMoves']
        
            for next_position in list_of_moves:
                action = (piece, player, current_position)
                if not(next_position in moves.keys()):
                    moves[next_position] = [action]
                else:
                    moves[next_position] = moves[next_position] + [action]
               
        for to_uci, item in moves.items():
            for piece in item:
                (piece_name, piece_color, from_uci) = piece
                self.graph.create_suggest(piece_name, piece_color, from_uci, to_uci, strategy)
            
        return moves
    
    # Verification
    def verify_position(self, piece, color, position):
        try:
            query = self.prolog.query(f"""verify_position({piece}, {"Color" if color == "N/A" else color}, {"Position" if position == "N/A" else position})""")
            result = list(query)
            
            return result
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()
    
    def verify_relation(self, piece1, color1, position1, piece2, color2, position2, relation):
        try:
            query = self.prolog.query(f"""verify_relation({piece1}, {"Color1" if color1 == "N/A" else color1}, {"Position1" if position1 == "N/A" else position1}, {"Piece2" if piece2 == "N/A" else piece2}, {"Color2" if color2 == "N/A" else color2}, {"Position2" if position2 == "N/A" else position2}, {relation})""")
            result = list(query)

            return result
        except Exception as e:
            print(f"Error during Prolog query: {e}")
        finally:
            query.close()        
        
    # Utilities
    @staticmethod
    def convert_string_to_tuple(input_str):
        cleaned_str = input_str.strip(',()')
        str_list = cleaned_str.split(', ')
        
        int_list = [int(i) for i in str_list]
        result_tuple = tuple(int_list)
        
        return result_tuple
        
    
class InferenceGraph:
    
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
        
    def close(self):
        self.driver.close()
        
    def create_piece(self, piece, color, position):
        with self.driver.session() as session:
            session.execute_write(self.create_piece_node, piece, color, position)
            
    def create_square(self, position):
        with self.driver.session() as session:
            session.execute_write(self.create_square_node, position)
            
    def create_locate(self, piece, color, position):
        with self.driver.session() as session:
            session.execute_write(self.create_locate_relation, piece, color, position)
            
    def create_suggest(self, piece, color, from_position, to_position, strategy):
        with self.driver.session() as session:
            session.execute_write(self.create_suggest_relation, piece, color, from_position, to_position, strategy)
            
    def create_feature(self, piece, color, from_position, to_position, impacted_piece, impacted_piece_color, impacted_piece_position, feature):
        with self.driver.session() as session:
            session.execute_write(self.create_feature_relation, piece, color, from_position, to_position, impacted_piece, impacted_piece_color, impacted_piece_position, feature)
    
    def build_feature(self, piece, color, from_position, to_position, feature):
        with self.driver.session() as session:
            session.execute_write(self.build_feature_relation, piece, color, from_position, to_position, feature)
            
    def add_property(self, piece, color, position, prop):
        with self.driver.session() as session:
            session.execute_write(self.add_property_node, piece, color, position, prop)
            
    def remove_property(self, piece, color, position, prop):
        with self.driver.session() as session:
            session.execute_write(self.remove_property, piece, color, position, prop)
            
    def destroy(self):
        with self.driver.session() as session:
            session.execute_write(self.delete_all_nodes)
            
    def fetch_suggest(self, piece, color, from_position, to_position):
        with self.driver.session() as session:
            result = session.execute_read(self.fetch_suggest_relation, piece, color, from_position, to_position)
            return result
    
    def fetch_props(self, piece, color, position):
        with self.driver.session() as session:
            result = session.execute_read(self.fetch_props_node, piece, color, position)
            return result
        
    def add_property_interference(self, piece, color, position, next_position, opponent_piece1, opponent_color1, opponent_position1,  opponent_piece2, opponent_color2, opponent_position2):
        with self.driver.session() as session:
            result = session.execute_write(self.add_property_relation_interference, piece, color, position, next_position, opponent_piece1, opponent_color1, opponent_position1,  opponent_piece2, opponent_color2, opponent_position2)

    def verify_move_feature(self, piece1, color1, position1, piece2, color2, position2, move, feature):
        with self.driver.session() as session:
            result = session.execute_read(self.verify_move_feature_relation, piece1, color1, position1, piece2, color2, position2, move, feature)
            return result
        
    def find_moves(self, feature):
        with self.driver.session() as session:
            result = session.execute_read(self.find_move_feature_relation, feature)
            return result
        
    def verify_move_feature_missing_param(self, feature):
        with self.driver.session() as session:
            result = session.execute_read(self.verify_move_feature_relation_missing_param, feature)
            return result
        
    def create_discovery_attack_relation(self, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_discovery_attack, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position)
    
    def create_skewer_relation(self, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        with self.driver.session() as session:
            result = session.execute_write(self.create_skewer, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
        
    def create_fork_relation(self, piece, color, position, move, opponent_piece, opponent_color, opponent_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_fork, piece, color, position, move, opponent_piece, opponent_color, opponent_position)
    
    def create_absolute_pin_relation(self, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        with self.driver.session() as session:
            result = session.execute_write(self.create_absolute_pin, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)
    
    def create_relative_pin_relation(self, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        with self.driver.session() as session:
            result = session.execute_write(self.create_relative_pin, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)    
    
    def create_discovery_check_relation(self, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_discovery_check, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position)
    
    def create_interference_relation(self, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        with self.driver.session() as session:
            result = session.execute_write(self.create_interference, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2)        
    
    def create_mate_in_two_relation(self, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_current_position, opponent_next_position, ally_piece, ally_color, ally_current_position, ally_next_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_mate_in_two, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_current_position, opponent_next_position, ally_piece, ally_color, ally_current_position, ally_next_position)        
        
    def create_mate_in_one_relation(self, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_mate_in_one, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position)        

    def create_hanging_piece_relation(self, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position):
        with self.driver.session() as session:
            result = session.execute_write(self.create_hanging_piece, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position)        

    # Specific methods
    @staticmethod
    def create_piece_node(tx, piece, color, position):
        tx.run("CREATE (piece:Piece)"
                "SET piece = {piece: $piece, color: $color, position:$position} ", 
                piece= piece, color=color, position=position
                )
    
    @staticmethod
    def create_square_node(tx, position):
        tx.run("CREATE (square:Square)"
                "SET square = {position: $position}",
                position=position
                )
        
    @staticmethod
    def create_suggest_relation(tx, piece, color, from_position, to_position, strategy):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $to_position})
                WITH piece, to_square
                MATCH (piece) -[:Locate]-> (from_square:Square {position: $from_position})
                CREATE (piece)-[:Suggest {tactic: $strategy}]->(to_square)""",
                piece=piece, color=color, from_position=from_position, strategy=strategy, to_position=to_position
                )
        
    @staticmethod
    def create_feature_relation(tx, piece, color, from_position, to_position, impacted_piece, impacted_piece_color, impacted_piece_position, feature):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $to_position})
                WITH piece, to_square
                MATCH (piece) -[:Locate]-> (from_square:Square {position: $from_position})
                CREATE (piece)-[:Feature {feature: $feature, piece: $impacted_piece, color: $impacted_piece_color, position: $impacted_piece_position}]->(to_square)""",
                piece=piece, color=color, from_position=from_position, feature=feature, to_position=to_position, impacted_piece=impacted_piece, impacted_piece_color=impacted_piece_color, impacted_piece_position=impacted_piece_position
                )
    
    @staticmethod
    def add_property_node(tx, piece, color, position, prop):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color, position:$position})
               SET piece.props = piece.props + [$prop]
               RETURN piece
               """,
               piece=piece, color=color, position=position, prop=prop)
      
    @staticmethod  
    def remove_property_node(tx, piece, color, position, prop):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color, position: $position})
                SET piece.props = FILTER(x IN piece.props WHERE x <> $prop)""",
               piece=piece, color=color, position=position, prop=prop
                )
    
    @staticmethod
    def create_locate_relation(tx, piece, color, position):
        tx.run("MATCH (piece:Piece {piece: $piece, color: $color, position: $position}), (square: Square {position: $position})"
               "CREATE (piece)-[:Locate]->(square)",
               piece=piece, color=color, position=position
               )
    
    @staticmethod
    def fetch_suggest_relation(tx, piece, color, from_position, to_position):
        result = tx.run("""
                        MATCH (piece:Piece {piece: $piece, color: $color}) -[suggest:Suggest]-> (to_square:Square {position: $to_position})
                        WITH piece, suggest
                        MATCH (piece) -[:Locate]-> (from_square:Square {position: $from_position})
                        RETURN PROPERTIES(suggest)
                        """,
                        piece = piece, color = color, from_position = from_position, to_position = to_position
                        )
        
        list_of_strategies = []
        for node in result:
            list_of_strategies = list_of_strategies + [node[0].get('tactic')]

        return list_of_strategies
    
    @staticmethod
    def fetch_props_node(tx, piece, color, position):
        result = tx.run("""
                        MATCH (piece:Piece {piece: $piece, color: $color, position: $position})
                        RETURN PROPERTIES(piece)
                        """,
                        piece=piece, color=color, position=position)
    
        return result.single()
    
    @staticmethod
    def delete_all_nodes(tx):
        tx.run("MATCH (n)"
               "DETACH DELETE n"
               )

    # Specific Methods
    # Interference
    @staticmethod
    def add_property_relation_interference(tx, piece, color, position, next_position, opponent_piece1, opponent_color1, opponent_position1,  opponent_piece2, opponent_color2, opponent_position2):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color, position: $position}) -[suggest:Suggest {tactic: "Interference"}]-> (square:Square {position: $next_position})
                SET suggest = {opponent_piece1: $opponent_piece1, opponent_color1: $opponent_color1, opponent_position1: $opponent_position1, opponent_piece2: $opponent_piece2, opponent_color2: $opponent_color2, opponent_position2:$opponent_position2}
               """,
               piece=piece, color=color, position=position, next_position=next_position, opponent_piece1=opponent_piece1, opponent_color1=opponent_color1, opponent_position1=opponent_position1, opponent_piece2=opponent_piece2, opponent_color2=opponent_color2, opponent_position2=opponent_position2)
     
    # Verification
    @staticmethod
    def verify_move_feature_relation(tx, piece1, color1, position1, piece2, color2, position2, move, feature):
        result = tx.run("""MATCH (piece:Piece {piece: $piece1, color: $color1, position: $position1}) -[feature:Feature {feature: $feature, piece: $piece2, color: $color2, position: $position2}]-> (square:Square {position: $move})
                RETURN piece
               """,
               piece1=piece1, color1=color1, position1=position1, piece2=piece2, color2=color2, position2=position2, move=move, feature=feature)
    
        return result.single()
    
    @staticmethod
    def verify_move_feature_relation_missing_param(tx, feature):
        result = tx.run("""MATCH (piece:Piece) -[feature:Feature {feature: $feature}]-> (square:Square)
                RETURN piece.piece As piece1, piece.color As color1, piece.position As position1, piece.position As from, square.position As to, feature.piece As piece2, feature.color As color2, feature.position As position2
                """,
                feature=feature)
        
        list_of_elem = []
        
        for record in list(result):
            list_of_elem.append(record)
        
        return list_of_elem
    
    @staticmethod
    def find_move_feature_relation(tx, feature):
        result = tx.run("""MATCH (piece:Piece) -[feature:Feature {feature: $feature}]-> (square:Square)
                RETURN piece.piece As piece, piece.color As color, piece.position As from, square.position As to
                """,
                feature=feature)
        
        list_of_moves = []
            
        for record in list(result):
            list_of_moves.append(record)
            
        return list_of_moves
    
    @staticmethod
    def build_feature_relation(tx, piece, color, from_position, to_position, feature):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $to_position})
                WITH piece, to_square
                MATCH (piece) -[:Locate]-> (from_square:Square {position: $from_position})
                CREATE (piece)-[:Feature {feature: $feature}]->(to_square)""",
                piece=piece, color=color, from_position=from_position, feature=feature, to_position=to_position
                )
     
    @staticmethod
    def create_discovery_attack(tx, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
                WITH piece, to_square
                MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
                CREATE (piece) -[:Tactic {tactic_name: $tactic_name, ally_piece: $ally_piece, ally_color: $ally_color, ally_position: $ally_position, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_position: $opponent_position}]-> (to_square)
               """,
               piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="discovered attack", ally_piece=ally_piece, ally_color=ally_color, ally_position=ally_position, opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_position=opponent_position
               )
            
    @staticmethod  
    def create_skewer(tx, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece1: $opponent_piece1, opponent_color1: $opponent_color1, opponent_position1: $opponent_position1, opponent_piece2: $opponent_piece2, opponent_color2: $opponent_color2, opponent_position2: $opponent_position2}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="skewer", opponent_piece1=opponent_piece1, opponent_color1=opponent_color1, opponent_position1=opponent_position1, opponent_piece2=opponent_piece2, opponent_color2=opponent_color2, opponent_position2=opponent_position2
            )
    
    @staticmethod
    def create_fork(tx, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_position: $opponent_position}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="fork", opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_position=opponent_position
            )
        
    @staticmethod
    def create_absolute_pin(tx, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece1: $opponent_piece1, opponent_color1: $opponent_color1, opponent_position1: $opponent_position1, opponent_piece2: $opponent_piece2, opponent_color2: $opponent_color2, opponent_position2: $opponent_position2}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="absolute pin", opponent_piece1=opponent_piece1, opponent_color1=opponent_color1, opponent_position1=opponent_position1, opponent_piece2=opponent_piece2, opponent_color2=opponent_color2, opponent_position2=opponent_position2
            )
    
    @staticmethod
    def create_relative_pin(tx, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece1: $opponent_piece1, opponent_color1: $opponent_color1, opponent_position1: $opponent_position1, opponent_piece2: $opponent_piece2, opponent_color2: $opponent_color2, opponent_position2: $opponent_position2}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="relative pin", opponent_piece1=opponent_piece1, opponent_color1=opponent_color1, opponent_position1=opponent_position1, opponent_piece2=opponent_piece2, opponent_color2=opponent_color2, opponent_position2=opponent_position2
            )
        
    @staticmethod
    def create_discovery_check(tx, piece, color, current_position, next_position, ally_piece, ally_color, ally_position, opponent_piece, opponent_color, opponent_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, ally_piece: $ally_piece, ally_color: $ally_color, ally_position: $ally_position, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_position: $opponent_position}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="discovered check", ally_piece=ally_piece, ally_color=ally_color, ally_position=ally_position, opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_position=opponent_position
            )
    
    @staticmethod
    def create_interference(tx, piece, color, current_position, next_position, opponent_piece1, opponent_color1, opponent_position1, opponent_piece2, opponent_color2, opponent_position2):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece1: $opponent_piece1, opponent_color1: $opponent_color1, opponent_position1: $opponent_position1, opponent_piece2: $opponent_piece2, opponent_color2: $opponent_color2, opponent_position2: $opponent_position2}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="interference", opponent_piece1=opponent_piece1, opponent_color1=opponent_color1, opponent_position1=opponent_position1, opponent_piece2=opponent_piece2, opponent_color2=opponent_color2, opponent_position2=opponent_position2
            )
        
    @staticmethod
    def create_mate_in_two(tx, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_current_position, opponent_next_position, ally_piece, ally_color, ally_current_position, ally_next_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_current_position: $opponent_current_position, opponent_next_position: $opponent_next_position, ally_piece: $ally_piece, ally_color: $ally_color, ally_current_position: $ally_current_position, ally_next_position: $ally_next_position}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="mateIn2", opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_current_position=opponent_current_position, opponent_next_position=opponent_next_position, ally_piece=ally_piece, ally_color=ally_color, ally_current_position=ally_current_position, ally_next_position=ally_next_position
            )
        
    @staticmethod
    def create_mate_in_one(tx, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_position: $opponent_position}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="mateIn1", opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_position=opponent_position
            )

    @staticmethod
    def create_hanging_piece(tx, piece, color, current_position, next_position, opponent_piece, opponent_color, opponent_position):
        tx.run("""MATCH (piece:Piece {piece: $piece, color: $color}), (to_square:Square {position: $next_position})
            WITH piece, to_square
            MATCH (piece) -[:Locate]-> (from_square:Square {position: $current_position})
            CREATE (piece) -[:Tactic {tactic_name: $tactic_name, opponent_piece: $opponent_piece, opponent_color: $opponent_color, opponent_position: $opponent_position}]-> (to_square)
            """,
            piece=piece, color=color, current_position=current_position, next_position=next_position, tactic_name="hanging piece", opponent_piece=opponent_piece, opponent_color=opponent_color, opponent_position=opponent_position
            )


# sym = Symbolic()
# sym.consult("server/neurosymbolicAI/symbolicAI/general.pl")
# sym.parse_fen("3r4/7p/8/R1N2bk1/2p5/2P5/PP2r1PP/2KR4 b - - 2 29")
# query = sym.prolog.query(f"""moves_cause_mate_in_two(black, Piece, Position, ListOfMoves)""")
# result = list(query)
# print(result)
# query.close()