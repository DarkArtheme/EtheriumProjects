const Bank = artifacts.require("Bank");
const Gachi = artifacts.require("Gachi");

var BN = web3.utils.BN;
var Hex = web3.utils.toHex;
var Decimal = web3.utils.toDecimal;

contract("Bank test", async accounts => {

    // Тест Bank::getStorage при деплое
    const initial_storage = 200;                                                     // начальное значение storage
    it(`Тест Bank::getStorage при деплое. storage должен быть равен ${initial_storage} при деплое.`, async () => {
        const bank = await Bank.deployed();
        let storage = await bank.getStorage();
        let balance = await bank.getBalance();
        assert.equal(storage, Decimal(new BN(initial_storage)));                            // storage изначально 200, потому что при деплое банк получает столько (см. 8 строку 3_bank_migration.js)      
        assert.equal(balance, Decimal(new BN(initial_storage)));
    });

    // Тест Bank::addToStorage
    const payment = 40;
    it(`Тест Bank::addToStorage. В storage должно добавиться ${payment} Gachi.`, async () => {
        const bank = await Bank.deployed();
        let old_storage = await bank.getStorage();
        let old_balance = await bank.getBalance();
        bank.addToStorage(payment);
        let new_storage = await bank.getStorage();
        let new_balance = await bank.getBalance();
        assert.equal(old_storage, Decimal(new_storage) - payment); 
        assert.equal(old_balance, Decimal(new_balance) - payment);
    });

    // Тест Bank::calculateTotalSum
    it(`Тест Bank::calculateTotalSum. В данном тесте результат функции сравнивается с предпосчитанным значением.`, async () => {
        const bank = await Bank.deployed();
        let sum1 = await bank.calculateTotalSum(20, 5);
        let sum2 = await bank.calculateTotalSum(39, 4);
        let sum3 = await bank.calculateTotalSum(231, 9);
        assert.equal(sum1, Decimal(new BN(25)));
        assert.equal(sum2, Decimal(new BN(47)));
        assert.equal(sum3, Decimal(new BN(358)));
    });

    // Тест Bank::register
    const startSum = 10;
    it(`Тест Bank::register.`, async () => {
        const bank = await Bank.deployed();
        await bank.register("arty", "123", startSum, {from: accounts[3]});
        let clients = await bank.getClients();
        assert.equal(clients.length, 1);
        assert.equal(clients[0].id, accounts[3]);
        assert.equal(clients[0].login, "arty");
        assert.equal(clients[0].password, "123");
        assert.equal(clients[0].balance, startSum);
        assert.equal(clients[0].credit.currentSum, 0);
        assert.equal(clients[0].credit.months, 0);
        assert.equal(clients[0].credit.totalSum, 0);
        await bank.register("arty", "1231", 10, {from: accounts[4]});
        clients = await bank.getClients();
        assert.equal(clients.length, 1);
    });

    // Тест Bank::takeCredit
    const credit_size = 30;
    const months = 6;
    let sum_to_return = 0;
    it(`Тест Bank::takeCredit.`, async () => {
        const token = await Gachi.deployed();
        const bank = await Bank.deployed();
        sum_to_return = await bank.calculateTotalSum(credit_size, months);
        await token.approve(bank.address, sum_to_return, {from: accounts[3]});
        let old_balance = await bank.getBalance();
        let old_storage = await bank.getStorage();
        await bank.takeCredit("arty", "123", credit_size, months, {from: accounts[3]});
        let clients = await bank.getClients();
        let new_balance = await bank.getBalance();
        let new_storage = await bank.getStorage();
        assert.equal(clients[0].balance, Number(startSum) + Number(credit_size));
        assert.equal(clients[0].credit.currentSum, credit_size);
        assert.equal(clients[0].credit.months, months);
        assert.equal(clients[0].credit.totalSum, sum_to_return);
        assert.equal(old_balance, Decimal(new_balance) + credit_size);
        assert.equal(old_storage, Decimal(new_storage) + credit_size);
    });

    // Тест Bank::returnCredit
    const first_payment = 15;
    it(`Тест Bank::returnCredit.`, async () => {
        const bank = await Bank.deployed();
        let old_balance = await bank.getBalance();
        let old_storage = await bank.getStorage();
        await bank.returnCredit(first_payment, {from: accounts[3]});
        let clients = await bank.getClients();
        let new_balance = await bank.getBalance();
        let new_storage = await bank.getStorage();
        assert.equal(clients[0].balance, Number(startSum) + Number(credit_size) - first_payment);
        assert.equal(clients[0].credit.totalSum, sum_to_return - first_payment);
        assert.equal(old_balance, Decimal(new_balance) - first_payment);
        assert.equal(old_storage, Decimal(new_storage) - first_payment);

        let last_payment = sum_to_return - first_payment;
        old_balance = new_balance;
        old_storage = new_storage;
        await bank.returnCredit(last_payment, {from: accounts[3]});
        new_balance = await bank.getBalance();
        new_storage = await bank.getStorage();
        clients = await bank.getClients();
        assert.equal(clients[0].balance, Number(startSum) + Number(credit_size) - sum_to_return);
        assert.equal(clients[0].credit.totalSum, 0);
        assert.equal(old_balance, Decimal(new_balance) - last_payment);
        assert.equal(old_storage, Decimal(new_storage) - last_payment);
    });
});