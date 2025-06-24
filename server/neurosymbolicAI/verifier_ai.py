import os
import json
from langchain_google_genai import GoogleGenerativeAI
from langchain.prompts import PromptTemplate
from langchain.agents import AgentExecutor, create_react_agent
from kor import create_extraction_chain, Object, Text
from .symbolicAI import Symbolic
import streamlit as st

os.environ["URI"] = st.secrets["NEO4J_URI"]
os.environ["NEO_USER"] = st.secrets["NEO4J_USERNAME"]
os.environ["PASSWORD"] = st.secrets["NEO4J_PASSWORD"]
os.environ["KB_PATH"] = st.secrets["KB_PATH"]

class Verifier():  
    
    def __init__(self):
        
        self.llm = GoogleGenerativeAI(
            model="gemini-pro",
            google_api_key=st.secrets["GEMINI_API_KEY"],
            temperature=0,
        )

        self.sym = Symbolic()
        self.sym.consult(os.getenv('KB_PATH'))
        
        self.agent_prompt = PromptTemplate.from_template("""
            # Role
            You are an expert in converting complex text to simple statements in form of JSON
            you have no knowledge about anything other than converting statements to JSON
            NEVER add information not stated in the input such as color, position, relations or features.
            
            # Specifics
            - This is very important to my career
            - This task is vital to my career, and I greatly value your thorough analysis
            
            # Context 
            - You MUST ONLY give the JSON format of the Input.
            
                TOOLS:
                ------

                You have access to the following tools:

                {tools}

                To use a tool, please use the following format:

                    Thought: Do I need to use a tool? Yes
                    Action: the action to take, should be one of [{tool_names}]
                    Action Input: the input to the action
                    Observation: the result of the action
                    Output: the output from the tool

                When you have a response to say to the Human, or if you do not need to use a tool, you MUST use the format:

                    Thought: Do I need to use a tool? No
                    Final Answer: [your response here]
            
            # Examples
            ### Example 1
            Input: The white queen at e4 defends white pawn at c2, white pawn at b2 and white king at c1
            Answer: {{'statements': {{'statement_1': 'The white queen at e4 defends white pawn at c2', 'statement_2': 'The white queen at e4 defends white pawn at b2', 'statement_3': 'The white queen at e4 defends white king at c1'}}}}                        

            ### Example 2
            Input: white queen at g3 is attacked by black king at h8 for the move g8.
            Answer: {{'statements': {{'statement_1': 'white queen at g3 is attacked by black king at h8 for the move g8'}}}}
            
            ### Example 3
            Input: The position of kings are e4 and b2.
            Answer: {{'statements': {{'statement_1': 'The king position is e4', 'statement_2': 'The king position is b2'}}}}
            
            ### Example 4
            Input: The black rook move from c3 to h3 is attacked by white rook at h1.
            Answer: {{'statements': {{'statement_1': 'The black rook move from c3 to h3 is attacked by white rook at h1'}}}}

            # Note:
            - Do NOT provide your opinion regarding the input ONLY convert text to JSON.
            - Do not write Uppercased or Capitalized letters for color, piece or position
            - Generate a statement for every comma ','
            - Please do not include ``` in your output
                            
            New input: {input}
            {agent_scratchpad}
        """)
        
        self.agent = create_react_agent(self.llm, [], self.agent_prompt)
        self.agent_executor = AgentExecutor(
            agent=self.agent,
            tools=[],
            verbose=True
        )
        
        self.fix_agent_prompt =  PromptTemplate.from_template(""" 
            # Role
            You are an english expert in re-adjusting statements in better structure
            you have no knowledge about anything else
            Do NOT state your opnion                          
                                                              
            # Specifics
            - This is very important to my career
            - This task is vital to my career, and I greatly value your thorough analysis
            
            You have access to the following tools:
                
            {tools}
            
            {tool_names}
                
            Do not use any tool

            When you have a response to say to the Human, you MUST use the format:

                Thought: Do I have an answer? Yes
                Final Answer: [your response here]
            
            # Examples
            ### Example 1
            Input: {{"statement": "The position of queen is d8", "piece": queen, "color": white, "position": d8}}
            Final Answer: The position of the white queen is d8. 
            
            # Note
            - Do not include in the output the characters ```
            - Please remove the character ` from the output
            - If the statement stated that it does not know the answer then ignore it and must use the remaining information to provide an answer.
            
            New input: {input}
            {agent_scratchpad}         
        """)
        
        self.fix_agent = create_react_agent(self.llm, [], self.fix_agent_prompt)
        self.fix_agent_executor = AgentExecutor(
            agent=self.fix_agent,
            tools=[],
            verbose=True,
        )
        
    def parse_fen(self, fen_string: str):
        self.sym.parse_fen(fen_string)

    def verify_piece_position(self, response) -> list:
        '''
        Checks whether the position of the piece specified in the commentary is valid.
        
        :param: :response: response propagated from the chess solver
        :return: a list of dict
        '''
        
        # Create a schema
        schema = Object(
                    id="position schema",
                    description=(
                        "A generated chess commentary."
                    ),
                    attributes=[
                        Text(
                            id="piece",
                            description="""
                                Chess piece from the following list of pieces: [king, queen, knight, bishop, rook, pawn]
                                Chess color of a chess piece from the following list: [black, white]
                                Chess position of a chess piece from the following list of positions: [
                                    a1, a2, a3, a4, a5, a6, a7, a8,
                                    b1, b2, b3, b4, b5, b6, b7, b8,
                                    c1, c2, c3, c4, c5, c6, c7, c8,
                                    d1, d2, d3, d4, d5, d6, d7, d8,
                                    e1, e2, e3, e4, e5, e6, e7, e8,
                                    f1, f2, f3, f4, f5, f6, f7, f8,
                                    g1, g2, g3, g4, g5, g6, g7, g8,
                                    h1, h2, h3, h4, h5, h6, h7, h8
                                ]
                                
                                # Note
                                - you must fill fields with 'N/A' if they are not stated in the input.
                            """,
                            examples=[
                                ("The position of black queen is a2.", "{'piece': 'queen', 'color': 'black', 'position': 'a2'}"),
                                ("The position of king is a2.", "{'piece': 'king', 'color': 'N/A', 'position': 'a2'}"),
                                ("The position of black bishop.", "{'piece': 'bishop', 'color': 'black', 'position': 'N/A'}"),
                            ],
                            many=True
                        ),
                    ],
                    many=False,
                )
        
        chain = create_extraction_chain(self.llm, schema, encoder_or_encoder_class='json')
        
        list_of_statements = []
            
        structured_response = self.agent_executor.invoke({'input': response})
        print("before structured_response:", structured_response['output'])
        structured_response = json.loads(str(structured_response['output']).replace("\'", "\""))
        print("after structured_response:", structured_response)
        
        for index, statement_key in enumerate(structured_response['statements']):
            try:
                print("statement_key:", statement_key) 
                statement = structured_response['statements'][statement_key]
                print(f"statement_{index + 1}:", statement)
            
                structured_filtered_response = chain.invoke(statement)['text']['raw']
                structured_filtered_response = structured_filtered_response.replace("<json>", "")
                structured_filtered_response = structured_filtered_response.replace("</json>", "")
                json_response = json.loads(structured_filtered_response)

                piece_info = json.loads(json_response["position schema"]["piece"][0].replace("\'", "\""))
                print("piece_info:", piece_info)
                
                piece = piece_info['piece']
                color = piece_info['color']
                position = piece_info['position']
                
                print("piece name:", piece)
                print("color:", color)
                print("position:", position)
                
                # Use Symbolic class to verfiy the statement
                response = self.sym.verify_position(piece, color, position)
                print("response:", response)
                
                if piece == "N/A"or len(response) == 0:
                    list_of_statements.append({"statement": statement, "condition": False})
                elif color == "N/A" or position == "N/A":
                    if color == "N/A":
                        color = response[0]['Color']

                    if position == "N/A":
                        position = response[0]['Position']
                        
                    fix_agent_input = {"statement": statement, "piece": piece, "color": color, "position": position}
                    print("fix_agent_input:", f"""{fix_agent_input}""")
                    fixed_statement = self.fix_agent_executor.invoke({"input": f"""{fix_agent_input}"""})['output']
                    print("fixed_statement:", fixed_statement)      
                    list_of_statements.append({"statement": fixed_statement, "condition": True})              
                else:
                    if not(len(response) == 0):
                        list_of_statements.append({"statement": statement, "condition": True}) 
            except:
                pass

        return list_of_statements
        
    def verify_piece_relation(self, response):
        '''
        Checks whether the move of a piece is legal.
        
        :param: :response: response propagated from the chess solver

        :return: a list of dict

        '''
        
        # Create a schema
        schema = Object(
                    id="relation schema",
                    description=(
                        "what is the relation between chess pieces?"
                    ),
                    attributes=[
                        Text(
                            id="relations",
                            description="""
                                # Role
                                You are programmer expert in converting text to JSON
                            
                                # Context
                                Chess piece from the following list of pieces: [king, queen, knight, bishop, rook, pawn]
                                Chess color of a chess piece from the following list: [black, white]
                                Chess position of a chess piece from the following list of positions: [
                                    a1, a2, a3, a4, a5, a6, a7, a8,
                                    b1, b2, b3, b4, b5, b6, b7, b8,
                                    c1, c2, c3, c4, c5, c6, c7, c8,
                                    d1, d2, d3, d4, d5, d6, d7, d8,
                                    e1, e2, e3, e4, e5, e6, e7, e8,
                                    f1, f2, f3, f4, f5, f6, f7, f8,
                                    g1, g2, g3, g4, g5, g6, g7, g8,
                                    h1, h2, h3, h4, h5, h6, h7, h8
                                ]
                                Chess relation between two chess pieces is from the following list of relations: [defend, threat]
                                - The following is a description of the relations:
                                    1. {{tactic: "defend"}}: is a relationship between a piece and an ally piece such that piece can defend or protect the ally piece. this is DIFFERENT from "move_defend" and "move_is_protected".
                                    2. {{tactic: "threat"}}: is a relationship between a piece and an opponent piece such that piece can attack or threat the opponent. this is DIFFERENT from "move_threat" and "move_is_attacked".              
                                
                                # Note:
                                    - If piece color is "white" then opponent color is "black" and if piece color is "black" then its opponent color is "white".
                                    - Ally pieces have the same color.
                                    - you must fill fields with 'N/A' if they are not stated in the input.
                            """,
                            examples=[
                                ("The black queen at c6 defend the black pawn at f3", "{'piece': 'queen', 'color': 'black', 'position': 'c6', 'ally_piece': 'pawn', 'ally_color': 'black', 'ally_position': 'f3', 'relation': 'defend'}"),
                                ("Black pawn at h5 is threated by the white rook at h8", "{'piece': 'rook', 'color': 'white', 'position': 'h8', 'opponent_piece': 'pawn', 'opponent_color': 'black', 'opponent_position': 'h5', 'relation': 'threat'}"),
                            ],
                            many=True
                        ),
                    ],
                    many=False,
                )
        
        chain = create_extraction_chain(self.llm, schema, encoder_or_encoder_class='json') 
        
        list_of_statements = []
            
        structured_response = self.agent_executor.invoke({'input': response})
        print("before structured_response:", structured_response['output'])
        structured_response = json.loads(structured_response['output'].replace("\'", "\""))
        print("after structured_response:", structured_response)

        for index, statement_key in enumerate(structured_response['statements']):
            try:
                statement = structured_response['statements'][statement_key]
                print(f"statement_{index + 1}:", statement)
            
                json_response = chain.invoke(statement)['text']['data']['relation schema']['relations'][0]
                print("JSON Response:", json_response)
            
                json_response = json_response.replace("<json>", "")
                json_response = json_response.replace("</json>", "").replace("\'","\"")
                print("before json_response:", json_response)
        
                relation_info = json.loads(json_response)
                print("relation_info:", relation_info)
                    
                piece1 = relation_info['piece']
                color1 = relation_info['color']
                position1 = relation_info['position']
                
                relation = relation_info['relation']
                    
                if relation == "defend":                    
                    piece2 = relation_info['ally_piece']
                    color2 = relation_info['ally_color']
                    position2 = relation_info['ally_position']
                elif relation == "threat":
                    piece2 = relation_info['opponent_piece']
                    color2 = relation_info['opponent_color']
                    position2 = relation_info['opponent_position']
                    
                print("piece1:", piece1)
                print("color1:", color1)
                print("position1:", position1)
                    
                print("piece2:", piece2)
                print("color2:", color2)
                print("position2:", position2)
                    
                print("relation:", relation)
                    
                # Use Symbolic class to verfiy the statement
                response = self.sym.verify_relation(piece1, color1, position1, piece2, color2, position2, relation)
                print(response)
                
                if piece1 == "N/A" or relation == "N/A" or len(response) == 0:
                    list_of_statements.append({"statement": statement, "condition": False})
                elif color1 == "N/A" or position1 == "N/A" or color2 == "N/A" or position2 == "N/A" or piece2 == "N/A":
                    if color1 == "N/A":
                        color1 = response[0]['Color1']

                    if position1 == "N/A":
                        position1 = response[0]['Position1']
                        
                    if piece2 == "N/A":
                        piece2 = response[0]['Piece2']
                    
                    if color2 == "N/A":
                        color2 = response[0]['Color2']
                        
                    if position2 == "N/A":
                        position2 = response[0]['Position2']
                        
                    fix_agent_input = {"statement": statement, "piece1": piece1, "color1": color1, "position1": position1, "piece2": piece2, "color2": color2, "position2": position2, "relation": relation}
                    print("fix_agent_input:", f"""{fix_agent_input}""")
                    fixed_statement = self.fix_agent_executor.invoke({"input": f"""{fix_agent_input}"""})['output']
                    print("fixed_statement:", fixed_statement)      
                    list_of_statements.append({"statement": fixed_statement, "condition": True})              
                else:
                    if not(len(response) == 0):
                        list_of_statements.append({"statement": statement, "condition": True})
            except:
                pass
                        
        return list_of_statements

    def verify_piece_move_feature(self, response):
        '''
        Checks whether piece have certain move relation.
        
        :param: :response: response propagated from the chess solver.
        :return: a list of dict
        '''
        
        # Create a schema
        schema = Object(
            id="move feature schema",
            description=(
                "what is the move feature between chess pieces?"
            ),
            attributes=[
            Text(
                    id="move feature",
                    description="""
                        # Role
                        You are programmer expert in converting text to JSON
                    
                        # Context
                        Chess piece from the following list of pieces: [king, queen, knight, bishop, rook, pawn]
                        Chess color of a chess piece from the following list: [black, white]
                        Chess position and move of a chess piece from the following list of positions: [
                            a1, a2, a3, a4, a5, a6, a7, a8,
                            b1, b2, b3, b4, b5, b6, b7, b8,
                            c1, c2, c3, c4, c5, c6, c7, c8,
                            d1, d2, d3, d4, d5, d6, d7, d8,
                            e1, e2, e3, e4, e5, e6, e7, e8,
                            f1, f2, f3, f4, f5, f6, f7, f8,
                            g1, g2, g3, g4, g5, g6, g7, g8,
                            h1, h2, h3, h4, h5, h6, h7, h8
                        ]
                        Chess move features between two chess pieces is from the following list of relations: [move_defend, move_threat, move_is_protected, move_is_attacked]
                        - The following is a description of the relations:
                            1. {{feature: "move_defend"}}: is a move made by a piece from its current position to new position to defend an ally piece on a third different position. Use when asked about a "move" that defend or protect a piece.
                            2. {{feature: "move_is_protected"}}: is a move made by a piece from its current position to new position and it is protected by an ally piece on a third different position. Use when asked about pieces that defend or protect a "move".
                            3. {{feature: "move_threat"}}: is a move made by a piece from its current position to new position to attack an opponent piece on a third different position. Use when asked about a "move" that attack or threat a piece.
                            4. {{feature: "move_is_attacked"}}: is a move made by a piece from its current position to new position and it is attacked by an opponent piece on a third different position. Use when asked about pieces that attack or threat a "move".
       
                        # Note:
                            - If piece color is "white" then opponent color is "black" and if piece color is "black" then its opponent color is "white".
                            - Ally pieces have the same color.
                            - The output must have 'piece', 'color', 'position', 'move' and 'feature'
                            - The output must include 'opponent_piece', 'opponent_color' and 'opponent_position' for 'move_is_attacked' or 'move_threat'
                            - The output must include 'ally_piece', 'ally_color' and 'ally_position' for 'move_is_protected' or 'move_defend'
                            - The 'move' can not be None or null!
                            - you must fill fields with 'N/A' if they are not stated in the input.
                            - The position of a piece MUST NOT be the SAME as the value of the move!
                    """,
                    examples=[
                        ("white rook at d1 is attacked by black rook at d8 for the move e1", "{'piece': 'rook', 'color': 'white', 'position': 'd1', 'opponent_piece': 'rook', 'opponent_color': 'black', 'opponent_position': 'd8', 'move': 'e1', 'feature': 'move_is_attacked'}"),
                        ("The black rook move to d8 is threatened by a white knight at f7.", "{'piece': 'rook', 'color': 'black', 'position': 'N/A', 'opponent_piece': 'knight', 'opponent_color': 'white', 'opponent_position': 'f7', 'move': 'd8', 'feature': 'move_is_attacked'}")
                    ],
                    many=True
                ),
            ],
            many=False,
        )
        
        chain = create_extraction_chain(self.llm, schema, encoder_or_encoder_class='json')
        
        list_of_statements = []
            
        structured_response = self.agent_executor.invoke({'input': response})
        print("before structured_response:", structured_response['output'])
        structured_response = json.loads(structured_response['output'].replace("\'", "\""))
        print("after structured_response:", structured_response)

    
        for index, statement_key in enumerate(structured_response['statements']): 
            try:
                statement = structured_response['statements'][statement_key]
                print(f"statement_{index + 1}:", statement)
            
                json_response = chain.invoke(statement)['text']['data']['move feature schema']['move feature'][0]
                print("JSON Response:", json_response)
            
                json_response = json_response.replace("<json>", "")
                json_response = json_response.replace("</json>", "").replace("\'","\"")
                print("before json_response:", json_response)
        
                move_info = json.loads(json_response)
                print("move_info:", move_info)
                 
                piece1 = move_info['piece']
                color1 = move_info['color']
                position1 = move_info['position']
                
                feature = move_info['feature']
                
                move = move_info['move']
                print("move:", move)
                 
                if feature == "move_defend" or feature == "move_is_protected":                    
                    piece2 = move_info['ally_piece']
                    color2 = move_info['ally_color']
                    position2 = move_info['ally_position']
                elif feature == "move_threat" or feature == "move_is_attacked":
                    piece2 = move_info['opponent_piece']
                    color2 = move_info['opponent_color']
                    position2 = move_info['opponent_position']
                
                print("piece1:", piece1)
                print("color1:", color1)
                print("position1:", position1)
                
                print("piece2:", piece2)
                print("color2:", color2)
                print("position2:", position2)
                
                print("feature:", feature)
                
                if color1 == "N/A" and not(color2 == "N/A"):
                    if feature == "move_defend" or feature == "move_is_protected":
                        color1 = "white" if color2 == "white" else "black"
                    elif feature == "move_threat" or feature == "move_is_attacked":
                        color1 = "white" if color2 == "black" else "black"
                
                if color2 == "N/A" and not(color1 == "N/A"):
                    if feature == "move_defend" or feature == "move_is_protected":
                        color2 = "white" if color1 == "white" else "black"
                    elif feature == "move_threat" or feature == "move_is_attacked":
                        color1 = "black" if color1 == "white" else "white"
                
                # Use Symbolic class to verfiy the statement
                if piece1 == "N/A" or feature == "N/A" or color1 == "N/A" or color2 == "N/A":
                    list_of_statements.append({"statement": statement, "condition": False})
                elif piece1 == "N/A" or position1 == "N/A" or piece2 == "N/A" or position2 == "N/A":
                    responses = self.sym.graph.verify_move_feature_missing_param(feature)
                    # print("responses:", responses)
                    
                    list_of_true_elem = []
                    list_of_false_elem = []
                   
                    if not(piece2 == "N/A"):
                        if not(position2 == "N/A"):
                            if not(position1 == "N/A"):
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and piece2 == response['piece2'] and color1 == response['color1'] and color2 == response['color2'] and position1 == response['position1'] and position2 == response["position2"] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": position1, "from_position": position1, "to_position": response["to"] if move == "N/A" else move, "piece2": piece2, "color2": color2, "position2": position2})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                            else:
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and piece2 == response['piece2'] and color1 == response['color1'] and color2 == response['color2'] and position2 == response['position2'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": response['position1'], "from_position": response['position1'], "to_position": response["to"] if move == "N/A" else move, "piece2": piece2, "color2": color2, "position2": position2})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                        else:
                            if (position1 == "N/A"):
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and piece2 == response['piece2'] and color1 == response['color1'] and color2 == response['color2'] and position1 == response['position1'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": position1, "from_position": position1, "to_position": response["to"] if move == "N/A" else move, "piece2": piece2, "color2": color2, "position2": response['position2']})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                            else:
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and piece2 == response['piece2'] and color1 == response['color1'] and color2 == response['color2'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": response['position1'], "from_position": response['position1'], "to_position": response["to"] if move == "N/A" else move, "piece2": piece2, "color2": color2, "position2": response['position2']})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                    else:
                        if not(position2 == "N/A"):
                            if not(position1 == "N/A"):
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and color1 == response['color1'] and color2 == response['color2'] and position1 == response['position1'] and position2 == response["position2"] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": position1, "from_position": position1, "to_position": response["to"] if move == "N/A" else move, "piece2": response['piece2'], "color2": color2, "position2": position2})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                            else:
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and color1 == response['color1'] and color2 == response['color2'] and position2 == response['position2'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": response['position1'], "from_position": response['position1'], "to_position": response["to"] if move == "N/A" else move, "piece2": response['piece2'], "color2": color2, "position2": position2})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                        else:
                            if (position1 == "N/A"):
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and color1 == response['color1'] and color2 == response['color2'] and position1 == response['position1'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": position1, "from_position": position1, "to_position": response["to"] if move == "N/A" else move, "piece2": response['piece2'], "color2": color2, "position2": response['position2']})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                            else:
                                for response in responses:
                                    try:
                                        if piece1 == response['piece1'] and color1 == response['color1'] and color2 == response['color2'] and ((not(move == "N/A") and move == response["to"]) or move == "N/A"):
                                            list_of_true_elem.append({"statement": statement, "piece1": piece1, "color1": color1, "position1": response['position1'], "from_position": response['position1'], "to_position": response["to"] if move == "N/A" else move, "piece2": response['piece2'], "color2": color2, "position2": response['position2']})
                                        else:
                                            list_of_false_elem.append({"statement": statement})
                                    except:
                                        pass
                                                        
                    for correct_statement in list_of_true_elem:
                        try:
                            print("correct_statement:", f"""{correct_statement}""")
                            fixed_statement = self.fix_agent_executor.invoke({"input": f"""{correct_statement}"""})['output']
                            print("fixed_statement:", fixed_statement)      
                            list_of_statements.append({"statement": fixed_statement, "condition": True})  
                        except:
                            pass
                        
                    if len(correct_statement) == 0:
                        list_of_statements.append({"statement": statement, "condition": False}) 

                else:
                    response = self.sym.graph.verify_move_feature(piece1, color1, position1, piece2, color2, position2, move, feature)
                    print("response:", response[0]['piece'])
                    
                    if response == None or response[0] == None: # Incorrect
                        list_of_statements.append({"statement": statement, "condition": False})
                    elif response[0]['piece'] == piece1: # Correct
                        list_of_statements.append({"statement": statement, "condition": True})    
            except:
                pass
                
        return list_of_statements
