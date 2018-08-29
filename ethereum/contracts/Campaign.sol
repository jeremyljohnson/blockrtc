pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;
    
    function createCampaign(uint minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    constructor(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }
    
    function contribute() public payable {
        require(msg.value > minimumContribution);
        // example of mapping - note that we can't iterate through addresses
        approvers[msg.sender] = true;
        approversCount++;
    }
    
    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
            // only have to initialize value types; mapping is a reference type
        });
        
        requests.push(newRequest);
    }
    
    function approveRequest(uint index) public {
        Request storage request = requests[index];
        
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        
        require(!request.complete);
        require(request.approvalCount > (approversCount / 2));
        
        request.recipient.transfer(request.value);
        request.complete = true;
        
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}

contract MeetingContract {
    struct Meeting {
        uint256 meetingId;                  // integer representing the meetingId
        bytes32 name;                       // title of meeting
        uint256 startTime;                       // start day and time
        uint256 endTime;                         // end day and time
        uint256 status;                      // current status (pending=0, active=1, ended=2, failed=3)
        address host;                       // host ether address - MAYBE REPLACE THIS WITH MEETINGHOSTS
        address server;                     // server ether address - MAYBE REPLACE THIS WITH MEETINGSERVERS
        uint256 quality;                      // 180p, 240p, 360p, 480p, 720p, 960p, 1080p, 2160p
        uint256 maxParticipants;              // maximum number of participants
        string url;                         // url of the host - could use ENS name service
        bool invitationOnly;                // are only users with ethereum addresses - and were invited - are allowed access
        bytes32 password;              // if meeting is authenticated, need password
        // use keccak256 to make sure password matches what was hashed off-chain
        mapping(address => bool) participants; // is this address a participant
    }

    struct Server {
        address recipient;      // address of the server, where funds will be sent for successful meeting
    }

    struct Client {
        address clientAddress;  // ethereum client address (possibly optional)
        bytes32 name;            // whatever name a client wants to use to display
    }

    struct MeetingOffer {
        address serverAddress;      // recipient address of the server making this offer - IS THIS STILL NEEDED?
        string url;                 // url where meetings will he held - could be ip address and port
        uint256 availableFrom;         // time server is available from
        uint256 availableTo;           // time server is available to
        uint256 hourlyCost;            // hourly cost a server is willing to accept
        uint256 maxConnections;       // rough estimate of maximum number of meeting connections a server can provide
    }

    struct MeetingRequest {
        bytes32 name;
        address host;
        uint256 startTime;
        uint256 endTime;
        uint256 quality;
        uint256 maxCost;
        uint256 participants;
        bool invitationOnly;
        bytes32 password;
    }

    uint256 registrationCost = 100000;
    uint256 numHosts = 0;
    uint256 numServers = 0;
    uint256 numOffers = 0;
    uint256 numMeetings = 0;

    mapping(uint256 => Server) public servers; // mapping list of servers
    mapping(address => bool) public potentialServers; // mapping server address => whether an address is registered as a server

    mapping(uint256 => Meeting) public meetings; // mapping list of meetings 1:1


    mapping(uint256 => address) public serverOffers; // mapping meetingOfferId => server address
    mapping(address => MeetingOffer) public meetingOffers; // server => meetingOffer (only 1 allowed per server)

    mapping(uint256 => address) public meetingHosts; // mapping of meetingIds to host address 1:1
    mapping(uint256 => address) public meetingServers; // mapping of meetingIds to server address 1:1


    // Restricted to servers that have registered
    modifier serverOnly() {
        require(potentialServers[msg.sender] == true);
        _;
    }

    // Only the server who is serving this particular meeting can modify
    modifier meetingServerOnly(uint256 meetingId) {
        require(msg.sender == meetingServers[meetingId]);
        _;
    }

    // Only the host who has scheduled this meeting can modify
    modifier meetingHostOnly(uint256 meetingId) {
        require(msg.sender == meetingHosts[meetingId]);
        _;
    }

    // Only the server that has offered this meeting can modify
    modifier offerServerOnly(uint256 meetingId) {
        require(meetingOffers[msg.sender].serverAddress == meetingServers[meetingId]);
        _;
    }

    modifier includesRegistrationFee() {
        require(msg.value > registrationCost);
        _;
    }

    modifier includesPayment(uint256 maxCost) {
        require(msg.value > maxCost);
        _;
    }
    
    function registerServer() public payable includesRegistrationFee returns (uint256 serverId) {
        // Increment the serverId, and return it
        numServers++;
        Server memory potentialServer = Server ({
            recipient: msg.sender
        });

        servers[numServers] = potentialServer;
        potentialServers[msg.sender] = true;
        return numServers;
    }

    function offerMeeting(string url, uint256 availableFrom, uint256 availableTo, uint256 hourlyCost, uint256 maxConnections)
        public serverOnly returns (uint256) {
        // Increment the number of offers and return it
        numOffers++;
        MeetingOffer memory meetingOffer = MeetingOffer ({
            serverAddress: msg.sender,
            url: url,
            availableFrom: availableFrom,
            availableTo: availableTo,
            hourlyCost: hourlyCost,
            maxConnections: maxConnections
        });
        serverOffers[numOffers] = meetingOffer.serverAddress;
        meetingOffers[msg.sender] = meetingOffer;
    }

    // function getOffersLength() public pure returns (uint256) {
    //    return numOffers;
    // }

    function checkCriteria (MeetingOffer offer, uint256 from, uint256 availableTo, uint256 maxCost, uint256 maxConnections) 
        private pure returns (bool) {
        if (offer.hourlyCost < maxCost && offer.maxConnections > maxConnections) {
            if (offer.availableTo > availableTo && offer.availableFrom < from) {
                // Need to also check whether someone else has a booked meeting that overlaps with this time
                return true;
            }
        }
        return false;
    }
    
    function matchOffer(uint256 startTime, uint256 endTime, uint256 maxCost, uint256 quality, uint256 maxConnections) 
        internal view returns (uint256) {
        // only returns first address of a server that has created a meeting offer that fulfills the time, cost and connection requirements
        for (uint256 i = 0; i < numOffers; i++) {
            MeetingOffer memory meetingOffer = meetingOffers[serverOffers[i]];
            bool available = checkCriteria(meetingOffer, startTime, endTime, maxCost, maxConnections);
            if (available == true) {
                return i;
                // Note: only returns if a server's meetingOffer meets the criteria
                // MAYBE WE CREATE A NEW CONTRACT FOR A SCHEDULED MEETING HERE
            }
        }
    }

    function requestMeeting(
        bytes32 name,
        uint256 startTime,
        uint256 endTime,
        uint256 quality,
        uint256 maxCost,
        uint256 participants,
        bool invitationOnly,
        bytes32 password)
        public
        includesPayment(maxCost)
        payable
        returns (uint256) {
        
        uint256 offerId = matchOffer(startTime, endTime, maxCost, quality, participants);
        
        if (offerId > 0) {
            MeetingOffer memory meetingOffer = meetingOffers[serverOffers[offerId]];
            numMeetings++;
            Meeting memory newMeeting = Meeting({
                meetingId: numMeetings,
                name: name,
                startTime: startTime,
                endTime: endTime,
                status: 0,
                host: msg.sender,
                server: meetingOffer.serverAddress,
                quality: quality,
                maxParticipants: participants,
                url: meetingOffer.url,
                invitationOnly: invitationOnly,
                password: password
                // Note: not including participants mapped to meeting yet
            });

            meetings[numMeetings] = newMeeting;
            meetingHosts[numMeetings] = newMeeting.host;
            meetingServers[numMeetings] = newMeeting.server;
            return numMeetings;

        }
        // this is where the offer would be accepted and commms established between the two participants. 
        // check if there is an offer meeting that request 
        //getOffersLength() will return
        // iterate from 0-length until 
        //checkCriteria returns true
    

    }
       
    // acceptMeeting
    // startMeeting
    // stopMeeting
    // pauseMeeting
    // joinMeeting
    // reviewMeeting - Uber-style star rating

    // checkPassword
    // estimateMaxLength - estimates maximum length of a meeting based on funds in user wallet
    // payDownPayment - pay downpayment for 50% of meeting fee
    // payServer - pay server fee for hosting meeting at end of meeting
    // refundHost - refund if host does not run meeting, or meeting ended < 90% complete
    // split difference between contract and server if meeting takes less than scheduled time 
    // is less than 10% of scheduled time - otherwise refund host meeting fee minus cost to schedule
}