import torch
import transformers
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import re

MIN_TRANSFORMERS_VERSION = '4.25.1'

# check transformers version
assert transformers.__version__ >= MIN_TRANSFORMERS_VERSION, f'Please upgrade transformers to version {MIN_TRANSFORMERS_VERSION} or higher.'

class ChessGPT:
    def __init__(self):
        self.tokenizer = AutoTokenizer.from_pretrained("/mnt/d/MET/College/Semester8/Project/Neuro-Symbolic-Chess-Solver/neurosymbolicAI/llmAI")
        self.model = AutoModelForCausalLM.from_pretrained("/mnt/d/MET/College/Semester8/Project/Neuro-Symbolic-Chess-Solver/neurosymbolicAI/llmAI", low_cpu_mem_usage=True, trust_remote_code=True, torch_dtype=torch.float32)
        self.model = self.model.to('cpu')
        self.generator = pipeline(task="text-generation", model=self.model, tokenizer=self.tokenizer, model_kwargs={'device_map': "auto", "load_in_8bit": True}, max_new_tokens=200)
             
        
    def predict(self, fen_string):
        prompt = f"""With the FEN board state {fen_string} give next UCI move?"""
        inputs = self.tokenizer(prompt, return_tensors='pt').to(self.model.device)
        input_length = inputs.input_ids.shape[1]
        outputs = self.model.generate(
            **inputs, max_new_tokens=10, do_sample=True, temperature=0.1, top_p=0.7, top_k=50, return_dict_in_generate=True, pad_token_id=self.tokenizer.eos_token_id, 
        )
        
        token = outputs.sequences[0, input_length:]
        output_str = self.tokenizer.decode(token)
        return output_str
    
    def play_puzzle(self, fen_string, strategies):
        ls = ""

        for strategy in strategies:
            if ls == "":
                ls = strategy
            else:
                ls = ls + ", " + strategy

        prompt = f"""Try your hand at this chess puzzle. The board’s FEN is
        {fen_string}, and you need to
        determine the optimal move for the player. This puzzle focuses on
        {ls}. The solutions are provided in both SAN format as 
        """

        inputs = self.tokenizer(prompt, return_tensors='pt').to(self.model.device)
        input_length = inputs.input_ids.shape[1]
        outputs = self.model.generate(
            **inputs, max_new_tokens=128, do_sample=True, temperature=0.01, top_p=0.7, top_k=50, return_dict_in_generate=True, pad_token_id=self.tokenizer.eos_token_id
        )
        
        token = outputs.sequences[0, input_length:]
        output_str = self.tokenizer.decode(token)
        
        return self.extract_uci(output_str)
        
    def ask(self, prompt):
        inputs = self.tokenizer(prompt, return_tensors='pt').to(self.model.device)
        input_length = inputs.input_ids.shape[1]
        outputs = self.model.generate(
            **inputs, max_new_tokens=128, do_sample=True, temperature=0.7, top_p=0.7, top_k=50, return_dict_in_generate=True, pad_token_id=self.tokenizer.eos_token_id
        )
        
        token = outputs.sequences[0, input_length:]
        output_str = self.tokenizer.decode(token)
        
        return output_str
    
    def extract_uci(self, fen_string):
        # Regular expression pattern to match UCI moves
        pattern = r"[a-h][1-8][a-h][1-8]"

        # Search for the pattern in the string
        match = re.search(pattern, fen_string)

        # Extract the UCI move if a match is found
        uci_move = ""
        if match:
            uci_move = match.group()

        return uci_move
    
    def pipeline(self, prompt):
        output = self.generator(prompt)
        return output
