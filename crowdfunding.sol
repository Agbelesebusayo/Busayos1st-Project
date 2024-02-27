// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    //interface is used here because the legal tender here is an ERC20 token
    function transfer(address, uint) external returns (bool); 
 /*This function is part of the ERC-20 standard and is used to transfer tokens from the 
 sender's address to another address. the address you are sending to is required and amount and the 
 returns a bool when transaction is successful or failed*/
    function transferFrom(address, address, uint) external returns (bool);
    /* This function is also part of the ERC-20 standard and is used to transfer tokens 
    from one address to another on behalf of a third-party (the "spender"). here 2 addresses are
    required senders acct, spenders acct and amount it also returns bool to signify success 
    or failure*/
}
 
contract CrowdFund {
    //name of contract is CrowdFund
    event Launch(
        /*we are communicating from the backend to the frontend that we are launching a
        the crowdfunding where people can donate tokens for charity cause*/
        uint id,
        //there will be several campaigns here each campaign will have a unique id 
        address indexed creator,
        /*the address of the creator, indexed because there maybe more than 1 creator since
        there are more than one campaign  */
        uint goal,
        //the amount the crowdfund is trying to raise
        uint32 startAt,
        //when the crowdfund starts
        uint32 endAt
        //when the crowdfund ends
    );
    event Cancel(uint id);
    /*this event is emitted when the creator wants to cancel a particular campaign the id for the 
    campaign must be provided to avoid cancelling other running campaigns*/
    event Pledge(uint indexed id, address indexed caller, uint amount);
    /*This event is emitted when a contributor pledges funds to a campaign. It includes the 
    campaign ID (id), the address of the contributor (caller), and the pledged amount (amount) */
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    /*event is emitted where a pledger wants to be reverse or cancel, the contributor will have to  
    provide the unique id, the address of the caller and amount pledged*/
    event Claim(uint id);
    /*the event is emitted creator wants to claim the donations a unique id is required in numbers to 
    avoid theft and also know which of the campaign he wants to claim*/
    event Refund(uint id, address indexed caller, uint amount);
    /*This event is emitted when a contributor requests and receives a refund or if funds 
    realised exceeds the goal*/

 
    struct Campaign {
        //the variables below will be saved in this struct called Campaign//
        address creator;
         // Creator of campaign
        uint goal;
        // Amount of tokens to raise
        uint pledged;
         // Total amount pledged
        uint32 startAt;
         // Timestamp of start of campaign
        uint32 endAt;
        // Timestamp of end of campaign
        bool claimed;
          // True if goal was reached and creator has claimed the tokens.

    }
 
    IERC20 public immutable token;
    //this is an IERC20 token and it can NEVER be changed
    uint public count;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    mapping(uint => Campaign) public campaigns;
     /* we are using mapping to reach a particular campaign using the campaign id because 
     there are several other campaigns here. the mapping is saved in campaigns*/
    mapping(uint => mapping(address => uint)) public pledgedAmount;
     /* this is a nested mapping here we are trying to track the amount pledged for each campaign 
     and the address of the pledger we saved this nested mapping in a variable called
     pledgedAmount */
    constructor(address _token) {
        token = IERC20(_token);
        //this constructor would only be called once in this contract
    }
 
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        //lauching a crowdfunding and we are showing the goal i.e the amount, the start and end date
        require(_startAt >= block.timestamp, "start at < now");
        /*the time for the campaign is now or in the future, else show an error that start at
        less than now*/
        //block.timestamp === current time (12:38pm)
        require(_endAt >= _startAt, "end at < start at");
        /*the time the funding will end will be greater than when it started or show an error
        end at lesser than start at*/
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        /* end at should be less than equal to block.timestamp which is the current time 
        and 90 days time that means the campaign should run till 90days max else an error should 
        show end at greater than max duration*/
 
        count += 1;
      //this increases the campaign count to allow for more campaigns//
        campaigns[count] = Campaign({
            /*this is a struct called Campaign it is linked to the mapping called campaigns
            this struct called Campaign updates any new campaign added using count with 
            the features below saved in the struct Campaign*/
            creator: msg.sender,
            /*creator of the campaign here the address is set to the address of the creator
            of the transaction*/  
            goal: _goal,
            //the amount the campaign hopes to get
            pledged: 0,
            // the amount the new campaign started with, indicating no funds has been pledged 
            startAt: _startAt,
            //start date of the new campaign
            endAt: _endAt,
            //end date of the new campaign
            claimed: false
            //the campaign has not been claimed so it is in default settings which is false
        });
 
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
        /*announcing the launch of a new campaign to the public with the id number, address of 
        the creator, target amount, start and end date*/
    }
 
    function cancel(uint _id) external {
        /*this a function to enable cancelling of a particular campaign using its unique id to 
        ensure it is only the creator that can cancel the particular campaign*/
        Campaign memory campaign = campaigns[_id];
        /*This line creates a temporary copy of the Campaign struct stored at the 
        _id in the campaigns mapping and assigns it to the local variable campaign. The use of memory 
        indicates that this variable is a temporary copy and won't persist on the blockchain.*/
        require(campaign.creator== msg.sender, "not creator");
        /* showing that the campaign creator is the msg.sender trying to cancel if not send an
         error not creator*/
        require(block.timestamp < campaign.startAt, "started");
       /*show that the current time is less than the campaign start time if not show an error 
       started, to prevent cancelling a campaign that is in progress*/
        delete campaigns[_id];
        // to delete a particular campaign using its unique id in the campaigns mapping
        emit Cancel(_id);
        //shows the public that a particular campaign has been cancelled
    }
 
    function pledge(uint _id, uint _amount) external {
     //function pledge to pledge the campaign id and amount to pledge is required   
        Campaign storage campaign = campaigns[_id];
        /*This line declares a storage reference to the campaign with the 
        specified _id from the campaigns mapping*/
        require(block.timestamp >= campaign.startAt, "not started");
        /*current time is greater than or equal to campaign start time indicating campaign has 
        started if not send an error not started */
        require(block.timestamp <= campaign.endAt, "ended");
        /* that current time is lesser than or equal to campaign end date signifying 
        campaign hasnt ended if not show an error ended*/
        campaign.pledged += _amount;
        //when a pledge is made the account should increase
        pledgedAmount[_id][msg.sender] += _amount;
        /*Increases the pledged amount specifically for the contributor (msg.sender) and the 
        campaign with the specified _id*/
        token.transferFrom(msg.sender, address(this), _amount);
        //transfers token from the contributor to the campaign account with a specific amount//
        emit Pledge(_id, msg.sender, _amount);
        /*shows the front end that a pledge has been made to a particular campaign using the, 
        campaign id, the address of the contributor and amount donated*/
    }
 
    function unpledge(uint _id, uint _amount) external {
      /*this function allows a pledger to unpledge if they decide to by providing the 
      unique id they pledge into initially and amount pledged*/  
        Campaign storage campaign = campaigns[_id];
        /*This line declares a storage reference to the campaign with the specified 
        id from the campaigns mapping.*/
        require(block.timestamp <= campaign.endAt, "ended");
        //current is less than equal to the campaign end date meaning the campaign is still on
        //funds can only be unpledged while the campaign is still on 
        campaign.pledged -= _amount;
        //Decreases the total pledged amount for the campaign by the specified amount.
        pledgedAmount[_id][msg.sender] -= _amount;
        /*Decreases the pledged amount specifically for the contributor (msg.sender) 
        and the campaign with the specified id.*/
        token.transfer(msg.sender, _amount);
        //Transfers tokens from the contract to the contributor (msg.sender) for the unpledged amount.
        emit Unpledge(_id, msg.sender, _amount);
        /*Emits an Unpledge event, indicating that a contributor (msg.sender) has retracted a pledge 
        from the campaign with the specified id*/
    }
 
    function claim(uint _id) external {
        /*this a function that allows the creator claim funds realised from a campaign  
        after the campaign has ended and goals reached using the unique id of the campaign*/
        Campaign storage campaign = campaigns[_id];
        /*This line declares a storage reference to the campaign with the specified 
        id from the campaigns mapping.*/
        require(campaign.creator == msg.sender, "not creator");
        //ensure that the creator is the one trying to withdraw funds if not show not creator
        require(block.timestamp > campaign.endAt, "not ended");
        /*ensure that campaign has ended by showing that current time is greater than end time 
       to avoid withdrawing funds before the campaign end date if not show not ended */
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        /* ensure that the total sum realised is greater than or equal to the campaign goal if not
        show pledged less than goal */
        require(!campaign.claimed, "claimed");
        /*Ensures that the funds have not been claimed already. This prevents multiple
         claims for the same campaign.*/
        campaign.claimed = true;
        //Marks the funds as claimed to prevent further claims.
        token.transfer(campaign.creator, campaign.pledged);
        //Transfers the pledged funds to the campaign creator.
        emit Claim(_id);
        /*Emits a Claim event, indicating that the campaign creator has claimed the funds for 
        the campaign with the specified id*/

    }
 
    function refund(uint _id) external {
        /*this function allows for refund of a particular campaign if the crowdfunding has ended
       and goals hasnt been reached */
        Campaign memory campaign = campaigns[_id];
        /*This line declares a memory reference to the campaign with the specified 
        id from the campaigns mapping*/
        require(block.timestamp > campaign.endAt, "not ended");
        /*Ensures that the current timestamp is greater than the endAt timestamp of the campaign,
         indicating that the campaign has ended.*/
        require(campaign.pledged < campaign.goal, "pledged >= goal");
        /*Ensures that the total pledged amount is less than the campaign goal. Contributors
         can only request a refund if the goal has not been reached.*/
        uint bal = pledgedAmount[_id][msg.sender];
        // Retrieves the pledged amount for the contributor (msg.sender) for the specified campaign (_id).
        pledgedAmount[_id][msg.sender] = 0;
        //Sets the contributor's pledged amount to zero, indicating that the refund has been processed.
        token.transfer(msg.sender, bal);
        //Transfers the pledged amount back to the contributor.
        emit Refund(_id, msg.sender, bal);
        /*Emits a Refund event, indicating that the contributor (msg.sender) has been refunded 
        for the campaign with the specified _id with the amount bal.*/
    }
}