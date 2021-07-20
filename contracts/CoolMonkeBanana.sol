// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CoolMonkeBanana is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address public enforcerAddress;

    //Monkeworld Socio-economic Ecosystem
    //This maximum value is not used by default, can be turned on if necessary in the future if optimal for $CMB ecosystem health
    uint256 public totalCMBMinted = 0;
    uint256 public maxCMBLimit = 0;

    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Approved Spender Contracts
    mapping(address => bool) public approvedSpenders;

    //Last claim timestamp
    mapping(address => uint80) public lastClaim;

    constructor() ERC20("Cool Monke Banana", "CMB") ERC20Permit("Cool Monke Banana") {}

    //Returns nounce for earner to enable transaction parity for security, next nounce has to be > than this value!
    function earnerCurrentNounce(address earner) public view returns (uint256) {
        return nounceTracker[earner];
    }

    function getMessageHash(address _to, uint _amount, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _nounce);
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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMaxLimit(uint256 amount) public onlyOwner {
        amount = amount * (10 ** 18);
        require(amount >= totalCMBMinted, 'Max limit is lower than already minted supply!');
        maxCMBLimit = amount;
    }

    function setApprovedSpender(address spender, bool enabled) public onlyOwner {
        approvedSpenders[spender] = enabled;
    }

    function mint(address to, uint256 amount, uint nounce, bytes memory signature) public whenNotPaused {
        require(to == _msgSender(), 'Not your earnings!');
        require(nounceTracker[_msgSender()] < nounce, "Can not repeat a prior transaction!");
        require(verify(enforcerAddress, _msgSender(), amount, nounce, signature) == true, "CMB must be minted from our website!");
        amount = amount * (10 ** 18);
        if (maxCMBLimit > 0) {
            require(totalCMBMinted + amount <= maxCMBLimit, 'Max CMB minting limit has been reached!');
            totalCMBMinted += amount;
        }

        nounceTracker[_msgSender()] = nounce;
        lastClaim[_msgSender()] = uint80(block.timestamp);
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
}