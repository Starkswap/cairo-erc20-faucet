fn setup() -> (ContractAddress, u256) {
    let initial_supply: u256 = u256_from_felt252(2000);
    let account: ContractAddress = contract_address_const::<1>();
    // Set account as default caller
    set_caller_address(account);

    ERC20::constructor(NAME, SYMBOL, initial_supply, account);
    (account, initial_supply)
}

#[test]
#[available_gas(2000000)]
fn test_initializer() {
}
