// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Gachi {

    using SafeMath for uint256;

    string public constant name = "gachi"; //название монеты
    string public constant symbol = "GCH"; //символ монеты (как USD дял доллара)
    uint8 public constant decimal = 2; //количество знаков после запятой

    uint256 public _totalSupply; //сколько всего токенов выпущено

    mapping(address => uint256) balances; //балансы (адрес - кол-во токенов)

    mapping(address => mapping(address => uint256)) allowed; //разрешения на снятие денег каким-то адресам с других адресов

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _from, address indexed _to, uint256 _value);

    //constructor() public {}

    function totalSupply() public view returns (uint256) {
       return _totalSupply; 
    }

    function mint(address _to, uint256 _value) public { //эмиссия средств на указанный адрес
        balances[_to] = balances[_to].add(_value); // то же, что и balances[_to] += _value;
        _totalSupply = _totalSupply.add(_value);
    }

    function balanceOf(address owner) public view returns(uint256) { //узнать баланс на указанном адресе
        return balances[owner];
    }

    function transfer(address _to, uint256 _value) public { //перевод средств с текущего адреса на адрес
        require(balances[msg.sender] >= _value); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public { //перевод средств с адреса на адрес
        require(balances[_from] >= _value && allowed[_from][_to] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][_to] = allowed[_from][_to].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public { //установление снимать сумму _value адресу _spender с текущего адреса
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function setAllowance(address _owner, address _spender, uint256 _value) public {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }    

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { //сколько валюты разрешено снимать адресу _spender с адреса _owner
        return allowed[_owner][_spender];
    }
}