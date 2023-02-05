# Starkswap ERC20 Token Faucet


# Development prerequisites

Clone the [starknet cairo repository](https://github.com/starkware-libs/cairo) and build the `starknet-compile` tool
```
git clone git@github.com:starkware-libs/cairo.git
cd cairo
cargo build --bin starknet-compile
```

Take a note of the directory as we'll need it later. 
The binary should be found in `clone_dir/target/debug/starknet-compile`

# Building the project

To build the contracts run 
```
STARKNET_COMPILE=<path-to-binary> make
```

To clean the artifacts run
```
make clean 
```
