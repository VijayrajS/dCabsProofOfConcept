pragma solidity ^0.5.10;

contract Dcabs {
    
    address public auditor; //!< Person who authorises the registration of a cab driver into the system
    
    //structure that stores trip data
    struct Trip {
        bytes32 pickupHash; //!< Hash of the pickup address
        bytes32 destHash;   //!< Hash of the destination address 
        
        uint256 startTime; //!< Time of trip start
        uint256 endTime; //!< Time of trip end

        address payable driverAddr;   //!< Wallet address of the driver involved
        address payable customerAddr; //!< Wallet address of the customer involved
        
        uint256 price;           //!< Expense of the trip
        uint rating;          //!< Rating of the 
        string comments;      //!< Customer comments of the ride
        bool customerEnded;   //!< Whether the customer is ready to end the trip
        bool driverEnded;     //!< Whether the driver is ready to end the trip
    }
    
    //!< structure that the customer pushes onto the blockchain to make a pickup
    //!< request to a particular driver
    
    struct TripRequest {
        bool requestMade;                //!< Whether a customer has made this request
        bytes32 encryptedPickup;         //!< pickup location encrypted with the PubKey of the requsted driver 
        bytes32 encryptedDest;           //!< pickup location encrypted with the PubKey of the requsted driver 
        bytes32 driverPhoneNumEncrpyted; //!< phone number of driver encrpyted with the customer's key
        bool accepted;                   //!< Boolean variable that determines whether the driver has accepted the request
    }
    
    //!< Structure that stores the details of drivers in the system
    
    struct Driver{
        uint driverLicense;     //!< A verifiable hash of the driver's license
        uint reputation;        //!< Reputation score of the driver
        Trip[] driverTrips;     //!< List of all trips undertaken by the driver 
        bool registered;        //!< A boolean variable that determines whether the driver is registered or not
    }
    
    //!< Structure that stores the details of a customer
    
    struct Customer{
        uint paid;               //!< The amount of money the customer has deposited in the contract
        Trip[] customerTrips;    //!< List of all trips embarked on by the customer
        bool exists;             //!< Whether this customer has used the app before
        uint nUniqueDrivers;     //!< Number of unique cab drivers the customer has ridden with
        
        mapping(address => bool) uniqueDriversMap; //!< A hashmap to determine whether a driver has ridden with the customer before 
    }
    
    mapping(address => Customer) customers;       //!< Mapping b/w a customer profile and his wallet address
    mapping(address => Driver) drivers;           //!< Mapping b/w a driver profile and his wallet address
    mapping(uint => Trip) currentTrip;            //!< Mapping b/w an OTP and a trip object
    mapping(address => mapping(address => TripRequest)) activeTrips;  //!< Mapping b/w a driver address and a TripRequest object (corresponding to an ongoing trip)
    uint cur;                                     //!< Variable storing most recent OTP
    uint public nDrivers = 0;
    
    constructor() public{
        auditor = msg.sender;
    }

    // Function to register a driver into the system
    function registerDriver (address driverAddr, uint license) public{
        require(msg.sender == auditor);
        require(!drivers[driverAddr].registered, "Driver was already registered");
        drivers[driverAddr].driverLicense = license;
        drivers[driverAddr].registered = true;
        nDrivers += 1;
    }
    
    // Function to send a pickup request to a particular driver and pay a flat fee amount
    function setPickup(bytes32 encryptedPickup, bytes32 encryptedDest, address driverRequested) public payable{
        require(msg.value >= 1 ether, "PAY UP THE MANDATORY FEE");
        if(!customers[msg.sender].exists){
            customers[msg.sender].paid = 0;
            customers[msg.sender].nUniqueDrivers = 0;
            customers[msg.sender].exists = true;
        }
        customers[msg.sender].paid += msg.value;
        activeTrips[driverRequested][msg.sender].requestMade = true;
        activeTrips[driverRequested][msg.sender].encryptedPickup = encryptedPickup;
        activeTrips[driverRequested][msg.sender].encryptedDest = encryptedDest;
    }

    
    // Function for driver to accept the trip
    function acceptTrip(bytes32 driverPhoneNumEncrpyted, address payable customer) public returns(uint) {
        require(drivers[msg.sender].registered, "Driver doesn't exist");
        require(activeTrips[msg.sender][customer].requestMade, "Invalid customer");
        activeTrips[msg.sender][customer].accepted = true;
        activeTrips[msg.sender][customer].driverPhoneNumEncrpyted = driverPhoneNumEncrpyted;
        enterTripDetails(msg.sender, customer, activeTrips[msg.sender][customer].encryptedPickup, activeTrips[msg.sender][customer].encryptedDest, cur);
        return cur++;
    }
    
    // Function to populate the currentTrip mapping while confirming a ride
    function enterTripDetails(address payable dAddr, address payable cAddr, bytes32 pcHash, bytes32 dHash, uint otp) internal{
        currentTrip[otp].pickupHash = pcHash;
        currentTrip[otp].destHash = dHash;
        currentTrip[otp].driverAddr = dAddr;
        currentTrip[otp].customerAddr = cAddr;
        currentTrip[otp].startTime = now;
    }
    
    // Customer cancels the trip request.
    function cancelRequest(address driverRequested) public{
        require(activeTrips[driverRequested][msg.sender].requestMade, "You haven't booked a cab");
        activeTrips[driverRequested][msg.sender].requestMade = false;
        msg.sender.transfer(customers[msg.sender].paid);
        customers[msg.sender].paid = 0;
    }
    
    // Linear function to get price based on time
    function getPrice(uint256 start, uint256 end) pure internal returns (uint256){
        uint256 flat = 100000;
        uint256 scale = 1000;
        uint256 dur = end - start;
        return flat + dur*scale;
    }

    // Function to end the trip, called by driver and customer
    function endTrip(uint otp, uint rating) public{
        require(!currentTrip[otp].customerEnded || !currentTrip[otp].driverEnded, "Trip is already done");
        require(currentTrip[otp].customerAddr == msg.sender || currentTrip[otp].driverAddr == msg.sender, "Unauthorised to end trip");
        
        // Customer has ended the trip from his/her side  (Update the reputation of the driver)
        
        if(msg.sender == currentTrip[otp].customerAddr && !currentTrip[otp].customerEnded){
            updateReputation(rating, currentTrip[otp].driverAddr, currentTrip[otp].customerAddr);
            currentTrip[otp].customerEnded = true;
        }
        // Driver has ended the trip from his/her side
        else{
            currentTrip[otp].driverEnded = true;
        }

        // After both have ended the trip, transfer money for trip and update the number of
        // unique drivers for the customer
        
        if(currentTrip[otp].driverEnded &&  currentTrip[otp].customerEnded){
            
            currentTrip[otp].price = getPrice(currentTrip[otp].startTime, currentTrip[otp].endTime);
            currentTrip[otp].driverAddr.transfer(currentTrip[otp].price);
            currentTrip[otp].customerAddr.transfer(customers[currentTrip[otp].customerAddr].paid - currentTrip[otp].price);
            customers[currentTrip[otp].customerAddr].paid = 0;
            currentTrip[otp].endTime = now;
            updateUniqueDrivers(currentTrip[otp].customerAddr, currentTrip[otp].driverAddr);
        }
    }
    
    // Function to update the list of drivers the customer has ridden with
    function updateUniqueDrivers (address customer, address driver) internal{
        // If the customer has already ridden with the driver do nothing
        if(customers[customer].uniqueDriversMap[driver] == true){
            return;
        }
        
        // Else update the mapping and increment the unique driver count
        customers[customer].uniqueDriversMap[driver] = true;
        customers[customer].nUniqueDrivers++;
    }
    
    // Function to update the list of drivers the customer has ridden with
    function updateReputation (uint rating, address customer, address driver) internal{
        require(rating <= 5 && rating > 0, "Invalid Rating");
        uint weight = customers[customer].nUniqueDrivers / nDrivers;
        drivers[driver].reputation += rating * weight;
    }
    
    // Function to cancel trip (either by the customer or driver)
    
    function cancelTrip(uint otp) public{
        require(currentTrip[otp].customerAddr == msg.sender || currentTrip[otp].driverAddr == msg.sender, "Unauthorised to cancel trip");
        
        currentTrip[otp].endTime = now;
        
        // If the customer cancels the trip midway, the driver gets paid for whatever
        // distance he has driven
        
        if(msg.sender == currentTrip[otp].customerAddr){
            currentTrip[otp].price = getPrice(currentTrip[otp].startTime, currentTrip[otp].endTime);
        }
        
        // If the driver ends the trip, he gets no money from the trip
        
        else{
            currentTrip[otp].price = 0;
        }
        
        // Money transfer for the trip
        currentTrip[otp].driverAddr.transfer(currentTrip[otp].price);
        currentTrip[otp].customerAddr.transfer(customers[currentTrip[otp].customerAddr].paid - currentTrip[otp].price);
        
        // Ending trip from both sides
        currentTrip[otp].customerEnded = true;
        currentTrip[otp].driverEnded = true;
    }

    // An empty payable function to make the contract payabl
    function () external payable{
    }
}