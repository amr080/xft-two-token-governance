// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { IERC20 } from "../interfaces/ImportedInterfaces.sol";
import { ISPOG } from "../interfaces/ISPOG.sol";
import { ISPOGGovernor } from "../interfaces/ISPOGGovernor.sol";
import { ISPOGVault } from "../interfaces/periphery/ISPOGVault.sol";
import { IVALUE, IVOTE } from "../interfaces/ITokens.sol";

import { PureEpochs } from "../pureEpochs/PureEpochs.sol";

import { SafeERC20 } from "../ImportedContracts.sol";

// TODO: "Lists" that are not enumerable are actually "Sets".

/// @title SPOG
/// @notice Contracts for governing lists and managing communal property through token voting
/// @dev Reference: https://github.com/MZero-Labs/SPOG-Spec/blob/main/README.md
/// @notice SPOG, "Simple Participation Optimized Governance"
/// @notice SPOG is used for permissioning actors and optimized for token holder participation
contract SPOG is ISPOG {
    using SafeERC20 for IERC20;

    // TODO: Drop the need for a struct for the constructor. Use named arguments instead.
    struct Configuration {
        address governor;
        address vault;
        address cash;
        uint256 tax;
        uint256 taxLowerBound;
        uint256 taxUpperBound;
        uint256 inflator;
        uint256 valueFixedInflation;
    }

    /// TODO find the right one for better precision
    uint256 private constant _INFLATOR_SCALE = 100;

    /// @notice Vault for value holders assets
    address public immutable vault;

    /// @notice Cash token used for proposal fee payments
    address public immutable cash;

    /// @notice Fixed inflation rewards per epoch for value holders
    uint256 public immutable valueFixedInflation;

    /// @notice Inflation rate per epoch for vote holders
    uint256 public immutable inflator;

    /// @notice Governor, upgradable via `reset` by value holders
    address public governor;

    /// @notice Tax value for proposal cash fee
    uint256 public tax;

    /// @notice Tax range: lower bound for proposal cash fee
    uint256 public taxLowerBound;

    /// @notice Tax range: upper bound for proposal cash fee
    uint256 public taxUpperBound;

    mapping(bytes32 key => bytes32 value) internal _valueAt;

    /// @dev Modifier checks if caller is a governor address
    modifier onlyGovernance() {
        if (msg.sender != governor) revert OnlyGovernor();

        _;
    }

    /// @notice Constructs a new SPOG instance
    /// @param config The configuration data for the SPOG
    constructor(Configuration memory config) {
        // Sanity checks
        if (config.governor == address(0)) revert ZeroGovernorAddress();
        if (config.vault == address(0)) revert ZeroVaultAddress();
        if (config.cash == address(0)) revert ZeroCashAddress();
        if (config.tax == 0) revert ZeroTax();
        if (config.tax < config.taxLowerBound || config.tax > config.taxUpperBound) revert TaxOutOfRange();
        if (config.inflator == 0) revert ZeroInflator();
        if (config.valueFixedInflation == 0) revert ZeroValueInflation();

        // Set configuration data
        governor = config.governor;

        // Initialize governor
        ISPOGGovernor(governor).initializeSPOG(address(this));

        vault = config.vault;
        cash = config.cash;
        tax = config.tax;
        taxLowerBound = config.taxLowerBound;
        taxUpperBound = config.taxUpperBound;
        inflator = config.inflator;
        valueFixedInflation = config.valueFixedInflation;
    }

    /// @notice Add an address to a list
    /// @param listName The name of the list to which the address will be added.
    /// @param account The address to be added to the list
    function addToList(bytes32 listName, address account) external onlyGovernance {
        _addToList(listName, account);
    }

    /// @notice Remove an address from a list
    /// @param listName The name of the list from which the address will be removed
    /// @param account The address to be removed from the list
    function removeFromList(bytes32 listName, address account) external onlyGovernance {
        _removeFromList(listName, account);
    }

    /// @notice Change the protocol configs
    /// @param valueName The name of the config to be updated
    /// @param value The value to update the config to
    function updateConfig(bytes32 valueName, bytes32 value) external onlyGovernance {
        _updateConfig(valueName, value);
    }

    /// @notice Emergency version of existing methods
    /// @param emergencyType The type of emergency method to be called (See enum in ISPOG)
    /// @param callData The data to be used for the target method
    /// @dev Emergency methods are encoded much like change proposals
    function emergency(uint8 emergencyType, bytes calldata callData) external onlyGovernance {
        EmergencyType emergencyType_ = EmergencyType(emergencyType);

        emit EmergencyExecuted(emergencyType, callData);

        if (emergencyType_ == EmergencyType.RemoveFromList) {
            (bytes32 listName, address account) = abi.decode(callData, (bytes32, address));
            _removeFromList(listName, account);
            return;
        }

        if (emergencyType_ == EmergencyType.AddToList) {
            (bytes32 listName, address account) = abi.decode(callData, (bytes32, address));
            _addToList(listName, account);
            return;
        }

        if (emergencyType_ == EmergencyType.UpdateConfig) {
            (bytes32 valueName, bytes32 value) = abi.decode(callData, (bytes32, bytes32));
            _updateConfig(valueName, value);
            return;
        }

        revert EmergencyMethodNotSupported();
    }

    /// @notice Reset current governor, special value governance method
    /// @param newGovernor The address of the new governor
    function reset(address newGovernor) external onlyGovernance {
        // NOTE: This function already ensures `newGovernor` implements `initializeSPOG`, `value`, and `vote`.
        //       It does not ensure `newGovernor` implements `currentEpoch` for `chargeFee`.
        governor = newGovernor;

        // Important: initialize SPOG address in the new vote governor
        ISPOGGovernor(governor).initializeSPOG(address(this));

        // Take snapshot of value token balances at the moment of reset
        // Update reset snapshot id for the voting token
        uint256 resetId = IVALUE(ISPOGGovernor(governor).value()).snapshot();
        IVOTE(ISPOGGovernor(governor).vote()).reset(resetId);

        emit ResetExecuted(newGovernor, resetId);
    }

    /// @notice Change the tax rate which is used to calculate the proposal fee
    /// @param newTax The new tax rate
    function changeTax(uint256 newTax) external onlyGovernance {
        if (newTax < taxLowerBound || newTax > taxUpperBound) revert TaxOutOfRange();

        emit TaxChanged(tax, newTax);

        tax = newTax;
    }

    /// @notice Change the tax range which is used to calculate the proposal fee
    /// @param newTaxLowerBound The new lower bound of the tax range
    /// @param newTaxUpperBound The new upper bound of the tax range
    function changeTaxRange(uint256 newTaxLowerBound, uint256 newTaxUpperBound) external onlyGovernance {
        if (newTaxLowerBound > newTaxUpperBound) revert InvalidTaxRange();

        emit TaxRangeChanged(taxLowerBound, newTaxLowerBound, taxUpperBound, newTaxUpperBound);

        taxLowerBound = newTaxLowerBound;
        taxUpperBound = newTaxUpperBound;
    }

    /// @notice Charge fee for calling a governance function
    /// @param account The address of the caller
    function chargeFee(address account, bytes4 /*func*/) external onlyGovernance returns (uint256) {
        // transfer the amount from the caller to the SPOG
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(cash).safeTransferFrom(account, address(this), tax);

        // approve amount to be sent to the vault
        IERC20(cash).approve(vault, tax);

        // deposit the amount to the vault
        uint256 epoch = PureEpochs.currentEpoch();
        ISPOGVault(vault).deposit(epoch, cash, tax);

        emit ProposalFeeCharged(account, epoch, tax);

        return tax;
    }

    /// @notice Check is proposed change is supported by governance
    /// @param selector The function selector to check
    /// @return Whether the function is supported by governance
    function isGovernedMethod(bytes4 selector) external pure returns (bool) {
        /// @dev ordered by frequency of usage
        return
            selector == this.addToList.selector ||
            selector == this.updateConfig.selector ||
            selector == this.removeFromList.selector ||
            selector == this.changeTax.selector ||
            selector == this.changeTaxRange.selector ||
            selector == this.emergency.selector ||
            selector == this.reset.selector;
    }

    /// @dev
    function getInflationReward(uint256 amount) external view returns (uint256) {
        // TODO: prevent overflow, precision loss ?
        return (amount * inflator) / _INFLATOR_SCALE;
    }

    function get(bytes32 key) external view returns (bytes32 value) {
        value = _valueAt[key];
    }

    function get(bytes32[] calldata keys) external view returns (bytes32[] memory values) {
        values = new bytes32[](keys.length);

        for (uint256 index_; index_ < keys.length; ++index_) {
            values[index_] = _valueAt[keys[index_]];
        }
    }

    function listContains(bytes32 listName, address account) external view returns (bool contains) {
        contains = _valueAt[_getKeyInSet(listName, account)] == bytes32(uint256(1));
    }

    function _addToList(bytes32 listName, address account) internal {
        // add the address to the list
        _valueAt[_getKeyInSet(listName, account)] = bytes32(uint256(1));

        emit AddressAddedToList(listName, account);
    }

    function _removeFromList(bytes32 listName, address account) internal {
        // remove the address from the list
        delete _valueAt[_getKeyInSet(listName, account)];

        emit AddressRemovedFromList(listName, account);
    }

    function _updateConfig(bytes32 valueName, bytes32 value) internal {
        _valueAt[valueName] = value;

        emit ConfigUpdated(valueName, value);
    }

    function _getKeyInSet(bytes32 listName, address account) private pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(listName, account));
    }
}
