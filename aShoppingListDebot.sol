pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Debot.sol";
import "base/Terminal.sol";
import "base/Menu.sol";
import "base/AddressInput.sol";
import "base/Sdk.sol";
import "shoppingListService.sol";
//import "base/onfirmInput.sol";
//import "base/Upgradable.sol";

abstract contract aShoppingListDebot is Debot{

    uint masterPubKey;
    TvmCell shoppingListCode;
    address shoppingListAddress;
    address msigAddress;
    string tempNamePurchase;
    uint tempNumberPurchase;
    
    uint32 INITIAL_BALANCE =  200000000;  //Initial shopping contract balance

    summaryPurchases statisticsOfPurchases;

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID ];
    }
    
    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key", false);
    }

    function _menu() internal virtual {}

    function getPurchasesList() public view {
        optional(uint256) pubkey = 0;

        IShoppingList(shoppingListAddress).getPurchasesList{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(showPurchasesList),
                onErrorId: 0
            }();
    }

    function showPurchasesList(purchase[] purchasesList) public {
        if (purchasesList.length > 0 ) {
            Terminal.print(0, "Your purchases list:");
            for (uint32 i = 0; i < purchasesList.length; i++) {
                
                string completed;

                if (purchasesList[i].bought) {
                    completed = '✓';
                } else {
                    completed = ' ';
                }

                Terminal.print(0, format("{} {}  \"{}\"  at {} cost {} amount {}",
                    purchasesList[i].number, completed, purchasesList[i].name, purchasesList[i].timestamp, purchasesList[i].cost, purchasesList[i].amount));
            }
        } else {
            Terminal.print(0, "Your purchases list is empty");
        }
        _menu();
    }

    function deletePurchaseInputNumber(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(deletePurchase), "Input number:", false);
    }

    function deletePurchase(string numberPurchase) public view {
        (uint256 number, ) = stoi(numberPurchase);
        optional(uint256) pubkey = 0;

        IShoppingList(shoppingListAddress).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(number));
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x" + value);

        if (status) {
            masterPubKey = res;

            Terminal.print(0, "Checking if you already have a shopping list...");
            TvmCell deployState = tvm.insertPubkey(shoppingListCode, masterPubKey);
            shoppingListAddress = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your shopping list contract address is {}", shoppingListAddress));
            Sdk.getAccountType(tvm.functionId(checkStatus), shoppingListAddress);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key", false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and contract is already deployed
            //Terminal.print(0, "You have shopping list. To work with shopping list, use the menu "); 
            getStatisticsOfPurchases(tvm.functionId(setStatisticsOfPurchases)); 

        } else if (acc_type == -1)  { //acc is inactive
            Terminal.print(0, "You don't have a shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { //acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your shopping list contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) { //acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", shoppingListAddress));
        }
    }

    function creditAccount(address value) public {
        msigAddress = value;


        Terminal.print(0, format("function creditAccount. msigAddress is {}", msigAddress));


        optional(uint256) pubkey = 0;
        TvmCell empty;
        ITransactable(msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit) 
        }(shoppingListAddress, INITIAL_BALANCE, false, 3, empty);
    }

    function deploy() internal view {
        TvmCell image = tvm.insertPubkey(shoppingListCode, masterPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: shoppingListAddress,
            callbackId: tvm.functionId(onSuccess),
            onErrorId:  tvm.functionId(onErrorRepeatDeploy), 
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {HasConstructorWithPubKey, masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }

    function waitBeforeDeploy() public {


        Terminal.print(0, format( "in waitBeforeDeploy msigAddress is {}", msigAddress));

        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), shoppingListAddress);
    }

    function checkIfStatusIs0(int8 acc_type) public {

        Terminal.print(0, format( "in checkIfStatusIs0. acc_type is {}", acc_type));


        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function setShoppingListCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        shoppingListCode = tvm.buildStateInit(code, data);
    }

    function getStatisticsOfPurchases(uint32 answerId) public view {
        optional(uint256) none;
        IShoppingList(shoppingListAddress).getStatisticsOfPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function setStatisticsOfPurchases(summaryPurchases _statisticsOfPurchases) public {
        statisticsOfPurchases = _statisticsOfPurchases;
        _menu();
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;


        Terminal.print(0, "in onErrorRepeatCredit");


        creditAccount(msigAddress);
    }

    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;

        Terminal.print(0, "in onErrorRepeatDeploy");


        deploy();
    }
    
    function onError(uint32 sdkError, uint32 exitCode) public {


        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode)); 


        _menu();
    }

    function onSuccess() public {

        Terminal.print(0, "in onSuccess");


        getStatisticsOfPurchases(tvm.functionId(setStatisticsOfPurchases));
    }
}