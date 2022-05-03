# Starkswap ERC20 Token Faucet


# Development prerequisites
This project uses python and gnu Make to build

Set up a python environment with the relevant packages, i.e. `cairo-lang`
```
python3 -m venv env
source env/bin/activate
pip3 install -r requirements.txt
```

Fetch the relevant dependencies (git submodules)
```
git submodule init
git submodule update
```

# Building the project

To build the contracts run 
```
make
```

To run the tests run

```
make test
```

To clean the artifacts run
```
make clean 
```
