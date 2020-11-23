pragma solidity ^0.5.10;

contract DCabs {
    
    address public auditor; //!< Person who authorises the registration of a cab driver into the system
    
    //!< structure that stores trip data
    
    struct Trip {
        bytes32 pickupHash; //!< Hash of the pickup address
        bytes32 destHash;   //!< Hash of the destination address 
        
        uint256 startTime; //!< Time of trip start
        uint256 endTime; //!< Time of trip end

        address driverAddr;   //!< Wallet address of the driver involved
        address customerAddr; //!< Wallet address of the customer involved
        
        uint256 price;           //!< Expense of the trip
        uint rating;          //!< Rating of the 
        string comments;      //!< Customer comments of the ride
        bool customerEnds;   //!< Whether the customer is ready to end the trip
        bool driverEnds;     //!< Whether the driver is ready to end the trip
    }
    
    //!< structure that the customer pushes onto the blockchain to make a pickup
    //!< request to a particular driver
    
    struct TripRequest {
        bytes32 encryptedPickup; //!< pickup location encrypted with the PubKey of the requsted driver 
        address customer;        //!< Wallet address of the customer
        uint driverPhoneNumEncrpyted; /* SUS */
        bool accepted;           //!< Boolean variable that determines whether the driver has accepted the request
    }
    
    //!< Structure that stores the details of drivers in the system
    
    struct Driver{
        uint driverLicense;     //!< A verifiable hash of the driver's license
        uint reputation;        //!< Reputation score of the driver
        // Trip[] driverTrips;     //!< List of all trips undertaken by the driver 
        bool registered;        //!< A boolean variable that determines whether the driver is registered or not
    }
    
    //!< Structure that stores the details of a customer
    
    struct Customer{
        uint paid;              //!< The amount of money the customer has deposited in the contract
        uint uniqueDrivers;     //!< Number of unique cab drivers the customer has ridden with
        // Trip[] customerTrips;   //!< List of all trips embarked on by the customer
        bool exists;            //!< Whether this customer has used the app before
    }
    
    mapping(address => Customer) customers;       //!< Mapping b/w a customer profile and his wallet address
    mapping(address => Driver) drivers;           //!< Mapping b/w a driver profile and his wallet address
    mapping(address => TripRequest) activeTrips;  //!< Mapping b/w a driver address and a TripRequest object (corresponding to an ongoing trip)
    mapping(uint => Trip) currentTrip;            //!< Mapping b/w an OTP and a trip object
    uint cur;                                     //!< Variable storing most recent OTP

    // Function to register a driver into the system
    function registerDriver public(address driverAddr, uint license){
        require(msg.sender == auditor);
        drivers[driverAddr].driverLicense = license;
        drivers[driverAddr].registered = true;
    }
    
    // Function to send a pickup request to a particular driver and pay a flat fee amount
    function setPickup(bytes32 encryptedPickup, address driverRequested) public payable{
        require(msg.value >= 1 ether, "PAY UP THE MANDATORY FEE");
        if(!customers[msg.sender].exists){
            customers[msg.sender].paid = 0;
            customers[msg.sender].uniqueDrivers = 0;
            customers[msg.sender].exists = true;
        }
        customers[msg.sender].paid += msg.value;
        activeTrips[driverRequested].encryptedPickup = encyptedPickup;
    }
    // IMPLEMENT MULTIPLE CUSTOMER REQUESTS THE SAME DRIVER.

    
    // Function for driver to accept the trip
    function acceptTrip(bytes32 driverPhoneNumEncrpyted) public returns(uint) {
        require(drivers[msg.sender].registered);
        activeTrips[msg.sender].accepted = true;
        activeTrips[msg.sender].driverPhoneNumEncrpyted = driverPhoneNumEncrpyted
        enterTripDetails(msg.sender, activeTrips[msg.sender].customer, activeTrips[msg.sender].pickupHash, activeTrips[msg.sender].destHash, cur);
        return cur++;
    }
    
    // Function to populate the currentTrip mapping while confirming a ride
    function enterTripDetails(bytes32 dAddr, bytes32 cAddr, bytes32 pcHash, bytes32 dHash, uint otp){
        currentTrip[otp].pickupHash = pcHash;
        currentTrip[otp].destHash = dHash;
        currentTrip[otp].driverAddr = dAddr;
        currentTrip[otp].customerAddr = cAddr;
        currentTrip[otp].startTime = now;
    }
    
    // Wait what
    function cancelRequest(bytes32 encryptedPickup, address driverRequested){
        require()
        activeTrips[driverRequested].encryptedPickup = encyptedPickup;
        msg.sender
    }
    
    // Linear function to get price based on time
    function getPrice(uint256 start, uint256 end) pure internal returns (uint256){{
        uint256 flat = 100000;
        uint256 scale = 1000;
        uint256 dur = end - start;
        return flat + dur*scale;
    }

    // Function to end the trip, called by driver and customer
    
    function endTrip(bytes32 encryptedPickup, address driverRequested, uint otp, uint rating){
        require(!currentTrip[otp].customerEnded || !currentTrip[otp].driverEnded, "Trip is already done");
        require(currentTrip[otp].customerAddr == msg.sender || currentTrip[otp].driverAddr == msg.sender);
        

        if(msg.sender == trip.customerAddr && !currentTrip[otp].customerEnded){
            updateReputation(rating, trip.driverAddr, trip.customerAddr);
            currentTrip[otp].customerEnded = true;
        }
        else{
            currentTrip[otp].driverEnded = true;
        }

        if( currentTrip[otp].driverEnded &&  currentTrip[otp].customerEnded){
            
            trip = currentTrip[otp];
            trip.price = getPrice(trip.startTime, trip.endTime);
            trip.driverAddr.transfer(trip.price);
            trip.customerAddr.transfer(customer[trip.customerAddr].paid - trip.price);
            trip.endTime = now;
            updateUniqueDrivers(trip.customerAddr, trip.driverAddr);
            // customers[trip.customerAddr].trips.push(trip);
            // drivers[trip.driverAddr].trips.push(trip);
        }
    }
    
    function cancelTrip(bytes32 encryptedPickup, address driverRequested, uint otp){
        require(currentTrip[otp].customerAddr == msg.sender || currentTrip[otp].driverAddr == msg.sender);
        trip = currentTrip[otp];
        trip.endTime = now;
        // customers[trip.customerAddr].trips.push(trip);
        // drivers[trip.driverAddr].trips.push(trip);
        if(msg.sender == trip.customerAddr){
            trip.price = getPrice(trip.startTime, trip.endTime);
        }
        else{
            trip.price = 0;
        }
        trip.driverAddr.transfer(trip.price);
        trip.customerAddr.transfer(customer[trip.customerAddr].paid - trip.price);
        currentTrip[otp].customerEnded = true;
        currentTrip[otp].driverEnded = true;
    }
    
    // An empty payable function to make the contract payabl
    function () external payable{
    }
}