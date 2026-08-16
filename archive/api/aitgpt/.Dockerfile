FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

RUN apt update && apt upgrade -y
RUN apt install -y python3 python3-pip
RUN rm -rf /var/cache/apt/archives /var/lib/apt/lists/*.

EXPOSE 80

WORKDIR /root/code

RUN pip3 install numpy
RUN pip3 install pandas
RUN pip3 install matplotlib
RUN pip3 install seaborn
RUN pip3 install scikit-learn

RUN pip3 install langchain==0.0.162
RUN pip3 install beautifulsoup4
RUN pip3 install InstructorEmbedding
RUN pip3 install torch
RUN pip3 install sentence_transformers
RUN pip3 install python-dotenv
RUN pip3 install transformers
RUN pip3 install chromadb
RUN pip3 install fschat
RUN pip3 install accelerate
RUN pip3 install bitsandbytes
RUN pip3 install openai
RUN pip3 install plotly
RUN pip3 install streamlit
RUN pip3 install faiss-cpu
RUN pip3 install gspread
RUN pip3 install altair 
RUN pip3 install streamlit-chat
RUN pip3 install protobuf==3.20.1

COPY ./code /root/code
# CMD tail -f /dev/null
CMD streamlit run app.py --server.port=80 --server.address=0.0.0.0