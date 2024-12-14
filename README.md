# nodeenv
The multiple versions node tool

# configuration 
git clone https://github.com/ericli2086/nodeenv.git

chmod +x nodeenv.sh

ln -s nodeenv.sh /usr/local/bin/nodeenv

nodeenv setup >> ~/.bashrc

source ~/.bashrc

# install the pointed version 
nodeenv install 22.12.0

# list available node version
nodeenv versions

# set node version for project 
nodeenv local 22.12.0
