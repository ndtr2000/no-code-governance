// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/Bytes32ToAddressMapUpgradeable.sol";

contract GovernorFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using Bytes32ToAddressMapUpgradeable for Bytes32ToAddressMapUpgradeable.Bytes32ToAddressMap;
    using ClonesUpgradeable for address;

    Bytes32ToAddressMapUpgradeable.Bytes32ToAddressMap private governorPresets;
    Bytes32ToAddressMapUpgradeable.Bytes32ToAddressMap private voteTokenPresets;
    address public timelockController;
    uint256 private totalGovernor;
    mapping(uint256 => Governor) public governors;

    struct Governor {
        address governor;
        address voteToken;
        address timelock;
    }

    // ========== Events ==========

    event GovernorCreated(
        uint256 id,
        address governor,
        address voteToken,
        address timelock
    );

    // ========== Modifiers ==========

    modifier isValidName(string calldata name) {
        require(bytes(name).length <= 32, "GovernorFactory: invalid name");
        _;
    }

    // ========== Gorvernance ==========

    function initialize(address _timelockController) public initializer {
        timelockController = _timelockController;
        __Ownable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addGovernorPreset(
        string calldata _name,
        address _governorPreset
    ) external onlyOwner isValidName(_name) {
        uint8 nameLength = uint8(bytes(_name).length);
        bytes32 bytesName = bytes32(abi.encodePacked(_name));
        governorPresets.set(bytesName, _governorPreset, nameLength);
    }

    function addVoteTokenPreset(
        string calldata _name,
        address _voteTokenPresets
    ) external onlyOwner isValidName(_name) {
        uint8 nameLength = uint8(bytes(_name).length);
        bytes32 bytesName = bytes32(abi.encodePacked(_name));
        voteTokenPresets.set(bytesName, _voteTokenPresets, nameLength);
    }

    // ========== Public functions ==========

    function createGovernor(
        string calldata _governorPreset,
        string calldata _voteTokenPreset
    ) external returns (address governor, address voteToken, address timelock) {
        governor = getGovernorPresetAddress(_governorPreset).clone();
        voteToken = getVoteTokenPresetAddress(_voteTokenPreset).clone();
        timelock = timelockController.clone();

        uint256 governorId = totalGovernor;
        governors[governorId] = Governor(governor, voteToken, timelock);

        emit GovernorCreated(governorId, governor, voteToken, timelock);

        totalGovernor++;
    }

    // ========== View functions ==========
    function getAllGovernorPresets() external view returns (string[] memory) {
        bytes[] memory keysBytes = governorPresets.keysPacked();
        string[] memory keys = new string[](keysBytes.length);
        for (uint256 i = 0; i < keysBytes.length; i++) {
            keys[i] = string(keysBytes[i]);
        }
        return keys;
    }

    function getAllVoteTokenPresets() external view returns (string[] memory) {
        bytes[] memory keysBytes = voteTokenPresets.keysPacked();
        string[] memory keys = new string[](keysBytes.length);
        for (uint256 i = 0; i < keysBytes.length; i++) {
            keys[i] = string(keysBytes[i]);
        }
        return keys;
    }

    function getGovernorPresetAddress(
        string calldata _name
    ) public view isValidName(_name) returns (address) {
        bytes32 bytesName = bytes32(abi.encodePacked(_name));
        return governorPresets.get(bytesName);
    }

    function getVoteTokenPresetAddress(
        string calldata _name
    ) public view isValidName(_name) returns (address) {
        bytes32 bytesName = bytes32(abi.encodePacked(_name));
        return voteTokenPresets.get(bytesName);
    }

    // ========== Private functions ==========
}
