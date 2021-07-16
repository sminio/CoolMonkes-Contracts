// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BoostPasses is ERC721, Pausable, Ownable {
   using SafeMath for uint256;
   using ECDSA for bytes32;

    address public enforcerAddress;
    
    uint256 public count;

    //Monkeworld Socio-economic Ecosystem
    uint256 public constant maxBoosts = 10000;
    
    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Reveal will be conducted on our API to prevent rarity sniping
    //Post reveal token metadata will be migrated from API and permanently frozen on IPFS
    string public baseTokenURI = "https://www.coolmonkes.io/api/metadata/boost/";

    constructor() ERC721("Cool Monkes Boosts", "CMBSTS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function multiMint(uint amount, address to) private {
        require(amount > 0, "Invalid amount");

        uint256 nextId = count + 1;

        for (uint i = 0; i < amount; i++) {
            _mint(to, nextId + i);
        }

        count += amount;
    }

    //Returns nounce for earner to enable transaction parity for security, next nounce has to be > than this value!
    function minterCurrentNounce(address minter) public view returns (uint256) {
        return nounceTracker[minter];
    }

    function getMessageHash(address _to, uint _amount, uint _price, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _price, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _price, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _price, _nounce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function mint(uint amount, uint price, uint nounce, bytes memory signature) public whenNotPaused  {
        require(count + amount <= maxBoosts, "Boosts are sold out!");
        require(nounceTracker[_msgSender()] < nounce, "Can not repeat a prior transaction!");
        require(verify(enforcerAddress, _msgSender(), amount, price, nounce, signature) == true, "Boosts must be minted from our website");

        nounceTracker[_msgSender()] = nounce;
       
        multiMint(amount, _msgSender());
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}