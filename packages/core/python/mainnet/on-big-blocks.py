from hyperliquid.utils import constants
import eth_account
from hyperliquid.exchange import Exchange
from dotenv import load_dotenv
import os

load_dotenv()

account = eth_account.Account.from_key(os.getenv("PRIVATE_KEY"))
print(account.address)

exchange = Exchange(
    account, constants.MAINNET_API_URL, account_address=account.address, perp_dexs=None
)


# This example shows how to switch an account to use big blocks on the EVM
def main():

    print(exchange.use_big_blocks(True))
    # print(exchange.use_big_blocks(False))


if __name__ == "__main__":
    main()
