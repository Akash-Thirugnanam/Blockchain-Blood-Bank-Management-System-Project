// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BloodBankManagement
 * @dev Blockchain-based blood bank management system smart contract
 * @notice This contract manages blood donations, requests, and transfers on blockchain
 */

contract BloodBankManagement {
    
    // ============================================
    // State Variables
    // ============================================
    
    address public owner;
    uint256 public donationCounter = 0;
    uint256 public requestCounter = 0;
    uint256 public transferCounter = 0;
    
    // Enums
    enum BloodGroup { O_POSITIVE, O_NEGATIVE, A_POSITIVE, A_NEGATIVE, B_POSITIVE, B_NEGATIVE, AB_POSITIVE, AB_NEGATIVE }
    enum DonationType { WHOLE_BLOOD, PLASMA, PLATELET, RBC }
    enum DonationStatus { PENDING, VERIFIED, REJECTED, EXPIRED }
    enum RequestStatus { PENDING, APPROVED, REJECTED, FULFILLED, CANCELLED }
    enum TransferStatus { INITIATED, IN_TRANSIT, DELIVERED, CANCELLED }
    
    // ============================================
    // Structures
    // ============================================
    
    struct Donation {
        uint256 donationId;
        address donor;
        address bloodBank;
        BloodGroup bloodGroup;
        uint256 quantityUnits;
        uint256 donationDate;
        DonationType donationType;
        DonationStatus status;
        string bloodBankRef;
        string ipfsHash;
        uint256 timestamp;
    }
    
    struct BloodRequest {
        uint256 requestId;
        address hospital;
        BloodGroup bloodGroup;
        uint256 quantityUnits;
        RequestStatus status;
        uint256 requestDate;
        uint256 requiredDate;
        string reason;
        bool isEmergency;
        string hospitalRef;
        uint256 timestamp;
    }
    
    struct BloodTransfer {
        uint256 transferId;
        uint256 donationId;
        address fromBloodBank;
        address toHospital;
        BloodGroup bloodGroup;
        uint256 quantityUnits;
        TransferStatus status;
        uint256 transferDate;
        string trackingHash;
        uint256 timestamp;
    }
    
    struct BloodInventory {
        BloodGroup bloodGroup;
        uint256 totalUnits;
        uint256 availableUnits;
        uint256 lastUpdated;
    }
    
    // ============================================
    // Mappings
    // ============================================
    
    mapping(uint256 => Donation) public donations;
    mapping(uint256 => BloodRequest) public requests;
    mapping(uint256 => BloodTransfer) public transfers;
    mapping(address => mapping(BloodGroup => BloodInventory)) public inventory;
    
    // User role management
    mapping(address => bool) public authorizedDonors;
    mapping(address => bool) public authorizedBloodBanks;
    mapping(address => bool) public authorizedHospitals;
    mapping(address => bool) public authorizedAdmins;
    
    // Transaction history
    mapping(address => uint256[]) public userDonations;
    mapping(address => uint256[]) public userRequests;
    mapping(address => uint256[]) public bloodBankTransfers;
    
    // Donor eligibility tracking
    mapping(address => uint256) public lastDonationDate;
    mapping(address => uint256) public totalDonationsCount;
    
    // ============================================
    // Events
    // ============================================
    
    event DonationRegistered(
        uint256 indexed donationId,
        address indexed donor,
        address indexed bloodBank,
        BloodGroup bloodGroup,
        uint256 quantity,
        uint256 timestamp
    );
    
    event DonationVerified(
        uint256 indexed donationId,
        DonationStatus status,
        uint256 timestamp
    );
    
    event BloodRequestCreated(
        uint256 indexed requestId,
        address indexed hospital,
        BloodGroup bloodGroup,
        uint256 quantity,
        bool isEmergency,
        uint256 timestamp
    );
    
    event BloodRequestApproved(
        uint256 indexed requestId,
        uint256 timestamp
    );
    
    event BloodTransferInitiated(
        uint256 indexed transferId,
        uint256 indexed donationId,
        address indexed fromBloodBank,
        address toHospital,
        uint256 timestamp
    );
    
    event BloodTransferCompleted(
        uint256 indexed transferId,
        TransferStatus status,
        uint256 timestamp
    );
    
    event InventoryUpdated(
        address indexed bloodBank,
        BloodGroup bloodGroup,
        uint256 totalUnits,
        uint256 availableUnits,
        uint256 timestamp
    );
    
    event UserRoleAdded(
        address indexed user,
        string role,
        uint256 timestamp
    );
    
    event UserRoleRemoved(
        address indexed user,
        string role,
        uint256 timestamp
    );
    
    // ============================================
    // Modifiers
    // ============================================
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAdmin() {
        require(authorizedAdmins[msg.sender] || msg.sender == owner, "Only admin can call this function");
        _;
    }
    
    modifier onlyAuthorizedDonor() {
        require(authorizedDonors[msg.sender], "Donor not authorized");
        _;
    }
    
    modifier onlyAuthorizedBloodBank() {
        require(authorizedBloodBanks[msg.sender], "Blood bank not authorized");
        _;
    }
    
    modifier onlyAuthorizedHospital() {
        require(authorizedHospitals[msg.sender], "Hospital not authorized");
        _;
    }
    
    modifier validBloodGroup(uint8 bloodGroup) {
        require(bloodGroup >= 0 && bloodGroup <= 7, "Invalid blood group");
        _;
    }
    
    // ============================================
    // Constructor
    // ============================================
    
    constructor() {
        owner = msg.sender;
        authorizedAdmins[msg.sender] = true;
    }
    
    // ============================================
    // Admin Functions - User Management
    // ============================================
    
    /**
     * @dev Add a donor to the system
     * @param _donor Address of the donor
     */
    function addDonor(address _donor) public onlyAdmin {
        require(_donor != address(0), "Invalid donor address");
        require(!authorizedDonors[_donor], "Donor already registered");
        
        authorizedDonors[_donor] = true;
        emit UserRoleAdded(_donor, "DONOR", block.timestamp);
    }
    
    /**
     * @dev Add a blood bank to the system
     * @param _bloodBank Address of the blood bank
     */
    function addBloodBank(address _bloodBank) public onlyAdmin {
        require(_bloodBank != address(0), "Invalid blood bank address");
        require(!authorizedBloodBanks[_bloodBank], "Blood bank already registered");
        
        authorizedBloodBanks[_bloodBank] = true;
        emit UserRoleAdded(_bloodBank, "BLOOD_BANK", block.timestamp);
    }
    
    /**
     * @dev Add a hospital to the system
     * @param _hospital Address of the hospital
     */
    function addHospital(address _hospital) public onlyAdmin {
        require(_hospital != address(0), "Invalid hospital address");
        require(!authorizedHospitals[_hospital], "Hospital already registered");
        
        authorizedHospitals[_hospital] = true;
        emit UserRoleAdded(_hospital, "HOSPITAL", block.timestamp);
    }
    
    /**
     * @dev Add an admin to the system
     * @param _admin Address of the admin
     */
    function addAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Invalid admin address");
        require(!authorizedAdmins[_admin], "Admin already registered");
        
        authorizedAdmins[_admin] = true;
        emit UserRoleAdded(_admin, "ADMIN", block.timestamp);
    }
    
    /**
     * @dev Remove a donor from the system
     * @param _donor Address of the donor
     */
    function removeDonor(address _donor) public onlyAdmin {
        require(authorizedDonors[_donor], "Donor not found");
        
        authorizedDonors[_donor] = false;
        emit UserRoleRemoved(_donor, "DONOR", block.timestamp);
    }
    
    /**
     * @dev Remove a blood bank from the system
     * @param _bloodBank Address of the blood bank
     */
    function removeBloodBank(address _bloodBank) public onlyAdmin {
        require(authorizedBloodBanks[_bloodBank], "Blood bank not found");
        
        authorizedBloodBanks[_bloodBank] = false;
        emit UserRoleRemoved(_bloodBank, "BLOOD_BANK", block.timestamp);
    }
    
    /**
     * @dev Remove a hospital from the system
     * @param _hospital Address of the hospital
     */
    function removeHospital(address _hospital) public onlyAdmin {
        require(authorizedHospitals[_hospital], "Hospital not found");
        
        authorizedHospitals[_hospital] = false;
        emit UserRoleRemoved(_hospital, "HOSPITAL", block.timestamp);
    }
    
    // ============================================
    // Donation Functions
    // ============================================
    
    /**
     * @dev Register a blood donation on blockchain
     * @param _bloodBank Address of the blood bank
     * @param _bloodGroup Blood group (0-7)
     * @param _quantityUnits Quantity of blood units
     * @param _donationType Type of donation
     * @param _ipfsHash IPFS hash for medical records
     * @param _bloodBankRef Blood bank reference ID
     */
    function registerDonation(
        address _bloodBank,
        uint8 _bloodGroup,
        uint256 _quantityUnits,
        uint8 _donationType,
        string memory _ipfsHash,
        string memory _bloodBankRef
    ) public onlyAuthorizedDonor validBloodGroup(_bloodGroup) {
        require(_bloodBank != address(0), "Invalid blood bank address");
        require(authorizedBloodBanks[_bloodBank], "Blood bank not authorized");
        require(_quantityUnits > 0, "Quantity must be greater than 0");
        require(bytes(_bloodBankRef).length > 0, "Blood bank reference required");
        
        // Check donor eligibility (minimum 56 days between donations)
        if (lastDonationDate[msg.sender] != 0) {
            require(block.timestamp >= lastDonationDate[msg.sender] + 56 days, "Donor not eligible - must wait 56 days between donations");
        }
        
        uint256 donationId = donationCounter++;
        
        donations[donationId] = Donation({
            donationId: donationId,
            donor: msg.sender,
            bloodBank: _bloodBank,
            bloodGroup: BloodGroup(_bloodGroup),
            quantityUnits: _quantityUnits,
            donationDate: block.timestamp,
            donationType: DonationType(_donationType),
            status: DonationStatus.PENDING,
            bloodBankRef: _bloodBankRef,
            ipfsHash: _ipfsHash,
            timestamp: block.timestamp
        });
        
        userDonations[msg.sender].push(donationId);
        lastDonationDate[msg.sender] = block.timestamp;
        totalDonationsCount[msg.sender]++;
        
        emit DonationRegistered(
            donationId,
            msg.sender,
            _bloodBank,
            BloodGroup(_bloodGroup),
            _quantityUnits,
            block.timestamp
        );
    }
    
    /**
     * @dev Verify a donation (Blood Bank or Admin)
     * @param _donationId ID of the donation
     * @param _isVerified True if verified, false if rejected
     */
    function verifyDonation(uint256 _donationId, bool _isVerified) public onlyAdmin {
        require(_donationId < donationCounter, "Donation not found");
        
        Donation storage donation = donations[_donationId];
        require(donation.status == DonationStatus.PENDING, "Donation already verified or rejected");
        
        if (_isVerified) {
            donation.status = DonationStatus.VERIFIED;
            
            // Update inventory
            inventory[donation.bloodBank][donation.bloodGroup].totalUnits += donation.quantityUnits;
            inventory[donation.bloodBank][donation.bloodGroup].availableUnits += donation.quantityUnits;
            inventory[donation.bloodBank][donation.bloodGroup].lastUpdated = block.timestamp;
            
            emit InventoryUpdated(
                donation.bloodBank,
                donation.bloodGroup,
                inventory[donation.bloodBank][donation.bloodGroup].totalUnits,
                inventory[donation.bloodBank][donation.bloodGroup].availableUnits,
                block.timestamp
            );
        } else {
            donation.status = DonationStatus.REJECTED;
        }
        
        emit DonationVerified(_donationId, donation.status, block.timestamp);
    }
    
    /**
     * @dev Get donation details
     * @param _donationId ID of the donation
     */
    function getDonation(uint256 _donationId) public view returns (Donation memory) {
        require(_donationId < donationCounter, "Donation not found");
        return donations[_donationId];
    }
    
    /**
     * @dev Get user's donation history
     * @param _user Address of the user
     */
    function getUserDonations(address _user) public view returns (uint256[] memory) {
        return userDonations[_user];
    }
    
    /**
     * @dev Get total donations by a user
     * @param _donor Address of the donor
     */
    function getTotalDonationCount(address _donor) public view returns (uint256) {
        return totalDonationsCount[_donor];
    }
    
    // ============================================
    // Blood Request Functions
    // ============================================
    
    /**
     * @dev Create a blood request
     * @param _bloodGroup Blood group (0-7)
     * @param _quantityUnits Quantity required
     * @param _reason Reason for request
     * @param _isEmergency Is it an emergency request
     * @param _hospitalRef Hospital reference ID
     */
    function createBloodRequest(
        uint8 _bloodGroup,
        uint256 _quantityUnits,
        string memory _reason,
        bool _isEmergency,
        string memory _hospitalRef
    ) public onlyAuthorizedHospital validBloodGroup(_bloodGroup) {
        require(_quantityUnits > 0, "Quantity must be greater than 0");
        require(bytes(_reason).length > 0, "Reason required");
        require(bytes(_hospitalRef).length > 0, "Hospital reference required");
        
        uint256 requestId = requestCounter++;
        uint256 requiredDate = block.timestamp + (_isEmergency ? 1 days : 7 days);
        
        requests[requestId] = BloodRequest({
            requestId: requestId,
            hospital: msg.sender,
            bloodGroup: BloodGroup(_bloodGroup),
            quantityUnits: _quantityUnits,
            status: RequestStatus.PENDING,
            requestDate: block.timestamp,
            requiredDate: requiredDate,
            reason: _reason,
            isEmergency: _isEmergency,
            hospitalRef: _hospitalRef,
            timestamp: block.timestamp
        });
        
        userRequests[msg.sender].push(requestId);
        
        emit BloodRequestCreated(
            requestId,
            msg.sender,
            BloodGroup(_bloodGroup),
            _quantityUnits,
            _isEmergency,
            block.timestamp
        );
    }
    
    /**
     * @dev Approve a blood request
     * @param _requestId ID of the request
     */
    function approveBloodRequest(uint256 _requestId) public onlyAdmin {
        require(_requestId < requestCounter, "Request not found");
        
        BloodRequest storage request = requests[_requestId];
        require(request.status == RequestStatus.PENDING, "Request already processed");
        
        request.status = RequestStatus.APPROVED;
        
        emit BloodRequestApproved(_requestId, block.timestamp);
    }
    
    /**
     * @dev Reject a blood request
     * @param _requestId ID of the request
     */
    function rejectBloodRequest(uint256 _requestId) public onlyAdmin {
        require(_requestId < requestCounter, "Request not found");
        
        BloodRequest storage request = requests[_requestId];
        require(request.status == RequestStatus.PENDING, "Request already processed");
        
        request.status = RequestStatus.REJECTED;
        
        emit BloodRequestApproved(_requestId, block.timestamp);
    }
    
    /**
     * @dev Get blood request details
     * @param _requestId ID of the request
     */
    function getBloodRequest(uint256 _requestId) public view returns (BloodRequest memory) {
        require(_requestId < requestCounter, "Request not found");
        return requests[_requestId];
    }
    
    /**
     * @dev Get hospital's request history
     * @param _hospital Address of the hospital
     */
    function getHospitalRequests(address _hospital) public view returns (uint256[] memory) {
        return userRequests[_hospital];
    }
    
    // ============================================
    // Blood Transfer Functions
    // ============================================
    
    /**
     * @dev Initiate a blood transfer
     * @param _donationId ID of the donation
     * @param _toHospital Address of the receiving hospital
     * @param _trackingHash Tracking hash for the transfer
     */
    function initiateBloodTransfer(
        uint256 _donationId,
        address _toHospital,
        string memory _trackingHash
    ) public onlyAuthorizedBloodBank {
        require(_donationId < donationCounter, "Donation not found");
        require(_toHospital != address(0), "Invalid hospital address");
        require(authorizedHospitals[_toHospital], "Hospital not authorized");
        require(bytes(_trackingHash).length > 0, "Tracking hash required");
        
        Donation storage donation = donations[_donationId];
        require(donation.status == DonationStatus.VERIFIED, "Donation not verified");
        require(donation.bloodBank == msg.sender, "Only blood bank that stored donation can transfer");
        
        // Check inventory availability
        require(
            inventory[msg.sender][donation.bloodGroup].availableUnits >= donation.quantityUnits,
            "Insufficient blood inventory"
        );
        
        uint256 transferId = transferCounter++;
        
        transfers[transferId] = BloodTransfer({
            transferId: transferId,
            donationId: _donationId,
            fromBloodBank: msg.sender,
            toHospital: _toHospital,
            bloodGroup: donation.bloodGroup,
            quantityUnits: donation.quantityUnits,
            status: TransferStatus.IN_TRANSIT,
            transferDate: block.timestamp,
            trackingHash: _trackingHash,
            timestamp: block.timestamp
        });
        
        bloodBankTransfers[msg.sender].push(transferId);
        
        // Reduce available inventory
        inventory[msg.sender][donation.bloodGroup].availableUnits -= donation.quantityUnits;
        
        emit BloodTransferInitiated(
            transferId,
            _donationId,
            msg.sender,
            _toHospital,
            block.timestamp
        );
    }
    
    /**
     * @dev Complete a blood transfer
     * @param _transferId ID of the transfer
     */
    function completeBloodTransfer(uint256 _transferId) public onlyAuthorizedHospital {
        require(_transferId < transferCounter, "Transfer not found");
        
        BloodTransfer storage transfer = transfers[_transferId];
        require(transfer.toHospital == msg.sender, "Only receiving hospital can complete transfer");
        require(transfer.status == TransferStatus.IN_TRANSIT, "Transfer not in transit");
        
        transfer.status = TransferStatus.DELIVERED;
        
        emit BloodTransferCompleted(_transferId, transfer.status, block.timestamp);
    }
    
    /**
     * @dev Get blood transfer details
     * @param _transferId ID of the transfer
     */
    function getBloodTransfer(uint256 _transferId) public view returns (BloodTransfer memory) {
        require(_transferId < transferCounter, "Transfer not found");
        return transfers[_transferId];
    }
    
    /**
     * @dev Get blood bank's transfer history
     * @param _bloodBank Address of the blood bank
     */
    function getBloodBankTransfers(address _bloodBank) public view returns (uint256[] memory) {
        return bloodBankTransfers[_bloodBank];
    }
    
    // ============================================
    // Inventory Functions
    // ============================================
    
    /**
     * @dev Get blood inventory for a blood bank
     * @param _bloodBank Address of the blood bank
     * @param _bloodGroup Blood group (0-7)
     */
    function getInventory(address _bloodBank, uint8 _bloodGroup) public view validBloodGroup(_bloodGroup) returns (BloodInventory memory) {
        return inventory[_bloodBank][BloodGroup(_bloodGroup)];
    }
    
    /**
     * @dev Get available blood units
     * @param _bloodBank Address of the blood bank
     * @param _bloodGroup Blood group (0-7)
     */
    function getAvailableBlood(address _bloodBank, uint8 _bloodGroup) public view validBloodGroup(_bloodGroup) returns (uint256) {
        return inventory[_bloodBank][BloodGroup(_bloodGroup)].availableUnits;
    }
    
    /**
     * @dev Update inventory (Admin only)
     * @param _bloodBank Address of the blood bank
     * @param _bloodGroup Blood group (0-7)
     * @param _totalUnits Total units
     * @param _availableUnits Available units
     */
    function updateInventory(
        address _bloodBank,
        uint8 _bloodGroup,
        uint256 _totalUnits,
        uint256 _availableUnits
    ) public onlyAdmin validBloodGroup(_bloodGroup) {
        require(_bloodBank != address(0), "Invalid blood bank address");
        require(_availableUnits <= _totalUnits, "Available units cannot exceed total units");
        
        inventory[_bloodBank][BloodGroup(_bloodGroup)] = BloodInventory({
            bloodGroup: BloodGroup(_bloodGroup),
            totalUnits: _totalUnits,
            availableUnits: _availableUnits,
            lastUpdated: block.timestamp
        });
        
        emit InventoryUpdated(
            _bloodBank,
            BloodGroup(_bloodGroup),
            _totalUnits,
            _availableUnits,
            block.timestamp
        );
    }
    
    // ============================================
    // Verification Functions
    // ============================================
    
    /**
     * @dev Verify donation authenticity
     * @param _donationId ID of the donation
     */
    function verifyDonationAuthenticity(uint256 _donationId) public view returns (bool) {
        require(_donationId < donationCounter, "Donation not found");
        
        Donation memory donation = donations[_donationId];
        return donation.status == DonationStatus.VERIFIED;
    }
    
    /**
     * @dev Verify transfer authenticity
     * @param _transferId ID of the transfer
     */
    function verifyTransferAuthenticity(uint256 _transferId) public view returns (bool) {
        require(_transferId < transferCounter, "Transfer not found");
        
        BloodTransfer memory transfer = transfers[_transferId];
        return transfer.status == TransferStatus.DELIVERED;
    }
    
    // ============================================
    // Statistics Functions
    // ============================================
    
    /**
     * @dev Get total donations in system
     */
    function getTotalDonations() public view returns (uint256) {
        return donationCounter;
    }
    
    /**
     * @dev Get total requests in system
     */
    function getTotalRequests() public view returns (uint256) {
        return requestCounter;
    }
    
    /**
     * @dev Get total transfers in system
     */
    function getTotalTransfers() public view returns (uint256) {
        return transferCounter;
    }
    
    /**
     * @dev Check if donor is eligible
     * @param _donor Address of the donor
     */
    function isDonorEligible(address _donor) public view returns (bool) {
        if (lastDonationDate[_donor] == 0) {
            return true; // First time donor
        }
        return block.timestamp >= lastDonationDate[_donor] + 56 days;
    }
    
    // ============================================
    // Utility Functions
    // ============================================
    
    /**
     * @dev Get blood group string representation
     * @param _bloodGroup Blood group enum
     */
    function getBloodGroupString(uint8 _bloodGroup) public pure validBloodGroup(_bloodGroup) returns (string memory) {
        BloodGroup bg = BloodGroup(_bloodGroup);
        
        if (bg == BloodGroup.O_POSITIVE) return "O+";
        if (bg == BloodGroup.O_NEGATIVE) return "O-";
        if (bg == BloodGroup.A_POSITIVE) return "A+";
        if (bg == BloodGroup.A_NEGATIVE) return "A-";
        if (bg == BloodGroup.B_POSITIVE) return "B+";
        if (bg == BloodGroup.B_NEGATIVE) return "B-";
        if (bg == BloodGroup.AB_POSITIVE) return "AB+";
        if (bg == BloodGroup.AB_NEGATIVE) return "AB-";
        
        return "UNKNOWN";
    }
    
    /**
     * @dev Get donor status
     * @param _donor Address of the donor
     */
    function getDonorStatus(address _donor) public view returns (bool isAuthorized, uint256 totalDonations, bool isEligible) {
        return (
            authorizedDonors[_donor],
            totalDonationsCount[_donor],
            isDonorEligible(_donor)
        );
    }
}
