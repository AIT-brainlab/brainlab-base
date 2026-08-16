#This version includes the memory and custom prompt, representing the final version

import streamlit as st
from streamlit_chat import message as st_message
import pandas as pd
import numpy as np
import datetime
import gspread
import pickle
import os
import csv
import json
import torch
from tqdm.auto import tqdm
from langchain.text_splitter import RecursiveCharacterTextSplitter


# from langchain.vectorstores import Chroma
from langchain.vectorstores import FAISS
from langchain.embeddings import HuggingFaceInstructEmbeddings


from langchain import HuggingFacePipeline
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferWindowMemory


from langchain.chains import LLMChain
from langchain.chains import ConversationalRetrievalChain
from langchain.chains.question_answering import load_qa_chain
from langchain.chains.conversational_retrieval.prompts import CONDENSE_QUESTION_PROMPT



prompt_template = """
You are the chatbot and the face of Asian Institute of Technology (AIT). Your job is to give answers to prospective and current students about the school.
Your job is to answer questions only and only related to the AIT. Anything unrelated should be responded with the fact that your main job is solely to provide assistance regarding AIT.
MUST only use the following pieces of context to answer the question at the end. If the answers are not in the context or you are not sure of the answer, just say that you don't know, don't try to make up an answer.
{context}
Question: {question}
When encountering abusive, offensive, or harmful language, such as fuck, bitch,etc,  just politely ask the users to maintain appropriate behaviours.
Always make sure to elaborate your response and use vibrant, positive tone to represent good branding of the school.
Never answer with any unfinished response
Answer:
"""
PROMPT = PromptTemplate(
    template=prompt_template, input_variables=["context", "question"]
)
chain_type_kwargs = {"prompt": PROMPT}


st.set_page_config(
    page_title = 'aitGPT',
    page_icon = '✅')




@st.cache_data
def load_scraped_web_info():
    with open("ait-web-document", "rb") as fp:
        ait_web_documents = pickle.load(fp)
        
        
    text_splitter = RecursiveCharacterTextSplitter(
        # Set a really small chunk size, just to show.
        chunk_size = 500,
        chunk_overlap  = 100,
        length_function = len,
    )

    chunked_text = text_splitter.create_documents([doc for doc in tqdm(ait_web_documents)])


@st.cache_resource
def load_embedding_model():
    embedding_model = HuggingFaceInstructEmbeddings(model_name='hkunlp/instructor-base',
                                                    cache_folder='/root/.cache',
                                                model_kwargs = {'device': torch.device('cuda' if torch.cuda.is_available() else 'cpu')})
    return embedding_model

@st.cache_data
def load_faiss_index():
    vector_database = FAISS.load_local("faiss_index_web_and_curri_new", embedding_model) #CHANGE THIS FAISS EMBEDDED KNOWLEDGE
    return vector_database

@st.cache_resource
def load_llm_model_cpu():
    llm = HuggingFacePipeline.from_model_id(model_id= 'lmsys/fastchat-t5-3b-v1.0', 
                            task= 'text2text-generation',        
                            model_kwargs={ "max_length": 256, "temperature": 0,
                                            "torch_dtype":torch.float32,
                                        "repetition_penalty": 1.3})

    return llm

@st.cache_resource
def load_llm_model_gpu(gpu_id:int ):
    llm = HuggingFacePipeline.from_model_id(model_id= 'lmsys/fastchat-t5-3b-v1.0', 
                                            task= 'text2text-generation',
                                            device=gpu_id,
                                            model_kwargs={ "device_map": "auto",
                                                        # "load_in_8bit": True,
                                                        "max_length": 256, 
                                                        "temperature": 0,
                                                        "repetition_penalty": 1.5},
                                            )

    return llm


@st.cache_resource
def load_conversational_qa_memory_retriever():

    question_generator = LLMChain(llm=llm_model, prompt=CONDENSE_QUESTION_PROMPT)
    doc_chain = load_qa_chain(llm_model, chain_type="stuff", prompt = PROMPT)
    memory = ConversationBufferWindowMemory(k = 3,  memory_key="chat_history", return_messages=True,  output_key='answer')
    
    
    
    conversational_qa_memory_retriever = ConversationalRetrievalChain(
        retriever=vector_database.as_retriever(),
        question_generator=question_generator,
        combine_docs_chain=doc_chain,
        return_source_documents=True,
        memory = memory,
        get_chat_history=lambda h :h)
    return conversational_qa_memory_retriever, question_generator

def load_retriever(llm, db):
    qa_retriever = RetrievalQA.from_chain_type(llm=llm, chain_type="stuff",
                            retriever=db.as_retriever(),
                            chain_type_kwargs= chain_type_kwargs)

    return qa_retriever

def retrieve_document(query_input):
    related_doc = vector_database.similarity_search(query_input)
    return related_doc



def retrieve_answer():
    prompt_answer=  st.session_state.my_text_input
    answer = qa_retriever.run(prompt_answer)
    log = {"timestamp": datetime.datetime.now(),
        "question":st.session_state.my_text_input,
        "generated_answer": answer[6:],
        "rating":0 }

    st.session_state.history.append(log)
    update_worksheet_qa()
    st.session_state.chat_history.append({"message": st.session_state.my_text_input, "is_user": True})
    st.session_state.chat_history.append({"message": answer[6:] , "is_user": False})

    st.session_state.my_text_input = ""

    return answer[6:] #this positional slicing helps remove "<pad> " at the beginning


