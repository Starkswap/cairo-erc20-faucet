import pytest
from .utils import Account

BURNER_ADDRESS=0x42

@pytest.mark.parametrize(
    "mint_scenario",
    [
        [0, 10, 10],
        [0, 100, 100],
        [0, 1000, 100],
        [910, 1000, 90]
    ],
    ids=[
        "Faucet funds don't suffice",
        "Faucet funds equal mintable",
        "Faucet funds exceed max mintable",
        "topup would exceed max allowed balance",
    ]
)
class TestFaucetMintable:

    @pytest.mark.asyncio
    async def test_faucet_mintable(self, owner: Account, user: Account, faucet, token, mint_scenario):
        start_balance = mint_scenario[0]
        faucet_balance = mint_scenario[1]
        mintable_amount = mint_scenario[2]

        if start_balance > 0:
            await owner.mint(token, user, start_balance)

        if faucet_balance > 0:
            await owner.mint(token, faucet, faucet_balance)

        res = await faucet.mintable_amount(user.contract_address).call()
        print(f"mintable: {res.result}")
        assert res.result.amount.low == mintable_amount



@pytest.mark.parametrize(
    "mint_scenario",
    [
        [0, 10, 10, 10],
        [0, 100, 100, 100],
        [0, 1000, 100, 100],
        [910, 1000, 90, 1000]
    ],
    ids=[
        "Faucet funds equal mintable",
        "Amount equal max topup",
        "Faucet funds exceed max mintable",
        "Top-up to max balance",
    ]
)
class TestFaucetMintSuccess:

    @pytest.mark.asyncio
    async def test_faucet_mint_success(self, owner: Account, user: Account, faucet, token, mint_scenario):
        start_balance = mint_scenario[0]
        faucet_balance = mint_scenario[1]
        requested_amount = mint_scenario[2]
        expected_balance = mint_scenario[3]

        if start_balance > 0:
            await owner.mint(token, user, start_balance)

        if faucet_balance > 0:
            await owner.mint(token, faucet, faucet_balance)

        await user.send_transaction(faucet.contract_address, "mint", calldata=[requested_amount, 0])

        res = await token.balanceOf(user.contract_address).call()
        print(f"balance: {res.result}")
        assert res.result.balance.low == expected_balance


@pytest.mark.parametrize(
    "mint_scenario",
    [
        [0, 10, 20],
        [0, 1000, 101],
        [1500, 100, 100],
        [950, 100, 100],
    ],
    ids=[
        "Amount exceeds faucet funds",
        "Amount exceeds max topup",
        "Balance exceed max balance",
        "Top-up would exceed max balance",
    ]
)
class TestFaucetMintFailure:

    @pytest.mark.asyncio
    async def test_faucet_mint_failure(self, owner: Account, user: Account, faucet, token, mint_scenario):
        start_balance = mint_scenario[0]
        faucet_balance = mint_scenario[1]
        requested_amount = mint_scenario[2]

        if start_balance > 0:
            await owner.mint(token, user, start_balance)

        if faucet_balance > 0:
            await owner.mint(token, faucet, faucet_balance)

        with pytest.raises(Exception):
            await user.send_transaction(faucet.contract_address, "mint", calldata=[requested_amount, 0])


class TestFaucet:

    @pytest.mark.asyncio
    async def test_getters(self, owner: Account, token, faucet):
        res = await faucet.get_owner().call()
        assert res.result.owner == owner.contract_address

        res = await faucet.get_token().call()
        assert res.result.token_address == token.contract_address

        res = await faucet.get_faucet_balance().call()
        assert res.result.balance.low == 0

        await owner.mint(token, faucet, 100)

        res = await faucet.get_faucet_balance().call()
        assert res.result.balance.low == 100


    @pytest.mark.asyncio
    async def test_faucet_config(self, user: Account, owner: Account, faucet):
        res = await faucet.get_faucet_config().call()
        print(f"{res.result.config}")
        assert res.result.config.max_balance.low == 1000
        assert res.result.config.max_topup.low == 100

        await owner.send_transaction(faucet.contract_address, "set_faucet_config", calldata=[100, 0, 10, 0])

        res = await faucet.get_faucet_config().call()
        assert res.result.config.max_balance.low == 100
        assert res.result.config.max_topup.low == 10

        with pytest.raises(Exception):
            await user.send_transaction(faucet.contract_address, "set_faucet_config", calldata=[10, 0, 1, 0])

        res = await faucet.get_faucet_config().call()
        assert res.result.config.max_balance.low == 100
        assert res.result.config.max_topup.low == 10

    @pytest.mark.asyncio
    async def test_set_token(self, user: Account, owner: Account, token, faucet):
        with pytest.raises(Exception):
            await user.send_transaction(faucet.contract_address, "set_token", calldata=[42])

        res = await faucet.get_token().call()
        assert res.result.token_address == token.contract_address

        await owner.send_transaction(faucet.contract_address, "set_token", calldata=[42])
        res = await faucet.get_token().call()
        assert res.result.token_address == 42

    @pytest.mark.asyncio
    async def test_transfer_ownership(self, user: Account, owner: Account, token, faucet):
        await owner.mint(token, faucet, 100)

        with pytest.raises(Exception):
            await user.send_transaction(faucet.contract_address, "transfer", calldata=[user.contract_address, 100, 0])

        await owner.send_transaction(faucet.contract_address, "transfer_ownership", calldata=[user.contract_address])

        await user.send_transaction(faucet.contract_address, "transfer", calldata=[user.contract_address, 100, 0])
        res = token.balanceOf(user.contract_address).call()
        print(f"{res}")
