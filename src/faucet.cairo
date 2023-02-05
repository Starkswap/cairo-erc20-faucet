#[contract]
mod StarkswapTokenFaucet {
    use erc20faucet::ierc20::IERC20;
    use erc20faucet::ierc20::IERC20DispatcherTrait;
    use erc20faucet::ierc20::IERC20Dispatcher;
    use starknet::ContractAddress;
    use zeroable::Zeroable;
    use integer::u256_from_felt252;
    use starknet::get_caller_address;
    use starknet::get_contract_address;

    #[derive(Copy, Drop, Serde)]
    struct FaucetConfig {
        max_balance: u256,
        max_topup: u256
    }

    struct Storage {
        sv_owner_address: ContractAddress,
        sv_token_address: ContractAddress,
        sv_max_balance: u256,
        sv_max_topup: u256
    }


    #[event]
    fn ev_balance_too_high(balance: u256, max: u256) {
    }

    #[constructor]
    fn constructor(token_address: ContractAddress) {
        sv_owner_address::write(get_caller_address());
        sv_token_address::write(token_address);
        sv_max_balance::write(u256_from_felt252(1000));
        sv_max_topup::write(u256_from_felt252(100));
    }


    #[view]
    fn mintable_amount(recipient: ContractAddress) -> (u256) {
        let token_address = sv_token_address::read();
        let faucet_address = get_contract_address();
        let faucet_config = FaucetConfig {
            max_balance: sv_max_balance::read(),
            max_topup: sv_max_topup::read()
        };

        let user_balance: u256 = IERC20Dispatcher{contract_address: token_address}.balance_of(recipient);

        if (user_balance < faucet_config.max_balance) {
            let faucet_balance = IERC20Dispatcher{contract_address: token_address}.balance_of(faucet_address);

            let full_topup_amount = faucet_config.max_balance - user_balance;
            let allowed_topup_amount = if full_topup_amount < faucet_config.max_topup {
                full_topup_amount
            } else {
                faucet_config.max_topup
            };

            return if allowed_topup_amount < faucet_balance {
                allowed_topup_amount
            } else {
                faucet_balance
            };
        } else {
            ev_balance_too_high(user_balance, faucet_config.max_balance);
        }

        return u256_from_felt252(0);
    }


    #[external]
    fn mint(amount: u256) {
        let faucet_config = FaucetConfig {
            max_balance: sv_max_balance::read(),
            max_topup: sv_max_topup::read()
        };
        let recipient = get_caller_address();
        let token_address = sv_token_address::read();

        let user_balance = IERC20Dispatcher{contract_address: token_address}.balance_of(recipient);

        let topup = faucet_config.max_balance - user_balance;
        assert(topup > u256_from_felt252(0), 'Balance too high');
        assert(topup <= faucet_config.max_topup, 'Topup amount too high');

        IERC20Dispatcher{contract_address: token_address}.transfer(recipient, amount);
    }

    #[view]
    fn get_owner() -> ContractAddress {
        return sv_owner_address::read();
    }

    #[view]
    fn get_token() -> ContractAddress {
        return sv_token_address::read();
    }

    #[view]
    fn get_faucet_balance() -> u256 {
        let token_address = sv_token_address::read();
        let faucet_address = get_contract_address();

        let balance = IERC20Dispatcher{contract_address: token_address}.balance_of(faucet_address);
        return balance;
    }

    #[view] 
    fn get_faucet_config() -> FaucetConfig {
        return FaucetConfig {
            max_balance: sv_max_balance::read(),
            max_topup: sv_max_topup::read()
        };
    }


    #[external]
    fn set_token(token_address: ContractAddress) {
        assert_only_owner();

        sv_token_address::write(token_address);
    }

    #[external]
    fn set_faucet_config(max_balance: u256, max_topup: u256) {
        assert_only_owner();

        sv_max_balance::write(max_balance);
        sv_max_topup::write(max_topup);
    }

    #[external]
    fn transfer_ownership(new_owner: ContractAddress) {
        assert_only_owner();
        assert(new_owner != Zeroable::zero(), 'Ownable: new owner is zero');

        sv_owner_address::write(new_owner);
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) {
        assert_only_owner();

        let token_address = sv_token_address::read();
        IERC20Dispatcher{contract_address: token_address}.transfer(recipient, amount);
    }

    fn assert_only_owner() {
        let caller_address = get_caller_address();
        assert(caller_address != Zeroable::zero(), 'Ownable: caller is zero address');
        assert(caller_address == sv_owner_address::read(), 'Ownable: caller is not owner');
    }
}