def new_retrieve_answer():
    prompt_answer=  st.session_state.my_text_input + ". Try to be elaborate and informative in your answer."
    answer = conversational_qa_memory_retriever({"question": prompt_answer, })
    log = {"timestamp": datetime.datetime.now(),
        "question":st.session_state.my_text_input,
        "generated_answer": answer['answer'][6:],
        "rating":0 }

    print(f"condensed quesion : {question_generator.run({'chat_history': answer['chat_history'], 'question' : prompt_answer})}")

    print(answer["chat_history"])
    st.session_state.history.append(log)
    update_worksheet_qa()
    st.session_state.chat_history.append({"message": st.session_state.my_text_input, "is_user": True})
    st.session_state.chat_history.append({"message": answer['answer'][6:] , "is_user": False})

    st.session_state.my_text_input = ""

    return answer['answer'][6:] #this positional slicing helps remove "<pad> " at the beginning
    
# def update_score():
#     st.session_state.session_rating = st.session_state.rating


def update_worksheet_qa():
    # st.session_state.session_rating = st.session_state.rating
    #This if helps validate the initiated rating, if 0, then the google sheet would not be updated
    #(edited) now even with the score of 0, we still want to store the log because some users do not give the score to complete the logging
    # if st.session_state.session_rating  == 0:
    worksheet_qa.append_row([st.session_state.history[-1]['timestamp'].strftime(datetime_format), 
                            st.session_state.history[-1]['question'],
                            st.session_state.history[-1]['generated_answer'],
                             0])
    # else:
    #     worksheet_qa.append_row([st.session_state.history[-1]['timestamp'].strftime(datetime_format), 
    #                             st.session_state.history[-1]['question'],
    #                             st.session_state.history[-1]['generated_answer'], 
    #                             st.session_state.session_rating 
    #                             ])
        
def update_worksheet_comment():
    worksheet_comment.append_row([datetime.datetime.now().strftime(datetime_format),
                                feedback_input])
    success_message = st.success('Feedback successfully submitted, thank you', icon="✅",
               )
    time.sleep(3)
    success_message.empty()


def clean_chat_history():
    st.session_state.chat_history = []
    conversational_qa_memory_retriever.memory.chat_memory.clear() #add this to remove

#--------------


if "history" not in st.session_state: #this one is for the google sheet logging
    st.session_state.history = []


if "chat_history" not in st.session_state: #this one is to pass previous messages into chat flow
    st.session_state.chat_history = []
# if "session_rating" not in st.session_state:
#     st.session_state.session_rating = 0


credentials= st.secrets['google_sheet_credential']

service_account = gspread.service_account_from_dict(credentials)
workbook= service_account.open("aitGPT-qa-log")
worksheet_qa = workbook.worksheet("Sheet1")
worksheet_comment = workbook.worksheet("Sheet2")
datetime_format= "%Y-%m-%d %H:%M:%S"



load_scraped_web_info()
embedding_model = load_embedding_model()
vector_database = load_faiss_index()

enable_gpu = int(os.environ['enable_gpu'])
gpu_id = int(os.environ['gpu_id'])
llm_model = None
if(enable_gpu == 1):
    print(f"{enable_gpu=} {gpu_id=}")
    llm_model = load_llm_model_gpu(gpu_id)
else:
    print(f"Load LLM CPU model")
    llm_model = load_llm_model_cpu()
qa_retriever = load_retriever(llm= llm_model, db= vector_database)
conversational_qa_memory_retriever, question_generator = load_conversational_qa_memory_retriever()
print("all load done")


# Try adding this to set to clear the memory in each session
if st.session_state.chat_history == []:
    conversational_qa_memory_retriever.memory.chat_memory.clear()
#Addional things for Conversation flows






st.write("# aitGPT 🤖 ")
st.markdown("""
         #### The aitGPT project is a virtual assistant developed by the :green[Asian Institute of Technology] that contains a vast amount of information gathered from 205 AIT-related websites.  
        The goal of this chatbot is to provide an alternative way for applicants and current students to access information about the institute, including admission procedures, campus facilities, and more.  
          """)
st.write(' ⚠️ Please expect to wait **~ 10 - 20 seconds per question** as thi app is running on CPU against 3-billion-parameter LLM')

st.markdown("---")
st.write(" ")
st.write("""
         ### ❔ Ask a question
         """)


for chat in st.session_state.chat_history:
    st_message(**chat)

query_input = st.text_input(label= 'What would you like to know about AIT?' , key = 'my_text_input', on_change= new_retrieve_answer )
# generate_button = st.button(label = 'Ask question!')

# if generate_button:
#     answer = retrieve_answer(query_input)
#     log = {"timestamp": datetime.datetime.now(),
#         "question":query_input,
#         "generated_answer": answer,
#         "rating":0 }

#     st.session_state.history.append(log)
#     update_worksheet_qa()
#     st.session_state.chat_history.append({"message": query_input, "is_user": True})
#     st.session_state.chat_history.append({"message": answer, "is_user": False})

#     print(st.session_state.chat_history)


clear_button = st.button("Start new convo",
                         on_click=clean_chat_history)


st.write(" ")
st.write(" ")

st.markdown("---")
st.write("""
         ### 💌 Your voice matters
         """)

feedback_input = st.text_area(label= 'please leave your feedback or any ideas to make this bot more knowledgeable and fun')
feedback_button = st.button(label = 'Submit feedback!')

if feedback_button:
    update_worksheet_comment()