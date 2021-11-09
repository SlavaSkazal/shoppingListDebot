pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "aShoppingListDebot.sol";

contract shoppingListDebotInTheShop is aShoppingListDebot {

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi
    ) {
        name = "shopping List Debot";
        version = "0.2.0";
        publisher = "TON Labs";
        key = "shopping List Debot manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a shopping List Debot.";
        language = "en";
        dabi = m_debotAbi.get();
    }

    function buyInputNumber(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(buyInputCost), "Input number:", false);
    }

    function buyInputCost(string _number) public {
        (uint256 number, ) = stoi(_number);
        tempNumberPurchase = number;
        Terminal.input(tvm.functionId(buy), "Input cost:", false);
    }
 
    function buy(string _cost) public view {
        
        (uint256 cost, ) = stoi(_cost);
        optional(uint256) pubkey = 0;

        IShoppingList(shoppingListAddress).buy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(tempNumberPurchase), cost);
    }

    function _menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (paid/not paid/total payment) purchases",
                    statisticsOfPurchases.paidPurchases,
                    statisticsOfPurchases.unpaidPurchases,
                    statisticsOfPurchases.totalPayment
            ),
            sep,
            [
                MenuItem("Delete purchase", "", tvm.functionId(deletePurchaseInputNumber)),
                MenuItem("Buy", "", tvm.functionId(buyInputNumber)),
                MenuItem("Get purchases list","",tvm.functionId(getPurchasesList))
            ]
        );
    }
}
