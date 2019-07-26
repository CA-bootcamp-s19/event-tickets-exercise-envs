pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PRICE_TICKET = 100 wei;
    address payable public owner = msg.sender;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping(address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;


    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyOwner(){
        require(
            msg.sender == owner,
            "Only the owner can call this function"
            );
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _desc, string memory _website, uint _totalTickets) verifyOwner public returns(uint) {
        Event memory myEvent;
        myEvent.description = _desc;
        myEvent.website = _website;
        myEvent.totalTickets = _totalTickets;
        myEvent.isOpen = true;
        uint newEventId = idGenerator;
        events[idGenerator] = myEvent;
        ++idGenerator;
        emit LogEventAdded(_desc, _website, _totalTickets, newEventId);
        return newEventId;

    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id)
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        return (events[_id].description, events[_id].website, events[_id].totalTickets, events[_id].sales, events[_id].isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _id, uint _numTickets) public payable {
        require(events[_id].isOpen == true);
        require(msg.value >= _numTickets * PRICE_TICKET);
        require(events[_id].totalTickets - events[_id].sales >= _numTickets);
        events[_id].buyers[msg.sender] += _numTickets;
        events[_id].sales += _numTickets;
        uint payChange = msg.value - _numTickets * PRICE_TICKET;
        if (payChange > 0) {
            address(msg.sender).transfer(payChange);
        }
        emit LogBuyTickets(msg.sender, _id, _numTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _id) public {
        require(events[_id].buyers[msg.sender] > 0);
        uint refundTickets = events[_id].buyers[msg.sender];
        events[_id].sales -= refundTickets;
        delete events[_id].buyers[msg.sender];
        address(msg.sender).transfer(refundTickets * PRICE_TICKET);
        emit LogGetRefund(msg.sender, _id, refundTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _id) view public returns(uint) {
        return events[_id].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _id) public verifyOwner {
        events[_id].isOpen = false;
        uint balance = events[_id].sales * PRICE_TICKET;
        owner.transfer(balance);
        emit LogEndSale(owner, balance, _id);
    }
}
