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
        string title;                       // title of meeting
        string description;                 // description of meeting
        string start;                       // start day and time
        string end;                         // end day and time
        string status;                      // current status (pending, active, ended)
        address host;                       // host ether address
        address server;                     // server ether address
        uint256 quality;                      // 180p, 240p, 360p, 480p, 720p, 960p, 1080p, 2160p
        uint256 maxParticipants;              // maximum number of participants
        bool successful;                    // did meeting fail or was it successful
        string url;                         // url of the host - could use ENS name service
        bool invitationOnly;                // are only users with ethereum addresses - and were invited - are allowed access
        string hashedPassword;              // if meeting is authenticated, need password, 
        // use keccak256 to make sure password matches what was hashed off-chain
        mapping(address => bool) active;    // is the user active in the meeting
        mapping(address => bool) participant; // is this address a participant
    }

    struct Server {
        address recipient;      // address of the server, where funds will be sent for successful meeting
        string url;             // url where meetings will he held - could be ip address and port
<<<<<<< HEAD
        uint8[] ports;          // possibly just port range
        // bool available;         // probably just calculate this if active meetings.maxParticipants < maxConnections
=======
        uint256 port;          // possibly just port range
>>>>>>> master
    }

    struct Client {
        address clientAddress;  // ethereum client address (possibly optional)
        string name;            // whatever name a client wants to use to display
    }

    struct MeetingOffer {
        address serverAddress;      // recipient address of the server making this offer
<<<<<<< HEAD
        uint availableFrom;         // time server is available from
        uint availableTo;           // time server is available to
        uint hourlyCost;            // hourly cost a server is willing to accept
        uint8 maxConnections;       // rough estimate of maximum number of meeting connections a server can provide
=======
        uint256 availableFrom;         // time server is available from
        uint256 availableTo;           // time server is available to
        uint256 hourlyCost;            // hourly cost a server is willing to accept
        uint256 maxConnections;       // rough estimate of maximum number of meeting connections a server can provide
>>>>>>> master
    }

    Meeting[] meetings;
    Client[] clients;
    Server[] servers;
    MeetingOffer[] meetingOffers;
    mapping(address => bool) public potentialServers;
<<<<<<< HEAD
    uint16 registrationCost = 10000;
=======
    uint256 registrationCost = 10000;
>>>>>>> master

    modifier serverOnly() {
        require(potentialServers[msg.sender] == true);
        _;
    }

<<<<<<< HEAD
    function registerServer(string url, uint8[] ports) public payable {
=======
    function registerServer(string url, uint256 port) public payable {
>>>>>>> master
        require(msg.value > registrationCost);

        Server memory potentialServer = Server ({
            recipient: msg.sender,
            url: url,
<<<<<<< HEAD
            ports: ports
=======
            port: port
>>>>>>> master
        });

        servers.push(potentialServer);
        potentialServers[msg.sender] = true;
    }
<<<<<<< HEAD

    function offerMeeting(uint availableFrom, uint availableTo, uint hourlyCost, uint8 maxConnections) public serverOnly {
        MeetingOffer memory meetingOffer = MeetingOffer ({
            serverAddress: msg.sender,
            availableFrom: availableFrom,
            availableTo: availableTo,
            hourlyCost: hourlyCost,
            maxConnections: maxConnections
        });

        meetingOffers.push(meetingOffer);
    }

    function getOffersLength() public view returns (uint) {
        return meetingOffers.length;
    }

    function checkCriteria (MeetingOffer offer, uint from, uint availableTo, uint maxCost, uint8 maxConnections) private view returns (bool) {
        if (offer.hourlyCost < maxCost && offer.maxConnections > maxConnections) {
            if (offer.availableTo > availableTo && offer.availableFrom < from) {
                return true;
            }
        }
        return false;
    }

    function listOffers(uint availableFrom, uint availableTo, uint maxCost, uint8 maxConnections) public view returns (address[]) {
        // only returns address of servers who have created meeting offers that meet the time, cost and connection requirements
        address[] memory offerAddresses;
        uint offerIndex = 0;
        for (uint i = 0; 1 < meetingOffers.length; i++) {
            MeetingOffer storage meetingOffer = meetingOffers[i];
            bool available = checkCriteria(meetingOffer, availableFrom, availableTo, maxCost, maxConnections);
            if (available) {
                offerAddresses[offerIndex] = meetingOffer.serverAddress;
                offerIndex++;
            }
        }
        return offerAddresses;
    }

    // requestMeeting
=======

    function offerMeeting(uint256 availableFrom, uint256 availableTo, uint256 hourlyCost, uint256 maxConnections) public serverOnly {
        MeetingOffer memory meetingOffer = MeetingOffer ({
            serverAddress: msg.sender,
            availableFrom: availableFrom,
            availableTo: availableTo,
            hourlyCost: hourlyCost,
            maxConnections: maxConnections
        });

        meetingOffers.push(meetingOffer);
    }

    function getOffersLength() public view returns (uint256) {
        return meetingOffers.length;
    }

    function checkCriteria (MeetingOffer offer, uint256 from, uint256 availableTo, uint256 maxCost, uint256 maxConnections) private pure returns (bool) {
        if (offer.hourlyCost < maxCost && offer.maxConnections > maxConnections) {
            if (offer.availableTo > availableTo && offer.availableFrom < from) {
                return true;
            }
        }
        return false;
    }
    
    function matchOffer(uint256 startTime, uint256 endTime, uint256 maxCost, uint256 maxConnections) public view returns (address) {
        // only returns first address of a server that has created a meeting offer that fulfills the time, cost and connection requirements
        for (uint256 i = 0; 1 < meetingOffers.length; i++) {
            MeetingOffer storage meetingOffer = meetingOffers[i];
            bool available = checkCriteria(meetingOffer, startTime, endTime, maxCost, maxConnections);
            if (available) {
                return meetingOffer.serverAddress;
                // Note: only returns if a server meets the criteria
            }
        }
    }

>>>>>>> master
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