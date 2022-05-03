import os
import sys
import pytest_asyncio
import pytest
import asyncio
from .utils import Account, str_to_felt, uint

from starkware.starknet.testing.starknet import Starknet

def resolve(filename):
    for directory in sys.path:
        path = os.path.join(directory, filename)
        if os.path.isfile(path):
            return path

ACCOUNT_FILE = resolve("openzeppelin/account/Account.cairo")
MINTABLE_TOKEN = resolve("openzeppelin/token/erc20/ERC20_Mintable.cairo")
FAUCET = os.path.join("contracts", "faucet.cairo")

@pytest_asyncio.fixture(scope="module")
async def starknet():
    return await Starknet.empty()

@pytest_asyncio.fixture(scope="module")
async def token(starknet: Starknet, owner):
    return await starknet.deploy(source=MINTABLE_TOKEN, cairo_path=sys.path, constructor_calldata=[
        str_to_felt("TestToken"),
        str_to_felt("TST"),
        18,
        *uint(0),
        owner.contract_address,
        owner.contract_address
    ])

@pytest_asyncio.fixture(scope="module")
async def owner(starknet):
    owner = Account(123456789987654321)
    owner.set_contract(await starknet.deploy(ACCOUNT_FILE, cairo_path=sys.path, constructor_calldata=[owner.public_key]))
    return owner

@pytest_asyncio.fixture(scope="function")
async def user(starknet):
    owner = Account(12312312313123123)
    owner.set_contract(await starknet.deploy(ACCOUNT_FILE, cairo_path=sys.path, constructor_calldata=[owner.public_key]))
    return owner


@pytest_asyncio.fixture(scope="function")
async def faucet(starknet, owner, token):
    return await starknet.deploy(FAUCET, cairo_path=sys.path, constructor_calldata=[owner.contract_address, token.contract_address])

@pytest.fixture(scope='module')
def event_loop(request):
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()
