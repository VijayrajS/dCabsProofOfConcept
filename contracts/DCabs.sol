pragma solidity ^0.5.10;

contract DCabs {
    
    address public auditor; //!< Person who authorises the registration of a cab driver into the system
    
    //!< structure that stores trip data
    
    struct Trip {
        bytes32 pickupHash; //!< Hash of the pickup address
        bytes32 destHash;   //!< Hash of the destination address 
        
        uint duration;        //!< Duration of the cab ride in minutes
        address driverAddr;   //!< Wallet address of the driver involved
        address customerAddr; //!< Wallet address of the customer involved
        
        uint price;           //!< Expense of the trip
        uint rating;          //!< Rating of the 
        string comments;      //!< Customer comments of the ride
        uint canEnd;          //!< Variable to determine whether the trip can end (Details given later)
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
        Trip[] driverTrips;     //!< List of all trips undertaken by the driver 
        bool registered;        //!< A boolean variable that determines whether the driver is registered or not
    }
    
    //!< Structure that stores the details of a customer
    
    struct Customer{
        uint paid;              //!< The amount of money the customer has deposited in the contract
        uint uniqueDrivers;     //!< Number of unique cab drivers the customer has ridden with
        Trip[] customerTrips;   //!< List of all trips embarked on by the customer
    }
    
    mapping(address => Customer) customers;       //!< Mapping b/w a customer profile and his wallet address
    mapping(address => Driver) drivers;           //!< Mapping b/w a driver profile and his wallet address
    mapping(address => TripRequest) activeTrips;  //!< Mapping b/w a driver address and a TripRequest object (corresponding to an ongoing trip)
    mapping(address => Trip) currentTrip;         //!< SUS (?)
    
    // Function to register a driver into the system
    function registerDriver public(address driverAddr, uint license){
        require(msg.sender == auditor);
        drivers[driverAddr].driverLicense = license;
        drivers[driverAddr].registered = true;
    }
    
    // Function to send a pickup request to a particular driver and pay a flat fee amount
    function setPickup(bytes32 encryptedPickup, address driverRequested) public payable{
        require(msg.value == 1 ether, "PAY UP THE MANDATORY FEE");
        activeTrips[driverRequested].encryptedPickup = encyptedPickup;
    }
    
    // Function for driver to accept the trip
    function acceptTrip(bytes32 driverPhoneNumEncrpyted) public {
        require(drivers[msg.sender].registered);
        activeTrips[msg.sender].accepted = true;
        activeTrips[msg.sender].driverPhoneNumEncrpyted = driverPhoneNumEncrpyted
        enterTripDetails(msg.sender, activeTrips[msg.sender].customer, activeTrips[msg.sender].pickupHash, activeTrips[msg.sender].destHash);
    }
    
    // Function to 
    function enterTripDetails(bytes32 driverAddress, bytes32 customerAddress, bytes32 pickupHash, bytes32 destHash){
        
    }
    
    // Wait what
    function cancelRequest(bytes32 encryptedPickup, address driverRequested){
        activeTrips[driverRequested].encryptedPickup = encyptedPickup;
    }
    
    function endTrip(bytes32 encryptedPickup, address driverRequested){
        require(currentTrip[msg.sender]);
        currentTrip[msg.sender].canEnd += 1;
        if(currentTrip[msg.sender].canEnd == 2){
            trip = currentTrip[msg.sender];
            trip.price = getPrice();
            trip.driverAddr.transfer(trip.price);
            trip.customerAddr.transfer(customer[trip.customerAddr].paid - trip.price);
            
            if(msg.sender == trip.customerAddr){
                updateReputation(rating, trip.customerAddr);
                updateUniqueDrivers(trip.customerAddr, trip.driverAddr);
            }
            customers[trip.customerAddr].trips.push(trip);
            drivers[trip.driverAddr].trips.push(trip);
        }
    }
    
    function cancelTrip(bytes32 encryptedPickup, address driverRequested){
        trip = currentTrip[msg.sender];
        trip.price = getPrice();
        if(msg.sender is not a driver)
            trip.driverAddr.transfer(trip.price);
            trip.customerAddr.transfer(customer[trip.customerAddr].paid - trip.price);
        else transfer all fee back to customer
        
        customers[trip.customerAddr].trips.push(trip);
        drivers[trip.driverAddr].trips.push(trip);
        //Similar format to endTrip < Getting Rating etc.>
    }
    
    // An empty payable function to make the contract payabl
    function () external payable{
    }
}