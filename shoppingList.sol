pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "shoppingListService.sol";

contract shoppingList is IShoppingList{

	mapping(uint32 => purchase) purchases;

	summaryPurchases statisticsOfPurchases = summaryPurchases(0, 0, 0);

	uint ownerPubkey;
	uint32 numberOfPurchase;

	constructor() public {	
		require(tvm.pubkey() != 0, 101);	
		require(msg.pubkey() == tvm.pubkey(), 102);
		tvm.accept();

		ownerPubkey = tvm.pubkey();
	}

	modifier onlyOwner() {
        require(msg.pubkey() == ownerPubkey, 101);
        _;
    }

	function addPurchase(string _name, uint _amount) public onlyOwner override {
		tvm.accept();

		purchases[numberOfPurchase] = purchase(numberOfPurchase, _name, _amount, now, false, 0);
		numberOfPurchase++;
		statisticsOfPurchases.unpaidPurchases += _amount;
	}

	function deletePurchase(uint32 number) public onlyOwner override {
		require(purchases.exists(number), 102);
		tvm.accept();

		if (purchases[number].bought) {
			statisticsOfPurchases.paidPurchases -= purchases[number].amount;
			statisticsOfPurchases.totalPayment -= purchases[number].cost;
		} else {
			statisticsOfPurchases.unpaidPurchases -= purchases[number].amount;
		}

		delete purchases[number];
		numberOfPurchase--;
	}

	function buy(uint32 number, uint cost) public onlyOwner override {
		require(purchases.exists(number), 102);
		tvm.accept();

		purchases[number].cost = cost;
		purchases[number].bought = true;

		statisticsOfPurchases.paidPurchases += purchases[number].amount;
		statisticsOfPurchases.unpaidPurchases -= purchases[number].amount;
		statisticsOfPurchases.totalPayment += cost;
	}

	function getStatisticsOfPurchases() public override returns(uint paidPurchases, uint unpaidPurchases, uint totalPayment) {
		paidPurchases = statisticsOfPurchases.paidPurchases;
		unpaidPurchases = statisticsOfPurchases.unpaidPurchases;
		totalPayment = statisticsOfPurchases.totalPayment;
	}

	function getPurchasesList() public override returns(purchase[] purchasesArr) {
        for((, purchase currentPurchase) : purchases) {
            purchasesArr.push(currentPurchase);
        }
	}
}