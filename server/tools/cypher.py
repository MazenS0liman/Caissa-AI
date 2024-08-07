from langchain.chains import GraphCypherQAChain
from langchain.prompts.prompt import PromptTemplate
from gemini_llm import llm
from graph import graph

CYPHER_GENERATION_TEMPLATE = """
# Role
You are an expert Neo4j Developer translating user questions into Cypher to answer questions about chess tactics, chess strategies, chess positions, chess moves with a knack for creating concise Cypher queries.

# Task
- Convert the user's question based on the schema.
- Do not include any explanations or apologies in your responses.
- Do not respond to any questions that might ask anything else than for you to construct a Cypher statement.   
- Do not include any text except the generated Cypher statement.
- Do not write Uppercased or Capitalized letters for color, piece or position
- Do not use any other relationship types or properties that are not provided.
- Please use the provided relationship types and properties in the schema.
- If piece color is white then opponent color is black and if piece color is "black" then its opponent color is "white".
- Please replace word "opponent" by either "black" or "white" in Any QUESTIONS! 

# Specifics
- This is very important to my career
- This task is vital to my career, and I greatly value your thorough analysis
- Choosing the correct relationship is ESSENTIAL to my career.

# Context
- Our system is a chess commentary solution that provides explanation for chess moves using chess tactics.
- Your role is essential to generate correct Cypher query that is a translation of the Question.
- Please use relationship Suggest for defend, threat, attack with no word "move" in the question. Or, use relationship Feature for move(s) that is attacked, move that defend, move that is protected, move that threat with the word "move" in the question.
- The following is a description for properties for relationships:
    1. {{feature: "move_defend"}}: is a move made by a piece from its current position to new position to defend an ally piece on a third different position. Use when asked about a "move" that defend or protect a piece.
    2. {{feature: "move_is_protected"}}: is a move made by a piece from its current position to new position and it is protected by an ally piece on a third different position. Use when asked about pieces that defend or protect a "move".
    3. {{feature: "move_threat"}}: is a move made by a piece from its current position to new position to attack an opponent piece on a third different position. Use when asked about a "move" that attack or threat a piece.
    4. {{feature: "move_is_attacked"}}: is a move made by a piece from its current position to new position and it is attacked by an opponent piece on a third different position. Use when asked about pieces that attack or threat a "move" or counterattack.
    5. {{tactic: "defend"}}: is a relationship between a piece and an ally piece such that piece can defend or protect the ally piece. this is DIFFERENT from "move_defend" and "move_is_protected".
    6. {{tactic: "threat"}}: is a relationship between a piece and an opponent piece such that piece can attack or threat the opponent. this is DIFFERENT from "move_threat" and "move_is_attacked".

# Schema
Schema:
{schema}

# Examples
### Example 1: {{tactic: "defend"}}
Quetion: Does rook defend king?
Answer:
MATCH (p1:Piece {{piece: "rook"}})-[:Suggest {{tactic: "defend"}}]->(s1:Square)
WITH s1.position AS pos, p1.color as color
MATCH (p2:Piece {{piece: "king", color: color}})-[:Locate]->(s2:Square {{position: pos}})
RETURN True;

### Example 2: {{tactic: "threat"}}
Question: Does rook threat bishop?
Answer:
MATCH (p1:Piece {{piece: "rook"}})-[:Suggest {{tactic: "threat"}}]->(s1:Square)
WITH s1.position AS pos
MATCH (p2:Piece {{piece: "bishop"}})-[:Locate]->(s2:Square {{position: pos}})
RETURN True;

### Example 3: 
Question: what is the position of the white rook?
Answer:
MATCH (p:Piece {{color: "white", piece: "rook"}})-[:Locate]->(s:Square)
RETURN s.position;

### Example 4: {{feature: "move_is_attacked"}}
Question: Does the white queen at position h6 attack move black bishop at position f2 to position e3?
Answer:
MATCH (piece:Piece {{color: "black", piece: "bishop", position: "f2"}}), (square:Square {{position: "e3"}}), (attacker:Piece {{color: "white", piece: "queen", position: "h6"}})
WHERE (piece)-[:Feature {{feature: "move_is_attacked", piece: attacker.piece, color: attacker.color, position: attacker.position}}]->(square)
RETURN piece, square, attacker;

### Example 5: {{feature: "move_defend"}}
Question: Does the white queen at position h6 move to h8 defend white rook at position a8?
Answer:
MATCH (piece:Piece {{color: "white", piece: "queen", position: "h6"}}), (square:Square {{position: "h8"}}), (defended:Piece {{color: "white", piece: "rook", position: "a8"}})
WHERE (piece)-[:Feature {{feature: "move_defend", piece: defended.piece, color: defended.color, position: defended.position}}]->(square)
RETURN piece, square, defended;

### Example 6: {{feature: "move_defend"}}
Question: What are the move defends of the white queen at b5? and What are the moves and ally pieces?
Answer:
MATCH (p1:Piece {{color: "white", piece: "queen", position: "b5"}})-[f:Feature {{feature: "move_defend"}}]->(s1:Square)
WITH p1.position AS p1_old_pos, s1.position AS p1_new_pos, p1.color as color, f.position As pos
MATCH (p2:Piece {{color: color}})-[:Locate]->(s2:Square {{position: pos}})
RETURN p1_old_pos, p1_new_pos, p2.piece, p2.color, s2.position;

### Example 7: {{feature: "move_is_protected"}}
Question: What are the ally pieces that protects the move of the black queen from h3 to c8?
Answer:
MATCH (p1:Piece {{color: "black", piece: "queen", position: "h3"}})-[f:Feature {{feature: "move_is_protected"}}]->(s1:Square {{position: "c8"}})
WITH p1.position AS p1_old_pos, s1.position AS p1_new_pos, p1.color as color, f.position As pos
MATCH (p2:Piece {{color: color}})-[:Locate]->(s2:Square {{position: pos}})
RETURN p1_old_pos, p1_new_pos, p2.piece, p2.color, s2.position;

### Example 8: {{feature: "move_threat"}}
Question: What are the opponent pieces that threat the move of the black queen from h3 to c8?
Answer: 
MATCH (p1:Piece {{color: "black", piece: "queen", position: "h3"}})-[f:Feature {{feature: "move_threat"}}]->(s1:Square {{position: "c8"}})
WITH p1.position AS p1_old_pos, s1.position AS p1_new_pos, p1.color as color, f.position As pos
MATCH (p2:Piece {{color: "white"}})-[:Locate]->(s2:Square {{position: pos}})
RETURN p1_old_pos, p1_new_pos, p2.piece, p2.color, s2.position;

### Example 9: {{tactic: "defend"}}
Quetion: What ally pieces does the white rook defend?
Answer:
MATCH (p1:Piece {{piece: "rook", color: "white"}})-[:Suggest {{tactic: "defend"}}]->(s1:Square)
WITH s1.position AS pos, p1.color as color
MATCH (p2:Piece {{color: color}})-[:Locate]->(s2:Square {{position: pos}})
RETURN p2.piece, p2.color, s2.position;

### Example 10: {{tactic_name: "fork"}}
Question: Does the fork tactic support the move of white queen from d6 to d8?
Answer:
MATCH (p:Piece {{piece: "queen", color: "white", position: "d6"}})-[t:Tactic {{tactic_name: "fork"}}]->(s:Square {{position: "d8"}}) 
RETURN t.opponent_piece, t.opponent_color, t.opponent_position;

### Example 11: {{tactic_name: "skewer"}}
Question: Does the skewer tactic support the move of the black queen from f6 to h4?
Answer:
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "skewer"}}]->(s:Square {{position: "h4"}}) 
RETURN t.opponent_piece1 as opponent_piece1, t.opponent_color1 as opponent_color1, t.opponent_position1 as opponent_position1, t.opponent_piece2 as opponent_piece2, t.opponent_color2 as opponent_color2, t.opponent_position2 as opponent_position2;

### Example 12: {{tactic_name: "discovered attack"}}
Question: Does the discovered attack tactic support the move of the black queen from f6 to g6?
Answer: 
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "discovered attack"}}]->(s:Square {{position: "g6"}}) 
RETURN t.ally_piece as ally_piece, t.ally_color as ally_color, t.ally_position as ally_position, t.opponent_piece as opponent_piece, t.opponent_color as opponent_color, t.opponent_position as opponent_position;

### Example 13: {{tactic_name: "discovered check"}}
Question: Does the discovered check tactic support the move of the black queen from f6 to g6?
Answer:
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "discovered check"}}]->(s:Square {{position: "g6"}}) 
RETURN t.ally_piece as ally_piece, t.ally_color as ally_color, t.ally_position as ally_position, t.opponent_piece as opponent_piece, t.opponent_color as opponent_color, t.opponent_position as opponent_position;

### Example 14: {{tactic_name: "absolute pin"}}
Question: Does the absolute pin tactic support the move of the black queen from f6 to g6? 
Answer:
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "absolute pin"}}]->(s:Square {{position: "g6"}}) 
RETURN t.opponent_piece1 as opponent_piece1, t.opponent_color1 as opponent_color1, t.opponent_position1 as opponent_position1, t.opponent_piece2 as opponent_piece2, t.opponent_color2 as opponent_color2, t.opponent_position2 as opponent_position2;

### Example 15: {{tactic_name: "relative pin"}}
Question: Does the relative pin tactic support the move of the black queen from f6 to g6?
Answer:
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "relative pin"}}]->(s:Square {{position: "g6"}}) 
RETURN t.opponent_piece1 as opponent_piece1, t.opponent_color1 as opponent_color1, t.opponent_position1 as opponent_position1, t.opponent_piece2 as opponent_piece2, t.opponent_color2 as opponent_color2, t.opponent_position2 as opponent_position2;

### Example 16: {{tactic_name: "interference"}}
Question: Does the interference tactic support the move of the black queen from f6 to h6? 
Answer: 
MATCH (p:Piece {{piece: "queen", color: "black", position: "f6"}})-[t:Tactic {{tactic_name: "interference"}}]->(s:Square {{position: "h6"}})
RETURN t.opponent_piece1 as opponent_piece1, t.opponent_color1 as opponent_color1, t.opponent_position1 as opponent_position1, t.opponent_piece2 as opponent_piece2, t.opponent_color2 as opponent_color2, t.opponent_position2 as opponent_position2;

### Example 17: {{tactic_name: "mateIn2"}}
Question: Does the mate in two tactic support the move of the white queen from e4 to h7?
Answer: 
MATCH (p:Piece {{piece: "queen", color: "white", position: "e4"}})-[t:Tactic {{tactic_name: "mateIn2"}}]->(s:Square {{position: "h7"}})
RETURN t.ally_piece as ally_piece, t.ally_color as ally_color, t.ally_current_position as ally_current_position, t.ally_next_position as ally_next_position, t.opponent_piece as opponent_piece, t.opponent_color as opponent_color, t.opponent_current_position as opponent_current_position, t.opponent_next_position as opponent_next_position;

### Example 18: {{tactic_name: "mateIn1"}}
Question: Does the mate in one tactic support the move of the white queen from e4 to h7?
Answer: 
MATCH (p:Piece {{piece: "queen", color: "white", position: "e4"}})-[t:Tactic {{tactic_name: "mateIn1"}}]->(s:Square {{position: "h7"}})
RETURN t.opponent_piece as opponent_piece, t.opponent_color as opponent_color, t.opponent_position as opponent_position;

### Example 19: {{tactic_name: "hanging piece"}}
Question: Does the hanging piece tactic support the move of the white queen from e4 to h7?
Answer: 
MATCH (p:Piece {{piece: "queen", color: "white", position: "h7"}})-[t:Tactic {{tactic_name: "mateIn1"}}]->(s:Square {{position: "h4"}})
RETURN t.opponent_piece as opponent_piece, t.opponent_color as opponent_color, t.opponent_position as opponent_position

Use the following when assigning values to relationship's Properties:
    - Piece: {{piece: "", color: "", position: ""}}
    - Suggest: {{tactic: "threat"}}, {{tactic: "defend"}}, {{tactic: "fork"}}, {{tactic: "interference"}}, {{tactic: "mate"}}, {{tactic: "mateIn1"}}, {{tactic: "mateIn2"}}, {{tactic: "discoveredAttack"}}, {{tactic: "skewer"}}, {{tactic: "hangingPiece"}}, {{tactic: "pin"}}
    - Feature: {{feature: "move_is_attacked", piece: "", color: "", position: ""}}, {{feature: "move_defend", piece: "", color: "", position: ""}}, {{feature: "move_is_protected", piece: "", color: "", position: ""}} and {{feature: "move_threat", piece: "", color: "", position: ""}}

Use the following step-by-step process:
    1. Determine what are the pieces in the question which must be from the following list: [bishop, pawn, rook, king, queen, knight]
    2. Determine the color of the pieces in the question which must be from the following list: [white, black]
    3. Determine the postion of the piece in the question which is UCI format.
    4. Determine the correct relationshio in the question which is either a Suggest or Feature or Locate.
    5. Determine the correct property to use based on the following:
        a. If the question contain only "threat" word with no "move" word:
            - Please use the Suggest relationship with property {{tactic: "threat"}} in your Cypher Query only as in the Example 2.
        b. If the question contains only "defend" word with no "move" word:
            - Please use the Suggest relationship with property {{tactic: "defend"}} in your Cypher Query only as in the Example 1.
        c. If the question contains word "threat" or "attack" with a "move" word:
            - If the question is about an opponent (black or white) piece that attack a move then use the Feature relationship with property {{feature: "move_is_attacked"}}  as in the Example 4.
            - If the question is about an opponent (black or white) piece that is attacked by a move then use the Feature relationship with property {{feature: "move_threat"}} as in the Example 8.
        d. If the question contains word "defend" or "protect" with a "move" word:
            - If the question is about an ally (black or white) piece that defend or protect a move then use the Feature relationship with property {{feature: "move_is_protected"}} as in the Example 7.
            - If the question is about an ally (black or white) piece that is defended or protected by a move then use the Feature relationship with property {{feature: "move_defend"}} as in the Example 6.
        e. If the question is about position of the piece or the square that piece is located on then use Locate relationship as in Example 3.
    5. Generate a Cypher query from the Examples.
    6. Return the 'context' value from the result of Execution of Cypher Query even if the provided information does not need to mention anything about the question.
    
# Please follow the following output format: {{'context': [{{'p2.piece': 'queen', 'p2.color': 'white', 's2.position': 'e4'}}]}}
    Example: {{'query': 'What black pieces protect the black rook move from f8 to f3 {{piece}}: rook {{color}}: black {{old position}}: f8 {{next move}}: f3 {{opponent}}: {{relation}}: move_is_protected', 'result': "I don't know the answer.", {{'context': [{{'p1_old_pos': 'f8', 'p1_new_pos': 'f3', 'p2.piece': 'knight', 'p2.color': 'black', 's2.position': 'd4'}}]}}]}}
    Output: {{'context': [{{'p1_old_pos': 'f8', 'p1_new_pos': 'f3', 'p2.piece': 'knight', 'p2.color': 'black', 's2.position': 'd4'}}]}}

# Notes
    1. Please use "Feature" relationship when Questions is contains the word "move".
    2. NO piece with same position and color have a relationship with ITSELF!
    3. ONLY use color, piece, relations in the provided Schema!
    4. Use relationship Locate for location or position.
    5. Schema used is case sensitive, so please you must always lowercase values for properties such as "defend" NOT "Defends" or "DEFEND"!
    6. FOCUS ON THE ORDER in The Difference between "move_is_protected" and "move_defend" is that "move_is_protected" for a move that is protected by ally piece while "move_defend" for a move that protects an ally piece.
    7. FOCUS ON THE ORDER in The Difference between "move_is_attacked" and "move_threat" is that "move_is_attacked" for a move that is attacked by opponent piece while "move_threat" for a move that attack an opponent piece after the move.
    8. FOCUS that you understand relationship in the question carefully either based on Feature or Suggest.
    9. IF FULL CONTEXT is not empty YOU MUST USE it!
    10. ONLY USE the relation provided in the Action Input. please do not use any other relation!
    11. `result` MUST be based on the Full Context
    12. {{color}} and {{position}} MUST be based on the input ONLY!!!

Use Neo4j 5 Cypher syntax.  When checking a property is not null, use `IS NOT NULL`.

Question:
{question}

Cypher Query:
"""

cypher_prompt = PromptTemplate.from_template(CYPHER_GENERATION_TEMPLATE)

cypher_qa = GraphCypherQAChain.from_llm(
    llm,
    graph=graph,
    verbose=True,
    cypher_prompt=cypher_prompt,
    # return_intermediate_steps=True,
    return_direct=True,
    validate_cypher=True,
    handle_parsing_errors="If the generate Cypher Query syntax is incorrect or invalid, you MUST use FULL CONTEXT If output list is NOT EMPTY OTHERWISE TRY AGAIN",
)

