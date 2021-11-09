pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

interface IShoppingList {  
    function addPurchase(string, uint) external;
    function deletePurchase(uint32) external;
    function buy(uint32, uint) external;
    function getStatisticsOfPurchases() external returns(uint, uint, uint);
    function getPurchasesList() external returns(purchase[]);
}

interface ITransactable {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}

struct purchase {
    uint number;
    string name;
	uint amount;
    uint timestamp;
    bool bought;
    uint cost;
}

struct summaryPurchases {
	uint paidPurchases;
	uint unpaidPurchases;
	uint totalPayment;
}

abstract contract HasConstructorWithPubKey{
   constructor(uint256 pubkey) public {}
}