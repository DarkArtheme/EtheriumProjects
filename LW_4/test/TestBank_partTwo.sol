// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol"; //стандартная библиотека с тестами
import "truffle/DeployedAddresses.sol"; /*библиотека, хранящая адреса развернутых контрактов(каждый раз, когда мы меняем и после этого
                                        передеплоим контракт, мы можем узнать его новый адрес здесь)*/
import "../contracts/Bank.sol";

contract TestBank_partTwo {
    Bank public bank;
    Gachi public token;

                                        
    function beforeEach() public { //"хук", запускается перед каждой тестовой функцией, работаем с не измененным контрактом
        token = new Gachi();
        bank = new Bank(address(token), 100); // получаем адрес задеплоенного контракта
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
