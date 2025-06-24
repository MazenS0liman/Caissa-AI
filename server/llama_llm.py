import os
from langchain_groq import ChatGroq
import streamlit as st

llm = ChatGroq(
    temperature=0.7, 
    model_name="meta-llama/llama-4-scout-17b-16e-instruct", 
    api_key=st.secrets.get("GROQ_API_KEY")
)
