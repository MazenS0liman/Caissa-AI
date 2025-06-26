# <img src="images/caïssa.png" alt="Caïssa Chatbot" width="100" align="center" style="margin-right: 10px;"/> Caïssa: Multi-Agent Neuorsymbolic  Approach for Chess

<img src="images/caïssa_main.jpeg" alt="Caïssa Main Image" align="center" style="width: 100%; height: auto;"/>

## Motivation
Caïssa is an approach that provides reasoning and understanding of the chess move. It transmits information represented in the knowledge base in Prolog to nodes and edges as a knowledge graph in Neo4j that can be queried directly to retrieve structured information from the knowledge graph. This information advocates the reasoning behind the suggested move. This allows to build dynamic ontologies as a solution where static ontologies would fail, since small variances between chessboards can have an enormous difference in the information represented in the ontology. By leveraging the capabilities of combining both a large model called Gemini and the existing knowledge in Neo4j using LangChain, Caïssa is capable of creating chess commentary based on user input related to piece positions and relations between pieces on a chessboard and providing a move commentary. Caïssa also utilizes a newly introduced library called LangGraph to implement a verification module that acts as a guard to prevent any incorrectly generated commentary where the results obtained from the system almost contain no hallucinations. This prototype can be scaled to be a software solution that assists in teaching beginners chess rules and tactics, where existing solutions either provide a basic explanation or statistical representation that does not help a beginner understand the reason behind a chess move.

## Video
https://github.com/user-attachments/assets/6b49da4f-532f-480b-a69e-00d359e66eeb

> [!NOTE]
> The chatbot was previously called Eureka, but we changed it to Caïssa to match the theme.

## Architecture
### Caïssa's Architecture
As an approach for creating a system capable of generating chess commentary and diminishes the amount of hallucination. Caïssa grounds LLM, which is Gemini with the built knowledge graphs in Neo4j, which result in the construction of a Retrieval Augmented Generation (RAG) system that enhances the outcome of large language model (LLM) based on the facts stored in the knowledge graph in Neo4j.

Caïssa utilizes LangChain that allow to create agents from Large Language Models such as Gemini and specify the purpose of each agent using Prompt Engineering by specifying its role and context and giving it examples of how to perform its task. The process of providing chess commentary is the following:
1. User clicks on the toggle button to use Gemini and sends a request from the browser using Next.js with a query in natural language.
2. The request is handled at the backend using APIs in Flask, which contains an instance of the chess commentary agent.
3. The agent is configured with tools that allow it to use other agents by forming chains for a specific type of question, such as for questions that are related to chess pieces position and moves, it would use GraphCypherQAChain from LangChain to generate a Cypher query that can be executed and retrieve a structured response that is sent to the main agent to transform it back to natural language, or if the query is about tactics, it would use the basic neurosymbolic module and summarise its answer.
4. In both cases, the retrieved answer, either from sub-agent or from the neurosymbolic module, is sent back to the user in the body of the response to the request made in the browser.

<img src="images/caïssa_solver_basic_architecture.png" alt="Caïssa Basic Architecture Image" align="center" style="margin: 10px;"/>

### Example
Let’s call the first agent “the conductor” which is a person who directs the performance of an orchestra as it orchestrate what module to use based on the user question and what information to pass to the modules.

