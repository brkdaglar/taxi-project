// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;



contract TaxiContract {
    
    struct Participant{
        address adres;
        uint256 balance;
        bool carVote;
        bool driverVote;
        
    }

    
    struct TaxiDriver{
        address adres;
        uint expectedSalary;
        bool set;
        uint approvalState;
        bool isWork;
        uint256 lastGetSalary;
        uint balance;
    }
    
    struct Proposed{
        bytes32 carId;
        uint  price;
        uint validTime;
        uint approvalState;

    }

    uint maxParticipants;
    
    address owner;
    address carDealer;
    uint contractBalance;
    uint fixedExpenses;
    uint participationFee;
    bytes32 ownedCar;

    uint256 _1monthSec = 2629743;

    
    mapping (address=>Participant) participants;
    address[]  parts;

    Proposed proposedCar;
    Proposed proposedRepurschase;

    TaxiDriver taxiDriver;

    uint256 lastCarExpenses;
    uint256 lastDividend;

    // Fallback Function
    fallback() external payable{
        participants[msg.sender].balance += msg.value;
    }

    receive() external payable {
        participants[msg.sender].balance += msg.value;
    }
    
    // Called by owner of the contract and sets initial values for state variables 
    constructor(address nCarDealer)  {
        owner = msg.sender;
        carDealer = nCarDealer;
        contractBalance = 0 ether;
        fixedExpenses = 10 ether;
        participationFee = 100 ether;
        maxParticipants = 9;
        lastCarExpenses = block.timestamp;
        lastDividend = block.timestamp;
    }

    // Called by participants, Participants needs to pay the participation fee set in the contract to be a 
    // member in the taxi investment
    function join() public payable {
        require(msg.value >= participationFee,"You have not enough value");
        require(parts.length < maxParticipants,"No place");
        

        participants[msg.sender] = Participant(msg.sender,0 ether,false,false);
        parts.push(msg.sender);

        contractBalance += participationFee;
        
    }

    // Only CarDealer can call this, sets Proposed Car values, such as CarID, price, offer valid time and
    // approval state 
    function carProposeToBusiness(bytes32 _id, uint _price, uint _validTime)  public {
        require(msg.sender==carDealer,"You do not have access to this transaction.");
        proposedCar = Proposed(_id,_price,_validTime,0);   
    
    }
    
    //Participants can call this function, approves the Proposed Purchase with incrementing the approval
    //state. Each participant can increment once. When the majority of participants approve, calls PurschaseCar
    //function
    function approvePurchaseCar() public {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(participants[msg.sender].carVote!=true,"You already entered vote");
        require(proposedCar.carId!=0,"No car in the system");

        proposedCar.approvalState += 1;
        participants[msg.sender].carVote=true;

        if(proposedCar.approvalState>parts.length/2){
            for(uint i=0;i<parts.length;i++){
                participants[parts[i]].carVote = false;
            }
            ownedCar = proposedCar.carId;
            purchaseCar();
        }
    }

    //Sends the CarDealer the price of the proposed car if the offer valid time is not passed yet
    function purchaseCar() internal {
        require(block.timestamp<proposedCar.validTime,"Not have a time");
        payable(carDealer).transfer(proposedCar.price);
        contractBalance -= proposedCar.price;
    }


    //Only CarDealer can call this, sets Proposed Purchase values, such as CarID, price, offer valid time and
    //approval state 
    function repurchaseCarPropose(bytes32 id,uint price,uint valdTim) public { 
        require(msg.sender==carDealer,"You do not have access to this transaction.");
        proposedRepurschase = Proposed(id,price,valdTim,0);
        
    }

    //Participants can call this function, approves the Proposed Sell with incrementing the approval state.
    //Each participant can increment once. When the majority of participants approve, calls Repurchasecar function

    function approveSellProposal() public {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(participants[msg.sender].carVote!=true,"You already entered vote");
        require(proposedRepurschase.carId!=0,"No repurschase in the system");

        proposedRepurschase.approvalState += 1;
        participants[msg.sender].carVote=true;

        if(proposedRepurschase.approvalState>parts.length/2){
            for(uint i=0;i<parts.length;i++){
                participants[parts[i]].carVote = false;
            }
            repurchaseCar();
        }
    }

    //Participants can call this function, approves the Proposed Sell with incrementing the approval state.
    //Each participant can increment once. When the majority of participants approve, calls Repurchasecar function

    function repurchaseCar() public payable {
        require(block.timestamp<proposedRepurschase.validTime,"Not have a time");
        contractBalance += proposedRepurschase.price;
    }

    //Caller proposes himself/herself as driver and sets his/her address, and expected salary. Only one
    //proposed driver can be set
    function proposeDriver(address adres,uint salary) public {
        require(taxiDriver.set!=true,"A driver is already set");
        taxiDriver = TaxiDriver(adres,salary,true,0,false,0,0);
    }


    //Participants can call this function, approves the Proposed Driver with incrementing the approval state.
    //Each participant can increment once. When the majority of participants approve, calls SetDriver function
    function approveDriver() public {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(participants[msg.sender].driverVote!=true,"You already entered vote");
        require(taxiDriver.adres!=address(0x0),"No driver in the system");

        taxiDriver.approvalState += 1;
        participants[msg.sender].driverVote = true;

        if(taxiDriver.approvalState>parts.length/2){
            for(uint i=0;i<parts.length;i++){
                participants[parts[i]].driverVote = false;
            }
            setDriver();
        }
    }
    
    //Sets the Driver info if approval state is approved by more than half of the participants. Clears proposed
    //driver info
    function setDriver() internal {
        taxiDriver.isWork = true;
        taxiDriver.approvalState = 0;
        taxiDriver.lastGetSalary = block.timestamp;
        taxiDriver.balance = taxiDriver.expectedSalary;

    }

    //Participants can call this function, approves firing driver with incrementing the approval state. Each
    //participant can increment once. When the majority of participants approve, calls Fire Driver function
    function proposeFireDriver() public {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(participants[msg.sender].driverVote!=true,"You already entered vote");
        require(taxiDriver.adres!=address(0x0),"No driver in the system");

        taxiDriver.approvalState += 1;
        participants[msg.sender].driverVote = true;

        if(taxiDriver.approvalState>maxParticipants/2){
            for(uint i=0;i<parts.length;i++){
                participants[parts[i]].driverVote = false;
            }
            fireDriver();
        }
    }

    //Sends any amount of money of the current driver’s account to Driver’s address. Clears the driver info
    function fireDriver() public payable {
        if (taxiDriver.balance>0){
            contractBalance -= taxiDriver.balance;
            payable(taxiDriver.adres).transfer(taxiDriver.balance);
        }    
        delete taxiDriver;

    }

    //Only Driver can call this function, calls FireDriver function
    function leaveJob() public {
        require(msg.sender==taxiDriver.adres,"You do not have access to this transaction.");
        fireDriver();
    }

    // customers who use the taxi pays their ticket through this function. Charge is sent to contract
    function getCharge() public payable {
        contractBalance += msg.value;
    }

    //Only Driver can call this function, releases the salary of the Driver to his/her account monthly. Make
    //sure it is not being called more than once in a month. If there is any money in Driver’s account, it will be send to
    //his/her address
    function getSalary() public payable {
        require(msg.sender==taxiDriver.adres,"You do not have access to this transaction.");
        require(block.timestamp-taxiDriver.lastGetSalary>=_1monthSec,"It has not been 1 months");
        require(taxiDriver.balance>0,"You do not have money."); 

        contractBalance -= taxiDriver.expectedSalary;
        taxiDriver.lastGetSalary = block.timestamp;  
        payable(taxiDriver.adres).transfer(taxiDriver.expectedSalary);
        taxiDriver.balance = taxiDriver.expectedSalary;
        
    }

    // Only one of the participants can initiate this function, sends the CarDealer the price of the expenses
    //every 6 month. Make sure it is not being called more than once in the last 6 months.
    function carExpenses() public payable{
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(block.timestamp-lastCarExpenses>=(6*_1monthSec),"It has not been 6 months");

        contractBalance -= fixedExpenses;
        payable(carDealer).transfer(fixedExpenses);
        lastCarExpenses = block.timestamp;
    }

    //Only one of the participants can initiate this function, calculates the total profit after expenses and
    //Driver salaries, calculates the profit per participant and releases this amount to participants in every 6 month.
    function payDividend() public {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(block.timestamp-lastDividend>=(6*_1monthSec),"It has not been 6 month");
        require(contractBalance>participationFee*parts.length,"No money to pay");

        uint pay = (contractBalance - (participationFee*parts.length)) / parts.length;
        for(uint i=0;i<parts.length;i++){
            participants[parts[i]].balance += pay;
        }
        contractBalance = participationFee*parts.length;
        lastDividend = block.timestamp;
        
    }

    //Only Participants can call this function, if there is any money in the calling participants’ account, it will
    //be send to his/her address.
    function getDividend() public payable {
        require(participants[msg.sender].adres!=address(0x0),"You do not have access to this transaction.");
        require(participants[msg.sender].balance>0,"You do not have money");

        payable(msg.sender).transfer(participants[msg.sender].balance);
        participants[msg.sender].balance = 0;
    }

    

    
}