// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//Using interfaces is particularly useful in scenarios where multiple contracts need to 
//adhere to a common set of functions,
interface IERC20 {         // interface helps to standardize our token
    function totalSupply()external view returns(uint);
//Functions declared as external can only be called from outside the contract, i.e.,
// by other contracts or transactions initiated by external actors.
//These functions cannot be called internally by other functions within the same contract.


    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

   function allowance(address owner, address spender) external view returns(uint);

   function approve(address spender, uint amount) external returns(bool);

   function transferFrom(address sender, address recipient, uint amount) external returns(bool); 

   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);

}

contract ERC20 is IERC20{ // ERC20 is inheriting from IERC using the 'IS' statement
    uint public override totalSupply;
    mapping (address => uint) public override balanceOf;
    mapping (address => mapping(address =>uint)) public override allowance;
    string public name ="BILLY TOKEN";
    string public symbol="BTK";
    uint public decimal = 18;

    function transfer(address recipient, uint amount) 
    external override returns(bool){
    balanceOf[msg.sender] -= amount;
    balanceOf[recipient] += amount;
 
emit Transfer(msg.sender,recipient,amount);// emit showcases what is done behind to the front
 return true;   
    }
    function approve(address spender,uint amount)
    external override returns(bool) { 
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount); 
        return true;
  }
  
function transferFrom (address sender,address recipient,uint amount)
external override returns(bool){
// this transferFrom function will be called by the spender/recipient
//deduct the allowance you were given
allowance[sender][msg.sender] -= amount;
//remove the amount from the senders account
 balanceOf[sender] -= amount;
 //credit the recipient with the amount deducted above
  //balanceOf[sender] =  balanceOf[sender] - amount;
 balanceOf[recipient] += amount;
 //let the frontend know a transaction has occured
 emit Transfer(sender, recipient, amount);
return true;
}
 
function mint(uint amount) external {
balanceOf[msg.sender] += amount;
//line 44/45 will add more money to the msg.sender
//balanceOf[msg.sender]=balanceOf[msg.sender] + amount;
totalSupply += amount;
//totalSupply=totalSupply + amount;
emit Transfer(address(0), msg.sender, amount);
}
 
function burn(uint amount) external {
   balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
}
 
}   
    