In the following, more explanation will be provided for step number 4 in the process. After the conductor receives a question from the user, it determines which tool
to pick. The options are the GraphCypherQA Chain tool, responsible for generating Cypher queries and executing them to retrieve an answer usable by the conductor for generating chess commentary, or the Chess Solver Chain tool, which utilizes a neurosymbolic module to provide a chess move suggestion from [ChessGPT](https://arxiv.org/abs/2306.09200) and its corresponding tactic.

If the conductor choses the GraphCypherQA Chain tool then it is capable of grounding LLM based on the context stored in the knowledge graph in Neo4j, built using Prolog, to derive the correct response to a user query.

<img src="images/caïssa_commentary_example_diagram.png" alt="Caïssa Example Image" align="center" style="margin: 10px;"/>

### Final Architecure Overview
Even though progress was made in providing chess commentary with logical correctness, challenges were encountered. Obstacles arose as the model did not consistently
generate answers for the same prompt. Responses varied from full answers to partial ones, or no answer at all with the statement that it did not know the answer. Additionally, efforts were made to minimise hallucination, achieved by prompting the LLM to provide answers based on information in the knowledge graph in Neo4j. However, there is still a risk of hallucination, as LLM (the conductor) may deviate from the prompt and provide an answer from its knowledge. To mitigate this, the whole architecture of Caïssa was modified by adding the verifier module as an attempt to solve this problem using LangGraph.

<img src="images/caïssa_overall_architecture.png" alt="Caïssa Final Architecture Image" align="center" style="margin: 10px;"/>

LangGraph enables the coordination of multiple agents across numerous steps of computation in a cyclic manner. The verifier module consists of two phases after receiving the chess commentary from the chess commentary agent and the Forsyth-Edwards Notation (FEN) representation of the chessboard.

#### First Phase
1. The verifier agent determines the type of the commentary.
2. Based on the type of commentary determined by the verifier agent, a corresponding module would be executed to validate the chess commentary

<img src="images/verifier_arch.png" alt="Verifier Module Phase 1 Image" align="center" style="margin: 10px;"/>

#### Second Phase
Every module follows a number of steps, utilising tiny agents to perform various tasks. The overall process is as follows:
1. **Tiny Agent 1**: The main purpose of this agent is to split chess commentary into multiple simple statements to process them later on by the rest of the agents in the pipeline. The chess commentary can sometimes be complex, involving multiple pieces of information about various chess pieces.
2. **Tiny Agent 2**: This agent is utilising the KOR library, which is a wrapper over the LLM, to retrieve structured data from the LLM, which constructs a JSON representation of every statement received from the previous agent.
3. **Symbolic Module**: This module either utilises a knowledge base in Prolog or a knowledge graph in Neo4j to execute queries based on the data included in the JSON format of every statement. Moreover, this module filters out any incorrect information from the chess commentary and outputs the correct statements and include any missing information in the chess commentary, such as position or the color of a piece.
4. **Tiny Agent 3**: This agent receives the output of the previous symbolic module and augments the missing information in each statement.

<img src="images/verifier_module.png" alt="Verifier Module Phase 2 Image" align="center" style="margin: 10px;"/>

## Features
### Chat with Caïssa <img src="images/message.png" alt="Message Image" width="50" align="left" style="margin-right: 10px;"/>
Engage with Caïssa to grasp tactics and counterattacks for each move.

### Speak to Caïssa <img src="images/mic.png" alt="Message Image" width="50" align="left" style="margin-right: 10px;"/>
An exciting Speech-Recognition feature that lets you interact with Caïssa using your voice! (Supported only in Chrome)

### Reset Chessboard <img src="images/reset.png" alt="Message Image" width="50" align="left" style="margin-right: 10px;"/>
Reset the chessboard to the initial state (Forsyth-Edwards Notation: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1).

### Edit Chessboard <img src="images/edit.png" alt="Message Image" width="50" align="left" style="margin-right: 10px;"/>
Get creative with the chessboard by customizing it using Forsyth-Edwards Notation!

### Change Theme <img src="images/threed.png" alt="Message Image" width="50" align="left" style="margin-right: 10px;"/>
Customize the chessboard theme to your preference.

## Frameworks and Technologies Used

### Frontend
* **Next.js**: A React framework that enables functionality such as server-side rendering and generating static websites for React-based web applications.

* **Typescript**: A strongly typed programming language that builds on JavaScript that allow specifying the types of data being passed around within the code, and has the ability to report errors when the types don't match 

* **Three.js**: A JavaScript library that makes it easy to create 3D graphics for web applications using WebGL.

### Backend
* **Flask**: A lightweight WSGI web application framework in Python. It is designed to make getting started quick and easy create REST APIs.

* **Neo4j**: A graph database management system that allows for the representation and querying of data as graphs.

* **Gemini**: A platform and model designed for integrating large language model that can be tuned using prompt engineering and other technologies.

* **Hugging Face**: A machine learning (ML) and data science platform and community that helps users build, deploy and train machine learning models.

* **SWI-Prolog**: A declarative programming language that enforces chess logic by providing a robust framework for representing and reasoning about chess rules and strategies.


## Credits
### Libraries
* [LangChain](https://github.com/langchain-ai/langchain): A library for developing applications powered by language models. It provides a comprehensive set of tools for building, deploying, and managing language model-based applications.
* [LangGraph](https://github.com/langchain-ai/langgraph): A library designed to integrate graph databases and knowledge graphs with language models, enhancing the ability to query and reason about structured data.
* [React Chessboard](https://github.com/Clariity/react-chessboard): A library that provides a customizable chessboard UI.
  
### Resources
* [3D Icons](https://3dicons.co/): Credits to the creators for providing 3D icons that enhance user experience.

## Screenshots
### Chessboard
<img src="images/caïssa_default_chessboard.jpeg" alt="Caïssa Default Image" align="center" style="margin-right: 10px;"/>

### Change Chessboard Theme
<img src="images/caïssa_3d_chessboard.jpeg" alt="Caïssa 3D Chessboard Image" align="center" style="margin-right: 10px;"/>

### Edit Chessboard
<img src="images/caïssa_edit.jpeg" alt="Caïssa Edit Image" align="center" style="margin-right: 10px;"/>

### Chat with Caïssa
<img src="images/caïssa_chat_1.jpeg" alt="Caïssa Chat Image 1" align="center" style="margin-right: 10px;"/>

### Chat with Reinforced Caïssa
<img src="images/caïssa_chat_reinforced.jpeg" alt="Caïssa Chat Reinforced Image" align="center" style="margin-right: 10px;"/>

### Speak to Caïssa
<img src="images/caïssa_speak.jpeg" alt="Caïssa Speak Image" align="center" style="margin-right: 10px;"/>

## Tactics & Concepts
### Tactics
The following table demonstrate tactics that are supported by basic Caïssa.

**Tactic**  | **Definition**
------------- | -------------
**Fork**  | A fork occurs when an ally piece can threat two or more pieces at the same time.
**Discover attack**  | A discover attack occurs when an ally piece is moved such that it allows another ally piece to attack opponent’s piece that was previously blocked.
**Discover check** | A discover check occurs when an ally piece is moved such that it allows another ally piece to check the opponent’s king.
**Skewer** | A skewer occurs when two opponent pieces are aligned such that an ally piece causes a threat to the more valuable opponent piece, where the move of the more valuable piece would result in the capture of the less or equal valuable opponent piece by the same ally piece.
**Relative pin** | A relative pin occurs when a less valuable opponent piece is aligned with a more valuable opponent piece, such that if the less valuable opponent piece moved, it would cause the more valuable opponent piece to be captured.
**Absolute pin** | An absolute pin occurs when an opponent piece is aligned with the opponent king such that if the opponent piece moved, it would cause the king to be checked.
**Hanging piece** | A hanging piece is an opponent piece that can be captured and there is no other opponent piece that can defend it.
**Mate in one** | A mate in one occurs when there is a single move that would cause the opponent to be checkmated.
**Mate in two** | A mate in two occurs when there are two moves that would cause the opponent to be checkmated.
**Interference** | An interference occurs when there is a move that interferes between opponent pieces where one of the pieces defends the other piece.

### Concepts
The following table demonstrate concepts that are supported by both basic and reinforced Caïssa.

**Concept**  | **Definition**
------------- | -------------
**Defend** | Whether a piece can defend or protect the ally piece directly.
**Threat** | Whether an opponent piece such that piece can attack or threat the opponent directly.
**Move defend** | A move made by a piece from its current position to new position to defend an ally piece on a third different position.
**Move is protected** | A move made by a piece from its current position to new position and it is protected by an ally piece on a third different position at the new position.
**Move threat** | A move made by a piece from its current position to new position to attack an opponent piece on a third different position.
**Move is attacked** | A move made by a piece from its current position to new position and it is attacked by an opponent piece on a third different position at the new position.

## Code Snippets
### Build Knowledge Graph with Multiprocessing
```python
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
```

### Chat with Reinforced Caïssa with LangGraph
```python
def chat(input, fen_string) -> str:
    '''
    Starts the pipeline for either generating chess commentary or building new relations.
    
    :param: :input: user query
    :param: :fen_string: current forsyth-edwards notation of a chessboard 
    
    :return: text generated from the chatbot
    '''
    
    inputs = {"input": input, "status": "Begin", "fen": fen_string}
    
    results = []
    
    try:   
        for s in app.stream(inputs):
            result = list(s.values())[0]
            results.append(result)
            print(bcolors.OKGREEN + "Result:" + bcolors.ENDC, result)
        
        return results[-1]['final_answer']
    except:
        return "Sorry, I do not know the answer!"
```

## API Reference
#### Chat With Caïssa
* **Endpoint**: `chatbot`
* **Method**: GET
* **Description**: Chat with Caïssa.
  
#### Chat With Reinforced Caïssa
* **Endpoint**: `reinforced_chatbot`
* **Method**: GET
* **Description**: Chat with Caïssa enhanced by LangGraph.

#### Retrieve Legal Moves
* **Endpoint**: `legal_moves`
* **Method**: GET
* **Description**: Fetch legal moves of a chess piece.
  
#### Set FEN
* **Endpoint**: `set_fen`
* **Method**: POST
* **Description**: Set a forsyth-edwards notation.

#### Move a Chess Piece
* **Endpoint**: `make_move`
* **Method**: POST
* **Description**: Move a chess piece from a position to another position.

## Installation Guide
### 1. Install SWIPL
* Follow the installation instructions in this [video tutorial](https://www.youtube.com/watch?v=FE1d5vauTlU).

### 2. Obtain Your Tokens
* **NEO4J Token:** Get your token from [Neo4j Aura](https://neo4j.com/cloud/platform/aura-graph-database/?ref=docs-nav-get-started).
* **GEMINI Token:** Generate your token through [AI Studio](https://aistudio.google.com/app/apikey).
* **Groq Token:** Generate your token from [Groq](https://console.groq.com/keys).

## Requirements

- **Python**: ≥ 3.10  
- **OS**: Linux or WSL on Windows

## Usage Instructions
### 1. Configure Tokens:
  *  Open the `Caïssa/.streamlit/secrets.toml` file.
  *  Set your Gemini and Neo4j tokens in the file.

### 2. Set Up the Client:
  * Navigate to the **client** directory: 
    ```
    cd client
    ```
  * Install the necessary dependencies:
    ```
    npm install
    ```
  * Build the app:
    ```
    npm run build
    ```
  * Return to the root directory:
    ```
    cd ..
    ```

### 3. Set Up the Server:
  * Navigate to the **server** directory:
    ```
    cd server
    ```
  * Create a virtual environment **proj_env**:
    ```
    python3 -m venv proj_env
    ```
  * Activate the virtual environment:
    ```
    source proj_env/bin/activate
    ```
  * Install the required Python packages:
    ```
    pip install -r requirements.txt
    ```
  * Return to the root directory:
    ```
    cd ..
    ```

### 4. Start the Application:
  * Run the application using:
    ```
    ./start.exe
    ```

## :warning: Note
- Caïssa requires lots of computational power, so it tends to run slowly on older devices.
- To chat with Caïssa you need to toggle the button first.

> [!CAUTION]
> Although the verifier module was added to Caïssa to reduce the occurrence of hallucinations, it can still make mistakes.

## Contribute
Caïssa is still in its prototype stage and could be improved with additional logic to fully grasp all aspects of a chess game, ultimately becoming a comprehensive tool to assist chess beginners.

## License
This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

## Hope You Enjoy :heart:
<img src="images/flower.png" alt="Caïssa Example Image" align="center" style="margin: 10px;"/>
