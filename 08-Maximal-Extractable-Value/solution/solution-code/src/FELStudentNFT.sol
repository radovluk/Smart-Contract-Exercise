// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FELStudentNFT
 * @notice A collection of CTU FEL Student NFTs
 *         - Each NFT represents a unique FEL student with different traits
 *         - Only the owner can mint new NFTs
 *         - The collection features various student traits: degree program at CTU FEL, sleep status, study tools
 */
contract FELStudentNFT is ERC721, Ownable {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // Counter for the next token ID to be minted
    uint256 private _tokenIdCounter;
    
    // Maps each token ID to its trait combination
    mapping(uint256 => string) public studentTrait;
    
    // Available degree programs at CTU FEL
    string[] private degreePrograms = [
        "EEM", "EK", "BIO", "KYR", "OI", "OES", "SIT", "IB", "UEK"
    ];
    
    // Available sleep statuses
    string[] private sleepStatuses = [
        "Caffeinated", "Sleep Deprived", "Dozed Off", "Pulling All-Nighter for Zkouska",
        "Power Napper", "Hibernating", "Sleepwalking", "Dreaming of Statnice"
    ];
    
    // Available study tools
    string[] private studyTools = [
        "Laptop", "Skripta", "Energy Drink", "Headphones", "Kalkulacka", 
        "Tahak", "ChatGPT", "Vlastni vypisky", "Stackoverflow"
    ];

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------
    
    /// Emitted when a new FEL Student NFT is minted
    event FELStudentNFTMinted(uint256 indexed tokenId, string traits);
    
    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Index out of bounds error
    error IndexOutOfBound();
    
    /// Token does not exist
    error TokenDoesNotExist();

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------
    
    /**
     * @dev Initializes the NFT collection with name and symbol
     */
    constructor() ERC721("FEL Student Collection", "FELSC") Ownable(msg.sender) {}

    // ------------------------------------------------------------------------
    //                          External Functions
    // ------------------------------------------------------------------------
    
    /**
     * @dev Mints a new FEL Student NFT to the specified address
     * @param to The address that will receive the minted NFT
     * @param programIndex The index of the degree program in the degreePrograms array
     * @param sleepIndex The index of the sleep status in the sleepStatuses array
     * @param toolIndex The index of the study tool in the studyTools array
     * @return The ID of the newly minted token
     */
    function mint(
        address to, 
        uint8 programIndex, 
        uint8 sleepIndex, 
        uint8 toolIndex
    ) public onlyOwner returns (uint256) {
        if (programIndex >= degreePrograms.length || 
            sleepIndex >= sleepStatuses.length || 
            toolIndex >= studyTools.length) {
            revert IndexOutOfBound();
        }
        
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        // Construct the trait string
        string memory traitCombo = string(abi.encodePacked(
            "Program: ", degreePrograms[programIndex],
            ", Sleep: ", sleepStatuses[sleepIndex],
            ", Tool: ", studyTools[toolIndex]
        ));
        
        // Store the trait combination for the tokenID
        studentTrait[tokenId] = traitCombo;
        
        // Mint the token and transfer to the recipient
        _mint(to, tokenId);
        
        emit FELStudentNFTMinted(tokenId, traitCombo);
        
        return tokenId;
    }
    
    /**
     * @dev Returns the trait combination for a token ID
     * @param tokenId The ID of the token to query
     * @return The trait combination as a string
     */
    function getTraits(uint256 tokenId) external view returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }
        return studentTrait[tokenId];
    }
    
    /**
     * @dev Returns the token URI with metadata about the FEL student
     * @param tokenId The ID of the token to query
     * @return A URI for the token's metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }
        
        // In a real implementation, this would return a proper URI
        // For this example, we just return the trait combination
        return studentTrait[tokenId];
    }
}