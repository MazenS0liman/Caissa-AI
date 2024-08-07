import os
import json
from langchain_google_genai import GoogleGenerativeAI
from langchain.prompts import PromptTemplate
from langchain.agents import AgentExecutor, create_react_agent
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.pydantic_v1 import BaseModel, Field
from pydantic import BaseModel, Field
from .symbolicAI import Symbolic
import streamlit as st

os.environ["URI"] = st.secrets["NEO4J_URI"]
os.environ["NEO_USER"] = st.secrets["NEO4J_USERNAME"]
os.environ["PASSWORD"] = st.secrets["NEO4J_PASSWORD"]
os.environ["KB_PATH"] = st.secrets["KB_PATH"]

class Relation(BaseModel):
    name: str = Field(description="the name of the new relation")
    type: str = Field(description="type of the new relation")
    relationships: dict = Field(description="relations in the new relaton description")
        

class Builder():
    
    def __init__(self):
        self.llm = GoogleGenerativeAI(
            model="gemini-pro",
            google_api_key=st.secrets["PALM_API_KEY"],
            temperature=0,
        )
        
        self.sym = Symbolic()
        self.sym.consult(os.getenv('KB_PATH'))
        
        parser = JsonOutputParser(pydantic_object=Relation)
        
        self.agent_prompt = PromptTemplate.from_template("""
            # Role
            You are a chess expert in exracting features and relationships from complex statement related to chess in form of JSON  
            Do NOT provide your opinion regarding the input, ONLY convert to JSON.                    
                                  
            # Specifies
            - This is very important to my career
            - This task is vital to my career, and I greatly value your thorough analysis
            
            # Context
            - You MUST ONLY give the JSON format of the Input.
            - Chess piece from the following list of pieces: [king, queen, knight, bishop, rook, pawn]
            - Chess color of a chess piece from the following list: [black, white]
            - Chess position of a chess piece from the following list of positions: [
                a1, a2, a3, a4, a5, a6, a7, a8,
                b1, b2, b3, b4, b5, b6, b7, b8,
                c1, c2, c3, c4, c5, c6, c7, c8,
                d1, d2, d3, d4, d5, d6, d7, d8,
                e1, e2, e3, e4, e5, e6, e7, e8,
                f1, f2, f3, f4, f5, f6, f7, f8,
                g1, g2, g3, g4, g5, g6, g7, g8,
                h1, h2, h3, h4, h5, h6, h7, h8
             ]
            - Chess relation between two chess pieces is from the following list of relations: [defend, threat]
            - Chess move features between two chess pieces is from the following list of relations: [move_defend, move_threat, move_is_protected, move_is_attacked]
            - Please use relationship Suggest for defend, threat, attack with no word "move" in the question. Or, use relationship Feature for move(s) that is attacked, move that defend, move that is protected, move that threat with the word "move" in the question.
            
                TOOLS:
                ------
                
                You have access to the following tools:
                
                {tools}
                
                {tool_names}
                
                Do not use any tool
                
                
                Please use the following format:
                
                ```
                Thought: what features or tactics correspond to the relation description?
                Action: the action to take, should be one or more of [move_defend, move_threat, move_is_protected, move_is_attacked, defend, threat] ('N/A' if there is no action)
                ```

                When you have a response to say to the Human, or if you do not need to use a tool,
                
                ```
                Thought: Do I have a JSON response? Yes
                Final Answer: [your response here]
                ```
                            
            # Examples
            ### Example 1
            Input: A move_threat_and_defend is a feature of a move that defend an ally piece and attack an opponent piece.
            Final Answer: {{'name': 'move_threat_and_defend', 'type': 'Feature', 'relationships': {{'relation_1': 'move_defend', 'relation_2': 'move_threat'}}}}            
             
            ### Example 2
            Input:
            Final Answer:
               
            # How to get Final Answer step by step:
            1. Determine the name of the new relation.
            2. Split the description of the new relation into multiple features based on the following description of relationships:
                1. {{feature: "move_defend"}}: is a move made by a piece from its current position to new position to defend an ally piece on a third different position. Use when asked about a "move" that defend or protect a piece.
                2. {{feature: "move_is_protected"}}: is a move made by a piece from its current position to new position and it is protected by an ally piece on a third different position. Use when asked about pieces that defend or protect a "move".
                3. {{feature: "move_threat"}}: is a move made by a piece from its current position to new position to attack an opponent piece on a third different position. Use when asked about a "move" that attack or threat a piece.
                4. {{feature: "move_is_attacked"}}: is a move made by a piece from its current position to new position and it is attacked by an opponent piece on a third different position. Use when asked about pieces that attack or threat a "move".
            3. Give Final Answer with the following format in JSON
                1. `name`: name of the new relation.
                2. `type`: type of the new relation which is either a `Feature` or `Suggest`.
                3. `relationships`: a list of relations in the following format: {{'relationships': {{'relation_1': 'relation_name', ..., 'relation_nth': 'relation_name'}}}}
            4. STOP after getting the first Final Answer.
            5. If you do not have a Final Answer AFTER trying then give {{'name': 'N/A', 'type': 'N/A', 'relationships': 'N/A'}}
            
            # Note
            - Do not include characters ```
            
            New input: {input}
            {agent_scratchpad}                                        
        """,
        partial_variables={"format_instructions": parser.get_format_instructions()})
        
        self.agent = create_react_agent(self.llm, [], self.agent_prompt)
        
        self.agent_executor = AgentExecutor(
            agent=self.agent,
            tools=[],
            verbose=True,
            handle_parsing_errors="MUST return first Final Answer"            
        )

    def parse_fen(self, fen_string: str) -> None:
        
        self.sym.parse_fen(fen_string)
        
    def extract_relations(self, input) -> list:

        response = self.agent_executor.invoke({'input': input})
        
        return response
        
    def build_relations(self, input) -> None:
        # Extract relations from the new relationship description
        structured_response =self.extract_relations(input)['output'].replace("\'", "\"")
        print("structured_response:", structured_response)
        
        # Convert the response into a JSON
        json_response = json.loads(f"""{structured_response}""")
        print("json_response:", json_response)
        
        # If agent is unable to detect relations
        if json_response['relationships'] == "N/A":
            raise Exception("Could not build the relationship")
        
        # Get all pieces on the chess board
        pieces = list(self.sym.prolog.query("return_pieces(Piece, Color, Position)"))
        
        for index, piece in enumerate(pieces):
            print(f"piece {index}:", piece)

        feature_name = json_response['name']
        feature_relationships = json_response['relationships']
        print("feature_relationships:", feature_relationships)
        print("type(feature_relationships):", type(feature_relationships))
        
        # Get pieces that satisfies the relations in `relationships` field
        list_of_moves = []
        initial_flag = True
        
        for index, relation in enumerate(feature_relationships):
            relation_name = feature_relationships[f"relation_{index + 1}"]
            print("relation_name:", relation_name)
            
            records = self.sym.graph.find_moves(relation_name)
            print("records:", records)
            
            relation_list = []
            for record in records:
                piece = record['piece']
                color = record['color']
                from_position = record['from']
                to_position = record['to']
                
                move_tuple = (piece, color, from_position, to_position)
                relation_list.append(move_tuple)
                
                print("piece:", record['piece'])
                print("color:", record['color'])
                print("from:", record['from'])
                print("to:", record['to'])
                
            if initial_flag:
                list_of_moves = relation_list
                initial_flag = False
            else:
                common_list = [piece for piece in relation_list if piece in list_of_moves]
                list_of_moves = common_list
            
        # Create new relations
        print("list_of_moves:", list_of_moves)
        for elem in list_of_moves:
            (piece, color, from_position, to_position) = elem
            
            self.sym.graph.build_feature(piece, color, from_position, to_position, feature_name)
