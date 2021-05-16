// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "contracts/Gachi.sol";
contract Bank{

   struct Credit {
      uint256 currentSum; //сумма кредита
      uint256 months; //срок в месяцах
      uint256 totalSum; //сумма, которую надо выплатить
   }
   struct Client {
      address payable id; //адрес клиента
      string login;
      string password;
      uint256 balance;
      Credit credit;
   }
   uint256 constant percentageRate = 5; //процентная ставка
   uint256 private _storage; //количество токенов в контракте
   uint private numberClient; //количество клиентов
   address payable private owner; //адрес владельца контракта
   Client[] private clients; //массив клиентов
   Gachi public token;

   constructor (address _token, uint256 startSum) public {
      owner = payable(address(msg.sender));
      token = Gachi(_token);
      token.mint(address(this), startSum);
      _storage = token.totalSupply();
   }

   modifier checkOwner() { //проверка, что зашел владелец контракта
      require(msg.sender == owner); 
      _;
   }

   event Register(address id, string message); 
   event CreditDenied(address id, string message, address bank_address);
   event TakeCredit(address id, uint percent, uint sum, uint number_month);

   function register(string memory login, string memory password, uint256 startSum) public { //регистрация нового клиента
      bool isExist = false;
      for(uint i = 0; i < numberClient; i++) {
         require(clients[i].id != msg.sender);
         if(keccak256(bytes(clients[i].login)) == keccak256(bytes(login))) {
            emit Register(msg.sender, "This login already exist");
            isExist = true;
            break;
         }
      }
      if(!isExist) {
         emit Register(msg.sender, "Success register");
         token.mint(msg.sender, startSum);
         clients.push(Client(payable(address(msg.sender)), login, password, startSum, Credit(0, 0, 0)));
         numberClient++;
      }
   }

   function checkClient(Client memory current, string memory login, string memory password) public pure returns(bool) { //сравнение логинов и паролей
      return (keccak256(bytes(current.login)) == keccak256(bytes(login))) && (keccak256(bytes(current.password)) == keccak256(bytes(password)));
   }

   function takeCredit(string memory login, string memory password, uint256 num, uint256 month) public { //взятие кредита
      for(uint i = 0; i < numberClient; i++) {
         if(checkClient(clients[i], login, password)) {
            if(_storage >= num && clients[i].credit.totalSum == 0)  {
               uint256 totalSum = calculateTotalSum(num, month);
               if(token.allowance(msg.sender, address(this)) >= totalSum) {
                  clients[i].balance += num; 
                  clients[i].credit = Credit(num, month, totalSum);
                  _storage -= num;
                  token.transfer(clients[i].id, num);
                  emit TakeCredit(msg.sender, percentageRate, clients[i].id.balance, month);
                  break;
               } else {
                  emit CreditDenied(clients[i].id, "Bank cannot give you credit (there is no allowance).", address(this));
               }                 
            } else {
               emit CreditDenied(clients[i].id, "Bank cannot give you credit (the sum of credit is too big)", address(this));
            }
         }
      }
   }

   function returnCredit(uint256 payment) public { //возврат кредита
      uint256 total = 0;
      for(uint i = 0; i < numberClient; i++) {
         if(clients[i].id == msg.sender) { 
            total = clients[i].credit.totalSum;
            if(total <= payment) {
               clients[i].balance -= total;
               token.transferFrom(msg.sender, address(this), total);
               clients[i].credit = Credit(0, 0, 0);
               _storage += total;
            }
            else {
               token.transferFrom(msg.sender, address(this), payment);
               clients[i].credit.totalSum -= payment;
               clients[i].balance -= payment;
               _storage += payment;
            }
            break;
         }
      }
   }

   function getStorage() public view checkOwner returns(uint256) { //узнать сколько токенов в хранилище
      return _storage;
   }

   function addToStorage(uint256 _value) public checkOwner { //добавить в контракт токены
      _storage += _value;
      token.mint(address(this), _value);
   }

   function calculateTotalSum(uint256 sum, uint256 months) pure public returns(uint256){
      return sum * ((100+percentageRate)**months) / (100**months);
   }

   function getBalance() view public returns(uint256){
      return token.balanceOf(address(this));
   }
   function getClients() view public returns(Client[] memory){
      Client[] memory cl = clients;
      return cl;
   }
}