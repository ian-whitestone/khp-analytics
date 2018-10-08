conda env create -f environment.yml
conda activate khp-analytics

## Spacy stuff
conda install -c conda-forge spacy -y
python -m spacy download en
python -m spacy download fr

## Gensim for word2vec
conda install -c conda-forge gensim

# download binary file from here: https://drive.google.com/file/d/0B7XkCwpI5KDYNlNUTTlSS21pQmM/edit
