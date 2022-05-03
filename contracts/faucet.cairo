%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import (Uint256, uint256_sub, uint256_add, uint256_le, uint256_lt)
from openzeppelin.access.ownable import (Ownable_initializer, Ownable_only_owner, Ownable_get_owner, Ownable_transfer_ownership)

const TRUE = 1
const FALSE = 0

@event
func ev_balance_too_high(balance: Uint256, max: Uint256):
end

@storage_var
func sv_token_address() -> (res : felt):
end

struct FaucetConfig:
    member max_balance: Uint256
    member max_topup: Uint256
end

@storage_var
func sv_faucet_config() -> (config: FaucetConfig):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner: felt, token_address: felt):
    Ownable_initializer(owner)
    sv_token_address.write(token_address)
    sv_faucet_config.write(FaucetConfig(Uint256(1000,0), Uint256(100,0)))
    return ()
end


@view
func mintable_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(recipient: felt) -> (amount: Uint256):
    alloc_locals
    let (token_address) = sv_token_address.read()
    let (faucet_address) = get_contract_address()
    let (token_owner) = Ownable_get_owner()
    let (config) = sv_faucet_config.read()

    let (user_balance) = IERC20.balanceOf(token_address, recipient)
    let (should_top_up) = uint256_lt(user_balance, config.max_balance)

    if should_top_up == TRUE:
        let (faucet_balance) = IERC20.balanceOf(token_address, faucet_address)
        let (full_topup_amount) = uint256_sub(config.max_balance, user_balance)
        let (allowed_topup_amount) = uint256_min(full_topup_amount, config.max_topup)
        let (topup_amount) = uint256_min(allowed_topup_amount, faucet_balance)
        return (topup_amount)
    else:
        ev_balance_too_high.emit(user_balance, config.max_balance)
    end

    return (Uint256(0, 0))
end


@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount: Uint256):
    alloc_locals
    let (config) = sv_faucet_config.read()
    let (recipient) = get_caller_address()
    let (token_address) = sv_token_address.read()

    let (user_balance) = IERC20.balanceOf(token_address, recipient)
    with_attr error_message("Balance must be lower than {config.max_balance} - {config.max_topup} to mint."):
        let (resulting_balance, is_overflow) = uint256_add(user_balance, amount)
        assert is_overflow = 0

        let (should_top_up) = uint256_le(resulting_balance, config.max_balance)
        assert should_top_up = 1
    end

    with_attr error_message("Topup amount must be lower than {config.max_topup}"):
        let (should_top_up) = uint256_le(amount, config.max_topup)
        assert should_top_up = 1
    end

    IERC20.transfer(token_address, recipient, amount)
    return ()
end

@view
func get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner: felt):
    return Ownable_get_owner()
end

@view
func get_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (token_address: felt):
    return sv_token_address.read()
end

@view
func get_faucet_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (balance: Uint256):
    let (token_address) = sv_token_address.read()
    let (faucet_address) = get_contract_address()

    let (balance) = IERC20.balanceOf(token_address, faucet_address)
    return (balance)
end

@view
func get_faucet_config{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (config: FaucetConfig):
    return sv_faucet_config.read()
end


@external
func set_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_address: felt):
    Ownable_only_owner()

    sv_token_address.write(token_address)
    return ()
end

@external
func set_faucet_config{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(max_balance: Uint256, max_topup: Uint256):
    Ownable_only_owner()

    sv_faucet_config.write(FaucetConfig(max_balance, max_topup))
    return ()
end

@external
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_owner: felt) -> (new_owner: felt):
    return Ownable_transfer_ownership(new_owner)
end

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(recipient: felt, amount: Uint256):
    Ownable_only_owner()

    let (token_address) = sv_token_address.read()
    IERC20.transfer(token_address, recipient, amount)

    return ()
end



# ========== Utils ======
func uint256_min{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a: Uint256, b: Uint256) -> (min: Uint256):
    let (is_a_leq_b) = uint256_le(a, b)
    if is_a_leq_b == TRUE:
        return (a)
    end
    return (b)
end
