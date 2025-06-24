import torch
import transformers
from transformers import AutoConfig, AutoTokenizer, AutoModelForCausalLM
import intel_extension_for_pytorch as ipex
import argparse
from io import StringIO
import re
import chess

MIN_TRANSFORMERS_VERSION = '4.25.1'

# check transformers version
assert transformers.__version__ >= MIN_TRANSFORMERS_VERSION, f'Please upgrade transformers to version {MIN_TRANSFORMERS_VERSION} or higher.'

parser = argparse.ArgumentParser("Generation script (fp32/bf16 path)", add_help=False)

parser.add_argument("--greedy", action="store_true")
parser.add_argument("--batch-size", default=1, type=int, help="batch size")
args = parser.parse_args()
print(args)

# dtype
amp_enabled = True if args.dtype != "float32" else False
amp_dtype = getattr(torch, args.dtype)

tokenizer = AutoTokenizer.from_pretrained("/mnt/d/MET/College/Semester8/Project/Neuro-Symbolic-Chess-Solver/neurosymbolicAI/llmAI", trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained("/mnt/d/MET/College/Semester8/Project/Neuro-Symbolic-Chess-Solver/neurosymbolicAI/llmAI",  torch_dtype=amp_dtype, low_cpu_mem_usage=True, trust_remote_code=True, low_cpu_mem_usage=True, trust_remote_code=True,torch_dtype=torch.float32)
model = model.to('cpu')
model.to_bettertransformer()

model = ipex.llm.optimize(
    model,
    inplace=True,
    deployment_mode=True,
)

# generate args
num_beams = 1 if args.greedy else 4
generate_kwargs = dict(do_sample=False, temperature=0.9, num_beams=num_beams)

# input prompt
prompt = args.prompt
input_size = tokenizer(prompt, return_tensors="pt").input_ids.size(dim=1)
print("---- Prompt size:", input_size)
prompt = [prompt] * args.batch_size

# inference
with torch.no_grad(), torch.inference_mode(), torch.cpu.amp.autocast(enabled=amp_enabled):
    input_ids = tokenizer(prompt, return_tensors="pt").input_ids
    gen_ids = model.generate(
        input_ids,
        max_new_tokens=args.max_new_tokens,
        **generate_kwargs
    )
    gen_text = tokenizer.batch_decode(gen_ids, skip_special_tokens=True)
    input_tokens_lengths = [x.shape[0] for x in input_ids]
    output_tokens_lengths = [x.shape[0] for x in gen_ids]
    total_new_tokens = [
        o - i for i, o in zip(input_tokens_lengths, output_tokens_lengths)
    ]
    print(gen_text, total_new_tokens, flush=True)