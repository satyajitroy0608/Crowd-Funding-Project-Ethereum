// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;


contract CrowdFunding
{
    mapping (address=>uint) public contributors; // mapping address with contribution amount
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;


    struct Request
{
    string description;
    address payable recipient;
    uint value;
    bool completed; // It is false by default
    uint noOfVoters;
    mapping (address => bool) voters;
}

    mapping (uint => Request) public requests;
    uint public numRequests;


    constructor(uint _target, uint _deadline)
    {
        target = _target;
        deadline = block.timestamp + _deadline;
        minContribution = 0.1 ether;
        manager = msg.sender;
    }

    function sendEther() public payable
    {
        // Function to send ether to the smart contract

        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minContribution, "Minimum contribution value is not met");

        // msg.sender holds the address of the account currently sending ether

        if(contributors[msg.sender]==0) // If the address of the user does not exist in the mapping 'contributors'
        { // In simple words, it checks if the current account is transferring ether for the first time
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    // Function to return the  current balance of the smart contract
    function getContractBalance() public view returns (uint)
    {
        return address(this).balance;
    }


    function refund() public
    {
        require(block.timestamp > deadline, "Deadline is not over yet");
        require(raisedAmount < target, "Target reached");
        require(contributors[msg.sender] > 0);

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]); // Refunds the entire value sent from the account

        contributors[msg.sender] = 0; // Reset the transferred ether to 0 post refund
   
    }

    // Any function declared after this with the defined modifier will only be called by the manager
    modifier onlyManager() 
    {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public
    {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

    }


    function voteRequest(uint _requestNo) public
    {
        require(contributors[msg.sender] > 0, "You must be a contributor");

        Request storage thisRequest = requests[_requestNo];
        
        require(thisRequest.voters[msg.sender]==false, "You have already voted");

        thisRequest.voters[msg.sender] = true;

        thisRequest.noOfVoters++;
    }


    function makePayment(uint _requestNo) public onlyManager
    {
        require(raisedAmount >= target, "Target has not been reached");

        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.completed==false, "The request has been completed");

        require(thisRequest.noOfVoters > noOfContributors/2, "Majority does not support");

        thisRequest.recipient.transfer(thisRequest.value);

        thisRequest.completed = true;
        
    }

}