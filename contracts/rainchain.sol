// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RainChain
 * @dev A decentralized weather data management system
 * @author RainChain Team
 */
contract Project {
    // Structure to store weather data
    struct WeatherData {
        uint256 timestamp;
        int256 temperature; // in Celsius * 100 (to handle decimals)
        uint256 humidity; // percentage
        uint256 rainfall; // in millimeters * 100
        string location;
        address reporter;
        bool verified;
    }
    
    // Structure to store weather station information
    struct WeatherStation {
        string name;
        string location;
        address owner;
        bool isActive;
        uint256 totalReports;
        uint256 reputationScore;
    }
    
    // State variables
    mapping(uint256 => WeatherData) public weatherRecords;
    mapping(address => WeatherStation) public weatherStations;
    mapping(address => bool) public authorizedStations;
    
    uint256 public totalRecords;
    address public admin;
    uint256 public constant REPUTATION_THRESHOLD = 50;
    
    // Events
    event WeatherDataRecorded(
        uint256 indexed recordId,
        address indexed reporter,
        string location,
        uint256 timestamp
    );
    
    event StationRegistered(
        address indexed stationAddress,
        string name,
        string location
    );
    
    event DataVerified(
        uint256 indexed recordId,
        address indexed verifier
    );
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedStation() {
        require(
            authorizedStations[msg.sender] && weatherStations[msg.sender].isActive,
            "Unauthorized or inactive weather station"
        );
        _;
    }
    
    modifier validRecordId(uint256 _recordId) {
        require(_recordId < totalRecords, "Invalid record ID");
        _;
    }
    
    // Constructor
    constructor() {
        admin = msg.sender;
        totalRecords = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new weather station
     * @param _name Name of the weather station
     * @param _location Geographic location of the station
     */
    function registerWeatherStation(
        string memory _name,
        string memory _location
    ) external {
        require(bytes(_name).length > 0, "Station name cannot be empty");
        require(bytes(_location).length > 0, "Location cannot be empty");
        require(!authorizedStations[msg.sender], "Station already registered");
        
        weatherStations[msg.sender] = WeatherStation({
            name: _name,
            location: _location,
            owner: msg.sender,
            isActive: true,
            totalReports: 0,
            reputationScore: 100 // Starting reputation score
        });
        
        authorizedStations[msg.sender] = true;
        
        emit StationRegistered(msg.sender, _name, _location);
    }
    
    /**
     * @dev Core Function 2: Record weather data
     * @param _temperature Temperature in Celsius * 100
     * @param _humidity Humidity percentage
     * @param _rainfall Rainfall in millimeters * 100
     * @param _location Specific location description
     */
    function recordWeatherData(
        int256 _temperature,
        uint256 _humidity,
        uint256 _rainfall,
        string memory _location
    ) external onlyAuthorizedStation {
        require(_humidity <= 100, "Humidity cannot exceed 100%");
        require(bytes(_location).length > 0, "Location cannot be empty");
        require(_temperature >= -10000 && _temperature <= 6000, "Temperature out of valid range");
        
        weatherRecords[totalRecords] = WeatherData({
            timestamp: block.timestamp,
            temperature: _temperature,
            humidity: _humidity,
            rainfall: _rainfall,
            location: _location,
            reporter: msg.sender,
            verified: false
        });
        
        // Update station statistics
        weatherStations[msg.sender].totalReports++;
        
        emit WeatherDataRecorded(totalRecords, msg.sender, _location, block.timestamp);
        
        totalRecords++;
    }
    
    /**
     * @dev Core Function 3: Verify weather data and update reputation
     * @param _recordId ID of the weather record to verify
     * @param _isAccurate Whether the data is accurate or not
     */
    function verifyWeatherData(
        uint256 _recordId,
        bool _isAccurate
    ) external onlyAdmin validRecordId(_recordId) {
        require(!weatherRecords[_recordId].verified, "Record already verified");
        
        WeatherData storage record = weatherRecords[_recordId];
        WeatherStation storage station = weatherStations[record.reporter];
        
        record.verified = true;
        
        if (_isAccurate) {
            // Increase reputation for accurate data
            station.reputationScore += 5;
            if (station.reputationScore > 1000) {
                station.reputationScore = 1000; // Cap at 1000
            }
        } else {
            // Decrease reputation for inaccurate data
            if (station.reputationScore >= 10) {
                station.reputationScore -= 10;
            } else {
                station.reputationScore = 0;
            }
            
            // Deactivate station if reputation falls below threshold
            if (station.reputationScore < REPUTATION_THRESHOLD) {
                station.isActive = false;
                authorizedStations[record.reporter] = false;
            }
        }
        
        emit DataVerified(_recordId, msg.sender);
    }
    
    // Additional utility functions
    
    /**
     * @dev Get weather data by record ID
     * @param _recordId ID of the weather record
     * @return WeatherData struct
     */
    function getWeatherData(uint256 _recordId) 
        external 
        view 
        validRecordId(_recordId) 
        returns (WeatherData memory) 
    {
        return weatherRecords[_recordId];
    }
    
    /**
     * @dev Get weather station information
     * @param _stationAddress Address of the weather station
     * @return WeatherStation struct
     */
    function getStationInfo(address _stationAddress) 
        external 
        view 
        returns (WeatherStation memory) 
    {
        return weatherStations[_stationAddress];
    }
    
    /**
     * @dev Reactivate a weather station (admin only)
     * @param _stationAddress Address of the station to reactivate
     */
    function reactivateStation(address _stationAddress) external onlyAdmin {
        require(authorizedStations[_stationAddress], "Station not registered");
        weatherStations[_stationAddress].isActive = true;
        weatherStations[_stationAddress].reputationScore = 100; // Reset reputation
    }
    
    /**
     * @dev Get total number of records
     * @return Total number of weather records
     */
    function getTotalRecords() external view returns (uint256) {
        return totalRecords;
    }
}
