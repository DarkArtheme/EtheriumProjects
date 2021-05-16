// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol"; //стандартная библиотека с тестами
import "truffle/DeployedAddresses.sol"; /*библиотека, хранящая адреса развернутых контрактов(каждый раз, когда мы меняем и после этого
                                        передеплоим контракт, мы можем узнать его новый адрес здесь)*/
import "../contracts/Bank.sol";

contract TestBank {
    Bank public bank;
    Gachi public token;

                                        
    function beforeEach() public { //"хук", запускается перед каждой тестовой функцией, работаем с не измененным контрактом
        token = new Gachi();
        bank = new Bank(address(token), 100); // получаем адрес задеплоенного контракта
    }

    function testGettingStorage() public {
        uint256 expected_value = 100;
        Assert.equal(bank.getStorage(), expected_value, "It gets wrong storage");
        Assert.equal(bank.getBalance(), expected_value, "It gets wrong balance");
    }

    function testAddingToStorage() public {
        uint256 expected = bank.getStorage() + 10;
        bank.addToStorage(10);
        uint256 result = bank.getStorage();
        Assert.equal(result, expected, "It should add the correct value");
    }

    function testRegisterAndTakeCredit() public {
        bank.register("log", "pass", 0);
        Bank.Client[] memory clients = bank.getClients();
        Assert.equal(clients[0].login, 'log', "Login must be correct");
        Assert.equal(clients[0].password, 'pass', "Password must be correct");
        Assert.equal(clients[0].id, address(this), "Address must be correct");
        Assert.isZero(clients[0].balance, "Balance of new client must be zero");

        token.setAllowance(address(this), address(bank), 25);
        bank.takeCredit("log", "pass", 20, 5);
        clients = bank.getClients();
        uint256 expected_credit = 25;
        uint256 expected_balance = 20;
        Assert.equal(clients[0].credit.totalSum, expected_credit, "Credit sum isn't correct");
        Assert.equal(clients[0].balance, expected_balance, "Balance sum isn't correct");
        Assert.equal(bank.getStorage(), 80, "Bank storage wasn't changed correctly");
    }

    function testCheckingClient() public {
        bank.register("log", "pass", 0);
        Bank.Client[] memory clients = bank.getClients();        
        Assert.isTrue(bank.checkClient(clients[0], "log", "pass"), "Checking error");
        Assert.isFalse(bank.checkClient(clients[0], "wronglog", "pass"), "Checking error");
    }

    function testReturningCredit() public {
        uint256 old_storage = bank.getStorage();        
        bank.register("log", "pass", 100);
        token.setAllowance(address(this), address(bank), 25);
        bank.takeCredit("log", "pass", 20, 5);
        bank.returnCredit(20);
        Bank.Client[] memory clients = bank.getClients();        
        Assert.equal(clients[0].balance, 100, "Client's balance wasn't changed correctly");
        Assert.equal(clients[0].credit.totalSum, 5, "Credit TotalSum wasn't changed correctly");        
        Assert.equal(bank.getStorage(), old_storage, "Storage wasn't changed correctly");

        bank.returnCredit(5);
        clients = bank.getClients(); 
        Assert.isZero(clients[0].credit.totalSum, "TotalSum should be zero");
        Assert.equal(clients[0].balance, 95, "Client's balance wasn't changed correctly");
        Assert.equal(bank.getStorage(), old_storage + 5, "Storage wasn't changed correctly");        
    }
    
}

 
